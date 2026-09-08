<?php

namespace App\Services;

use App\Models\BpjsKesSetting;
use App\Models\BpjsTkSetting;
use App\Models\Employee;
use App\Models\Pph21Rate;
use App\Models\Pph21Setting;
use App\Models\Pph21TerRate;
use App\Models\PtkpSetting;

class PayrollCalculationService
{
    /**
     * Calculate all payroll components for an employee
     *
     * @param  array{
     *     gross_salary: float,
     *     basic_salary: float,
     *     total_earnings: float,
     *     taxable_earnings: float
     * }  $salaryData
     * @return array{
     *     pph21: float,
     *     bpjs_kes_employee: float,
     *     bpjs_kes_company: float,
     *     bpjs_tk_employee: float,
     *     bpjs_tk_company: float,
     *     bpjs_tk_details: array,
     *     total_deductions: float,
     *     net_salary: float
     * }
     */
    public function calculate(Employee $employee, array $salaryData, int $companyId): array
    {
        $grossSalary = $salaryData['gross_salary'];

        // Calculate BPJS first (as it may affect taxable income)
        $bpjsKes = $this->calculateBpjsKesehatan($companyId, $grossSalary);
        $bpjsTk = $this->calculateBpjsKetenagakerjaan($companyId, $grossSalary);

        // PPh21 is calculated on the taxable base only (basic salary + taxable
        // earning components), excluding non-taxable items such as expense
        // reimbursements. Falls back to gross salary when the caller doesn't
        // distinguish taxable earnings.
        $taxableBase = isset($salaryData['taxable_earnings'])
            ? ($salaryData['basic_salary'] ?? 0) + $salaryData['taxable_earnings']
            : $grossSalary;

        $pph21 = $this->calculatePph21($companyId, $employee, $taxableBase);

        // Total employee deductions
        $totalDeductions = $salaryData['total_deductions'] ?? 0;
        $totalDeductions += $bpjsKes['employee'];
        $totalDeductions += $bpjsTk['employee_total'];

        // When PPh21 is borne by the company ("Ditanggung Perusahaan"), the
        // employee's take-home pay isn't reduced by it — the tax is still
        // calculated and reported (tax_amount, for SPT/Bukti Potong
        // compliance), it just isn't deducted from net salary.
        $isGrossUp = (bool) (Pph21Setting::where('company_id', $companyId)->first()?->is_gross_up ?? false);
        $netSalary = $isGrossUp
            ? $grossSalary - $totalDeductions
            : $grossSalary - $totalDeductions - $pph21;

        return [
            'pph21' => round($pph21, 0),
            'bpjs_kes_employee' => round($bpjsKes['employee'], 0),
            'bpjs_kes_company' => round($bpjsKes['company'], 0),
            'bpjs_tk_employee' => round($bpjsTk['employee_total'], 0),
            'bpjs_tk_company' => round($bpjsTk['company_total'], 0),
            'bpjs_tk_details' => $bpjsTk,
            'total_deductions' => round($totalDeductions, 0),
            'net_salary' => round($netSalary, 0),
            'is_gross_up' => $isGrossUp,
        ];
    }

    /**
     * Calculate PPh21 using TER (Tarif Efektif Rata-rata) method
     */
    public function calculatePph21(int $companyId, Employee $employee, float $grossSalary): float
    {
        // Get PPh21 settings
        $settings = Pph21Setting::where('company_id', $companyId)->first();

        if (! $settings) {
            // Default: 5% simplified calculation if no settings
            return $grossSalary * 0.05;
        }

        // Get employee tax status (PTKP status)
        $taxStatus = $employee->tax_status ?? 'TK/0';
        $hasNpwp = ! empty($employee->npwp);

        if ($settings->use_ter) {
            // Use TER (Tarif Efektif Rata-rata) method
            $terRate = $this->getTerRate($companyId, $taxStatus, $grossSalary);

            if ($terRate) {
                $pph21 = $grossSalary * ($terRate / 100);
            } else {
                // Fallback to simplified calculation
                $pph21 = $this->calculatePph21Progressive($companyId, $grossSalary, $taxStatus);
            }
        } else {
            // Use progressive rate
            $pph21 = $this->calculatePph21Progressive($companyId, $grossSalary, $taxStatus);
        }

        // Apply NPWP discount (20% higher if no NPWP)
        if (! $hasNpwp) {
            $npwpPenalty = $settings->npwp_discount_rate ?? 20;
            $pph21 = $pph21 * (1 + ($npwpPenalty / 100));
        }

        return max(0, $pph21);
    }

    /**
     * Get TER rate based on category and gross income
     */
    protected function getTerRate(int $companyId, string $taxStatus, float $grossSalary): ?float
    {
        // Determine TER category based on PTKP status
        $category = $this->getTerCategoryByPtkpStatus($taxStatus);

        // Find matching TER rate
        $terRate = Pph21TerRate::where('company_id', $companyId)
            ->where('category', $category)
            ->where('is_active', true)
            ->where('min_income', '<=', $grossSalary)
            ->where(function ($query) use ($grossSalary) {
                $query->whereNull('max_income')
                    ->orWhere('max_income', '>=', $grossSalary);
            })
            ->orderBy('min_income', 'desc')
            ->first();

        return $terRate?->rate;
    }

    /**
     * Get TER category based on PTKP status
     */
    protected function getTerCategoryByPtkpStatus(string $status): string
    {
        $categoryA = ['TK/0', 'TK/1', 'K/0'];
        $categoryB = ['TK/2', 'TK/3', 'K/1', 'K/2'];
        $categoryC = ['K/3', 'K/I/0', 'K/I/1', 'K/I/2', 'K/I/3'];

        if (in_array($status, $categoryA)) {
            return 'A';
        }

        if (in_array($status, $categoryB)) {
            return 'B';
        }

        if (in_array($status, $categoryC)) {
            return 'C';
        }

        // Default to category A
        return 'A';
    }

    /**
     * Calculate PPh21 using progressive rate (fallback)
     * Simplified version based on monthly gross salary
     */
    protected function calculatePph21Progressive(int $companyId, float $grossSalary, string $taxStatus): float
    {
        $ptkpMonthly = $this->getPtkpMonthly($companyId, $taxStatus);

        // Calculate taxable income (PKP)
        $pkp = max(0, $grossSalary - $ptkpMonthly);

        if ($pkp <= 0) {
            return 0;
        }

        // Annual PKP estimation
        $annualPkp = $pkp * 12;

        // Return monthly tax
        return $this->calculateProgressiveTax($companyId, $annualPkp) / 12;
    }

    /**
     * Calculate PPh21 owed on an annual PKP (Penghasilan Kena Pajak) using
     * the company's configured progressive brackets (Pph21Rate), falling
     * back to the PP 58/2023 Pasal 17 default brackets when the company
     * hasn't configured rates for the current year.
     */
    public function calculateProgressiveTax(int $companyId, float $annualPkp): float
    {
        if ($annualPkp <= 0) {
            return 0;
        }

        $tax = 0;

        foreach ($this->getProgressiveTaxBrackets($companyId) as $bracket) {
            if ($annualPkp <= $bracket['min_amount']) {
                break;
            }

            $upperBound = $bracket['max_amount'] ?? $annualPkp;
            $taxableInBracket = min($annualPkp, $upperBound) - $bracket['min_amount'];

            if ($taxableInBracket > 0) {
                $tax += $taxableInBracket * ($bracket['rate'] / 100);
            }
        }

        return $tax;
    }

    /**
     * Get the progressive tax brackets configured for the company (via
     * Pph21SettingController), falling back to the 2024 defaults when none
     * are configured for the current year.
     *
     * @return array<int, array{min_amount: float, max_amount: ?float, rate: float}>
     */
    protected function getProgressiveTaxBrackets(int $companyId): array
    {
        $rates = Pph21Rate::where('company_id', $companyId)
            ->where('year', now()->year)
            ->where('is_active', true)
            ->orderBy('min_amount')
            ->get();

        if ($rates->isNotEmpty()) {
            return $rates->map(fn ($rate) => [
                'min_amount' => (float) $rate->min_amount,
                'max_amount' => $rate->max_amount !== null ? (float) $rate->max_amount : null,
                'rate' => (float) $rate->rate,
            ])->all();
        }

        return Pph21Rate::getDefaultRates2024();
    }

    /**
     * Get PTKP monthly amount based on status
     */
    protected function getPtkpMonthly(int $companyId, string $status): float
    {
        return $this->getPtkpAnnual($companyId, $status) / 12;
    }

    /**
     * Get the company's configured annual PTKP amount for a tax status
     * (via Pph21SettingController), falling back to the 2024 default
     * amounts when the company hasn't configured this status/year.
     */
    public function getPtkpAnnual(int $companyId, string $status): float
    {
        $setting = PtkpSetting::where('company_id', $companyId)
            ->where('status_code', $status)
            ->where('year', now()->year)
            ->where('is_active', true)
            ->first();

        if ($setting) {
            return (float) $setting->annual_amount;
        }

        $default = collect(PtkpSetting::getDefaultPtkp2024())->firstWhere('status_code', $status);

        return (float) ($default['annual_amount'] ?? 54000000);
    }

    /**
     * Calculate BPJS Kesehatan contribution
     */
    public function calculateBpjsKesehatan(int $companyId, float $grossSalary): array
    {
        $settings = BpjsKesSetting::where('company_id', $companyId)
            ->where('is_active', true)
            ->first();

        if (! $settings) {
            // Default rates if no settings
            return [
                'salary_basis' => $grossSalary,
                'company' => $grossSalary * 0.04,
                'employee' => $grossSalary * 0.01,
                'total' => $grossSalary * 0.05,
            ];
        }

        return $settings->calculateContribution($grossSalary);
    }

    /**
     * Calculate BPJS Ketenagakerjaan contribution
     */
    public function calculateBpjsKetenagakerjaan(int $companyId, float $grossSalary): array
    {
        $settings = BpjsTkSetting::where('company_id', $companyId)
            ->where('is_active', true)
            ->first();

        if (! $settings) {
            // Default rates if no settings
            $jhtEmployee = round($grossSalary * 0.02, 0);
            $jhtCompany = round($grossSalary * 0.037, 0);
            $jpEmployee = round($grossSalary * 0.01, 0);
            $jpCompany = round($grossSalary * 0.02, 0);
            $jkkCompany = round($grossSalary * 0.0024, 0);
            $jkmCompany = round($grossSalary * 0.003, 0);

            return [
                'jht_employee' => $jhtEmployee,
                'jht_company' => $jhtCompany,
                'jp_employee' => $jpEmployee,
                'jp_company' => $jpCompany,
                'jkk_company' => $jkkCompany,
                'jkm_company' => $jkmCompany,
                'employee_total' => $jhtEmployee + $jpEmployee,
                'company_total' => $jhtCompany + $jpCompany + $jkkCompany + $jkmCompany,
            ];
        }

        $employeeContribution = $settings->calculateEmployeeContribution($grossSalary);
        $companyContribution = $settings->calculateCompanyContribution($grossSalary);

        // Round each line item (not just the aggregate) — these individual
        // values are stored as-is in payroll_item_details and surfaced to
        // the mobile payslip, which expects whole-Rupiah amounts.
        $jhtEmployee = round($employeeContribution['jht'], 0);
        $jhtCompany = round($companyContribution['jht'], 0);
        $jpEmployee = round($employeeContribution['jp'], 0);
        $jpCompany = round($companyContribution['jp'], 0);
        $jkkCompany = round($companyContribution['jkk'], 0);
        $jkmCompany = round($companyContribution['jkm'], 0);

        return [
            'jht_employee' => $jhtEmployee,
            'jht_company' => $jhtCompany,
            'jp_employee' => $jpEmployee,
            'jp_company' => $jpCompany,
            'jkk_company' => $jkkCompany,
            'jkm_company' => $jkmCompany,
            'employee_total' => $jhtEmployee + $jpEmployee,
            'company_total' => $jhtCompany + $jpCompany + $jkkCompany + $jkmCompany,
        ];
    }

    /**
     * Get breakdown of all deductions for display.
     *
     * @param  float|null  $taxableGrossSalary  Taxable base for PPh21 (basic salary +
     *                                          taxable earning components only). Falls
     *                                          back to $grossSalary when not provided.
     */
    public function getDeductionBreakdown(Employee $employee, float $grossSalary, int $companyId, ?float $taxableGrossSalary = null): array
    {
        $bpjsKes = $this->calculateBpjsKesehatan($companyId, $grossSalary);
        $bpjsTk = $this->calculateBpjsKetenagakerjaan($companyId, $grossSalary);
        $pph21 = $this->calculatePph21($companyId, $employee, $taxableGrossSalary ?? $grossSalary);

        return [
            'pph21' => [
                'name' => 'PPh 21',
                'code' => 'PPH21',
                'amount' => round($pph21, 0),
                'type' => 'deduction',
                'category' => 'tax',
            ],
            'bpjs_kes' => [
                'name' => 'BPJS Kesehatan',
                'code' => 'BPJS-KES',
                'amount' => round($bpjsKes['employee'], 0),
                'type' => 'deduction',
                'category' => 'bpjs',
            ],
            'bpjs_jht' => [
                'name' => 'BPJS JHT',
                'code' => 'BPJS-JHT',
                'amount' => round($bpjsTk['jht_employee'], 0),
                'type' => 'deduction',
                'category' => 'bpjs',
            ],
            'bpjs_jp' => [
                'name' => 'BPJS JP',
                'code' => 'BPJS-JP',
                'amount' => round($bpjsTk['jp_employee'], 0),
                'type' => 'deduction',
                'category' => 'bpjs',
            ],
        ];
    }
}
