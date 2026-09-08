<?php

namespace App\Services;

use App\Models\Company;
use App\Models\Employee;
use App\Models\Payroll;
use App\Models\PayrollItem;
use App\Models\TaxForm1721A1;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class TaxForm1721A1Service
{
    public function __construct(
        protected PayrollCalculationService $calculationService
    ) {}

    /**
     * Generate 1721-A1 tax form for a single employee
     */
    public function generateForEmployee(Employee $employee, int $taxYear, int $generatedBy): TaxForm1721A1
    {
        $company = $employee->company;

        // Get all payroll items for the employee in the tax year
        $payrollItems = $this->getPayrollItemsForYear($employee->id, $company->id, $taxYear);

        // Calculate annual totals
        $calculations = $this->calculateAnnualTotals($payrollItems, $employee);

        // Create or update tax form
        return TaxForm1721A1::updateOrCreate(
            [
                'company_id' => $company->id,
                'employee_id' => $employee->id,
                'tax_year' => $taxYear,
            ],
            array_merge($calculations, [
                // Company data
                'company_npwp' => $company->npwp,
                'company_name' => $company->name,
                'company_address' => $company->address,
                // Employee data
                'employee_npwp' => $employee->npwp,
                'employee_nik' => $employee->identity_number,
                'employee_name' => $employee->full_name,
                'employee_address' => $employee->address,
                'ptkp_status' => $employee->tax_status,
                // Timestamps
                'generated_at' => now(),
                'generated_by' => $generatedBy,
            ])
        );
    }

    /**
     * Generate 1721-A1 forms for all employees with payroll data in a year
     */
    public function generateBulk(Company $company, int $taxYear, int $generatedBy): Collection
    {
        // Get all employees who have payroll data for the year
        $employeeIds = PayrollItem::whereHas('payroll', function ($query) use ($company, $taxYear) {
            $query->where('company_id', $company->id)
                ->where('period_year', $taxYear)
                ->where('status', 'paid');
        })->distinct()->pluck('employee_id');

        $employees = Employee::whereIn('id', $employeeIds)->get();

        $taxForms = collect();

        DB::transaction(function () use ($employees, $taxYear, $generatedBy, &$taxForms) {
            foreach ($employees as $employee) {
                $taxForm = $this->generateForEmployee($employee, $taxYear, $generatedBy);
                $taxForms->push($taxForm);
            }
        });

        return $taxForms;
    }

    /**
     * Regenerate an existing tax form with latest payroll data
     */
    public function regenerate(TaxForm1721A1 $taxForm, int $generatedBy): TaxForm1721A1
    {
        $employee = $taxForm->employee;
        $company = $taxForm->company;

        $payrollItems = $this->getPayrollItemsForYear(
            $employee->id,
            $company->id,
            $taxForm->tax_year
        );

        $calculations = $this->calculateAnnualTotals($payrollItems, $employee);

        $taxForm->update(array_merge($calculations, [
            'generated_at' => now(),
            'generated_by' => $generatedBy,
        ]));

        return $taxForm->fresh();
    }

    /**
     * Get payroll items for an employee in a specific year
     */
    protected function getPayrollItemsForYear(int $employeeId, int $companyId, int $year): Collection
    {
        return PayrollItem::with(['payroll', 'details'])
            ->whereHas('payroll', function ($query) use ($companyId, $year) {
                $query->where('company_id', $companyId)
                    ->where('period_year', $year)
                    ->where('status', 'paid');
            })
            ->where('employee_id', $employeeId)
            ->orderBy('id')
            ->get();
    }

    /**
     * Calculate annual totals from payroll items
     */
    protected function calculateAnnualTotals(Collection $payrollItems, Employee $employee): array
    {
        if ($payrollItems->isEmpty()) {
            return $this->getEmptyCalculations($employee);
        }

        // Find the work period (first and last month with payroll)
        $months = $payrollItems->map(fn ($item) => $item->payroll->period_month)->sort();
        $workStartMonth = $months->first();
        $workEndMonth = $months->last();

        // Sum up annual totals
        $annualBasicSalary = 0;
        $annualTotalEarnings = 0;
        $annualGrossSalary = 0;
        $annualTaxAmount = 0;
        $annualBpjsJht = 0;
        $annualBpjsJp = 0;

        foreach ($payrollItems as $item) {
            $annualBasicSalary += (float) $item->basic_salary;
            $annualTotalEarnings += (float) $item->total_earnings;
            $annualGrossSalary += (float) $item->gross_salary;
            $annualTaxAmount += (float) $item->tax_amount;

            // Get BPJS contributions from details. Matched by the exact
            // component_code every addDetail() call site uses for these
            // (BPJS-JHT/BPJS-JP) — a substring match on component_name was
            // used here previously and could wrongly match an unrelated
            // custom component whose name merely contained "JHT"/"JP".
            foreach ($item->details as $detail) {
                if ($detail->component_code === 'BPJS-JHT') {
                    $annualBpjsJht += (float) $detail->amount;
                }
                if ($detail->component_code === 'BPJS-JP') {
                    $annualBpjsJp += (float) $detail->amount;
                }
            }
        }

        // Calculate biaya jabatan (5% of gross, max 6 million per year)
        $biayaJabatan = min($annualGrossSalary * 0.05, 6000000);

        // Iuran pensiun = BPJS JHT + JP yang dibayar karyawan
        $iuranPensiun = $annualBpjsJht + $annualBpjsJp;

        $totalPengurang = $biayaJabatan + $iuranPensiun;

        // Neto salary
        $netoSalary = $annualGrossSalary - $totalPengurang;

        // PTKP
        $ptkpStatus = $employee->tax_status ?? 'TK/0';
        $ptkp = $this->calculationService->getPtkpAnnual($employee->company_id, $ptkpStatus);

        // PKP (Penghasilan Kena Pajak)
        $pkp = max(0, $netoSalary - $ptkp);

        // PPh21 Terutang (recalculated using progressive rate)
        $pph21Terutang = $this->calculationService->calculateProgressiveTax($employee->company_id, $pkp);

        return [
            'work_start_month' => $workStartMonth,
            'work_end_month' => $workEndMonth,
            'gaji_pokok' => $annualBasicSalary,
            'tunjangan_pph' => 0,
            'tunjangan_lainnya' => $annualTotalEarnings,
            'honorarium' => 0,
            'premi_asuransi' => 0,
            'natura' => 0,
            'tantiem_bonus_thr' => 0,
            'gross_salary' => $annualGrossSalary,
            'biaya_jabatan' => $biayaJabatan,
            'iuran_pensiun' => $iuranPensiun,
            'total_pengurang' => $totalPengurang,
            'neto_salary' => $netoSalary,
            'ptkp' => $ptkp,
            'ptkp_status' => $ptkpStatus,
            'pkp' => $pkp,
            'pph21_terutang' => $pph21Terutang,
            'pph21_dipotong_sebelumnya' => 0,
            'total_pph21_withheld' => $annualTaxAmount,
        ];
    }

    /**
     * Get empty calculations for employee with no payroll data
     */
    protected function getEmptyCalculations(Employee $employee): array
    {
        $ptkpStatus = $employee->tax_status ?? 'TK/0';
        $ptkp = $this->calculationService->getPtkpAnnual($employee->company_id, $ptkpStatus);

        return [
            'work_start_month' => 1,
            'work_end_month' => 12,
            'gaji_pokok' => 0,
            'tunjangan_pph' => 0,
            'tunjangan_lainnya' => 0,
            'honorarium' => 0,
            'premi_asuransi' => 0,
            'natura' => 0,
            'tantiem_bonus_thr' => 0,
            'gross_salary' => 0,
            'biaya_jabatan' => 0,
            'iuran_pensiun' => 0,
            'total_pengurang' => 0,
            'neto_salary' => 0,
            'ptkp' => $ptkp,
            'ptkp_status' => $ptkpStatus,
            'pkp' => 0,
            'pph21_terutang' => 0,
            'pph21_dipotong_sebelumnya' => 0,
            'total_pph21_withheld' => 0,
        ];
    }

    /**
     * Get available years for tax form generation
     */
    public function getAvailableYears(int $companyId): array
    {
        return Payroll::where('company_id', $companyId)
            ->where('status', 'paid')
            ->distinct()
            ->pluck('period_year')
            ->sort()
            ->values()
            ->toArray();
    }

    /**
     * Get employees with payroll data for a specific year
     */
    public function getEmployeesWithPayrollForYear(int $companyId, int $year): Collection
    {
        $employeeIds = PayrollItem::whereHas('payroll', function ($query) use ($companyId, $year) {
            $query->where('company_id', $companyId)
                ->where('period_year', $year)
                ->where('status', 'paid');
        })->distinct()->pluck('employee_id');

        return Employee::whereIn('id', $employeeIds)
            ->where('company_id', $companyId)
            ->orderBy('first_name')
            ->get();
    }
}
