<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\EmployeeDevice;

/**
 * Binds a physical mobile device to exactly one employee per company, so a
 * single phone cannot be reused to clock in for several employees. First
 * use of a device id wins; subsequent attempts by a different employee on
 * the same device are rejected until an admin releases the binding.
 */
class DeviceBindingService
{
    /**
     * @return array{allowed: bool, reason: ?string}
     */
    public function verifyOrBind(Employee $employee, string $deviceId, ?string $deviceName = null, ?string $platform = null): array
    {
        $binding = EmployeeDevice::where('company_id', $employee->company_id)
            ->where('device_id', $deviceId)
            ->first();

        if (! $binding) {
            try {
                EmployeeDevice::create([
                    'company_id' => $employee->company_id,
                    'employee_id' => $employee->id,
                    'device_id' => $deviceId,
                    'device_name' => $deviceName,
                    'platform' => $platform,
                    'first_seen_at' => now(),
                    'last_seen_at' => now(),
                    'is_active' => true,
                ]);

                return ['allowed' => true, 'reason' => null];
            } catch (\Illuminate\Database\UniqueConstraintViolationException) {
                // Lost the race to another employee binding this device id
                // at the same instant — re-read and evaluate against the
                // binding that actually won.
                return $this->verifyOrBind($employee, $deviceId, $deviceName, $platform);
            }
        }

        if ((int) $binding->employee_id !== (int) $employee->id) {
            return ['allowed' => false, 'reason' => 'device_bound_to_other_employee'];
        }

        $binding->update(['last_seen_at' => now()]);

        return ['allowed' => true, 'reason' => null];
    }
}
