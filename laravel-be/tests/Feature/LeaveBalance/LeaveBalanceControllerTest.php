<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\LeaveBalance;
use App\Models\LeaveType;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);
    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);
});

describe('LeaveBalanceController index', function () {
    it('displays whole-number balances without a trailing .0', function () {
        $employee = Employee::factory()->create(['company_id' => $this->company->id]);
        $leaveType = LeaveType::factory()->create(['company_id' => $this->company->id, 'name' => 'Cuti Tahunan']);

        LeaveBalance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $employee->id,
            'leave_type_id' => $leaveType->id,
            'entitled_days' => 10,
            'carried_forward_days' => 2,
            'used_days' => 0,
            'pending_days' => 0,
        ]);

        $response = $this->get(route('leave-balances.index'));

        // These digits sit directly inside their <td>, with no surrounding
        // whitespace in the compiled Blade output, so ">10<" only matches
        // when the value rendered exactly as "10" and not "10.0".
        $response->assertOk()
            ->assertSee('>10<', false)
            ->assertSee('>2<', false);
    });

    it('keeps the decimal for a half-day balance', function () {
        $employee = Employee::factory()->create(['company_id' => $this->company->id]);
        $leaveType = LeaveType::factory()->create(['company_id' => $this->company->id]);

        LeaveBalance::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => $employee->id,
            'leave_type_id' => $leaveType->id,
            'entitled_days' => 12,
            'used_days' => 0.5,
        ]);

        $response = $this->get(route('leave-balances.index'));

        $response->assertOk()->assertSee('>0.5<', false);
    });
});
