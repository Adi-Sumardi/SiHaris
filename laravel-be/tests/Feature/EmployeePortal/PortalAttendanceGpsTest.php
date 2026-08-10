<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\OfficeLocation;
use App\Models\User;
use App\Models\WorkSchedule;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create(['enable_gps_validation' => true]);
    setPermissionsTeamId($this->company->id);
    Role::findOrCreate('employee', 'web');

    $this->workSchedule = WorkSchedule::factory()->create(['company_id' => $this->company->id]);
    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('employee');
    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'user_id' => $this->user->id,
        'work_schedule_id' => $this->workSchedule->id,
    ]);

    $this->office = OfficeLocation::factory()->create([
        'company_id' => $this->company->id,
        'latitude' => -6.200000,
        'longitude' => 106.816666,
        'radius' => 100,
        'is_active' => true,
    ]);
    $this->employee->officeLocations()->attach($this->office->id, ['is_primary' => true]);
});

describe('Portal attendance GPS enforcement', function () {
    it('rejects clock in without GPS coordinates when required', function () {
        $this->actingAs($this->user);

        $response = $this->post('/portal/attendance/clock-in');

        $response->assertSessionHasErrors(['latitude', 'longitude']);
        $this->assertDatabaseMissing('attendances', ['employee_id' => $this->employee->id]);
    });

    it('rejects clock in when outside the assigned office radius', function () {
        $this->actingAs($this->user);

        $response = $this->post('/portal/attendance/clock-in', [
            'latitude' => -7.5000,
            'longitude' => 110.0000,
        ]);

        $response->assertSessionHas('error', 'Lokasi Anda terlalu jauh dari kantor. Absensi harus dilakukan di area kantor.');
        $this->assertDatabaseMissing('attendances', ['employee_id' => $this->employee->id]);
    });

    it('allows clock in when inside the assigned office radius', function () {
        $this->actingAs($this->user);

        $response = $this->post('/portal/attendance/clock-in', [
            'latitude' => -6.200000,
            'longitude' => 106.816666,
        ]);

        $response->assertSessionHas('success');
        $this->assertDatabaseHas('attendances', [
            'employee_id' => $this->employee->id,
            'office_location_id' => $this->office->id,
        ]);
    });

    it('does not require coordinates when the company disables GPS validation', function () {
        $this->company->update(['enable_gps_validation' => false]);
        $this->actingAs($this->user);

        $response = $this->post('/portal/attendance/clock-in');

        $response->assertSessionHas('success');
        $this->assertDatabaseHas('attendances', ['employee_id' => $this->employee->id]);
    });
});
