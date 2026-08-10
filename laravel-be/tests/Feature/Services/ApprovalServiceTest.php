<?php

use App\Models\ApprovalWorkflow;
use App\Models\ApprovalWorkflowStep;
use App\Models\Company;
use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\LeaveType;
use App\Models\User;
use App\Services\ApprovalService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);
    setPermissionsTeamId($this->company->id);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('employee');
    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'user_id' => $this->user->id,
        'manager_id' => null, // no manager assigned
    ]);

    $this->service = app(ApprovalService::class);
});

describe('ApprovalService auto-skip finalization', function () {
    it('does not record the requesting employee as the approver when every step is auto-skipped', function () {
        $workflow = ApprovalWorkflow::factory()->leaveRequest()->create([
            'company_id' => $this->company->id,
        ]);

        // Only step: direct manager, skippable — but this employee has no manager,
        // so it will be auto-skipped and the request auto-finalized with no real approver.
        ApprovalWorkflowStep::factory()->create([
            'approval_workflow_id' => $workflow->id,
            'step_order' => 1,
            'approver_type' => ApprovalWorkflowStep::APPROVER_TYPE_DIRECT_MANAGER,
            'can_skip' => true,
        ]);

        $leaveType = LeaveType::factory()->create(['company_id' => $this->company->id]);
        $leaveRequest = LeaveRequest::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'leave_type_id' => $leaveType->id,
            'start_date' => now()->addDays(3),
            'end_date' => now()->addDays(4),
            'total_days' => 2,
            'reason' => 'Test',
            'status' => 'pending',
        ]);

        $this->service->initializeWorkflow($leaveRequest, ApprovalWorkflow::TYPE_LEAVE_REQUEST, $this->company->id);

        $leaveRequest->refresh();

        expect($leaveRequest->status)->toBe('approved');
        expect($leaveRequest->approved_by)->not->toBe($this->user->id);
    });
});
