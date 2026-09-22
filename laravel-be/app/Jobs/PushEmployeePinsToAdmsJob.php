<?php

namespace App\Jobs;

use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Services\AdmsApiService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Pushes PIN changes the other direction from SyncAdmsEmployeesJob: SiHaris
 * (specifically each employee's `pin` column) is the source of truth here,
 * per SDM's directive, and ADMS's own record is brought in line with it -
 * the reverse of the usual ADMS-is-authoritative sync.
 *
 * Only touches employees who already have a FingerprintUserMapping (i.e.
 * are already known to ADMS) and whose mapped pin differs from their
 * current SiHaris pin. A brand-new employee who has never been enrolled on
 * the physical device has no mapping yet and is skipped - there's no API
 * for that; the fingerprint itself still has to be enrolled on the device.
 */
class PushEmployeePinsToAdmsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public ?int $companyId = null
    ) {}

    /**
     * @return array{total: int, updated: int, failed: int, failures: array<int, string>}
     */
    public function handle(AdmsApiService $admsService): array
    {
        $companyId = $this->companyId ?? 1;

        $device = FingerprintDevice::where('company_id', $companyId)
            ->where('serial_number', 'ADMS-FACE-APP')
            ->first();

        if (! $device) {
            return ['total' => 0, 'updated' => 0, 'failed' => 0, 'failures' => []];
        }

        $mappings = FingerprintUserMapping::where('fingerprint_device_id', $device->id)
            ->with('employee')
            ->get()
            ->filter(fn (FingerprintUserMapping $mapping) => $mapping->employee
                && ! empty($mapping->employee->pin)
                && $mapping->employee->pin !== $mapping->device_user_pin
            );

        $updated = 0;
        $failed = 0;
        $failures = [];

        foreach ($mappings as $mapping) {
            $result = $admsService->updateEmployeePin($mapping->device_user_pin, $mapping->employee->pin);

            if ($result['success']) {
                $mapping->update(['device_user_pin' => $mapping->employee->pin]);
                $updated++;
            } else {
                $failed++;
                $failures[] = "{$mapping->employee->full_name} (pin {$mapping->device_user_pin} -> {$mapping->employee->pin}): {$result['message']}";
                Log::warning('[PushEmployeePinsToAdmsJob] Failed to push PIN', [
                    'employee_id' => $mapping->employee_id,
                    'from_pin' => $mapping->device_user_pin,
                    'to_pin' => $mapping->employee->pin,
                    'error' => $result['message'],
                ]);
            }
        }

        return [
            'total' => $mappings->count(),
            'updated' => $updated,
            'failed' => $failed,
            'failures' => $failures,
        ];
    }
}
