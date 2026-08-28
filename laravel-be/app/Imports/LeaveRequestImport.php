<?php

namespace App\Imports;

use App\Models\Employee;
use App\Models\LeaveBalance;
use App\Models\LeaveRequest;
use App\Models\LeaveType;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\RemembersRowNumber;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class LeaveRequestImport implements SkipsEmptyRows, ToModel, WithHeadingRow, WithValidation
{
    use RemembersRowNumber;

    protected int $companyId;

    protected int $successCount = 0;

    protected int $skipCount = 0;

    /** @var array<int, string> */
    protected array $errors = [];

    protected int $currentRow = 1;

    /** @var array<string, Employee>|null */
    protected ?array $employeeMap = null;

    /** @var array<string, LeaveType>|null */
    protected ?array $leaveTypeMap = null;

    public function __construct(int $companyId)
    {
        $this->companyId = $companyId;
    }

    public function model(array $row): ?LeaveRequest
    {
        $this->currentRow++;
        $rowNum = $this->getRowNumber() ?? $this->currentRow;

        $empIdentifier = $this->getRowValue($row, ['id_karyawan', 'employee_id', 'pin', 'nik', 'email', 'nama', 'name']);
        if (empty($empIdentifier)) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: ID Karyawan wajib diisi.";

            return null;
        }

        $employee = $this->getEmployee($empIdentifier);
        if (! $employee) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Karyawan '{$empIdentifier}' tidak ditemukan.";

            return null;
        }

        $leaveTypeIdentifier = $this->getRowValue($row, ['jenis_cuti', 'leave_type', 'kode_jenis_cuti', 'tipe_cuti']);
        if (empty($leaveTypeIdentifier)) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Jenis Cuti wajib diisi.";

            return null;
        }

        $leaveType = $this->getLeaveType($leaveTypeIdentifier);
        if (! $leaveType) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Jenis cuti '{$leaveTypeIdentifier}' tidak ditemukan.";

            return null;
        }

        $startDateRaw = $this->getRowValue($row, ['tanggal_mulai', 'start_date', 'tgl_mulai']);
        $endDateRaw = $this->getRowValue($row, ['tanggal_selesai', 'end_date', 'tgl_selesai', 'tgl_berakhir']);
        $startDate = $this->parseDate($startDateRaw);
        $endDate = $this->parseDate($endDateRaw);

        if (! $startDate || ! $endDate) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Tanggal Mulai dan Tanggal Selesai wajib diisi dengan format tanggal yang valid.";

            return null;
        }

        if ($endDate < $startDate) {
            $this->skipCount++;
            $this->errors[] = "Baris {$rowNum}: Tanggal Selesai tidak boleh sebelum Tanggal Mulai.";

            return null;
        }

        $isHalfDay = $this->parseBoolean($this->getRowValue($row, ['setengah_hari', 'is_half_day', 'half_day']) ?? 'Tidak');
        $halfDayTypeRaw = $this->getRowValue($row, ['sesi_setengah_hari', 'half_day_type', 'sesi']);
        $halfDayType = $isHalfDay ? $this->parseHalfDayType($halfDayTypeRaw) : null;

        $totalDaysRaw = $this->getRowValue($row, ['jumlah_hari', 'total_days', 'lama_cuti']);
        if ($isHalfDay) {
            $totalDays = 0.5;
        } elseif (is_numeric($totalDaysRaw) && (float) $totalDaysRaw > 0) {
            $totalDays = (float) $totalDaysRaw;
        } else {
            $totalDays = (float) (Carbon::parse($startDate)->diffInDays(Carbon::parse($endDate)) + 1);
        }

        $reason = trim((string) $this->getRowValue($row, ['alasan', 'reason', 'keterangan']));
        $status = $this->parseStatus($this->getRowValue($row, ['status']));
        $approvalNotes = trim((string) $this->getRowValue($row, ['catatan', 'notes', 'catatan_persetujuan']));

        $leaveRequest = new LeaveRequest([
            'company_id' => $this->companyId,
            'employee_id' => $employee->id,
            'leave_type_id' => $leaveType->id,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_days' => $totalDays,
            'is_half_day' => $isHalfDay,
            'half_day_type' => $halfDayType,
            'reason' => ! empty($reason) ? $reason : 'Cuti (data impor)',
            'status' => $status,
        ]);

        if ($status === 'approved') {
            $leaveRequest->approved_at = now();
            $leaveRequest->approval_notes = ! empty($approvalNotes) ? $approvalNotes : null;
        } elseif ($status === 'rejected') {
            $leaveRequest->rejected_at = now();
            $leaveRequest->rejection_reason = ! empty($approvalNotes) ? $approvalNotes : null;
        } elseif ($status === 'cancelled') {
            $leaveRequest->cancelled_at = now();
            $leaveRequest->cancellation_reason = ! empty($approvalNotes) ? $approvalNotes : null;
        }

        $leaveRequest->save();

        $this->applyBalanceEffect($employee, $leaveType, $leaveRequest, $status, $totalDays);

        $this->successCount++;

        return $leaveRequest;
    }

    public function rules(): array
    {
        return [];
    }

    /**
     * Historical imports bypass LeaveRequest::approve()/reject()/cancel() (no
     * pending-days workflow to convert from), so the matching LeaveBalance
     * row is adjusted directly here instead.
     */
    protected function applyBalanceEffect(
        Employee $employee,
        LeaveType $leaveType,
        LeaveRequest $leaveRequest,
        string $status,
        float $totalDays
    ): void {
        if (! in_array($status, ['approved', 'pending'], true)) {
            return;
        }

        $year = Carbon::parse($leaveRequest->start_date)->year;

        $balance = LeaveBalance::firstOrCreate(
            [
                'company_id' => $this->companyId,
                'employee_id' => $employee->id,
                'leave_type_id' => $leaveType->id,
                'year' => $year,
            ],
            [
                'entitled_days' => $leaveType->default_days,
                'used_days' => 0,
                'pending_days' => 0,
                'carried_forward_days' => 0,
                'adjustment_days' => 0,
            ]
        );

        if ($status === 'approved') {
            $balance->deductDays($totalDays);
        } else {
            $balance->addPendingDays($totalDays);
        }
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

    protected function getEmployee(mixed $identifier): ?Employee
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
                    $this->employeeMap[strtolower(trim($emp->employee_id))] = $emp;
                }
                if (! empty($emp->pin)) {
                    $this->employeeMap[(string) $emp->pin] = $emp;
                }
                if (! empty($emp->nik)) {
                    $this->employeeMap[strtolower(trim($emp->nik))] = $emp;
                }
                if (! empty($emp->identity_number)) {
                    $this->employeeMap[strtolower(trim($emp->identity_number))] = $emp;
                }
                if (! empty($emp->email)) {
                    $this->employeeMap[strtolower(trim($emp->email))] = $emp;
                }
                $fullName = trim($emp->first_name.' '.($emp->last_name ?? ''));
                if (! empty($fullName)) {
                    $this->employeeMap[strtolower($fullName)] = $emp;
                }
            }
        }

        return $this->employeeMap[$key] ?? null;
    }

    protected function getLeaveType(mixed $identifier): ?LeaveType
    {
        $key = strtolower(trim((string) $identifier));
        if ($key === '') {
            return null;
        }

        if ($this->leaveTypeMap === null) {
            $this->leaveTypeMap = [];
            $leaveTypes = LeaveType::where('company_id', $this->companyId)->get();

            foreach ($leaveTypes as $type) {
                if (! empty($type->code)) {
                    $this->leaveTypeMap[strtolower(trim($type->code))] = $type;
                }
                if (! empty($type->name)) {
                    $this->leaveTypeMap[strtolower(trim($type->name))] = $type;
                }
            }
        }

        return $this->leaveTypeMap[$key] ?? null;
    }

    public function parseDate(mixed $value): ?string
    {
        if (empty($value)) {
            return null;
        }

        if ($value instanceof \DateTime || $value instanceof Carbon) {
            return $value->format('Y-m-d');
        }

        if (is_numeric($value)) {
            try {
                return \PhpOffice\PhpSpreadsheet\Shared\Date::excelToDateTimeObject($value)->format('Y-m-d');
            } catch (\Exception $e) {
                // fallback below
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

    public function parseBoolean(mixed $value): bool
    {
        if (is_bool($value)) {
            return $value;
        }

        $value = strtolower(trim((string) $value));

        return in_array($value, ['ya', 'yes', '1', 'true']);
    }

    public function parseHalfDayType(mixed $value): string
    {
        $value = strtolower(trim((string) $value));

        return in_array($value, ['siang', 'afternoon', 'sore']) ? 'afternoon' : 'morning';
    }

    public function parseStatus(mixed $value): string
    {
        $value = strtolower(trim((string) $value));

        return match ($value) {
            'ditolak', 'rejected' => 'rejected',
            'dibatalkan', 'cancelled', 'canceled' => 'cancelled',
            'menunggu', 'pending' => 'pending',
            default => 'approved',
        };
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
