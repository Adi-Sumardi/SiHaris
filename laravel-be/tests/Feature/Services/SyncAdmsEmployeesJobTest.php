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

    it('does not overwrite an existing mapping even when ADMS reports a different pin for that employee', function () {
        // Regression test: the ADMS employee master list can carry a stale or
        // duplicate pin for someone who already has a working mapping (e.g. an
        // old device-enrollment pin vs. a newer SiHaris-style one, or a fuzzy
        // name match landing on the wrong record). Overwriting broke real
        // attendance sync in production for several employees — this job must
        // only fill in employees who don't have a mapping yet.
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
            'device_user_pin' => '330010',
        ]);

        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/employees' => Http::response([
                'success' => true,
                'data' => [
                    [
                        'employee_id' => 999,
                        'name' => 'Ilmi Kharisah',
                        'pin' => '330002',
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

        expect(\App\Models\FingerprintUserMapping::where('fingerprint_device_id', $device->id)
            ->where('employee_id', $employee->id)
            ->count())->toBe(1);
    });

    it('creates a mapping for an employee who has none yet, using the ADMS pin', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'first_name' => 'Anisa',
            'last_name' => 'Oktavia',
            'email' => 'anisa@example.com',
            'pin' => '100013',
        ]);

        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/employees' => Http::response([
                'success' => true,
                'data' => [
                    [
                        'employee_id' => 328,
                        'name' => 'Anisa Octavia',
                        'pin' => '1066',
                        'email' => 'anisa@example.com',
                    ],
                ],
            ], 200),
        ]);

        $admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-token');
        $job = new SyncAdmsEmployeesJob($this->company->id);
        $job->handle($admsService);

        $device = FingerprintDevice::where('company_id', $this->company->id)->first();

        $this->assertDatabaseHas('fingerprint_user_mappings', [
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '1066',
        ]);
    });
});
