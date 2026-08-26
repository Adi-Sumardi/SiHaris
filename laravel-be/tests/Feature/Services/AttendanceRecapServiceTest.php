<?php

use App\Models\Attendance;
use App\Models\Company;
use App\Models\Employee;
use App\Models\Holiday;
use App\Models\LeaveRequest;
use App\Models\LeaveType;
use App\Services\AttendanceRecapService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create(['timezone' => 'Asia/Jakarta']);
    $this->employee = Employee::factory()->create(['company_id' => $this->company->id]);
    $this->service = app(AttendanceRecapService::class);
});

describe('AttendanceRecapService::compute', function () {
    it('excludes weekends and company holidays from working_days', function () {
        // Monday 2026-02-02 to Sunday 2026-02-08 (1 full week)
        $start = Carbon::create(2026, 2, 2);
        $end = Carbon::create(2026, 2, 8);

        Holiday::create([
            'company_id' => $this->company->id,
            'name' => 'Libur Nasional',
            'date' => '2026-02-04', // Wednesday inside the period
            'type' => 'national',
            'is_recurring' => false,
            'is_active' => true,
        ]);

        $recap = $this->service->compute($this->employee, $start, $end);

        // Mon, Tue, Thu, Fri are working days (Wed is holiday, Sat/Sun are weekend)
        expect($recap['working_days'])->toBe(4);
    });

    it('counts present, late, absent and leave days correctly', function () {
        $start = Carbon::create(2026, 2, 2); // Monday
        $end = Carbon::create(2026, 2, 6); // Friday

        Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => '2026-02-02',
            'status' => 'present',
        ]);
        Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => '2026-02-03',
            'status' => 'late',
        ]);
        Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => '2026-02-04',
            'status' => 'absent',
        ]);

        $leaveType = LeaveType::factory()->create(['company_id' => $this->company->id]);
        LeaveRequest::factory()->approved()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'leave_type_id' => $leaveType->id,
            'start_date' => '2026-02-05',
            'end_date' => '2026-02-05',
            'total_days' => 1,
        ]);

        $recap = $this->service->compute($this->employee, $start, $end);

        expect($recap['working_days'])->toBe(5);
        expect($recap['present_days'])->toBe(2); // present + late both count as present
        expect($recap['weekday_present_days'])->toBe(2);
        expect($recap['saturday_present_days'])->toBe(0);
        expect($recap['total_present_days'])->toBe(2);
        expect($recap['late_days'])->toBe(1);
        expect($recap['absent_days'])->toBe(1);
        expect($recap['leave_days'])->toBe(1);
        expect((float) $recap['attendance_percentage'])->toEqual(40.0); // 2/5
    });

    it('accurately counts Saturday attendance and late > 5 minutes', function () {
        $start = Carbon::create(2026, 8, 1);
        $end = Carbon::create(2026, 8, 10);

        // Saturday 2026-08-01: present
        Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => '2026-08-01',
            'status' => 'present',
            'late_minutes' => 0,
        ]);

        // Monday 2026-08-03: late by 15 mins (> 5)
        Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => '2026-08-03',
            'status' => 'late',
            'late_minutes' => 15,
        ]);

        // Tuesday 2026-08-04: late by 3 mins (<= 5)
        Attendance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'date' => '2026-08-04',
            'status' => 'late',
            'late_minutes' => 3,
        ]);

        $recap = $this->service->compute($this->employee, $start, $end);

        expect($recap['weekday_present_days'])->toBe(2);
        expect($recap['saturday_present_days'])->toBe(1);
        expect($recap['total_present_days'])->toBe(3);
        expect($recap['late_days'])->toBe(2);
        expect($recap['late_gt_5_days'])->toBe(1); // only the 15 mins one
    });
});

describe('AttendanceRecapService::periodFor', function () {
    it('returns yesterday for daily frequency', function () {
        $reference = Carbon::create(2026, 2, 10); // Tuesday

        [$start, $end] = $this->service->periodFor('daily', $reference);

        expect($start->toDateString())->toBe('2026-02-09');
        expect($end->toDateString())->toBe('2026-02-09');
    });

    it('returns the most recently completed Monday-Sunday week for weekly frequency', function () {
        $reference = Carbon::create(2026, 2, 10); // Tuesday, week of Feb 9-15

        [$start, $end] = $this->service->periodFor('weekly', $reference);

        expect($start->toDateString())->toBe('2026-02-02'); // previous Monday
        expect($end->toDateString())->toBe('2026-02-08'); // previous Sunday
    });

    it('returns the most recently completed calendar month for monthly frequency when cutoff is 1', function () {
        $reference = Carbon::create(2026, 3, 5);

        [$start, $end] = $this->service->periodFor('monthly', $reference);

        expect($start->toDateString())->toBe('2026-02-01');
        expect($end->toDateString())->toBe('2026-02-28');
    });

    it('returns custom cutoff period (21st to 20th) when company cutoff is 21', function () {
        $company = Company::factory()->create([
            'attendance_recap_day_of_month' => 21,
            'timezone' => 'Asia/Jakarta',
        ]);
        $reference = Carbon::create(2026, 8, 21, 8, 0, 0, 'Asia/Jakarta');

        [$start, $end] = $this->service->periodFor('monthly', $reference, $company);

        expect($start->toDateString())->toBe('2026-07-21');
        expect($end->toDateString())->toBe('2026-08-20');
    });
});
