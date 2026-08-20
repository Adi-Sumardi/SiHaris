<?php

namespace App\Imports;

use App\Models\WorkSchedule;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\RemembersRowNumber;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class WorkScheduleImport implements SkipsEmptyRows, ToModel, WithHeadingRow, WithValidation
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

    public function model(array $row): ?WorkSchedule
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $code = trim((string) ($row['kode'] ?? ''));
        $name = trim((string) ($row['nama'] ?? ''));
        $description = trim((string) ($row['deskripsi'] ?? ''));

        if (empty($code) || empty($name)) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Nama dan Kode wajib diisi.";

            return null;
        }

        // Check if code already exists (including soft-deleted)
        $existingSchedule = WorkSchedule::withTrashed()
            ->where('company_id', $this->companyId)
            ->where('code', $code)
            ->first();

        if ($existingSchedule) {
            $this->skipCount++;
            $statusText = $existingSchedule->trashed() ? ' (arsip/terhapus)' : '';
            $this->errors[] = "Baris {$rowNum}: Kode '{$code}' sudah ada{$statusText}, dilewati.";

            return null;
        }

        $startTime = $this->parseTime($row['jam_masuk'] ?? null);
        $endTime = $this->parseTime($row['jam_keluar'] ?? null);

        if (! $startTime || ! $endTime) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Format jam masuk atau jam keluar tidak valid.";

            return null;
        }

        $breakStart = ! empty($row['jam_istirahat_mulai']) ? $this->parseTime($row['jam_istirahat_mulai']) : null;
        $breakEnd = ! empty($row['jam_istirahat_selesai']) ? $this->parseTime($row['jam_istirahat_selesai']) : null;
        $breakDuration = ! empty($row['durasi_istirahat']) && is_numeric($row['durasi_istirahat']) ? (int) $row['durasi_istirahat'] : 60;
        $lateTolerance = ! empty($row['toleransi_terlambat']) && is_numeric($row['toleransi_terlambat']) ? (int) $row['toleransi_terlambat'] : 15;
        $earlyLeaveTolerance = ! empty($row['toleransi_pulang_awal']) && is_numeric($row['toleransi_pulang_awal']) ? (int) $row['toleransi_pulang_awal'] : 0;
        $isDefault = $this->parseBoolean($row['default'] ?? 'Tidak');

        if ($isDefault) {
            WorkSchedule::where('company_id', $this->companyId)->update(['is_default' => false]);
        }

        $workingHours = $this->calculateWorkingHours($startTime, $endTime, $breakDuration);

        $this->successCount++;

        return new WorkSchedule([
            'company_id' => $this->companyId,
            'name' => $name,
            'code' => $code,
            'start_time' => $startTime,
            'end_time' => $endTime,
            'break_start' => $breakStart,
            'break_end' => $breakEnd,
            'break_duration' => $breakDuration,
            'working_hours' => $workingHours,
            'working_days' => $this->parseWorkingDays($row['hari_kerja'] ?? '1,2,3,4,5'),
            'late_tolerance' => $lateTolerance,
            'early_leave_tolerance' => $earlyLeaveTolerance,
            'is_flexible' => $this->parseBoolean($row['fleksibel'] ?? 'Tidak'),
            'is_default' => $isDefault,
            'is_active' => $this->parseBoolean($row['aktif'] ?? 'Ya'),
            'description' => ! empty($description) ? $description : null,
        ]);
    }

    public function rules(): array
    {
        return [
            'nama' => ['required', 'string', 'max:255'],
            'kode' => ['required', 'string', 'max:50'],
            'jam_masuk' => ['required'],
            'jam_keluar' => ['required'],
        ];
    }

    public function customValidationMessages(): array
    {
        return [
            'nama.required' => 'Kolom Nama wajib diisi.',
            'kode.required' => 'Kolom Kode wajib diisi.',
            'jam_masuk.required' => 'Kolom Jam Masuk wajib diisi.',
            'jam_keluar.required' => 'Kolom Jam Keluar wajib diisi.',
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

    public function parseTime(mixed $value): ?string
    {
        if (empty($value)) {
            return null;
        }

        if ($value instanceof \DateTime || $value instanceof Carbon) {
            return $value->format('H:i');
        }

        // Handle Excel time serial numbers (e.g. 0.33333333333333)
        if (is_numeric($value) && $value >= 0 && $value < 1) {
            try {
                return \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($value)->format('H:i');
            } catch (\Exception $e) {
                $hours = (int) ($value * 24);
                $minutes = (int) round(($value * 24 - $hours) * 60);

                return sprintf('%02d:%02d', $hours, $minutes);
            }
        }

        $str = trim((string) $value);

        // Normalize dot format e.g. "08.00" -> "08:00"
        $str = preg_replace('/^(\d{1,2})\.(\d{2})(?::\d{2})?$/', '$1:$2', $str);

        // Match H:i or H:i:s
        if (preg_match('/^(\d{1,2}):(\d{2})/', $str, $matches)) {
            $h = (int) $matches[1];
            $m = (int) $matches[2];
            if ($h >= 0 && $h < 24 && $m >= 0 && $m < 60) {
                return sprintf('%02d:%02d', $h, $m);
            }
        }

        return null;
    }

    protected function calculateWorkingHours(string $startTime, string $endTime, int $breakDuration): float
    {
        try {
            $start = Carbon::createFromFormat('H:i', $startTime);
            $end = Carbon::createFromFormat('H:i', $endTime);

            // Overnight shift
            if ($end->lessThan($start)) {
                $end->addDay();
            }

            $diffMinutes = $start->diffInMinutes($end);
            $workingMinutes = max(0, $diffMinutes - $breakDuration);

            return round($workingMinutes / 60, 2);
        } catch (\Exception $e) {
            return 8.0;
        }
    }

    /**
     * Parse working days from comma-separated string, day names, or array
     *
     * @return array<int>
     */
    public function parseWorkingDays(mixed $value): array
    {
        if (is_array($value)) {
            $result = array_filter(array_map('intval', $value), fn ($d) => $d >= 1 && $d <= 7);

            return ! empty($result) ? array_values($result) : [1, 2, 3, 4, 5];
        }

        $str = strtolower(trim((string) $value));
        if (empty($str)) {
            return [1, 2, 3, 4, 5];
        }

        $dayMap = [
            'senin' => 1, 'mon' => 1, 'monday' => 1,
            'selasa' => 2, 'tue' => 2, 'tuesday' => 2,
            'rabu' => 3, 'wed' => 3, 'wednesday' => 3,
            'kamis' => 4, 'thu' => 4, 'thursday' => 4,
            'jumat' => 5, 'jum\'at' => 5, 'fri' => 5, 'friday' => 5,
            'sabtu' => 6, 'sat' => 6, 'saturday' => 6,
            'minggu' => 7, 'sun' => 7, 'sunday' => 7, 'ahad' => 7,
        ];

        $tokens = preg_split('/[,;\s]+/', $str);
        $days = [];

        foreach ($tokens as $token) {
            $token = trim($token);
            if (is_numeric($token)) {
                $val = (int) $token;
                if ($val >= 1 && $val <= 7) {
                    $days[] = $val;
                }
            } elseif (isset($dayMap[$token])) {
                $days[] = $dayMap[$token];
            }
        }

        $days = array_values(array_unique($days));
        sort($days);

        return ! empty($days) ? $days : [1, 2, 3, 4, 5];
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
