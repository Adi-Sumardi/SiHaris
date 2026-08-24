<?php

namespace App\Imports;

use App\Models\Employee;
use App\Models\EmployeeSalary;
use App\Models\EmployeeSalaryComponent;
use App\Models\SalaryComponent;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\RemembersRowNumber;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class EmployeeSalaryImport implements SkipsEmptyRows, ToModel, WithHeadingRow, WithValidation
{
    use RemembersRowNumber;

    protected int $companyId;

    protected int $successCount = 0;

    protected int $skipCount = 0;

    /** @var array<int, string> */
    protected array $errors = [];

    protected int $currentRow = 1;

    /** @var array<string, int>|null */
    protected ?array $employeeMap = null;

    protected ?SalaryComponent $basicComponent = null;

    /** @var array<string, SalaryComponent>|null */
    protected ?array $salaryComponentsMap = null;

    public function __construct(int $companyId)
    {
        $this->companyId = $companyId;
    }

    public function model(array $row): ?EmployeeSalary
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $empIdentifier = $this->getRowValue($row, ['id_karyawan', 'employee_id', 'pin', 'nik', 'nik_no_ktp', 'email', 'nama', 'name']);
        if (empty($empIdentifier)) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: ID Karyawan wajib diisi.";

            return null;
        }

        $employeeId = $this->getEmployeeId($empIdentifier);
        if (! $employeeId) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Karyawan '{$empIdentifier}' tidak ditemukan.";

            return null;
        }

        $basicSalaryRaw = $this->getRowValue($row, ['gaji_pokok', 'basic_salary', 'gaji', 'salary']);
        $basicSalary = $this->parseSalary($basicSalaryRaw);
        if ($basicSalary <= 0) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Gaji pokok harus lebih dari 0.";

            return null;
        }

        $effectiveDateRaw = $this->getRowValue($row, ['tanggal_berlaku', 'effective_date', 'tgl_berlaku', 'mulai_berlaku', 'tgl_mulai']);
        $effectiveDate = $this->parseDate($effectiveDateRaw) ?? now()->toDateString();

        $endDateRaw = $this->getRowValue($row, ['tanggal_berakhir', 'end_date', 'tgl_berakhir', 'selesai_berlaku', 'tgl_selesai']);
        $endDate = $this->parseDate($endDateRaw);

        if ($endDate && $endDate <= $effectiveDate) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Tanggal berakhir harus setelah tanggal berlaku.";

            return null;
        }

        $paymentMethodRaw = $this->getRowValue($row, ['metode_pembayaran', 'payment_method', 'metode', 'tipe_pembayaran']);
        $paymentMethod = $this->parsePaymentMethod($paymentMethodRaw);

        $bankName = trim((string) $this->getRowValue($row, ['nama_bank', 'bank_name', 'bank']));
        $bankAccountNumber = trim((string) $this->getRowValue($row, ['nomor_rekening', 'bank_account_number', 'no_rekening', 'no_rek', 'rekening']));
        $bankAccountName = trim((string) $this->getRowValue($row, ['nama_rekening', 'bank_account_name', 'atas_nama', 'pemilik_rekening']));

        $isActiveRaw = $this->getRowValue($row, ['aktif', 'is_active', 'status']);
        $isActive = $isActiveRaw !== null && $isActiveRaw !== '' ? $this->parseBoolean($isActiveRaw) : true;

        $notes = trim((string) $this->getRowValue($row, ['catatan', 'notes', 'keterangan', 'deskripsi']));

        // Deactivate previous active salaries if this one is active
        if ($isActive) {
            EmployeeSalary::where('company_id', $this->companyId)
                ->where('employee_id', $employeeId)
                ->where('is_active', true)
                ->update([
                    'is_active' => false,
                    'end_date' => $effectiveDate,
                ]);
        }

        $salary = EmployeeSalary::create([
            'company_id' => $this->companyId,
            'employee_id' => $employeeId,
            'basic_salary' => $basicSalary,
            'effective_date' => $effectiveDate,
            'end_date' => $endDate,
            'payment_method' => $paymentMethod,
            'bank_name' => ! empty($bankName) ? $bankName : null,
            'bank_account_number' => ! empty($bankAccountNumber) ? $bankAccountNumber : null,
            'bank_account_name' => ! empty($bankAccountName) ? $bankAccountName : null,
            'is_active' => $isActive,
            'notes' => ! empty($notes) ? $notes : null,
        ]);

        // Auto-create BASIC component
        $basicComp = $this->getBasicComponent();
        if ($basicComp) {
            EmployeeSalaryComponent::create([
                'employee_salary_id' => $salary->id,
                'salary_component_id' => $basicComp->id,
                'amount' => $basicSalary,
            ]);
        }

        // Attach additional dynamic salary components if matched from header
        $this->attachAdditionalComponents($salary, $row);

        // Update employee bank info and base_salary for consistency
        $employee = Employee::find($employeeId);
        if ($employee) {
            $employeeUpdates = ['base_salary' => $basicSalary];
            if (! empty($bankName)) {
                $employeeUpdates['bank_name'] = $bankName;
            }
            if (! empty($bankAccountNumber)) {
                $employeeUpdates['bank_account_number'] = $bankAccountNumber;
            }
            if (! empty($bankAccountName)) {
                $employeeUpdates['bank_account_name'] = $bankAccountName;
            }
            $employee->update($employeeUpdates);
        }

        $this->successCount++;

        return $salary;
    }

    public function rules(): array
    {
        return [];
    }

    protected function getRowValue(array $row, array $keys): mixed
    {
        foreach ($keys as $key) {
            if (isset($row[$key]) && $row[$key] !== '') {
                return $row[$key];
            }
        }

        return null;
    }

    protected function getEmployeeId(mixed $identifier): ?int
    {
        $key = strtolower(trim((string) $identifier));
        if ($key === '') {
            return null;
        }

        if ($this->employeeMap === null) {
            $this->employeeMap = [];
            $employees = Employee::withTrashed()
                ->where('company_id', $this->companyId)
                ->get(['id', 'employee_id', 'pin', 'nik', 'identity_number', 'email', 'first_name', 'last_name']);

            foreach ($employees as $emp) {
                if (! empty($emp->employee_id)) {
                    $this->employeeMap[strtolower(trim($emp->employee_id))] = $emp->id;
                }
                if (! empty($emp->pin)) {
                    $this->employeeMap[(string) $emp->pin] = $emp->id;
                }
                if (! empty($emp->nik)) {
                    $this->employeeMap[strtolower(trim($emp->nik))] = $emp->id;
                }
                if (! empty($emp->identity_number)) {
                    $this->employeeMap[strtolower(trim($emp->identity_number))] = $emp->id;
                }
                if (! empty($emp->email)) {
                    $this->employeeMap[strtolower(trim($emp->email))] = $emp->id;
                }
                $fullName = trim($emp->first_name.' '.($emp->last_name ?? ''));
                if (! empty($fullName)) {
                    $this->employeeMap[strtolower($fullName)] = $emp->id;
                }
            }
        }

        return $this->employeeMap[$key] ?? null;
    }

    protected function getBasicComponent(): ?SalaryComponent
    {
        if ($this->basicComponent === null) {
            $this->basicComponent = SalaryComponent::where('company_id', $this->companyId)
                ->where('code', 'BASIC')
                ->first();
        }

        return $this->basicComponent;
    }

    protected function attachAdditionalComponents(EmployeeSalary $salary, array $row): void
    {
        if ($this->salaryComponentsMap === null) {
            $this->salaryComponentsMap = [];
            $components = SalaryComponent::where('company_id', $this->companyId)
                ->where('code', '!=', 'BASIC')
                ->get();

            foreach ($components as $comp) {
                $this->salaryComponentsMap[strtolower(trim($comp->code))] = $comp;
                $this->salaryComponentsMap[strtolower(trim($comp->name))] = $comp;
            }
        }

        $standardKeys = [
            'id_karyawan', 'employee_id', 'pin', 'nik', 'nik_no_ktp', 'email', 'nama', 'name',
            'gaji_pokok', 'basic_salary', 'gaji', 'salary',
            'tanggal_berlaku', 'effective_date', 'tgl_berlaku', 'mulai_berlaku', 'tgl_mulai',
            'tanggal_berakhir', 'end_date', 'tgl_berakhir', 'selesai_berlaku', 'tgl_selesai',
            'metode_pembayaran', 'payment_method', 'metode', 'tipe_pembayaran',
            'nama_bank', 'bank_name', 'bank',
            'nomor_rekening', 'bank_account_number', 'no_rekening', 'no_rek', 'rekening',
            'nama_rekening', 'bank_account_name', 'atas_nama', 'pemilik_rekening',
            'aktif', 'is_active', 'status',
            'catatan', 'notes', 'keterangan', 'deskripsi',
        ];

        foreach ($row as $colName => $colValue) {
            $normalizedCol = strtolower(trim((string) $colName));
            if (in_array($normalizedCol, $standardKeys)) {
                continue;
            }

            if (isset($this->salaryComponentsMap[$normalizedCol])) {
                $comp = $this->salaryComponentsMap[$normalizedCol];
                $amount = $this->parseSalary($colValue);
                if ($amount > 0) {
                    EmployeeSalaryComponent::create([
                        'employee_salary_id' => $salary->id,
                        'salary_component_id' => $comp->id,
                        'amount' => $amount,
                    ]);
                }
            }
        }
    }

    public function parseSalary(mixed $value): int
    {
        if (empty($value)) {
            return 0;
        }

        if (is_int($value)) {
            return max(0, $value);
        }

        if (is_float($value)) {
            return max(0, (int) round($value));
        }

        $str = trim((string) $value);
        $str = preg_replace('/^(Rp|IDR)\.?\s*/i', '', $str);
        $str = str_replace(' ', '', $str);

        if (empty($str)) {
            return 0;
        }

        // If string contains both dots and commas (e.g. 10.000.000,00 or 10,000,000.00)
        if (str_contains($str, '.') && str_contains($str, ',')) {
            $lastDot = strrpos($str, '.');
            $lastComma = strrpos($str, ',');
            if ($lastComma > $lastDot) {
                // Indonesian format: 10.000.000,50
                $parts = explode(',', $str);
                $integerPart = str_replace('.', '', $parts[0]);
                $decimalPart = isset($parts[1]) ? (float) ('0.'.$parts[1]) : 0;

                return max(0, (int) round((float) $integerPart + $decimalPart));
            } else {
                // US format: 10,000,000.50
                $parts = explode('.', $str);
                $integerPart = str_replace(',', '', $parts[0]);
                $decimalPart = isset($parts[1]) ? (float) ('0.'.$parts[1]) : 0;

                return max(0, (int) round((float) $integerPart + $decimalPart));
            }
        }

        // If only comma exists: e.g. "10000,50" (decimal) vs "10,000,000" (thousands)
        if (str_contains($str, ',')) {
            if (preg_match('/,\d{1,2}$/', $str) && substr_count($str, ',') === 1) {
                $str = str_replace(',', '.', $str);

                return max(0, (int) round((float) $str));
            }
            $str = str_replace(',', '', $str);

            return max(0, (int) round((float) $str));
        }

        // If only dot exists: e.g. "10.000.000" (thousands) vs "10000.50" (decimal)
        if (str_contains($str, '.')) {
            if (substr_count($str, '.') > 1 || preg_match('/\.\d{3}$/', $str)) {
                $str = str_replace('.', '', $str);

                return max(0, (int) round((float) $str));
            }

            return max(0, (int) round((float) $str));
        }

        return max(0, (int) preg_replace('/[^\d]/', '', $str));
    }

    public function parseDate(mixed $value): ?string
    {
        if (empty($value)) {
            return null;
        }

        if ($value instanceof \DateTime || $value instanceof Carbon) {
            return $value->format('Y-m-d');
        }

        // Handle Excel numeric serial date
        if (is_numeric($value)) {
            try {
                return \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($value)->format('Y-m-d');
            } catch (\Exception $e) {
                // fallback
            }
        }

        $str = trim((string) $value);

        $formats = [
            'Y-m-d',
            'd/m/Y',
            'd-m-Y',
            'd.m.Y',
            'm/d/Y',
            'Y/m/d',
            'j/n/Y',
            'j-n-Y',
            'j.n.Y',
            'Y-m-d H:i:s',
            'd/m/Y H:i:s',
        ];

        foreach ($formats as $format) {
            $date = \DateTime::createFromFormat($format, $str);
            if ($date !== false) {
                return $date->format('Y-m-d');
            }
        }

        try {
            return Carbon::parse($str)->format('Y-m-d');
        } catch (\Exception $e) {
            return null;
        }
    }

    public function parsePaymentMethod(mixed $value): string
    {
        if (empty($value)) {
            return 'transfer';
        }

        $value = strtolower(trim((string) $value));

        if (in_array($value, ['cash', 'tunai', 'kontan', 'uang tunai'])) {
            return 'cash';
        }

        return 'transfer';
    }

    public function parseBoolean(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        $value = strtolower(trim((string) $value));

        return in_array($value, ['ya', 'yes', '1', 'true', 'aktif', 'active']);
    }

    public function getSuccessCount(): int
    {
        return $this->successCount;
    }

    public function getSkipCount(): int
    {
        return $this->skipCount;
    }

    /** @return array<int, string> */
    public function getErrors(): array
    {
        return $this->errors;
    }
}
