<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Models\WorkSchedule;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create(['timezone' => 'Asia/Jakarta']);
    $this->workSchedule = WorkSchedule::factory()->create([
        'company_id' => $this->company->id,
        'start_time' => '08:00:00',
        'end_time' => '17:00:00',
    ]);
    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'work_schedule_id' => $this->workSchedule->id,
    ]);
    $this->device = FingerprintDevice::factory()->create([
        'company_id' => $this->company->id,
        'serial_number' => 'X100C-0001',
        'webhook_secret' => 'super-secret-key',
    ]);
    FingerprintUserMapping::factory()->create([
        'fingerprint_device_id' => $this->device->id,
        'employee_id' => $this->employee->id,
        'device_user_pin' => '1001',
    ]);
});

function fingerprintSignature(array $payload, string $secret): string
{
    return hash_hmac('sha256', json_encode($payload), $secret);
}

describe('Fingerprint webhook', function () {
    it('rejects requests with an invalid signature', function () {
        $payload = [
            'device_serial' => 'X100C-0001',
            'logs' => [
                ['pin' => '1001', 'type' => 'clock_in', 'timestamp' => now()->toIso8601String()],
            ],
        ];

        $response = $this->postJson('/api/v1/webhooks/fingerprint', $payload, [
            'X-Device-Signature' => 'wrong-signature',
        ]);

        $response->assertStatus(401);
        $this->assertDatabaseMissing('attendances', ['employee_id' => $this->employee->id]);
    });

    it('rejects requests for an unknown device serial', function () {
        $payload = [
            'device_serial' => 'UNKNOWN-SERIAL',
            'logs' => [
                ['pin' => '1001', 'type' => 'clock_in', 'timestamp' => now()->toIso8601String()],
            ],
        ];

        $response = $this->postJson('/api/v1/webhooks/fingerprint', $payload, [
            'X-Device-Signature' => hash_hmac('sha256', json_encode($payload), 'irrelevant'),
        ]);

        $response->assertStatus(404);
    });

    it('records a clock-in for a mapped employee', function () {
        $eventTime = \Carbon\Carbon::parse($this->company->today()->format('Y-m-d').' 08:01:00', $this->company->timezone);
        $payload = [
            'device_serial' => 'X100C-0001',
            'logs' => [
                ['pin' => '1001', 'type' => 'clock_in', 'timestamp' => $eventTime->toIso8601String()],
            ],
        ];

        $response = $this->postJson('/api/v1/webhooks/fingerprint', $payload, [
            'X-Device-Signature' => fingerprintSignature($payload, 'super-secret-key'),
        ]);

        $response->assertOk()
            ->assertJsonPath('summary.applied', 1);

        $this->assertDatabaseHas('attendances', [
            'employee_id' => $this->employee->id,
            'clock_in_source' => 'fingerprint',
            'clock_in_device_id' => $this->device->id,
        ]);
        $this->device->refresh();
        expect($this->device->last_sync_at)->not->toBeNull();
    });

    it('processes multiple logs in one payload and is idempotent on retry', function () {
        $today = $this->company->today()->format('Y-m-d');
        $payload = [
            'device_serial' => 'X100C-0001',
            'logs' => [
                ['pin' => '1001', 'type' => 'clock_in', 'timestamp' => "{$today}T08:01:00+07:00"],
                ['pin' => '1001', 'type' => 'clock_out', 'timestamp' => "{$today}T17:02:00+07:00"],
            ],
        ];
        $headers = ['X-Device-Signature' => fingerprintSignature($payload, 'super-secret-key')];

        $this->postJson('/api/v1/webhooks/fingerprint', $payload, $headers)->assertOk();

        // Device retries the same batch (common with polling agents) — must not duplicate.
        $response = $this->postJson('/api/v1/webhooks/fingerprint', $payload, $headers);

        $response->assertOk()
            ->assertJsonPath('summary.duplicate', 2);

        $this->assertDatabaseCount('attendances', 1);
    });

    it('interprets a naive timestamp without a UTC offset as company-local time, not UTC', function () {
        // Real X100C pull agents typically log wall-clock time with no
        // timezone suffix (e.g. "2026-08-10 08:01:00"), not ISO8601 with an
        // explicit offset. That naive string must be read as company-local
        // time (Asia/Jakarta), not silently misinterpreted as UTC.
        $today = $this->company->today()->format('Y-m-d');
        $payload = [
            'device_serial' => 'X100C-0001',
            'logs' => [
                ['pin' => '1001', 'type' => 'clock_in', 'timestamp' => "{$today} 08:01:00"],
            ],
        ];

        $response = $this->postJson('/api/v1/webhooks/fingerprint', $payload, [
            'X-Device-Signature' => fingerprintSignature($payload, 'super-secret-key'),
        ]);

        $response->assertOk()->assertJsonPath('summary.applied', 1);

        $attendance = \App\Models\Attendance::where('employee_id', $this->employee->id)->first();
        expect($attendance->clock_in->copy()->setTimezone('Asia/Jakarta')->format('Y-m-d H:i'))
            ->toBe("{$today} 08:01");
    });

    it('marks logs for an unmapped PIN as unmatched for HR review', function () {
        $payload = [
            'device_serial' => 'X100C-0001',
            'logs' => [
                ['pin' => '9999', 'type' => 'clock_in', 'timestamp' => now()->toIso8601String()],
            ],
        ];

        $response = $this->postJson('/api/v1/webhooks/fingerprint', $payload, [
            'X-Device-Signature' => fingerprintSignature($payload, 'super-secret-key'),
        ]);

        $response->assertOk()
            ->assertJsonPath('summary.unmatched', 1);

        $this->assertDatabaseHas('raw_attendance_logs', [
            'device_user_pin' => '9999',
            'status' => 'unmatched',
        ]);
    });

    it('does not create a double clock-in when the app already recorded one', function () {
        $appTime = \Carbon\Carbon::parse($this->company->today()->format('Y-m-d').' 08:00:00', $this->company->timezone);
        app(App\Services\AttendanceReconciliationService::class)->record($this->employee, 'clock_in', $appTime, 'app_face');

        $fingerprintTime = $appTime->copy()->addMinutes(3);
        $payload = [
            'device_serial' => 'X100C-0001',
            'logs' => [
                ['pin' => '1001', 'type' => 'clock_in', 'timestamp' => $fingerprintTime->toIso8601String()],
            ],
        ];

        $response = $this->postJson('/api/v1/webhooks/fingerprint', $payload, [
            'X-Device-Signature' => fingerprintSignature($payload, 'super-secret-key'),
        ]);

        $response->assertOk()->assertJsonPath('summary.duplicate', 1);

        $this->assertDatabaseCount('attendances', 1);
        $this->assertDatabaseHas('attendances', [
            'employee_id' => $this->employee->id,
            'clock_in_source' => 'app_face',
        ]);
    });
});
