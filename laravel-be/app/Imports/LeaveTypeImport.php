<?php

namespace App\Imports;

use App\Models\LeaveType;
use Maatwebsite\Excel\Concerns\RemembersRowNumber;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class LeaveTypeImport implements SkipsEmptyRows, ToModel, WithHeadingRow, WithValidation
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

    public function model(array $row): ?LeaveType
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $code = trim((string) ($row['kode'] ?? ''));
        $name = trim((string) ($row['nama'] ?? ''));
        $description = trim((string) ($row['deskripsi'] ?? ''));
        $color = trim((string) ($row['warna'] ?? ''));

        if (empty($code) || empty($name)) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Nama dan Kode wajib diisi.";

            return null;
        }

        // Check if code already exists (including soft-deleted)
        $existingLeaveType = LeaveType::withTrashed()
            ->where('company_id', $this->companyId)
            ->where('code', $code)
            ->first();

        if ($existingLeaveType) {
            $this->skipCount++;
            $statusText = $existingLeaveType->trashed() ? ' (arsip/terhapus)' : '';
            $this->errors[] = "Baris {$rowNum}: Kode '{$code}' sudah ada{$statusText}, dilewati.";

            return null;
        }

        $defaultDays = isset($row['jatah_hari']) && is_numeric($row['jatah_hari']) ? (int) $row['jatah_hari'] : 0;
        $maxConsecutiveDays = ! empty($row['maksimal_hari_berturut']) && is_numeric($row['maksimal_hari_berturut']) ? (int) $row['maksimal_hari_berturut'] : null;
        $minNoticeDays = isset($row['minimal_hari_pengajuan']) && is_numeric($row['minimal_hari_pengajuan']) ? (int) $row['minimal_hari_pengajuan'] : 0;
        $maxCarryForwardDays = ! empty($row['maksimal_hari_dibawa']) && is_numeric($row['maksimal_hari_dibawa']) ? (int) $row['maksimal_hari_dibawa'] : null;

        $this->successCount++;

        return new LeaveType([
            'company_id' => $this->companyId,
            'name' => $name,
            'code' => $code,
            'description' => ! empty($description) ? $description : null,
            'default_days' => $defaultDays,
            'is_paid' => $this->parseBoolean($row['berbayar'] ?? 'Ya'),
            'requires_approval' => $this->parseBoolean($row['perlu_persetujuan'] ?? 'Ya'),
            'requires_attachment' => $this->parseBoolean($row['perlu_lampiran'] ?? 'Tidak'),
            'max_consecutive_days' => $maxConsecutiveDays,
            'min_notice_days' => $minNoticeDays,
            'is_carry_forward' => $this->parseBoolean($row['bisa_dibawa'] ?? 'Tidak'),
            'max_carry_forward_days' => $maxCarryForwardDays,
            'is_annual' => $this->parseBoolean($row['tahunan'] ?? 'Tidak'),
            'is_active' => $this->parseBoolean($row['aktif'] ?? 'Ya'),
            'color' => ! empty($color) ? $color : 'primary',
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
