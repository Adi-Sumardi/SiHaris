<?php

use App\Services\AdmsApiService;
use Illuminate\Support\Facades\Http;

describe('AdmsApiService', function () {
    beforeEach(function () {
        $this->admsService = new AdmsApiService('http://adms.alazhar-rm.com/api/v1/face', 'test-api-key');
    });

    it('returns true on successful health check', function () {
        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/health' => Http::response([
                'success' => true,
                'message' => 'ADMS Face API is healthy',
            ], 200),
        ]);

        expect($this->admsService->checkHealth())->toBeTrue();
    });

    it('returns false on failed health check', function () {
        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/health' => Http::response([
                'success' => false,
                'message' => 'Unauthorized',
            ], 401),
        ]);

        expect($this->admsService->checkHealth())->toBeFalse();
    });

    it('fetches employees list successfully', function () {
        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/employees' => Http::response([
                'success' => true,
                'data' => [
                    ['pin' => '12345', 'name' => 'Budi Santoso'],
                    ['pin' => '12346', 'name' => 'Siti Aminah'],
                ],
            ], 200),
        ]);

        $employees = $this->admsService->getEmployees();

        expect($employees)->toHaveCount(2);
        expect($employees[0]['name'])->toBe('Budi Santoso');
    });

    it('pushes attendance transaction successfully', function () {
        Http::fake([
            'http://adms.alazhar-rm.com/api/v1/face/attendance' => Http::response([
                'success' => true,
                'message' => 'Attendance recorded',
                'data' => [
                    'attendance_id' => 987654,
                    'pin' => '12345',
                    'timestamp' => '2026-08-14 09:30:00',
                    'type' => 'in',
                ],
            ], 200),
        ]);

        $result = $this->admsService->pushAttendance(
            pin: '12345',
            timestamp: '2026-08-14 09:30:00',
            type: 'in',
            deviceId: 'FACE-001'
        );

        expect($result['success'])->toBeTrue();
        expect($result['message'])->toBe('Attendance recorded');
    });

    it('fetches attendance logs successfully', function () {
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
                ],
            ], 200),
        ]);

        $logs = $this->admsService->getAttendanceLogs('2026-08-21');

        expect($logs)->toHaveCount(1);
        expect($logs[0]['pin'])->toBe(1032);
        expect($logs[0]['type'])->toBe('in');
    });
});
