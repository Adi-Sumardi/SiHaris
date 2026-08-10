<?php

use App\Models\Company;
use App\Models\Employee;
use App\Services\DeviceBindingService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    $this->employee = Employee::factory()->create(['company_id' => $this->company->id]);
    $this->otherEmployee = Employee::factory()->create(['company_id' => $this->company->id]);
    $this->service = app(DeviceBindingService::class);
});

afterEach(function () {
    app('events')->forget(\Illuminate\Database\Events\QueryExecuted::class);
});

describe('DeviceBindingService', function () {
    it('binds a new device to the employee on first use', function () {
        $result = $this->service->verifyOrBind($this->employee, 'device-abc-123');

        expect($result['allowed'])->toBeTrue();
        $this->assertDatabaseHas('employee_devices', [
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'device_id' => 'device-abc-123',
        ]);
    });

    it('allows the same employee to keep using their bound device', function () {
        $this->service->verifyOrBind($this->employee, 'device-abc-123');
        $result = $this->service->verifyOrBind($this->employee, 'device-abc-123');

        expect($result['allowed'])->toBeTrue();
        $this->assertDatabaseCount('employee_devices', 1);
    });

    it('rejects a device already bound to a different employee', function () {
        $this->service->verifyOrBind($this->employee, 'device-abc-123');
        $result = $this->service->verifyOrBind($this->otherEmployee, 'device-abc-123');

        expect($result['allowed'])->toBeFalse();
        expect($result['reason'])->toBe('device_bound_to_other_employee');

        $this->assertDatabaseHas('employee_devices', [
            'device_id' => 'device-abc-123',
            'employee_id' => $this->employee->id,
        ]);
        $this->assertDatabaseMissing('employee_devices', [
            'device_id' => 'device-abc-123',
            'employee_id' => $this->otherEmployee->id,
        ]);
    });

    it('allows the same device id to be used by employees in different companies', function () {
        $otherCompany = Company::factory()->create();
        $otherCompanyEmployee = Employee::factory()->create(['company_id' => $otherCompany->id]);

        $this->service->verifyOrBind($this->employee, 'device-shared-id');
        $result = $this->service->verifyOrBind($otherCompanyEmployee, 'device-shared-id');

        expect($result['allowed'])->toBeTrue();
    });

    it('allows an employee to bind multiple different devices', function () {
        $first = $this->service->verifyOrBind($this->employee, 'device-one');
        $second = $this->service->verifyOrBind($this->employee, 'device-two');

        expect($first['allowed'])->toBeTrue();
        expect($second['allowed'])->toBeTrue();
        $this->assertDatabaseCount('employee_devices', 2);
    });

    it('rejects gracefully instead of crashing when two employees race to bind the same new device', function () {
        // Simulate the interleaving: employee A's insert commits in the window
        // between employee B's "no existing binding" read and B's own insert.
        $alreadyRaced = false;
        \Illuminate\Support\Facades\DB::listen(function ($query) use (&$alreadyRaced) {
            if (! $alreadyRaced && str_starts_with(trim($query->sql), 'select') && str_contains($query->sql, 'employee_devices')) {
                $alreadyRaced = true;
                \App\Models\EmployeeDevice::create([
                    'company_id' => $this->company->id,
                    'employee_id' => $this->employee->id,
                    'device_id' => 'device-race',
                    'first_seen_at' => now(),
                    'last_seen_at' => now(),
                    'is_active' => true,
                ]);
            }
        });

        $result = $this->service->verifyOrBind($this->otherEmployee, 'device-race');

        expect($result['allowed'])->toBeFalse();
        expect($result['reason'])->toBe('device_bound_to_other_employee');
        $this->assertDatabaseCount('employee_devices', 1);
        $this->assertDatabaseHas('employee_devices', [
            'device_id' => 'device-race',
            'employee_id' => $this->employee->id,
        ]);
    });

    it('updates last_seen_at on repeated use without creating duplicates', function () {
        $this->service->verifyOrBind($this->employee, 'device-abc-123');
        $device = \App\Models\EmployeeDevice::first();
        $device->update(['last_seen_at' => now()->subDays(3)]);

        $this->service->verifyOrBind($this->employee, 'device-abc-123');

        expect($device->fresh()->last_seen_at->diffInMinutes(now()))->toBeLessThan(1);
        $this->assertDatabaseCount('employee_devices', 1);
    });
});
