<?php

use App\Models\Attendance;
use App\Models\Company;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);
    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);

    $this->workSchedule = WorkSchedule::factory()->create([
        'company_id' => $this->company->id,
    ]);

    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'work_schedule_id' => $this->workSchedule->id,
    ]);
});

describe('Attendance Report', function () {
    it('displays attendance report page', function () {
        $response = $this->get(route('attendances.report'));

        $response->assertOk();
        $response->assertViewIs('attendances.report');
    });

    it('can filter by month', function () {
        $thisMonth = Carbon::today();

        // Create attendances for different dates in the same month
        for ($i = 1; $i <= 5; $i++) {
            Attendance::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => $this->employee->id,
                'date' => $thisMonth->copy()->startOfMonth()->addDays($i - 1),
            ]);
        }

        $response = $this->get(route('attendances.report', [
            'month' => $thisMonth->format('Y-m'),
        ]));

        $response->assertOk();
    });

    it('can filter by employee', function () {
        // Create attendances for different dates
        for ($i = 1; $i <= 3; $i++) {
            Attendance::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => $this->employee->id,
                'date' => Carbon::today()->subDays($i),
            ]);
        }

        $response = $this->get(route('attendances.report', [
            'employee_id' => $this->employee->id,
        ]));

        $response->assertOk();
    });

    it('shows summary statistics', function () {
        // Create various attendance statuses on different dates
        Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => Carbon::today(),
            'status' => 'present',
        ]);
        Attendance::factory()->late()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => Carbon::today()->subDay(),
            'status' => 'late',
        ]);
        Attendance::factory()->absent()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => Carbon::today()->subDays(2),
        ]);

        $response = $this->get(route('attendances.report'));

        $response->assertOk();
        $response->assertViewHas('summary');
    });

    it('can export to excel', function () {
        // Create attendances for different dates
        for ($i = 1; $i <= 5; $i++) {
            Attendance::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => $this->employee->id,
                'date' => Carbon::today()->subDays($i),
            ]);
        }

        $response = $this->get(route('attendances.export', [
            'format' => 'csv',
        ]));

        $response->assertOk();
    });

    it('counts an employee with zero attendance rows as absent on their scheduled working days', function () {
        $targetMonth = Carbon::now()->subMonthNoOverflow()->startOfMonth();

        $expectedWorkingDays = 0;
        $cursor = $targetMonth->copy();
        while ($cursor->lte($targetMonth->copy()->endOfMonth())) {
            if ($cursor->isWeekday()) {
                $expectedWorkingDays++;
            }
            $cursor->addDay();
        }

        $absentEmployee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $this->workSchedule->id,
            'first_name' => 'Tanpa',
            'last_name' => 'Presensi',
        ]);

        $response = $this->get(route('attendances.report', ['month' => $targetMonth->format('Y-m')]));

        $response->assertOk();
        $reportData = $response->viewData('reportData');
        expect($reportData->get($absentEmployee->id)['absent'])->toBe($expectedWorkingDays);
        expect($reportData->get($absentEmployee->id)['leave'])->toBe(0);
    });

    it('counts approved leave days automatically without needing an Attendance row', function () {
        $targetMonth = Carbon::now()->subMonthNoOverflow()->startOfMonth();
        $leaveDate = $targetMonth->copy();
        while (! $leaveDate->isWeekday()) {
            $leaveDate->addDay();
        }

        $onLeaveEmployee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $this->workSchedule->id,
            'first_name' => 'Sedang',
            'last_name' => 'Cuti',
        ]);

        \App\Models\LeaveRequest::factory()->approved()->singleDay($leaveDate->format('Y-m-d'))->create([
            'company_id' => $this->company->id,
            'employee_id' => $onLeaveEmployee->id,
        ]);

        $response = $this->get(route('attendances.report', ['month' => $targetMonth->format('Y-m')]));

        $response->assertOk();
        $reportData = $response->viewData('reportData');
        expect($reportData->get($onLeaveEmployee->id)['leave'])->toBe(1);
    });

    it('does not count days later in the current month that have not happened yet', function () {
        $today = Carbon::today();

        $expectedWorkingDaysSoFar = 0;
        $cursor = $today->copy()->startOfMonth();
        while ($cursor->lte($today)) {
            if ($cursor->isWeekday()) {
                $expectedWorkingDaysSoFar++;
            }
            $cursor->addDay();
        }

        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $this->workSchedule->id,
            'first_name' => 'Bulan',
            'last_name' => 'Berjalan',
        ]);

        $response = $this->get(route('attendances.report', ['month' => $today->format('Y-m')]));

        $response->assertOk();
        $reportData = $response->viewData('reportData');
        expect($reportData->get($employee->id)['absent'])->toBe($expectedWorkingDaysSoFar);
    });

    it('filters the report rows by status', function () {
        $targetMonth = Carbon::now()->subMonthNoOverflow()->startOfMonth();

        $onLeaveEmployee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $this->workSchedule->id,
            'first_name' => 'Sedang',
            'last_name' => 'Cuti',
        ]);
        \App\Models\LeaveRequest::factory()->approved()->singleDay($targetMonth->copy()->addDays(2)->format('Y-m-d'))->create([
            'company_id' => $this->company->id,
            'employee_id' => $onLeaveEmployee->id,
        ]);

        $neverAbsentEmployee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'work_schedule_id' => $this->workSchedule->id,
            'first_name' => 'Hadir',
            'last_name' => 'Semua',
        ]);
        $cursor = $targetMonth->copy();
        while ($cursor->lte($targetMonth->copy()->endOfMonth())) {
            if ($cursor->isWeekday()) {
                Attendance::factory()->create([
                    'company_id' => $this->company->id,
                    'employee_id' => $neverAbsentEmployee->id,
                    'date' => $cursor->format('Y-m-d'),
                    'status' => 'present',
                ]);
            }
            $cursor->addDay();
        }

        $response = $this->get(route('attendances.report', [
            'month' => $targetMonth->format('Y-m'),
            'status' => 'leave',
        ]));

        $response->assertOk();
        $response->assertSee('Sedang Cuti');
        $response->assertDontSee('Hadir Semua');
    });

    it('shows only company attendances in report', function () {
        $myAttendance = Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
        ]);

        $otherCompany = Company::factory()->create();
        $otherEmployee = Employee::factory()->create([
            'company_id' => $otherCompany->id,
        ]);
        Attendance::factory()->create([
            'company_id' => $otherCompany->id,
            'employee_id' => $otherEmployee->id,
        ]);

        $response = $this->get(route('attendances.report'));

        $response->assertOk();
        $response->assertSee($this->employee->full_name);
    });
});
