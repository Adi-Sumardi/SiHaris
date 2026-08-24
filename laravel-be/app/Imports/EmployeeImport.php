<?php

namespace App\Imports;

use App\Models\Department;
use App\Models\Employee;
use App\Models\OfficeLocation;
use App\Models\Position;
use App\Models\WorkSchedule;
use Carbon\Carbon;
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

class EmployeeImport implements SkipsEmptyRows, ToModel, WithChunkReading, WithEvents, WithHeadingRow, WithValidation
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

    /** @var array<string, int>|null */
    protected ?array $managerMap = null;

    /** @var array<string, int>|null */
    protected ?array $officeLocationMap = null;

    /** @var array<string, bool> */
    protected array $seenNiks = [];

    /** @var array<string, int> */
    protected array $pendingOfficeLocations = [];

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
                $this->attachPendingOfficeLocations();
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
        return Cache::get("employee_import_{$importId}");
    }

    public function getSuccessCount(): int
    {
        $status = static::getImportStatus($this->importId);

        return $status['success_count'] ?? 0;
    }

    public function getSkipCount(): int
    {
        $status = static::getImportStatus($this->importId);

        return $status['skip_count'] ?? 0;
    }

    /** @return array<int, string> */
    public function getErrors(): array
    {
        $status = static::getImportStatus($this->importId);

        return $status['errors'] ?? [];
    }

    protected function getDepartmentId(mixed $identifier): ?int
    {
        $key = strtolower(trim((string) $identifier));
        if ($key === '') {
            return null;
        }

        if ($this->departmentMap === null) {
            $this->departmentMap = [];
            $departments = Department::where('company_id', $this->companyId)->get(['id', 'code', 'name']);
            foreach ($departments as $dept) {
                if (! empty($dept->code)) {
                    $this->departmentMap[strtolower(trim($dept->code))] = $dept->id;
                }
                if (! empty($dept->name)) {
                    $this->departmentMap[strtolower(trim($dept->name))] = $dept->id;
                }
            }
        }

        return $this->departmentMap[$key] ?? null;
    }

    protected function getPositionId(mixed $identifier, ?int $departmentId = null): ?int
    {
        $key = strtolower(trim((string) $identifier));
        if ($key === '') {
            return null;
        }

        if ($this->positionMap === null) {
            $this->positionMap = [];
            $positions = Position::where('company_id', $this->companyId)->get(['id', 'department_id', 'code', 'name']);
            foreach ($positions as $pos) {
                if (! empty($pos->code)) {
                    $codeKey = strtolower(trim($pos->code));
                    if ($pos->department_id) {
                        $this->positionMap[$pos->department_id . '_' . $codeKey] = $pos->id;
                    }
                    if (! isset($this->positionMap[$codeKey])) {
                        $this->positionMap[$codeKey] = $pos->id;
                    }
                }
                if (! empty($pos->name)) {
                    $nameKey = strtolower(trim($pos->name));
                    if ($pos->department_id) {
                        $this->positionMap[$pos->department_id . '_' . $nameKey] = $pos->id;
                    }
                    if (! isset($this->positionMap[$nameKey])) {
                        $this->positionMap[$nameKey] = $pos->id;
                    }
                }
            }
        }

        if ($departmentId !== null && isset($this->positionMap[$departmentId . '_' . $key])) {
            return $this->positionMap[$departmentId . '_' . $key];
        }

        return $this->positionMap[$key] ?? null;
    }

    protected function getWorkScheduleId(mixed $identifier): ?int
    {
        $key = strtolower(trim((string) $identifier));
        if ($key === '') {
            return null;
        }

        if ($this->workScheduleMap === null) {
            $this->workScheduleMap = [];
            $schedules = WorkSchedule::where('company_id', $this->companyId)->get(['id', 'code', 'name']);
            foreach ($schedules as $sched) {
                if (! empty($sched->code)) {
                    $this->workScheduleMap[strtolower(trim($sched->code))] = $sched->id;
                }
                if (! empty($sched->name)) {
                    $this->workScheduleMap[strtolower(trim($sched->name))] = $sched->id;
                }
            }
        }

        return $this->workScheduleMap[$key] ?? null;
    }

    protected function getManagerId(mixed $identifier): ?int
    {
        $key = strtolower(trim((string) $identifier));
        if ($key === '') {
            return null;
        }

        if ($this->managerMap === null) {
            $this->managerMap = [];
            $managers = Employee::where('company_id', $this->companyId)->get(['id', 'employee_id']);
            foreach ($managers as $mgr) {
                if (! empty($mgr->employee_id)) {
                    $this->managerMap[strtolower(trim($mgr->employee_id))] = $mgr->id;
                }
            }
        }

        return $this->managerMap[$key] ?? null;
    }

    protected function getOfficeLocationId(mixed $identifier): ?int
    {
        $key = strtolower(trim((string) $identifier));
        if ($key === '') {
            return null;
        }

        if ($this->officeLocationMap === null) {
            $this->officeLocationMap = [];
            $offices = OfficeLocation::where('company_id', $this->companyId)->get(['id', 'code', 'name']);
            foreach ($offices as $office) {
                if (! empty($office->code)) {
                    $this->officeLocationMap[strtolower(trim($office->code))] = $office->id;
                }
                if (! empty($office->name)) {
                    $this->officeLocationMap[strtolower(trim($office->name))] = $office->id;
                }
            }
        }

        return $this->officeLocationMap[$key] ?? null;
    }

    public function attachPendingOfficeLocations(): void
    {
        if (empty($this->pendingOfficeLocations)) {
            return;
        }

        foreach ($this->pendingOfficeLocations as $nik => $officeId) {
            $emp = Employee::where('company_id', $this->companyId)
                ->where('employee_id', $nik)
                ->first();

            if ($emp) {
                $emp->officeLocations()->syncWithoutDetaching([
                    $officeId => ['is_primary' => true],
                ]);
            }
        }

        $this->pendingOfficeLocations = [];
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
            if ($value == floor($value)) {
                return sprintf('%.0f', $value);
            }

            return (string) $value;
        }

        return trim((string) $value);
    }

    public function model(array $row): ?Employee
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $idKaryawanRaw = $this->getRowValue($row, ['id_karyawan', 'employee_id', 'nip', 'nik_karyawan']);
        $nikRaw = $this->getRowValue($row, ['nik']);

        // Determine employee_id: prefer explicit id_karyawan/nip, fallback to nik
        $employeeId = ! empty($idKaryawanRaw) ? $this->cleanString($idKaryawanRaw) : $this->cleanString($nikRaw);

        $firstNameRaw = $this->getRowValue($row, ['nama_depan', 'first_name']);
        $firstName = $this->cleanString($firstNameRaw);

        $lastNameRaw = $this->getRowValue($row, ['nama_belakang', 'last_name']);
        $lastName = $this->cleanString($lastNameRaw);

        // Fallback for single full name column
        if (empty($firstName)) {
            $fullName = $this->cleanString($this->getRowValue($row, ['nama_lengkap', 'nama', 'full_name', 'name']));
            if (! empty($fullName)) {
                $nameParts = preg_split('/\s+/', $fullName, 2);
                $firstName = $nameParts[0] ?? '';
                if (empty($lastName) && isset($nameParts[1])) {
                    $lastName = $nameParts[1];
                }
            }
        }

        if (empty($employeeId) || empty($firstName)) {
            $this->incrementCounter('skip_count');
            $this->addError("Baris {$rowNum}: ID Karyawan dan Nama Depan wajib diisi.");

            return null;
        }

        // Prevent in-file duplicate employee_id collision
        $empIdKey = strtolower($employeeId);
        if (isset($this->seenNiks[$empIdKey])) {
            $this->incrementCounter('skip_count');
            $this->addError("Baris {$rowNum}: ID Karyawan '{$employeeId}' duplikat di dalam file import.");

            return null;
        }
        $this->seenNiks[$empIdKey] = true;

        // Check if employee_id already exists in database (including soft-deleted)
        $existingEmployee = Employee::withTrashed()
            ->where('company_id', $this->companyId)
            ->where('employee_id', $employeeId)
            ->first();

        if ($existingEmployee) {
            $this->incrementCounter('skip_count');
            $statusText = $existingEmployee->trashed() ? ' (arsip/terhapus)' : '';
            $this->addError("Baris {$rowNum}: ID Karyawan '{$employeeId}' sudah ada{$statusText}, dilewati.");

            return null;
        }

        // Resolve department
        $departmentId = null;
        $deptVal = $this->getRowValue($row, ['kode_departemen', 'department_code', 'departemen', 'department', 'divisi']);
        if (! empty($deptVal)) {
            $departmentId = $this->getDepartmentId($deptVal);
            if (! $departmentId) {
                $this->addError("Baris {$rowNum}: Departemen '{$deptVal}' tidak ditemukan.");
            }
        }

        // Resolve position
        $positionId = null;
        $posVal = $this->getRowValue($row, ['kode_jabatan', 'position_code', 'jabatan', 'position']);
        if (! empty($posVal)) {
            $positionId = $this->getPositionId($posVal, $departmentId);
            if (! $positionId) {
                $this->addError("Baris {$rowNum}: Jabatan '{$posVal}' tidak ditemukan.");
            }
        }

        // Resolve work schedule
        $workScheduleId = null;
        $schedVal = $this->getRowValue($row, ['kode_jadwal', 'work_schedule_code', 'jadwal', 'jadwal_kerja', 'shift', 'work_schedule']);
        if (! empty($schedVal)) {
            $workScheduleId = $this->getWorkScheduleId($schedVal);
            if (! $workScheduleId) {
                $this->addError("Baris {$rowNum}: Jadwal kerja '{$schedVal}' tidak ditemukan.");
            }
        }

        // Resolve manager
        $managerId = null;
        $mgrVal = $this->getRowValue($row, ['nik_manajer', 'manager_nik', 'kode_manajer', 'manager_id']);
        if (! empty($mgrVal)) {
            $managerId = $this->getManagerId($mgrVal);
            if (! $managerId) {
                $this->addError("Baris {$rowNum}: NIK Manajer '{$mgrVal}' tidak ditemukan.");
            }
        }

        // Resolve office location
        $officeLocationId = null;
        $officeVal = $this->getRowValue($row, ['kode_lokasi_kantor', 'kode_kantor', 'lokasi_kantor', 'office_location_code', 'office_code']);
        if (! empty($officeVal)) {
            $officeLocationId = $this->getOfficeLocationId($officeVal);
            if (! $officeLocationId) {
                $this->addError("Baris {$rowNum}: Lokasi kantor '{$officeVal}' tidak ditemukan.");
            } else {
                $this->pendingOfficeLocations[$employeeId] = $officeLocationId;
            }
        }

        // Ensure hire_date is NEVER null (schema requirement)
        $hireDateRaw = $this->getRowValue($row, ['tanggal_masuk', 'hire_date', 'tgl_masuk', 'join_date']);
        $hireDate = $this->parseDate($hireDateRaw);
        if (! $hireDate) {
            $hireDate = now()->format('Y-m-d');
            $this->addError("Baris {$rowNum}: Tanggal masuk kosong/tidak valid untuk ID Karyawan '{$employeeId}', default ke hari ini ({$hireDate}).");
        }

        $this->incrementCounter('success_count');

        $pinRaw = $this->getRowValue($row, ['pin', 'pin_finger', 'pin_mesin', 'pin_absen']);
        $pin = $this->cleanString($pinRaw);

        $email = $this->getRowValue($row, ['email']);
        $phone = $this->cleanString($this->getRowValue($row, ['telepon', 'phone', 'no_hp', 'no_telepon', 'handphone']));
        $religion = $this->getRowValue($row, ['agama', 'religion']);
        $bloodType = $this->getRowValue($row, ['golongan_darah', 'blood_type', 'gol_darah']);
        
        $idNumber = $this->cleanString($this->getRowValue($row, ['nik_no_ktp', 'nik_ktp', 'no_ktp', 'nomor_ktp', 'identity_number', 'ktp']));
        if (empty($idNumber) && ! empty($idKaryawanRaw) && ! empty($nikRaw)) {
            $idNumber = $this->cleanString($nikRaw);
        }

        $idAddress = $this->getRowValue($row, ['alamat_ktp', 'identity_address']);
        $address = $this->getRowValue($row, ['alamat', 'address', 'alamat_domisili', 'domisili']);
        $city = $this->getRowValue($row, ['kota', 'city']);
        $province = $this->getRowValue($row, ['provinsi', 'province']);
        $postalCode = $this->cleanString($this->getRowValue($row, ['kode_pos', 'postal_code', 'zip_code']));
        $bankName = $this->getRowValue($row, ['nama_bank', 'bank_name', 'bank']);
        $bankNumber = $this->cleanString($this->getRowValue($row, ['nomor_rekening', 'bank_account_number', 'no_rek', 'no_rekening', 'rekening']));
        $bankHolder = $this->getRowValue($row, ['nama_rekening', 'bank_account_name', 'atas_nama', 'pemilik_rekening']);
        $npwp = $this->cleanString($this->getRowValue($row, ['npwp', 'no_npwp', 'nomor_npwp']));
        $taxStatus = $this->getRowValue($row, ['status_pajak', 'tax_status', 'ptkp', 'status_ptkp']);
        $bpjsKesehatan = $this->cleanString($this->getRowValue($row, ['bpjs_kesehatan', 'no_bpjs_kesehatan', 'nomor_bpjs_kesehatan']));
        $bpjsTk = $this->cleanString($this->getRowValue($row, ['bpjs_ketenagakerjaan', 'bpjs_tk', 'bpjstk', 'no_bpjs_ketenagakerjaan']));
        $ecName = $this->getRowValue($row, ['nama_kontak_darurat', 'emergency_contact_name', 'kontak_darurat_nama']);
        $ecPhone = $this->cleanString($this->getRowValue($row, ['telepon_kontak_darurat', 'emergency_contact_phone', 'kontak_darurat_telepon', 'kontak_darurat_no']));
        $ecRel = $this->getRowValue($row, ['hubungan_kontak_darurat', 'emergency_contact_relationship', 'kontak_darurat_hubungan']);

        return new Employee([
            'company_id' => $this->companyId,
            'department_id' => $departmentId,
            'position_id' => $positionId,
            'work_schedule_id' => $workScheduleId,
            'manager_id' => $managerId,
            'employee_id' => $employeeId,
            'pin' => ! empty($pin) ? $pin : null,
            'nik' => ! empty($idNumber) ? $idNumber : null,
            'identity_number' => ! empty($idNumber) ? $idNumber : null,
            'first_name' => $firstName,
            'last_name' => ! empty($lastName) ? $lastName : '',
            'email' => ! empty($email) ? trim((string) $email) : null,
            'phone' => ! empty($phone) ? $phone : null,
            'date_of_birth' => $this->parseDate($this->getRowValue($row, ['tanggal_lahir', 'date_of_birth', 'tgl_lahir', 'dob'])),
            'gender' => $this->parseGender($this->getRowValue($row, ['jenis_kelamin', 'gender', 'jk'])),
            'marital_status' => $this->parseMaritalStatus($this->getRowValue($row, ['status_pernikahan', 'marital_status', 'status_kawin', 'status_perkawinan'])),
            'religion' => ! empty($religion) ? trim((string) $religion) : null,
            'blood_type' => ! empty($bloodType) ? trim((string) $bloodType) : null,
            'identity_address' => ! empty($idAddress) ? trim((string) $idAddress) : null,
            'address' => ! empty($address) ? trim((string) $address) : null,
            'city' => ! empty($city) ? trim((string) $city) : null,
            'province' => ! empty($province) ? trim((string) $province) : null,
            'postal_code' => ! empty($postalCode) ? $postalCode : null,
            'hire_date' => $hireDate,
            'employment_status' => $this->parseEmploymentStatus($this->getRowValue($row, ['status_karyawan', 'employment_status', 'status_kerja'], 'permanent')),
            'contract_start_date' => $this->parseDate($this->getRowValue($row, ['tanggal_mulai_kontrak', 'contract_start_date', 'tgl_mulai_kontrak'])),
            'contract_end_date' => $this->parseDate($this->getRowValue($row, ['tanggal_selesai_kontrak', 'contract_end_date', 'tgl_selesai_kontrak', 'tgl_habis_kontrak'])),
            'base_salary' => $this->parseSalary($this->getRowValue($row, ['gaji_pokok', 'base_salary', 'gaji', 'salary'], 0)),
            'bank_name' => ! empty($bankName) ? trim((string) $bankName) : null,
            'bank_account_number' => ! empty($bankNumber) ? $bankNumber : null,
            'bank_account_name' => ! empty($bankHolder) ? trim((string) $bankHolder) : null,
            'npwp' => ! empty($npwp) ? $npwp : null,
            'tax_status' => ! empty($taxStatus) ? trim((string) $taxStatus) : null,
            'bpjs_kesehatan' => ! empty($bpjsKesehatan) ? $bpjsKesehatan : null,
            'bpjs_ketenagakerjaan' => ! empty($bpjsTk) ? $bpjsTk : null,
            'emergency_contact_name' => ! empty($ecName) ? trim((string) $ecName) : null,
            'emergency_contact_phone' => ! empty($ecPhone) ? $ecPhone : null,
            'emergency_contact_relationship' => ! empty($ecRel) ? trim((string) $ecRel) : null,
            'is_active' => $this->parseBoolean($this->getRowValue($row, ['aktif', 'is_active', 'status_aktif'], 'Ya')),
        ]);
    }

    public function rules(): array
    {
        return [
            'nik' => ['nullable'],
            'employee_id' => ['nullable'],
            'nama_depan' => ['nullable'],
            'first_name' => ['nullable'],
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

        // If string contains both dots and commas (e.g. 10.000.000,00 or 10,000,000.50)
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

        // Try common date formats
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

        if (in_array($value, ['male', 'laki-laki', 'laki - laki', 'laki', 'laki2', 'l', 'pria', 'm', 'cowok'])) {
            return 'male';
        }

        if (in_array($value, ['female', 'perempuan', 'wanita', 'p', 'f', 'cewek'])) {
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
            'belum kawin' => 'single',
            'lajang' => 'single',
            'tk' => 'single',
            'tk/0' => 'single',
            'tk/1' => 'single',
            'tk/2' => 'single',
            'tk/3' => 'single',
            'tidak kawin' => 'single',
            'married' => 'married',
            'menikah' => 'married',
            'kawin' => 'married',
            'k' => 'married',
            'k/0' => 'married',
            'k/1' => 'married',
            'k/2' => 'married',
            'k/3' => 'married',
            'sudah menikah' => 'married',
            'sudah kawin' => 'married',
            'divorced' => 'divorced',
            'cerai' => 'divorced',
            'cerai hidup' => 'divorced',
            'janda' => 'divorced',
            'duda' => 'divorced',
            'widowed' => 'widowed',
            'cerai mati' => 'widowed',
        ];

        return $mapping[$value] ?? null;
    }

    public function parseEmploymentStatus(mixed $value): string
    {
        if (empty($value)) {
            return 'permanent';
        }

        $value = strtolower(trim((string) $value));

        $mapping = [
            'permanent' => 'permanent',
            'tetap' => 'permanent',
            'karyawan tetap' => 'permanent',
            'pkwtt' => 'permanent',
            'contract' => 'contract',
            'kontrak' => 'contract',
            'karyawan kontrak' => 'contract',
            'pkwt' => 'contract',
            'probation' => 'probation',
            'percobaan' => 'probation',
            'masa percobaan' => 'probation',
            'intern' => 'intern',
            'magang' => 'intern',
            'internship' => 'intern',
            'pkl' => 'intern',
        ];

        return $mapping[$value] ?? 'permanent';
    }
}

