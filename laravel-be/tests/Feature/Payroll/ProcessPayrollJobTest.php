<?php

use App\Jobs\ProcessPayrollJob;
use App\Models\Company;
use App\Models\Employee;
use App\Models\EmployeeSalary;
use App\Models\Notification;
use App\Models\Payroll;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);
    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);
});

describe('Payroll processing is queued', function () {
    test('processing a payroll dispatches the job instead of running inline', function () {
        Queue::fake();

        $payroll = Payroll::factory()->draft()->create([
            'company_id' => $this->company->id,
            'created_by' => $this->user->id,
        ]);

        $response = $this->post(route('payrolls.process', $payroll));

        $response->assertRedirect(route('payrolls.show', $payroll));
        $response->assertSessionHas('success');

        Queue::assertPushed(ProcessPayrollJob::class, function (ProcessPayrollJob $job) use ($payroll) {
            return $job->payroll->is($payroll) && $job->triggeredByUserId === $this->user->id;
        });

        expect($payroll->fresh()->status)->toBe('processing');
    });

    test('the job calculates the payroll and notifies the trigger user', function () {
        $payroll = Payroll::factory()->draft()->create([
            'company_id' => $this->company->id,
            'created_by' => $this->user->id,
        ]);
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'is_active' => true,
        ]);
        EmployeeSalary::factory()->active()->create([
            'company_id' => $this->company->id,
            'employee_id' => $employee->id,
            'basic_salary' => 10000000,
        ]);

        (new ProcessPayrollJob($payroll, $this->user->id))
            ->handle(app(App\Services\PushNotificationService::class));

        $payroll->refresh();
        expect($payroll->status)->toBe('calculated');
        expect($payroll->items()->count())->toBeGreaterThan(0);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->user->id,
            'type' => 'payroll_completed',
        ]);
    });
});
