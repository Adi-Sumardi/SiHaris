<?php

namespace App\Imports;

use App\Models\Employee;
use Illuminate\Support\Facades\Cache;
use Maatwebsite\Excel\Concerns\RemembersRowNumber;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithEvents;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Events\AfterImport;
use Maatwebsite\Excel\Events\ImportFailed;

/**
 * Bulk-updates Employee::pin from an uploaded template (ID Karyawan, Nama
 * Karyawan, PIN Baru). Only writes the SiHaris side - it does NOT call ADMS
 * itself. PinImportController runs PushEmployeePinsToAdmsJob right after
 * this completes, so the two responsibilities (bulk-editing SiHaris's own
 * data vs. pushing the resulting differences to ADMS) stay separate and
 * the ADMS-push logic isn't duplicated between the two entry points.
 */
class PinImport implements SkipsEmptyRows, ToModel, WithChunkReading, WithEvents, WithHeadingRow
{
    use RemembersRowNumber;

    protected int $companyId;

    protected string $importId;

    public int $timeout = 300;

    public int $tries = 3;

    protected int $currentRow = 1;

    /** @var array<string, bool> */
    protected array $seenEmployeeIds = [];

    public function __construct(int $companyId, ?string $importId = null)
    {
        $this->companyId = $companyId;
        $this->importId = $importId ?? uniqid('pin_import_');
    }

    public function chunkSize(): int
    {
        return 200;
    }

    public function registerEvents(): array
    {
        return [
            AfterImport::class => function (AfterImport $event) {
                $this->markAsCompleted();
            },
            ImportFailed::class => function (ImportFailed $event) {
                $this->markAsFailed($event->getException()->getMessage());
            },
        ];
    }

    public function getImportId(): string
    {
        return $this->importId;
    }

    public function model(array $row): ?Employee
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $employeeId = $this->cleanString($this->getRowValue($row, ['id_karyawan', 'employee_id', 'nip']));
        $newPin = $this->cleanString($this->getRowValue($row, ['pin_baru', 'pin']));

        if (empty($employeeId) || empty($newPin)) {
            $this->incrementCounter('skip_count');
            $this->addError("Baris {$rowNum}: ID Karyawan dan PIN Baru wajib diisi.");

            return null;
        }

        $key = strtolower($employeeId);
        if (isset($this->seenEmployeeIds[$key])) {
            $this->incrementCounter('skip_count');
            $this->addError("Baris {$rowNum}: ID Karyawan '{$employeeId}' duplikat di dalam file import.");

            return null;
        }
        $this->seenEmployeeIds[$key] = true;

        $employee = Employee::where('company_id', $this->companyId)
            ->where('employee_id', $employeeId)
            ->first();

        if (! $employee) {
            $this->incrementCounter('skip_count');
            $this->addError("Baris {$rowNum}: karyawan dengan ID '{$employeeId}' tidak ditemukan.");

            return null;
        }

        if ($employee->pin === $newPin) {
            $this->incrementCounter('skip_count');
            $this->addError("Baris {$rowNum}: PIN {$employee->full_name} sudah '{$newPin}', tidak ada perubahan.");

            return null;
        }

        $employee->pin = $newPin;
        $this->incrementCounter('success_count');

        return $employee;
    }

    protected function getRowValue(array $row, array|string $keys, mixed $default = null): mixed
    {
        $keys = (array) $keys;
        foreach ($keys as $key) {
            if (array_key_exists($key, $row) && $row[$key] !== null && $row[$key] !== '') {
                return $row[$key];
            }
        }

        return $default;
    }

    protected function cleanString(mixed $value): string
    {
        if ($value === null) {
            return '';
        }

        if (is_int($value)) {
            return (string) $value;
        }

        if (is_float($value)) {
            return $value == floor($value) ? (string) (int) $value : (string) $value;
        }

        return trim((string) $value);
    }

    protected function getCacheKey(): string
    {
        return "pin_import_{$this->importId}";
    }

    protected function updateCache(callable $callback): void
    {
        $cacheKey = $this->getCacheKey();
        $data = Cache::get($cacheKey, $this->getDefaultCacheData());
        $data = $callback($data);
        Cache::put($cacheKey, $data, now()->addHours(24));
    }

    protected function incrementCounter(string $key): void
    {
        $this->updateCache(function ($data) use ($key) {
            $data[$key] = ($data[$key] ?? 0) + 1;

            return $data;
        });
    }

    public function addError(string $error): void
    {
        $this->updateCache(function ($data) use ($error) {
            $data['errors'][] = $error;

            return $data;
        });
    }

    protected function getDefaultCacheData(): array
    {
        return [
            'status' => 'processing',
            'success_count' => 0,
            'skip_count' => 0,
            'errors' => [],
            'started_at' => now()->toDateTimeString(),
            'completed_at' => null,
        ];
    }

    public function initializeImport(): void
    {
        Cache::put($this->getCacheKey(), $this->getDefaultCacheData(), now()->addHours(24));
    }

    public function markAsCompleted(): void
    {
        $this->updateCache(function ($data) {
            $data['status'] = 'completed';
            $data['completed_at'] = now()->toDateTimeString();

            return $data;
        });
    }

    public function markAsFailed(string $message): void
    {
        $this->updateCache(function ($data) use ($message) {
            $data['status'] = 'failed';
            $data['error_message'] = $message;
            $data['completed_at'] = now()->toDateTimeString();

            return $data;
        });
    }

    public static function getImportStatus(string $importId): ?array
    {
        return Cache::get("pin_import_{$importId}");
    }

    public function getSuccessCount(): int
    {
        return static::getImportStatus($this->importId)['success_count'] ?? 0;
    }

    public function getSkipCount(): int
    {
        return static::getImportStatus($this->importId)['skip_count'] ?? 0;
    }

    /** @return array<int, string> */
    public function getErrors(): array
    {
        return static::getImportStatus($this->importId)['errors'] ?? [];
    }
}
