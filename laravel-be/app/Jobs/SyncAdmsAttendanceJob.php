<?php

namespace App\Jobs;

use App\Models\Company;
use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Services\AdmsApiService;
use App\Services\AttendanceReconciliationService;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SyncAdmsAttendanceJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public ?int $companyId = null,
        public ?string $date = null
    ) {}

    public function handle(
        AdmsApiService $admsService,
        AttendanceReconciliationService $reconciliationService
    ): array {
        $targetDate = $this->date ?? date('Y-m-d');
        Log::info("SyncAdmsAttendanceJob started for date: {$targetDate}");

        $logs = $admsService->getAttendanceLogs($targetDate);
        if (empty($logs)) {
            Log::info("SyncAdmsAttendanceJob: No logs returned from ADMS API for date {$targetDate}.");

            return [
                'success' => true,
                'total' => 0,
                'applied' => 0,
                'skipped' => 0,
            ];
        }

        $companyId = $this->companyId ?? 1;
        $company = Company::find($companyId);
        $timezone = $company->timezone ?? 'Asia/Jakarta';

        // Ensure default ADMS FingerprintDevice exists
        $device = FingerprintDevice::firstOrCreate(
            [
                'company_id' => $companyId,
                'serial_number' => 'ADMS-FACE-APP',
            ],
            [
                'name' => 'ADMS Face Recognition Cloud Server',
                'brand' => 'solution',
                'is_active' => true,
                'ip_address' => 'adms.alazhar-rm.com',
                'port' => 80,
            ]
        );

        $applied = 0;
        $skipped = 0;

        foreach ($logs as $log) {
            $pin = (string) ($log['pin'] ?? '');

            // Ignore empty or zero PIN (e.g. dummy/unassigned records)
            if (empty($pin) || $pin === '0') {
                $skipped++;

                continue;
            }

            // Find matching employee in SiHaris by mapping or pin
            $mapping = FingerprintUserMapping::where('fingerprint_device_id', $device->id)
                ->where('device_user_pin', $pin)
                ->first();

            $employee = $mapping?->employee;

            if (! $employee) {
                $employee = Employee::where('company_id', $companyId)
                    ->where(function ($q) use ($pin) {
                        $q->where('pin', $pin)
                            ->orWhere('employee_id', $pin);
                    })
                    ->first();

                // If found, ensure mapping exists for future lookups
                if ($employee) {
                    FingerprintUserMapping::firstOrCreate([
                        'fingerprint_device_id' => $device->id,
                        'device_user_pin' => $pin,
                    ], [
                        'employee_id' => $employee->id,
                    ]);
                }
            }

            // ONLY process logs for mapped employees in SiHaris
            if (! $employee) {
                $skipped++;

                continue;
            }

            $type = strtolower($log['type'] ?? '') === 'out' ? 'clock_out' : 'clock_in';
            $timestamp = Carbon::parse($log['timestamp'], $timezone);

            $meta = [
                'company_id' => $companyId,
                'fingerprint_device_id' => $device->id,
                'device_user_pin' => $pin,
                'adms_log_id' => $log['id'] ?? null,
                'source' => $log['source'] ?? 'adms_cloud',
            ];

            $result = $reconciliationService->record(
                $employee,
                $type,
                $timestamp,
                'fingerprint',
                $meta
            );

            if (in_array($result['status'], ['applied', 'superseded'])) {
                $applied++;
            } else {
                $skipped++;
            }
        }

        $device->update(['last_sync_at' => now()]);

        Log::info("SyncAdmsAttendanceJob finished: {$applied} applied, {$skipped} skipped out of ".count($logs).' logs.');

        return [
            'success' => true,
            'total' => count($logs),
            'applied' => $applied,
            'skipped' => $skipped,
        ];
    }
}
