<?php

namespace App\Jobs;

use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Services\AdmsApiService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SyncAdmsEmployeesJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public ?int $companyId = null
    ) {}

    public function handle(AdmsApiService $admsService): void
    {
        Log::info('SyncAdmsEmployeesJob started.');

        $admsEmployees = $admsService->getEmployees();
        if (empty($admsEmployees)) {
            Log::warning('SyncAdmsEmployeesJob: No employees returned from ADMS API.');

            return;
        }

        $syncedCount = 0;
        $mappedCount = 0;

        $companyId = $this->companyId ?? 1;

        // Ensure default ADMS FingerprintDevice exists for mapping within this company
        $device = FingerprintDevice::firstOrCreate(
            [
                'company_id' => $companyId,
                'serial_number' => 'ADMS-FACE-APP',
            ],
            [
                'name' => 'ADMS Face Recognition Cloud Server',
                'brand' => 'solution',
                'is_active' => true,
            ]
        );

        foreach ($admsEmployees as $admsEmp) {
            $pin = (string) ($admsEmp['pin'] ?? '');
            $name = $admsEmp['name'] ?? '';
            $email = $admsEmp['email'] ?? null;
            $phone = $admsEmp['no_hp'] ?? null;

            if (empty($pin)) {
                continue;
            }

            // Find matching employee in SiHaris by pin, employee_id, email, or name
            $query = Employee::query();
            if ($this->companyId) {
                $query->where('company_id', $this->companyId);
            }

            $employee = (clone $query)->where('pin', $pin)->first();

            if (! $employee) {
                $employee = (clone $query)->where('employee_id', $pin)->first();
            }

            if (! $employee && $email) {
                $employee = (clone $query)->where('email', $email)->first();
            }

            if (! $employee && $name) {
                $employee = (clone $query)->where(function ($q) use ($name) {
                    $q->where('first_name', 'like', "%{$name}%")
                        ->orWhere('last_name', 'like', "%{$name}%");
                })->first();
            }

            if ($employee) {
                // If employee doesn't have pin filled, update it
                if (empty($employee->pin)) {
                    $employee->update(['pin' => $pin]);
                }

                // Remove conflicting mapping if another employee held this pin on this device
                FingerprintUserMapping::where('fingerprint_device_id', $device->id)
                    ->where('device_user_pin', $pin)
                    ->where('employee_id', '!=', $employee->id)
                    ->delete();

                // Update or create mapping for this employee on this device
                FingerprintUserMapping::updateOrCreate(
                    [
                        'fingerprint_device_id' => $device->id,
                        'employee_id' => $employee->id,
                    ],
                    [
                        'device_user_pin' => $pin,
                    ]
                );

                $mappedCount++;
            }
        }

        $device->update(['last_sync_at' => now()]);

        Log::info("SyncAdmsEmployeesJob completed: Mapped {$mappedCount} employees.");
    }
}
