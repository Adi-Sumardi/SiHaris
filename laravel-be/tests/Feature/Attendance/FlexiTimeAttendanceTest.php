<?php

use App\Models\Attendance;
use App\Models\Company;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

describe('Flexi Time Attendance', function () {
    beforeEach(function () {
        $this->company = Company::factory()->create([
            'timezone' => 'Asia/Jakarta',
            'enable_gps_validation' => false,
            'enable_face_recognition' => false,
        ]);

        $this->schedule = WorkSchedule::factory()->create([
            'company_id' => $this->company->id,
            'name' => 'Shift Fleksibel',
            'start_time' => '07:00',
            'end_time' => '16:00',
            'late_tolerance' => 60,
            'early_leave_tolerance' => 5,
            'break_duration' => 60,
            'is_flexible' => true,
            'is_active' => true,
        ]);

        $this->user = User::factory()->create([
            'company_id' => $this->company->id,
        ]);

        $this->employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
            'work_schedule_id' => $this->schedule->id,
        ]);
    });

    it('calculates on-time attendance when clocking in at standard start and clocking out at standard end', function () {
        $shiftDate = Carbon::parse('2026-08-26');

        $attendance = Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'work_schedule_id' => $this->schedule->id,
            'date' => $shiftDate,
            'scheduled_start' => '07:00',
            'scheduled_end' => '16:00',
        ]);

        $attendance->clockIn(['event_time' => Carbon::parse('2026-08-26 07:00:00', 'Asia/Jakarta')]);
        expect($attendance->status)->toBe('present');
        expect($attendance->clock_in_status)->toBe('on_time');
        expect($attendance->late_minutes)->toBe(0);
        expect($attendance->getDynamicScheduledEndDatetime()->setTimezone($this->company->timezone)->format('H:i'))->toBe('16:00');

        $attendance->clockOut(['event_time' => Carbon::parse('2026-08-26 16:00:00', 'Asia/Jakarta')]);
        expect($attendance->clock_out_status)->toBe('on_time');
        expect($attendance->early_leave_minutes)->toBe(0);
        expect($attendance->overtime_minutes)->toBe(0);
    });

    it('shifts target clock out dynamically when employee clocks in late within flexi tolerance (07:25 -> 16:25)', function () {
        $shiftDate = Carbon::parse('2026-08-26');

        $attendance = Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'work_schedule_id' => $this->schedule->id,
            'date' => $shiftDate,
            'scheduled_start' => '07:00',
            'scheduled_end' => '16:00',
        ]);

        // Clock in at 07:25 (25 minutes after 07:00, within 60 min tolerance)
        $attendance->clockIn(['event_time' => Carbon::parse('2026-08-26 07:25:00', 'Asia/Jakarta')]);

        expect($attendance->status)->toBe('present');
        expect($attendance->clock_in_status)->toBe('on_time');
        expect($attendance->late_minutes)->toBe(0);
        expect($attendance->getDynamicScheduledEndDatetime()->setTimezone($this->company->timezone)->format('H:i'))->toBe('16:25');

        // Clock out at 16:25 -> Exactly on time
        $attendance->clockOut(['event_time' => Carbon::parse('2026-08-26 16:25:00', 'Asia/Jakarta')]);

        expect($attendance->clock_out_status)->toBe('on_time');
        expect($attendance->early_leave_minutes)->toBe(0);
        expect($attendance->overtime_minutes)->toBe(0);
        expect($attendance->working_minutes)->toBe(480); // 9 hours - 1 hour break = 8 hours (480 mins)
    });

    it('treats clock-out within early leave tolerance (16:22) as on-time for flexi target 16:25', function () {
        $shiftDate = Carbon::parse('2026-08-26');

        $attendance = Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'work_schedule_id' => $this->schedule->id,
            'date' => $shiftDate,
            'scheduled_start' => '07:00',
            'scheduled_end' => '16:00',
        ]);

        $attendance->clockIn(['event_time' => Carbon::parse('2026-08-26 07:25:00', 'Asia/Jakarta')]);
        // Clock out at 16:22 (3 mins before 16:25, within 5 min early tolerance)
        $attendance->clockOut(['event_time' => Carbon::parse('2026-08-26 16:22:00', 'Asia/Jakarta')]);

        expect($attendance->clock_out_status)->toBe('on_time');
        expect($attendance->early_leave_minutes)->toBe(0);
    });

    it('marks attendance as early leave if employee leaves at 16:00 when dynamic flexi target was 16:25', function () {
        $shiftDate = Carbon::parse('2026-08-26');

        $attendance = Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'work_schedule_id' => $this->schedule->id,
            'date' => $shiftDate,
            'scheduled_start' => '07:00',
            'scheduled_end' => '16:00',
        ]);

        $attendance->clockIn(['event_time' => Carbon::parse('2026-08-26 07:25:00', 'Asia/Jakarta')]);
        // Leaves at 16:00 (25 mins before dynamic target 16:25)
        $attendance->clockOut(['event_time' => Carbon::parse('2026-08-26 16:00:00', 'Asia/Jakarta')]);

        expect($attendance->clock_out_status)->toBe('early');
        expect($attendance->early_leave_minutes)->toBe(25);
    });

    it('calculates overtime when clocking out after the dynamic flexi target (16:45 vs 16:25)', function () {
        $shiftDate = Carbon::parse('2026-08-26');

        $attendance = Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'work_schedule_id' => $this->schedule->id,
            'date' => $shiftDate,
            'scheduled_start' => '07:00',
            'scheduled_end' => '16:00',
        ]);

        $attendance->clockIn(['event_time' => Carbon::parse('2026-08-26 07:25:00', 'Asia/Jakarta')]);
        $attendance->clockOut(['event_time' => Carbon::parse('2026-08-26 16:45:00', 'Asia/Jakarta')]);

        expect($attendance->clock_out_status)->toBe('overtime');
        expect($attendance->overtime_minutes)->toBe(20);
        expect($attendance->early_leave_minutes)->toBe(0);
    });

    it('recalculates flexi attendance metrics correctly when recalculate() is called', function () {
        $shiftDate = Carbon::parse('2026-08-26');

        $attendance = Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'work_schedule_id' => $this->schedule->id,
            'date' => $shiftDate,
            'scheduled_start' => '07:00',
            'scheduled_end' => '16:00',
            'clock_in' => Carbon::parse('2026-08-26 07:25:00', 'Asia/Jakarta')->utc(),
            'clock_out' => Carbon::parse('2026-08-26 16:25:00', 'Asia/Jakarta')->utc(),
        ]);

        $attendance->recalculate();

        expect($attendance->clock_in_status)->toBe('on_time');
        expect($attendance->late_minutes)->toBe(0);
        expect($attendance->clock_out_status)->toBe('on_time');
        expect($attendance->early_leave_minutes)->toBe(0);
        expect($attendance->overtime_minutes)->toBe(0);
    });

    it('returns target_clock_out and flexi_minutes in GET /api/v1/attendance/today API response', function () {
        $today = $this->company->today();

        $attendance = Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'work_schedule_id' => $this->schedule->id,
            'date' => $today,
            'scheduled_start' => '07:00',
            'scheduled_end' => '16:00',
            'clock_in' => $this->company->toUtc(Carbon::parse($today->toDateString().' 07:25:00', 'Asia/Jakarta')),
            'status' => 'present',
            'late_minutes' => 0,
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/v1/attendance/today');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.clock_in', '07:25')
            ->assertJsonPath('data.target_clock_out', '16:25')
            ->assertJsonPath('data.flexi_minutes', 25)
            ->assertJsonPath('data.is_flexible', true)
            ->assertJsonPath('data.late_minutes', 0)
            ->assertJsonPath('schedule.is_flexible', true);
    });
});
