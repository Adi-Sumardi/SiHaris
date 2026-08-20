<?php

namespace App\Imports;

use App\Models\Department;
use Maatwebsite\Excel\Concerns\RemembersRowNumber;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class DepartmentImport implements SkipsEmptyRows, ToModel, WithHeadingRow, WithValidation
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

    public function model(array $row): ?Department
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $code = trim((string) ($row['kode'] ?? ''));
        $name = trim((string) ($row['nama'] ?? ''));
        $parentCode = trim((string) ($row['kode_induk'] ?? ''));
        $description = trim((string) ($row['deskripsi'] ?? ''));

        if (empty($code) || empty($name)) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Nama dan Kode wajib diisi.";

            return null;
        }

        // Check if code already exists (including soft-deleted)
        $existingDepartment = Department::withTrashed()
            ->where('company_id', $this->companyId)
            ->where('code', $code)
            ->first();

        if ($existingDepartment) {
            $this->skipCount++;
            $statusText = $existingDepartment->trashed() ? ' (arsip/terhapus)' : '';
            $this->errors[] = "Baris {$rowNum}: Kode '{$code}' sudah ada{$statusText}, dilewati.";

            return null;
        }

        // Resolve parent department
        $parentId = null;
        if (! empty($parentCode)) {
            $parent = Department::where('company_id', $this->companyId)
                ->where('code', $parentCode)
                ->first();

            if ($parent) {
                $parentId = $parent->id;
            } else {
                $this->errors[] = "Baris {$rowNum}: Kode induk '{$parentCode}' tidak ditemukan (departemen tetap dibuat tanpa induk).";
            }
        }

        $this->successCount++;

        return new Department([
            'company_id' => $this->companyId,
            'parent_id' => $parentId,
            'name' => $name,
            'code' => $code,
            'description' => ! empty($description) ? $description : null,
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
