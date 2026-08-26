<?php

namespace App\Services;

use App\Events\AttendanceClockIn;
use App\Events\AttendanceClockOut;
use App\Models\Attendance;
use App\Models\Employee;
use App\Models\RawAttendanceLog;
use Carbon\Carbon;

/**
 * Single entry point for recording an attendance event coming from any
 * channel (mobile app face+GPS, web portal, admin web, or a fingerprint
 * machine). Guarantees:
 *
 * - Idempotency: the exact same raw event (channel + device + type + time)
 *   is never applied twice, even if submitted concurrently.
 * - Anti-double-absen: only one `clock_in` and one `clock_out` per
 *   employee per work day is ever stored (enforced by the `attendances`
 *   unique(employee_id, date) constraint plus the rules below).
 * - Cross-channel consistency: `clock_in` keeps the earliest valid event,
 *   `clock_out` keeps the latest event, regardless of which channel sent it.
 */
class AttendanceReconciliationService
{
    /**
     * Events earlier than an already-recorded clock_in by less than this
     * many minutes are treated as noise (device clock drift) rather than a
     * genuine correction.
     */
    private const SKEW_MINUTES = 2;

    /**
     * @param  array{
     *     company_id?: int,
     *     fingerprint_device_id?: int|null,
     *     device_user_pin?: string|null,
     *     app_device_id?: string|null,
     *     latitude?: float|null,
     *     longitude?: float|null,
     *     photo?: string|null,
     *     notes?: string|null,
     *     face_verified?: bool|null,
     *     face_confidence?: float|null,
     *     liveness_passed?: bool|null,
     *     office_location_id?: int|null,
     *     ip?: string|null,
     * }  $meta
     * @return array{status: string, attendance: ?Attendance, raw: RawAttendanceLog}
     */
    public function record(?Employee $employee, string $type, Carbon $eventTime, string $channel, array $meta = []): array
    {
        $companyId = $employee?->company_id ?? $meta['company_id'] ?? null;

        $dedupHash = $this->buildDedupHash($employee, $type, $eventTime, $channel, $meta);

        $existingRaw = RawAttendanceLog::where('dedup_hash', $dedupHash)->first();
        if ($existingRaw) {
            return ['status' => 'duplicate_event', 'attendance' => $existingRaw->attendance, 'raw' => $existingRaw];
        }

        $raw = new RawAttendanceLog([
            'company_id' => $companyId,
            'employee_id' => $employee?->id,
            'channel' => $channel,
            'fingerprint_device_id' => $meta['fingerprint_device_id'] ?? null,
            'device_user_pin' => $meta['device_user_pin'] ?? null,
            'type' => $type,
            'event_time' => $eventTime,
            'received_at' => now(),
            'status' => 'pending',
            'dedup_hash' => $dedupHash,
            'payload' => $meta,
        ]);

        if (! $employee) {
            $raw->status = 'unmatched';

            try {
                $raw->save();
            } catch (\Illuminate\Database\UniqueConstraintViolationException) {
                // Lost the race to an identical concurrent event.
                $existingRaw = RawAttendanceLog::where('dedup_hash', $dedupHash)->first();

                return ['status' => 'duplicate_event', 'attendance' => null, 'raw' => $existingRaw];
            }

            return ['status' => 'unmatched', 'attendance' => null, 'raw' => $raw];
        }

        $company = $employee->company;
        $workDate = $company ? $company->toCompanyTimezone($eventTime)->toDateString() : $eventTime->toDateString();

        // Overnight shifts: a clock_out after midnight belongs to the shift
        // that started the day before, not to a fresh row for "today".
        if ($type === 'clock_out') {
            $previousDate = Carbon::parse($workDate)->subDay()->toDateString();
            $openOvernightShift = Attendance::where('employee_id', $employee->id)
                ->whereDate('date', $previousDate)
                ->whereNotNull('clock_in')
                ->whereNull('clock_out')
                ->whereHas('workSchedule', fn ($q) => $q->where('is_overnight', true))
                ->exists();

            if ($openOvernightShift) {
                $workDate = $previousDate;
            }
        }

        // Store timestamps in UTC regardless of which channel/timezone the
        // event originated from, so cross-channel comparisons (app vs
        // fingerprint machine vs web) are always comparing true instants.
        $storageEventTime = $company ? $company->toUtc($eventTime) : $eventTime->copy()->utc();

        try {
            $result = \Illuminate\Support\Facades\DB::transaction(function () use ($employee, $type, $storageEventTime, $channel, $meta, $workDate) {
                $attendance = Attendance::where('employee_id', $employee->id)
                    ->whereDate('date', $workDate)
                    ->lockForUpdate()
                    ->first();

                $isNew = false;
                if (! $attendance) {
                    $isNew = true;
                    $schedule = $employee->resolveScheduleForDate(Carbon::parse($workDate, $employee->company?->timezone));
                    $attendance = new Attendance([
                        'company_id' => $employee->company_id,
                        'employee_id' => $employee->id,
                        'work_schedule_id' => $schedule?->id,
                        'date' => $workDate,
                        'scheduled_start' => $schedule?->start_time,
                        'scheduled_end' => $schedule?->end_time,
                    ]);
                }

                return $type === 'clock_in'
                    ? $this->applyClockIn($attendance, $isNew, $storageEventTime, $channel, $meta)
                    : $this->applyClockOut($attendance, $isNew, $storageEventTime, $channel, $meta);
            });
        } catch (\Illuminate\Database\UniqueConstraintViolationException) {
            // Lost the race creating the attendance row itself; retry once by
            // re-reading — the concurrent transaction has already committed.
            return $this->record($employee, $type, $eventTime, $channel, $meta);
        }

        [$attendance, $status] = $result;

        $raw->status = $status;
        $raw->attendance_id = $attendance->id;

        try {
            $raw->save();
        } catch (\Illuminate\Database\UniqueConstraintViolationException) {
            $existingRaw = RawAttendanceLog::where('dedup_hash', $dedupHash)->first();

            return ['status' => 'duplicate_event', 'attendance' => $attendance, 'raw' => $existingRaw];
        }

        return ['status' => $status, 'attendance' => $attendance, 'raw' => $raw];
    }

    /**
     * @return array{0: Attendance, 1: string}
     */
    private function applyClockIn(Attendance $attendance, bool $isNew, Carbon $eventTime, string $channel, array $meta): array
    {
        $data = $this->buildEventData($eventTime, $channel, $meta);

        if ($isNew || ! $attendance->clock_in) {
            $attendance->clockIn($data);
            AttendanceClockIn::dispatch($attendance);

            return [$attendance, 'applied'];
        }

        if ($eventTime->lt($attendance->clock_in->copy()->subMinutes(self::SKEW_MINUTES))) {
            $attendance->clockIn($data);
            AttendanceClockIn::dispatch($attendance);

            return [$attendance, 'superseded'];
        }

        return [$attendance, 'duplicate_ignored'];
    }

    /**
     * @return array{0: Attendance, 1: string}
     */
    private function applyClockOut(Attendance $attendance, bool $isNew, Carbon $eventTime, string $channel, array $meta): array
    {
        $data = $this->buildEventData($eventTime, $channel, $meta);

        if ($isNew) {
            $attendance->needs_review = true;
            $attendance->clockOut($data);
            AttendanceClockOut::dispatch($attendance);

            return [$attendance, 'applied'];
        }

        if (! $attendance->clock_out) {
            $attendance->clockOut($data);
            AttendanceClockOut::dispatch($attendance);

            return [$attendance, 'applied'];
        }

        if ($eventTime->gt($attendance->clock_out)) {
            $attendance->clockOut($data);
            AttendanceClockOut::dispatch($attendance);

            return [$attendance, 'applied'];
        }

        return [$attendance, 'duplicate_ignored'];
    }

    private function buildEventData(Carbon $eventTime, string $channel, array $meta): array
    {
        return array_filter([
            'event_time' => $eventTime,
            'source' => $channel,
            'device_id' => $meta['fingerprint_device_id'] ?? null,
            'app_device_id' => $meta['app_device_id'] ?? null,
            'ip' => $meta['ip'] ?? null,
            'latitude' => $meta['latitude'] ?? null,
            'longitude' => $meta['longitude'] ?? null,
            'photo' => $meta['photo'] ?? null,
            'notes' => $meta['notes'] ?? null,
            'office_location_id' => $meta['office_location_id'] ?? null,
            'face_verified' => $meta['face_verified'] ?? null,
            'face_confidence' => $meta['face_confidence'] ?? null,
            'liveness_passed' => $meta['liveness_passed'] ?? null,
        ], fn ($value) => $value !== null);
    }

    private function buildDedupHash(?Employee $employee, string $type, Carbon $eventTime, string $channel, array $meta): string
    {
        if ($channel === 'fingerprint') {
            $deviceKey = ($meta['fingerprint_device_id'] ?? 'unknown').'|'.($meta['device_user_pin'] ?? 'unknown');

            return hash('sha256', "{$deviceKey}|{$type}|{$eventTime->toIso8601String()}");
        }

        $employeeKey = $employee?->id ?? 'unmatched';

        return hash('sha256', "{$employeeKey}|{$type}|{$eventTime->toIso8601String()}|{$channel}");
    }
}
