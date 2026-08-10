<?php

namespace Database\Factories;

use App\Models\Employee;
use App\Models\FingerprintDevice;
use Illuminate\Database\Eloquent\Factories\Factory;

class FingerprintUserMappingFactory extends Factory
{
    public function definition(): array
    {
        return [
            'fingerprint_device_id' => FingerprintDevice::factory(),
            'employee_id' => Employee::factory(),
            'device_user_pin' => fake()->unique()->numerify('####'),
        ];
    }
}
