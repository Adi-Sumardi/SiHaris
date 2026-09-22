<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AdmsApiService
{
    protected string $baseUrl;

    protected string $apiKey;

    public function __construct(?string $baseUrl = null, ?string $apiKey = null)
    {
        $this->baseUrl = rtrim($baseUrl ?? config('services.adms.base_url', 'http://adms.alazhar-rm.com/api/v1/face'), '/');
        $this->apiKey = $apiKey ?? config('services.adms.api_key', '');
    }

    /**
     * Check connection health of ADMS API.
     */
    public function checkHealth(): bool
    {
        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'Accept' => 'application/json',
            ])->timeout(5)->get("{$this->baseUrl}/health");

            return $response->successful() && ($response->json('success') === true);
        } catch (\Throwable $e) {
            Log::error("ADMS API Health Check failed: {$e->getMessage()}");

            return false;
        }
    }

    /**
     * Get ADMS Face Recognition configuration.
     */
    public function getConfig(): ?array
    {
        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'Accept' => 'application/json',
            ])->timeout(10)->get("{$this->baseUrl}/config");

            if ($response->successful() && $response->json('success') === true) {
                return $response->json('data');
            }
        } catch (\Throwable $e) {
            Log::error("ADMS API getConfig failed: {$e->getMessage()}");
        }

        return null;
    }

    /**
     * Fetch master employees from ADMS API.
     *
     * @return array<int, array{employee_id: int, pin: string, name: string, email: ?string, no_hp: ?string}>
     */
    public function getEmployees(): array
    {
        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'Accept' => 'application/json',
            ])->timeout(15)->get("{$this->baseUrl}/employees");

            if ($response->successful() && $response->json('success') === true) {
                return $response->json('data') ?? [];
            }
        } catch (\Throwable $e) {
            Log::error("ADMS API getEmployees failed: {$e->getMessage()}");
        }

        return [];
    }

    /**
     * Fetch detail of a single employee from ADMS API by employeeId.
     */
    public function getEmployeeDetail(string|int $employeeId): ?array
    {
        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'Accept' => 'application/json',
            ])->timeout(10)->get("{$this->baseUrl}/employees/{$employeeId}");

            if ($response->successful() && $response->json('success') === true) {
                return $response->json('data');
            }
        } catch (\Throwable $e) {
            Log::error("ADMS API getEmployeeDetail failed for {$employeeId}: {$e->getMessage()}");
        }

        return null;
    }

    /**
     * Update an employee's PIN in ADMS (PUT {base_url}/employees/{pin_lama},
     * per docs/API_Face_Employees_ADMS.pdf §3). The path parameter is keyed
     * on the employee's CURRENT pin, not their employee_id - inconsistent
     * with GET /employees/{employeeId}, which is keyed on employee_id.
     *
     * Per that doc's developer notes: ADMS's own database is updated
     * immediately, but the physical FACE machine may cache its own local
     * PIN list and need a separate re-sync on ADMS's side if so - outside
     * what this API call alone guarantees.
     *
     * @return array{success: bool, message: string, data: ?array}
     */
    public function updateEmployeePin(string $currentPin, string $newPin): array
    {
        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'Content-Type' => 'application/json',
                'Accept' => 'application/json',
            ])->timeout(10)->put("{$this->baseUrl}/employees/{$currentPin}", [
                'pin' => $newPin,
            ]);

            if ($response->successful() && $response->json('success') === true) {
                return [
                    'success' => true,
                    'message' => $response->json('message') ?? 'PIN updated in ADMS',
                    'data' => $response->json('data'),
                ];
            }

            Log::warning("ADMS API updateEmployeePin failed for pin {$currentPin}: ".($response->json('message') ?? $response->body()));

            return [
                'success' => false,
                'message' => $response->json('message') ?? 'Failed to update PIN in ADMS',
                'data' => null,
            ];
        } catch (\Throwable $e) {
            Log::error("ADMS API updateEmployeePin exception for pin {$currentPin}: {$e->getMessage()}");

            return [
                'success' => false,
                'message' => $e->getMessage(),
                'data' => null,
            ];
        }
    }

    /**
     * Push face recognition attendance transaction log to ADMS API.
     *
     * @return array{success: bool, message: string, data: ?array}
     */
    public function pushAttendance(
        string $pin,
        Carbon|string $timestamp,
        string $type,
        ?string $deviceId = null,
        ?string $eventId = null
    ): array {
        $formattedTimestamp = $timestamp instanceof Carbon
            ? $timestamp->format('Y-m-d H:i:s')
            : $timestamp;

        $payload = array_filter([
            'pin' => $pin,
            'timestamp' => $formattedTimestamp,
            'type' => strtolower($type) === 'clock_out' || strtolower($type) === 'out' ? 'out' : 'in',
            'device_id' => $deviceId ?? 'FACE-APP-SIHARIS',
            'event_id' => $eventId ?? ('SIHARIS-'.$pin.'-'.date('YmdHis', strtotime($formattedTimestamp))),
        ], fn ($val) => $val !== null);

        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'Content-Type' => 'application/json',
                'Accept' => 'application/json',
            ])->timeout(10)->post("{$this->baseUrl}/attendance", $payload);

            if ($response->successful() && $response->json('success') === true) {
                return [
                    'success' => true,
                    'message' => $response->json('message') ?? 'Attendance recorded in ADMS',
                    'data' => $response->json('data'),
                ];
            }

            Log::warning('ADMS API pushAttendance failed: '.($response->json('message') ?? $response->body()));

            return [
                'success' => false,
                'message' => $response->json('message') ?? 'Failed to record attendance in ADMS',
                'data' => null,
            ];
        } catch (\Throwable $e) {
            Log::error("ADMS API pushAttendance exception: {$e->getMessage()}");

            return [
                'success' => false,
                'message' => $e->getMessage(),
                'data' => null,
            ];
        }
    }

    /**
     * Fetch attendance transaction logs from ADMS API for a given date.
     *
     * @return array<int, array{id: int, pin: int|string, employee_id: ?int, timestamp: string, type: string, source: ?string}>
     */
    public function getAttendanceLogs(?string $date = null): array
    {
        $targetDate = $date ?? date('Y-m-d');

        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'Accept' => 'application/json',
            ])->timeout(15)->get("{$this->baseUrl}/attendance-logs", [
                'date' => $targetDate,
            ]);

            if ($response->successful() && $response->json('success') === true) {
                return $response->json('data') ?? [];
            }

            Log::warning("ADMS API getAttendanceLogs failed for date {$targetDate}: ".($response->json('message') ?? $response->body()));
        } catch (\Throwable $e) {
            Log::error("ADMS API getAttendanceLogs exception for date {$targetDate}: {$e->getMessage()}");
        }

        return [];
    }
}
