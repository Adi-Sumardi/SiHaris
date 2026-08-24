<?php

namespace App\Imports;

use App\Models\Department;
use App\Models\Position;
use Maatwebsite\Excel\Concerns\RemembersRowNumber;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class PositionImport implements SkipsEmptyRows, ToModel, WithHeadingRow, WithValidation
{
    use RemembersRowNumber;

    protected int $companyId;

    protected int $successCount = 0;

    protected int $skipCount = 0;

    /** @var array<int, string> */
    protected array $errors = [];

    protected int $currentRow = 1;

    public function __construct(int $companyId)
    {
        $this->companyId = $companyId;
    }

    public function model(array $row): ?Position
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $code = trim((string) ($row['kode'] ?? ''));
        $name = trim((string) ($row['nama'] ?? ''));
        $deptCode = trim((string) ($row['kode_departemen'] ?? ''));
        $description = trim((string) ($row['deskripsi'] ?? ''));

        if (empty($code) || empty($name)) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Nama dan Kode wajib diisi.";

            return null;
        }

        // Resolve department
        $departmentId = null;
        if (! empty($deptCode)) {
            $department = Department::where('company_id', $this->companyId)
                ->where('code', $deptCode)
                ->first();

            if ($department) {
                $departmentId = $department->id;
            } else {
                $this->errors[] = "Baris {$rowNum}: Departemen '{$deptCode}' tidak ditemukan (jabatan dibuat tanpa departemen).";
            }
        }

        // Check if code already exists in the same department (including soft-deleted)
        $existingPosition = Position::withTrashed()
            ->where('company_id', $this->companyId)
            ->where('department_id', $departmentId)
            ->where('code', $code)
            ->first();

        if ($existingPosition) {
            $this->skipCount++;
            $statusText = $existingPosition->trashed() ? ' (arsip/terhapus)' : '';
            $this->errors[] = "Baris {$rowNum}: Kode '{$code}' sudah ada di departemen ini{$statusText}, dilewati.";

            return null;
        }

        $level = ! empty($row['level']) && is_numeric($row['level']) ? max(1, (int) $row['level']) : 1;

        $this->successCount++;

        return new Position([
            'company_id' => $this->companyId,
            'department_id' => $departmentId,
            'name' => $name,
            'code' => $code,
            'description' => ! empty($description) ? $description : null,
            'level' => $level,
            'base_salary' => $this->parseSalary($row['gaji_pokok'] ?? 0),
            'is_active' => $this->parseBoolean($row['aktif'] ?? 'Ya'),
        ]);
    }

    public function rules(): array
    {
        return [
            'nama' => ['required', 'string', 'max:255'],
            'kode' => ['required', 'string', 'max:50'],
        ];
    }

    public function customValidationMessages(): array
    {
        return [
            'nama.required' => 'Kolom Nama wajib diisi.',
            'kode.required' => 'Kolom Kode wajib diisi.',
        ];
    }

    protected function parseBoolean(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        $value = strtolower(trim((string) $value));

        return in_array($value, ['ya', 'yes', '1', 'true', 'aktif', 'active']);
    }

    protected function parseSalary(mixed $value): int
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
