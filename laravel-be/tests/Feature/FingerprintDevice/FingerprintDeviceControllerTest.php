<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Models\OfficeLocation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    setPermissionsTeamId($this->company->id);
    Role::findOrCreate('admin', 'web');

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);

    $this->office = OfficeLocation::factory()->create(['company_id' => $this->company->id]);
});

describe('FingerprintDeviceController', function () {
    it('lists devices for the current company only', function () {
        FingerprintDevice::factory()->create(['company_id' => $this->company->id, 'name' => 'Mesin Sendiri']);
        $otherCompany = Company::factory()->create();
        FingerprintDevice::factory()->create(['company_id' => $otherCompany->id, 'name' => 'Mesin Lain']);

        $response = $this->get(route('fingerprint-devices.index'));

        $response->assertOk();
        $response->assertSee('Mesin Sendiri');
        $response->assertDontSee('Mesin Lain');
    });

    it('creates a device with an auto-generated webhook secret', function () {
        $response = $this->post(route('fingerprint-devices.store'), [
            'name' => 'Mesin Lobby',
            'brand' => 'solution',
            'serial_number' => 'X100C-9999',
            'office_location_id' => $this->office->id,
            'port' => 4370,
            'is_active' => true,
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $device = FingerprintDevice::where('serial_number', 'X100C-9999')->first();
        expect($device)->not->toBeNull();
        expect($device->company_id)->toBe($this->company->id);
        expect($device->webhook_secret)->not->toBeEmpty();
    });

    it('rejects duplicate serial numbers within the same company', function () {
        FingerprintDevice::factory()->create([
            'company_id' => $this->company->id,
            'serial_number' => 'DUP-001',
        ]);

        $response = $this->post(route('fingerprint-devices.store'), [
            'name' => 'Mesin Baru',
            'brand' => 'zkteco',
            'serial_number' => 'DUP-001',
        ]);

        $response->assertSessionHasErrors('serial_number');
    });

    it('renders the show page with mappings and unmatched logs', function () {
        $device = FingerprintDevice::factory()->create(['company_id' => $this->company->id]);
        $employee = Employee::factory()->create(['company_id' => $this->company->id]);
        FingerprintUserMapping::factory()->create([
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '4321',
        ]);
        \App\Models\RawAttendanceLog::factory()->unmatched()->create([
            'company_id' => $this->company->id,
            'fingerprint_device_id' => $device->id,
            'device_user_pin' => '9999',
        ]);

        $response = $this->get(route('fingerprint-devices.show', $device));

        $response->assertOk();
        $response->assertSee('4321');
        $response->assertSee('9999');
    });

    it('renders the create and edit pages', function () {
        $this->get(route('fingerprint-devices.create'))->assertOk();

        $device = FingerprintDevice::factory()->create(['company_id' => $this->company->id]);
        $this->get(route('fingerprint-devices.edit', $device))->assertOk();
    });

    it('prevents access to another company device', function () {
        $otherCompany = Company::factory()->create();
        $device = FingerprintDevice::factory()->create(['company_id' => $otherCompany->id]);

        $this->get(route('fingerprint-devices.show', $device))->assertNotFound();
        $this->get(route('fingerprint-devices.edit', $device))->assertNotFound();
    });

    it('regenerates the webhook secret', function () {
        $device = FingerprintDevice::factory()->create([
            'company_id' => $this->company->id,
            'webhook_secret' => 'old-secret',
        ]);

        $response = $this->post(route('fingerprint-devices.regenerate-secret', $device));

        $response->assertRedirect();
        expect($device->fresh()->webhook_secret)->not->toBe('old-secret');
    });

    it('maps an employee PIN to a device', function () {
        $device = FingerprintDevice::factory()->create(['company_id' => $this->company->id]);
        $employee = Employee::factory()->create(['company_id' => $this->company->id]);

        $response = $this->post(route('fingerprint-devices.mappings.store', $device), [
            'employee_id' => $employee->id,
            'device_user_pin' => '1234',
        ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('fingerprint_user_mappings', [
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '1234',
        ]);
    });

    it('rejects mapping a PIN that is already used on the same device', function () {
        $device = FingerprintDevice::factory()->create(['company_id' => $this->company->id]);
        $employeeA = Employee::factory()->create(['company_id' => $this->company->id]);
        $employeeB = Employee::factory()->create(['company_id' => $this->company->id]);

        FingerprintUserMapping::factory()->create([
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employeeA->id,
            'device_user_pin' => '1234',
        ]);

        $response = $this->post(route('fingerprint-devices.mappings.store', $device), [
            'employee_id' => $employeeB->id,
            'device_user_pin' => '1234',
        ]);

        $response->assertSessionHasErrors('device_user_pin');
    });

    it('removes a mapping', function () {
        $device = FingerprintDevice::factory()->create(['company_id' => $this->company->id]);
        $mapping = FingerprintUserMapping::factory()->create(['fingerprint_device_id' => $device->id]);

        $response = $this->delete(route('fingerprint-devices.mappings.destroy', [$device, $mapping]));

        $response->assertRedirect();
        $this->assertDatabaseMissing('fingerprint_user_mappings', ['id' => $mapping->id]);
    });

    it('deletes a device', function () {
        $device = FingerprintDevice::factory()->create(['company_id' => $this->company->id]);

        $response = $this->delete(route('fingerprint-devices.destroy', $device));

        $response->assertRedirect();
        $this->assertSoftDeleted('fingerprint_devices', ['id' => $device->id]);
    });
});
