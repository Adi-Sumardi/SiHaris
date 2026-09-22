<?php

use App\Jobs\PushEmployeePinsToAdmsJob;
use App\Models\Company;
use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Services\AdmsApiService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

describe('PushEmployeePinsToAdmsJob', function () {
    beforeEach(function () {
        $this->company = Company::factory()->create();
        $this->device = FingerprintDevice::factory()->create([
            'company_id' => $this->company->id,
            'serial_number' => 'ADMS-FACE-APP',
        ]);
    });

    it('pushes the new pin to ADMS when an employee mapping pin differs from SiHaris', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'pin' => '100013',
        ]);

        FingerprintUserMapping::create([
            'fingerprint_device_id' => $this->device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '1066',
        ]);

        Http::fake([
            '*/employees/1066' => Http::response([
                'success' => true,
                'message' => 'Pegawai berhasil diperbarui',
                'data' => ['employee_id' => 328, 'pin' => '100013'],
            ], 200),
        ]);

        $admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-token');
        $job = new PushEmployeePinsToAdmsJob($this->company->id);
        $result = $job->handle($admsService);

        expect($result)->toBe(['total' => 1, 'updated' => 1, 'failed' => 0, 'failures' => []]);

        Http::assertSent(fn ($request) => $request->url() === 'http://adms.alazhar-rm.com/api/v1/face/employees/1066'
            && $request->method() === 'PUT'
            && $request['pin'] === '100013'
        );

        expect(FingerprintUserMapping::where('employee_id', $employee->id)->value('device_user_pin'))->toBe('100013');
    });

    it('skips employees whose mapping pin already matches their SiHaris pin', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'pin' => '1066',
        ]);

        FingerprintUserMapping::create([
            'fingerprint_device_id' => $this->device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '1066',
        ]);

        Http::fake();

        $admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-token');
        $job = new PushEmployeePinsToAdmsJob($this->company->id);
        $result = $job->handle($admsService);

        expect($result)->toBe(['total' => 0, 'updated' => 0, 'failed' => 0, 'failures' => []]);
        Http::assertNothingSent();
    });

    it('records a failure and leaves the mapping unchanged when ADMS rejects the update', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'first_name' => 'Anisa',
            'last_name' => 'Oktavia',
            'pin' => '100013',
        ]);

        FingerprintUserMapping::create([
            'fingerprint_device_id' => $this->device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '1066',
        ]);

        Http::fake([
            '*/employees/1066' => Http::response([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => ['pin' => ['The pin has already been taken.']],
            ], 422),
        ]);

        $admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-token');
        $job = new PushEmployeePinsToAdmsJob($this->company->id);
        $result = $job->handle($admsService);

        expect($result['total'])->toBe(1);
        expect($result['updated'])->toBe(0);
        expect($result['failed'])->toBe(1);
        expect($result['failures'][0])->toContain('Anisa Oktavia');

        expect(FingerprintUserMapping::where('employee_id', $employee->id)->value('device_user_pin'))->toBe('1066');
    });

    it('skips employees with no fingerprint mapping at all (never enrolled on the physical device)', function () {
        Employee::factory()->create([
            'company_id' => $this->company->id,
            'pin' => '100099',
        ]);

        Http::fake();

        $admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-token');
        $job = new PushEmployeePinsToAdmsJob($this->company->id);
        $result = $job->handle($admsService);

        expect($result)->toBe(['total' => 0, 'updated' => 0, 'failed' => 0, 'failures' => []]);
        Http::assertNothingSent();
    });
});
