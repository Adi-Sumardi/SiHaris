<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\Holiday;
use App\Models\WorkSchedule;
use App\Services\LeaveDayCalculatorService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    $this->service = new LeaveDayCalculatorService;
});

describe('LeaveDayCalculatorService', function () {
    it('counts a half day as 0.5 regardless of the date range', function () {
        $employee = Employee::factory()->create(['company_id' => $this->company->id]);

        $days = $this->service->calculate($employee, Carbon::parse('2026-03-02'), Carbon::parse('2026-03-02'), true);

        expect($days)->toBe(0.5);
    });

    it('excludes weekends for an employee with a standard Mon-Fri schedule', function () {
        $schedule = WorkSchedule::factory()->create([
            'company_id' => $this->company->id,
            'working_days' => [1, 2, 3, 4, 5],
        ]);
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $schedule->id,
        ]);

        // Friday 2026-03-06 through Monday 2026-03-09 (spans a weekend).
        $days = $this->service->calculate($employee, Carbon::parse('2026-03-06'), Carbon::parse('2026-03-09'));

        // Fri + Mon = 2 working days, Sat/Sun excluded.
        expect($days)->toBe(2.0);
    });

    it('excludes company holidays that fall within the range', function () {
        $schedule = WorkSchedule::factory()->create([
            'company_id' => $this->company->id,
            'working_days' => [1, 2, 3, 4, 5],
        ]);
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $schedule->id,
        ]);

        // A Wednesday declared as a company holiday inside a Mon-Fri range.
        Holiday::factory()->create([
            'company_id' => $this->company->id,
            'date' => '2026-03-04',
            'is_active' => true,
        ]);

        $days = $this->service->calculate($employee, Carbon::parse('2026-03-02'), Carbon::parse('2026-03-06'));

        // Mon, Tue, Thu, Fri = 4 days; Wed (holiday) excluded.
        expect($days)->toBe(4.0);
    });

    it('falls back to Mon-Fri when the employee has no schedule at all', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => null,
        ]);

        $days = $this->service->calculate($employee, Carbon::parse('2026-03-06'), Carbon::parse('2026-03-09'));

        expect($days)->toBe(2.0);
    });

    it('counts weekend days for an employee whose schedule includes Saturday', function () {
        $schedule = WorkSchedule::factory()->create([
            'company_id' => $this->company->id,
            'working_days' => [1, 2, 3, 4, 5, 6],
        ]);
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $schedule->id,
        ]);

        // Friday through Sunday: Fri+Sat are working days for this schedule, Sun is not.
        $days = $this->service->calculate($employee, Carbon::parse('2026-03-06'), Carbon::parse('2026-03-08'));

        expect($days)->toBe(2.0);
    });
});
