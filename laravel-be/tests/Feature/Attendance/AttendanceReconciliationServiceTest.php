<?php

use App\Events\AttendanceClockIn;
use App\Events\AttendanceClockOut;
use App\Models\Company;
use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Models\WorkSchedule;
use App\Services\AttendanceReconciliationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create(['timezone' => 'Asia/Jakarta']);
    $this->workSchedule = WorkSchedule::factory()->create([
        'company_id' => $this->company->id,
        'start_time' => '08:00:00',
        'end_time' => '17:00:00',
        'late_tolerance' => 15,
        'early_leave_tolerance' => 15,
    ]);
    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'work_schedule_id' => $this->workSchedule->id,
    ]);
    $this->service = app(AttendanceReconciliationService::class);
});

function jakartaTime(Company $company, string $time): \Carbon\Carbon
{
    return \Carbon\Carbon::parse($company->today()->format('Y-m-d').' '.$time, $company->timezone);
}

describe('AttendanceReconciliationService', function () {
    it('creates attendance on first clock-in event', function () {
        $eventTime = jakartaTime($this->company, '08:05');

        $result = $this->service->record($this->employee, 'clock_in', $eventTime, 'app_face');

        expect($result['status'])->toBe('applied');
        expect($result['attendance'])->not->toBeNull();
        expect($result['attendance']->clock_in_source)->toBe('app_face');
        expect($result['attendance']->clock_in_status)->toBe('on_time');

        $this->assertDatabaseCount('raw_attendance_logs', 1);
        $this->assertDatabaseHas('raw_attendance_logs', ['status' => 'applied', 'channel' => 'app_face']);
    });

    it('ignores an exact duplicate event (idempotent)', function () {
        $eventTime = jakartaTime($this->company, '08:05');

        $this->service->record($this->employee, 'clock_in', $eventTime, 'app_face');
        $result = $this->service->record($this->employee, 'clock_in', $eventTime, 'app_face');

        expect($result['status'])->toBe('duplicate_event');
        $this->assertDatabaseCount('raw_attendance_logs', 1);
    });

    it('ignores a second clock-in from a different channel same day', function () {
        $appTime = jakartaTime($this->company, '08:05');
        $fingerprintTime = jakartaTime($this->company, '08:07');

        $this->service->record($this->employee, 'clock_in', $appTime, 'app_face');
        $result = $this->service->record($this->employee, 'clock_in', $fingerprintTime, 'fingerprint');

        expect($result['status'])->toBe('duplicate_ignored');
        expect($result['attendance']->clock_in_source)->toBe('app_face');
        expect($result['attendance']->clock_in?->setTimezone($this->company->timezone)->format('H:i'))->toBe('08:05');

        $this->assertDatabaseCount('raw_attendance_logs', 2);
    });

    it('supersedes clock-in when an earlier event arrives beyond skew tolerance', function () {
        $laterTime = jakartaTime($this->company, '08:10');
        $earlierTime = jakartaTime($this->company, '08:00');

        $this->service->record($this->employee, 'clock_in', $laterTime, 'app_face');
        $result = $this->service->record($this->employee, 'clock_in', $earlierTime, 'fingerprint');

        expect($result['status'])->toBe('superseded');
        expect($result['attendance']->clock_in?->setTimezone($this->company->timezone)->format('H:i'))->toBe('08:00');
        expect($result['attendance']->clock_in_source)->toBe('fingerprint');
    });

    it('does not supersede clock-in when the earlier event is within skew tolerance', function () {
        $laterTime = jakartaTime($this->company, '08:10:00');
        $withinSkew = jakartaTime($this->company, '08:09:00'); // 1 minute earlier, within 2-minute skew

        $this->service->record($this->employee, 'clock_in', $laterTime, 'app_face');
        $result = $this->service->record($this->employee, 'clock_in', $withinSkew, 'fingerprint');

        expect($result['status'])->toBe('duplicate_ignored');
        expect($result['attendance']->clock_in?->setTimezone($this->company->timezone)->format('H:i'))->toBe('08:10');
    });

    it('always applies the latest clock-out event', function () {
        $clockIn = jakartaTime($this->company, '08:00');
        $firstOut = jakartaTime($this->company, '17:00');
        $secondOut = jakartaTime($this->company, '17:05');

        $this->service->record($this->employee, 'clock_in', $clockIn, 'app_face');
        $this->service->record($this->employee, 'clock_out', $firstOut, 'app_face');
        $result = $this->service->record($this->employee, 'clock_out', $secondOut, 'fingerprint');

        expect($result['status'])->toBe('applied');
        expect($result['attendance']->clock_out?->setTimezone($this->company->timezone)->format('H:i'))->toBe('17:05');
        expect($result['attendance']->clock_out_source)->toBe('fingerprint');
    });

    it('ignores an earlier clock-out event replayed after a later one is recorded', function () {
        $clockIn = jakartaTime($this->company, '08:00');
        $laterOut = jakartaTime($this->company, '17:05');
        $earlierOut = jakartaTime($this->company, '17:00');

        $this->service->record($this->employee, 'clock_in', $clockIn, 'app_face');
        $this->service->record($this->employee, 'clock_out', $laterOut, 'app_face');
        $result = $this->service->record($this->employee, 'clock_out', $earlierOut, 'fingerprint');

        expect($result['status'])->toBe('duplicate_ignored');
        expect($result['attendance']->clock_out?->setTimezone($this->company->timezone)->format('H:i'))->toBe('17:05');
    });

    it('creates a needs_review record for clock-out without prior clock-in', function () {
        $clockOut = jakartaTime($this->company, '17:00');

        $result = $this->service->record($this->employee, 'clock_out', $clockOut, 'fingerprint');

        expect($result['status'])->toBe('applied');
        expect($result['attendance']->needs_review)->toBeTrue();
        expect($result['attendance']->clock_in)->toBeNull();
        expect($result['attendance']->clock_out)->not->toBeNull();
    });

    it('marks the raw log as unmatched when no employee is resolved (unmapped fingerprint PIN)', function () {
        $device = FingerprintDevice::factory()->create(['company_id' => $this->company->id]);
        $eventTime = jakartaTime($this->company, '08:00');

        $result = $this->service->record(null, 'clock_in', $eventTime, 'fingerprint', [
            'company_id' => $this->company->id,
            'fingerprint_device_id' => $device->id,
            'device_user_pin' => '9999',
        ]);

        expect($result['status'])->toBe('unmatched');
        expect($result['attendance'])->toBeNull();
        $this->assertDatabaseHas('raw_attendance_logs', [
            'status' => 'unmatched',
            'device_user_pin' => '9999',
        ]);
    });

    it('records fingerprint device metadata on the attendance row', function () {
        $device = FingerprintDevice::factory()->create(['company_id' => $this->company->id]);
        $eventTime = jakartaTime($this->company, '08:00');

        $result = $this->service->record($this->employee, 'clock_in', $eventTime, 'fingerprint', [
            'fingerprint_device_id' => $device->id,
            'device_user_pin' => '1234',
        ]);

        expect($result['attendance']->clock_in_device_id)->toBe($device->id);
    });

    it('is idempotent when the exact same raw event is submitted concurrently (dedup hash race)', function () {
        $eventTime = jakartaTime($this->company, '08:05');

        // Simulate two near-simultaneous submissions of the identical event.
        $first = $this->service->record($this->employee, 'clock_in', $eventTime, 'fingerprint', [
            'fingerprint_device_id' => null,
            'device_user_pin' => '1234',
        ]);
        $second = $this->service->record($this->employee, 'clock_in', $eventTime, 'fingerprint', [
            'fingerprint_device_id' => null,
            'device_user_pin' => '1234',
        ]);

        expect($first['status'])->toBe('applied');
        expect($second['status'])->toBe('duplicate_event');
        $this->assertDatabaseCount('attendances', 1);
    });

    it('attaches a post-midnight clock-out to the overnight shift that started the day before', function () {
        $overnightSchedule = WorkSchedule::factory()->create([
            'company_id' => $this->company->id,
            'start_time' => '22:00:00',
            'end_time' => '06:00:00',
            'is_overnight' => true,
            'working_days' => [1, 2, 3, 4, 5, 6, 7],
        ]);
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $overnightSchedule->id,
        ]);

        $yesterday = $this->company->today()->subDay();
        $clockIn = \Carbon\Carbon::parse($yesterday->format('Y-m-d').' 22:05', $this->company->timezone);
        $clockOut = \Carbon\Carbon::parse($this->company->today()->format('Y-m-d').' 06:10', $this->company->timezone);

        $inResult = $this->service->record($employee, 'clock_in', $clockIn, 'app_face');
        $outResult = $this->service->record($employee, 'clock_out', $clockOut, 'app_face');

        expect($outResult['status'])->toBe('applied');
        expect($outResult['attendance']->id)->toBe($inResult['attendance']->id);
        expect($outResult['attendance']->date->toDateString())->toBe($yesterday->toDateString());

        $this->assertDatabaseCount('attendances', 1);
    });

    it('dispatches AttendanceClockIn/ClockOut for a fingerprint (ADMS) channel event, not just app_face', function () {
        Event::fake([AttendanceClockIn::class, AttendanceClockOut::class]);

        $clockIn = jakartaTime($this->company, '08:00');
        $clockOut = jakartaTime($this->company, '17:00');

        $this->service->record($this->employee, 'clock_in', $clockIn, 'fingerprint');
        $this->service->record($this->employee, 'clock_out', $clockOut, 'fingerprint');

        Event::assertDispatchedTimes(AttendanceClockIn::class, 1);
        Event::assertDispatchedTimes(AttendanceClockOut::class, 1);
    });

    it('does not dispatch a duplicate AttendanceClockIn when the same event is replayed', function () {
        Event::fake([AttendanceClockIn::class]);

        $eventTime = jakartaTime($this->company, '08:05');

        $this->service->record($this->employee, 'clock_in', $eventTime, 'app_face');
        $this->service->record($this->employee, 'clock_in', $eventTime, 'app_face');

        Event::assertDispatchedTimes(AttendanceClockIn::class, 1);
    });
});
