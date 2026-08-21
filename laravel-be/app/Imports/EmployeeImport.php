<?php

namespace App\Imports;

use App\Models\Department;
use App\Models\Employee;
use App\Models\Position;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Cache;
use Maatwebsite\Excel\Concerns\RemembersRowNumber;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithEvents;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;
use Maatwebsite\Excel\Events\AfterImport;
use Maatwebsite\Excel\Events\ImportFailed;

class EmployeeImport implements ShouldQueue, SkipsEmptyRows, ToModel, WithChunkReading, WithEvents, WithHeadingRow, WithValidation
{
    use RemembersRowNumber;

    protected int $companyId;

    protected string $importId;

    public int $timeout = 600;

    public int $tries = 3;

    protected int $currentRow = 1;

    /** @var array<string, int>|null */
    protected ?array $departmentMap = null;

    /** @var array<string, int>|null */
    protected ?array $positionMap = null;

    /** @var array<string, int>|null */
    protected ?array $workScheduleMap = null;

    public function __construct(int $companyId, ?string $importId = null)
    {
        $this->companyId = $companyId;
        $this->importId = $importId ?? uniqid('emp_import_');
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

    protected function getCacheKey(): string
    {
        return "employee_import_{$this->importId}";
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

    protected function addError(string $error): void
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

    protected function markAsCompleted(): void
    {
        $this->updateCache(function ($data) {
            $data['status'] = 'completed';
            $data['completed_at'] = now()->toDateTimeString();

            return $data;
        });
    }

    protected function markAsFailed(string $message): void
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
        return Cache::get("employee_import_{$importId}");
    }

    protected function getDepartmentId(string $code): ?int
    {
        if ($this->departmentMap === null) {
            $this->departmentMap = Department::where('company_id', $this->companyId)
                ->pluck('id', 'code')
                ->toArray();
        }

        return $this->departmentMap[$code] ?? null;
    }

    protected function getPositionId(string $code): ?int
    {
        if ($this->positionMap === null) {
            $this->positionMap = Position::where('company_id', $this->companyId)
                ->pluck('id', 'code')
                ->toArray();
        }

        return $this->positionMap[$code] ?? null;
    }

    protected function getWorkScheduleId(string $code): ?int
    {
        if ($this->workScheduleMap === null) {
            $this->workScheduleMap = WorkSchedule::where('company_id', $this->companyId)
                ->pluck('id', 'code')
                ->toArray();
        }

        return $this->workScheduleMap[$code] ?? null;
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

    public function model(array $row): ?Employee
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $nik = trim((string) $this->getRowValue($row, ['nik', 'employee_id'], ''));
        $firstName = trim((string) $this->getRowValue($row, ['nama_depan', 'first_name'], ''));
        $lastName = trim((string) $this->getRowValue($row, ['nama_belakang', 'last_name'], ''));

        if (empty($nik) || empty($firstName)) {
            $this->incrementCounter('skip_count');
            $this->addError("Baris {$rowNum}: NIK dan Nama Depan wajib diisi.");

            return null;
        }

        // Check if employee_id already exists (including soft-deleted)
        $existingEmployee = Employee::withTrashed()
            ->where('company_id', $this->companyId)
            ->where('employee_id', $nik)
            ->first();

        if ($existingEmployee) {
            $this->incrementCounter('skip_count');
            $statusText = $existingEmployee->trashed() ? ' (arsip/terhapus)' : '';
            $this->addError("Baris {$rowNum}: NIK '{$nik}' sudah ada{$statusText}, dilewati.");

            return null;
        }

        // Resolve department
        $departmentId = null;
        $deptCode = trim((string) $this->getRowValue($row, ['kode_departemen', 'department_code'], ''));
        if (! empty($deptCode)) {
            $departmentId = $this->getDepartmentId($deptCode);
            if (! $departmentId) {
                $this->addError("Baris {$rowNum}: Departemen '{$deptCode}' tidak ditemukan.");
            }
        }

        // Resolve position
        $positionId = null;
        $posCode = trim((string) $this->getRowValue($row, ['kode_jabatan', 'position_code'], ''));
        if (! empty($posCode)) {
            $positionId = $this->getPositionId($posCode);
            if (! $positionId) {
                $this->addError("Baris {$rowNum}: Jabatan '{$posCode}' tidak ditemukan.");
            }
        }

        // Resolve work schedule
        $workScheduleId = null;
        $schedCode = trim((string) $this->getRowValue($row, ['kode_jadwal', 'work_schedule_code'], ''));
        if (! empty($schedCode)) {
            $workScheduleId = $this->getWorkScheduleId($schedCode);
            if (! $workScheduleId) {
                $this->addError("Baris {$rowNum}: Jadwal kerja '{$schedCode}' tidak ditemukan.");
            }
        }

        // Ensure hire_date is NEVER null (schema requirement)
        $hireDateRaw = $this->getRowValue($row, ['tanggal_masuk', 'hire_date']);
        $hireDate = $this->parseDate($hireDateRaw);
        if (! $hireDate) {
            $hireDate = now()->format('Y-m-d');
            $this->addError("Baris {$rowNum}: Tanggal masuk kosong/tidak valid untuk NIK '{$nik}', default ke hari ini ({$hireDate}).");
        }

        $this->incrementCounter('success_count');

        $pin = $this->getRowValue($row, ['pin', 'pin_finger', 'pin_mesin']);
        $email = $this->getRowValue($row, ['email']);
        $phone = $this->getRowValue($row, ['telepon', 'phone']);
        $religion = $this->getRowValue($row, ['agama', 'religion']);
        $bloodType = $this->getRowValue($row, ['golongan_darah', 'blood_type']);
        $idNumber = $this->getRowValue($row, ['no_ktp', 'identity_number']);
        $idAddress = $this->getRowValue($row, ['alamat_ktp', 'identity_address']);
        $address = $this->getRowValue($row, ['alamat', 'address']);
        $city = $this->getRowValue($row, ['kota', 'city']);
        $province = $this->getRowValue($row, ['provinsi', 'province']);
        $postalCode = $this->getRowValue($row, ['kode_pos', 'postal_code']);
        $bankName = $this->getRowValue($row, ['nama_bank', 'bank_name']);
        $bankNumber = $this->getRowValue($row, ['nomor_rekening', 'bank_account_number']);
        $bankHolder = $this->getRowValue($row, ['nama_rekening', 'bank_account_name']);
        $npwp = $this->getRowValue($row, ['npwp']);
        $taxStatus = $this->getRowValue($row, ['status_pajak', 'tax_status']);
        $bpjsKesehatan = $this->getRowValue($row, ['bpjs_kesehatan']);
        $bpjsTk = $this->getRowValue($row, ['bpjs_ketenagakerjaan']);
        $ecName = $this->getRowValue($row, ['nama_kontak_darurat', 'emergency_contact_name']);
        $ecPhone = $this->getRowValue($row, ['telepon_kontak_darurat', 'emergency_contact_phone']);
        $ecRel = $this->getRowValue($row, ['hubungan_kontak_darurat', 'emergency_contact_relationship']);

        return new Employee([
            'company_id' => $this->companyId,
            'department_id' => $departmentId,
            'position_id' => $positionId,
            'work_schedule_id' => $workScheduleId,
            'employee_id' => $nik,
            'pin' => ! empty($pin) ? trim((string) $pin) : null,
            'first_name' => $firstName,
            'last_name' => ! empty($lastName) ? $lastName : '',
            'email' => ! empty($email) ? trim((string) $email) : null,
            'phone' => ! empty($phone) ? trim((string) $phone) : null,
            'date_of_birth' => $this->parseDate($this->getRowValue($row, ['tanggal_lahir', 'date_of_birth'])),
            'gender' => $this->parseGender($this->getRowValue($row, ['jenis_kelamin', 'gender'])),
            'marital_status' => $this->parseMaritalStatus($this->getRowValue($row, ['status_pernikahan', 'marital_status'])),
            'religion' => ! empty($religion) ? trim((string) $religion) : null,
            'blood_type' => ! empty($bloodType) ? trim((string) $bloodType) : null,
            'identity_number' => ! empty($idNumber) ? trim((string) $idNumber) : null,
            'identity_address' => ! empty($idAddress) ? trim((string) $idAddress) : null,
            'address' => ! empty($address) ? trim((string) $address) : null,
            'city' => ! empty($city) ? trim((string) $city) : null,
            'province' => ! empty($province) ? trim((string) $province) : null,
            'postal_code' => ! empty($postalCode) ? trim((string) $postalCode) : null,
            'hire_date' => $hireDate,
            'employment_status' => $this->parseEmploymentStatus($this->getRowValue($row, ['status_karyawan', 'employment_status'], 'permanent')),
            'contract_start_date' => $this->parseDate($this->getRowValue($row, ['tanggal_mulai_kontrak', 'contract_start_date'])),
            'contract_end_date' => $this->parseDate($this->getRowValue($row, ['tanggal_selesai_kontrak', 'contract_end_date'])),
            'base_salary' => $this->parseSalary($this->getRowValue($row, ['gaji_pokok', 'base_salary'], 0)),
            'bank_name' => ! empty($bankName) ? trim((string) $bankName) : null,
            'bank_account_number' => ! empty($bankNumber) ? trim((string) $bankNumber) : null,
            'bank_account_name' => ! empty($bankHolder) ? trim((string) $bankHolder) : null,
            'npwp' => ! empty($npwp) ? trim((string) $npwp) : null,
            'tax_status' => ! empty($taxStatus) ? trim((string) $taxStatus) : null,
            'bpjs_kesehatan' => ! empty($bpjsKesehatan) ? trim((string) $bpjsKesehatan) : null,
            'bpjs_ketenagakerjaan' => ! empty($bpjsTk) ? trim((string) $bpjsTk) : null,
            'emergency_contact_name' => ! empty($ecName) ? trim((string) $ecName) : null,
            'emergency_contact_phone' => ! empty($ecPhone) ? trim((string) $ecPhone) : null,
            'emergency_contact_relationship' => ! empty($ecRel) ? trim((string) $ecRel) : null,
            'is_active' => $this->parseBoolean($this->getRowValue($row, ['aktif', 'is_active'], 'Ya')),
        ]);
    }

    public function rules(): array
    {
        return [
            'nik' => ['sometimes', 'string', 'max:50'],
            'employee_id' => ['sometimes', 'string', 'max:50'],
            'nama_depan' => ['sometimes', 'string', 'max:255'],
            'first_name' => ['sometimes', 'string', 'max:255'],
        ];
    }

    public function customValidationMessages(): array
    {
        return [
            'nik.required' => 'Kolom NIK wajib diisi.',
            'employee_id.required' => 'Kolom NIK wajib diisi.',
            'nama_depan.required' => 'Kolom Nama Depan wajib diisi.',
            'first_name.required' => 'Kolom Nama Depan wajib diisi.',
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

        // Handle Excel numeric serial date (using PhpOffice Date parser to avoid timezone drift)
        if (is_numeric($value)) {
            try {
                return \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($value)->format('Y-m-d');
            } catch (\Exception $e) {
                // fallback
            }
        }

        $str = trim((string) $value);

        // Try common date formats
        $formats = ['Y-m-d', 'd/m/Y', 'd-m-Y', 'm/d/Y', 'Y/m/d'];
        foreach ($formats as $format) {
            $date = \DateTime::createFromFormat($format, $str);
            if ($date !== false) {
                return $date->format('Y-m-d');
            }
        }

        // Last resort: try Carbon's parse
        try {
            return Carbon::parse($str)->format('Y-m-d');
        } catch (\Exception $e) {
            return null;
        }
    }

    public function parseGender(mixed $value): ?string
    {
        if (empty($value)) {
            return null;
        }

        $value = strtolower(trim((string) $value));

        if (in_array($value, ['male', 'laki-laki', 'laki', 'l', 'pria', 'm'])) {
            return 'male';
        }

        if (in_array($value, ['female', 'perempuan', 'wanita', 'p', 'f'])) {
            return 'female';
        }

        return null;
    }

    public function parseMaritalStatus(mixed $value): ?string
    {
        if (empty($value)) {
            return null;
        }

        $value = strtolower(trim((string) $value));

        $mapping = [
            'single' => 'single',
            'belum menikah' => 'single',
            'lajang' => 'single',
            'tk' => 'single',
            'married' => 'married',
            'menikah' => 'married',
            'kawin' => 'married',
            'k' => 'married',
            'divorced' => 'divorced',
            'cerai' => 'divorced',
            'cerai hidup' => 'divorced',
            'widowed' => 'widowed',
            'janda' => 'widowed',
            'duda' => 'widowed',
            'cerai mati' => 'widowed',
        ];

        return $mapping[$value] ?? null;
    }

    public function parseEmploymentStatus(mixed $value): string
    {
        $value = strtolower(trim((string) $value));

        $mapping = [
            'permanent' => 'permanent',
            'tetap' => 'permanent',
            'pkwtt' => 'permanent',
            'contract' => 'contract',
            'kontrak' => 'contract',
            'pkwt' => 'contract',
            'probation' => 'probation',
            'percobaan' => 'probation',
            'masa percobaan' => 'probation',
            'intern' => 'intern',
            'magang' => 'intern',
        ];

        return $mapping[$value] ?? 'permanent';
    }
}
