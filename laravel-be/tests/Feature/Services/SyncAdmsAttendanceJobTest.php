<?php

use App\Jobs\SyncAdmsAttendanceJob;
use App\Models\Attendance;
use App\Models\Company;
use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Services\AdmsApiService;
use App\Services\AttendanceReconciliationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

describe('SyncAdmsAttendanceJob', function () {
    beforeEach(function () {
        $this->company = Company::factory()->create(['timezone' => 'Asia/Jakarta']);
    });

    it('pulls attendance logs and creates attendance records for mapped employees', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'pin' => '1032',
            'first_name' => 'Adi',
            'last_name' => 'Sumardi',
        ]);

        $device = FingerprintDevice::factory()->create([
            'company_id' => $this->company->id,
            'serial_number' => 'ADMS-FACE-APP',
        ]);

        FingerprintUserMapping::create([
            'fingerprint_device_id' => $device->id,
            'employee_id' => $employee->id,
            'device_user_pin' => '1032',
        ]);

        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/attendance-logs*' => Http::response([
                'success' => true,
                'data' => [
                    [
                        'id' => 522650,
                        'pin' => 1032,
                        'employee_id' => 256,
                        'timestamp' => '2026-08-21 07:30:17',
                        'type' => 'in',
                        'source' => 'face-recognition',
                    ],
                    [
                        'id' => 522651,
                        'pin' => 0, // Unassigned dummy pin, should be ignored
                        'employee_id' => null,
                        'timestamp' => '2026-08-21 07:50:28',
                        'type' => 'in',
                        'source' => 'face-recognition',
                    ],
                    [
                        'id' => 522652,
                        'pin' => 9999, // Unmapped pin in SiHaris, should be ignored
                        'employee_id' => 999,
                        'timestamp' => '2026-08-21 08:00:00',
                        'type' => 'in',
                        'source' => 'face-recognition',
                    ],
                ],
            ], 200),
        ]);

        $admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-token');
        $reconciliationService = app(AttendanceReconciliationService::class);

        $job = new SyncAdmsAttendanceJob($this->company->id, '2026-08-21');
        $result = $job->handle($admsService, $reconciliationService);

        expect($result['applied'])->toBe(1);
        expect($result['skipped'])->toBe(2);

        $attendance = Attendance::where('employee_id', $employee->id)
            ->whereDate('date', '2026-08-21')
            ->first();

        expect($attendance)->not->toBeNull();
        expect($attendance->clock_in_source)->toBe('fingerprint');
    });
});
