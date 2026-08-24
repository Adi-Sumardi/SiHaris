<?php

use App\Jobs\SyncAdmsEmployeesJob;
use App\Models\Company;
use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Services\AdmsApiService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

describe('SyncAdmsEmployeesJob', function () {
    beforeEach(function () {
        $this->company = Company::factory()->create();
    });

    it('maps employees from ADMS and populates employee pin', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => 'EMP20260001',
            'first_name' => 'Adi',
            'last_name' => 'Sumardi',
            'email' => 'adisumardi1996@gmail.com',
            'pin' => null,
        ]);

        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/employees' => Http::response([
                'success' => true,
                'data' => [
                    [
                        'employee_id' => 256,
                        'name' => 'Adi Sumardi',
                        'pin' => '1032',
                        'email' => 'adisumardi1996@gmail.com',
                    ],
                ],
            ], 200),
        ]);

        $admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-token');
        $job = new SyncAdmsEmployeesJob($this->company->id);
        $job->handle($admsService);

        $employee->refresh();
        expect($employee->pin)->toBe('1032');

        $device = FingerprintDevice::where('company_id', $this->company->id)->first();
        expect($device)->not->toBeNull();

        $this->assertDatabaseHas('fingerprint_user_mappings', [
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '1032',
        ]);
    });

    it('updates existing employee mapping when ADMS returns a new pin without duplicate key error', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'employee_id' => 'EMP20260277',
            'first_name' => 'Ilmi',
            'last_name' => 'Kharisah',
            'email' => 'ilmi@example.com',
            'pin' => '330002',
        ]);

        $device = FingerprintDevice::factory()->create([
            'company_id' => $this->company->id,
            'serial_number' => 'ADMS-FACE-APP',
        ]);

        \App\Models\FingerprintUserMapping::create([
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '330002',
        ]);

        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/employees' => Http::response([
                'success' => true,
                'data' => [
                    [
                        'employee_id' => 999,
                        'name' => 'Ilmi Kharisah',
                        'pin' => '330010',
                        'email' => 'ilmi@example.com',
                    ],
                ],
            ], 200),
        ]);

        $admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-token');
        $job = new SyncAdmsEmployeesJob($this->company->id);
        $job->handle($admsService);

        $this->assertDatabaseHas('fingerprint_user_mappings', [
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '330010',
        ]);

        $this->assertDatabaseMissing('fingerprint_user_mappings', [
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '330002',
        ]);
    });
});
