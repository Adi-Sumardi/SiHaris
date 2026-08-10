<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\OfficeLocation;
use App\Models\User;
use App\Models\WorkSchedule;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create(['enable_gps_validation' => true]);
    createStandardRoles($this->company->id);

    $this->workSchedule = WorkSchedule::factory()->create([
        'company_id' => $this->company->id,
        'start_time' => '08:00',
        'end_time' => '17:00',
    ]);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
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

    $this->actingAs($this->user);
});

describe('Web admin self clock-in GPS enforcement', function () {
    it('rejects clock in without coordinates when GPS validation is required', function () {
        $response = $this->post(route('attendances.clock-in'));

        $response->assertSessionHasErrors(['latitude', 'longitude']);
        $this->assertDatabaseMissing('attendances', ['employee_id' => $this->employee->id]);
    });

    it('rejects clock in outside the assigned office radius', function () {
        $response = $this->post(route('attendances.clock-in'), [
            'latitude' => -7.5000,
            'longitude' => 110.0000,
        ]);

        $response->assertSessionHas('error', 'Lokasi Anda terlalu jauh dari kantor.');
        $this->assertDatabaseMissing('attendances', ['employee_id' => $this->employee->id]);
    });

    it('allows clock in inside the assigned office radius', function () {
        $response = $this->post(route('attendances.clock-in'), [
            'latitude' => -6.200000,
            'longitude' => 106.816666,
        ]);

        $response->assertSessionHas('success');
        $this->assertDatabaseHas('attendances', [
            'employee_id' => $this->employee->id,
            'office_location_id' => $this->office->id,
        ]);
    });
});
