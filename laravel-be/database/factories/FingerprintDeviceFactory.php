<?php

namespace Database\Factories;

use App\Models\Company;
use Illuminate\Database\Eloquent\Factories\Factory;

class FingerprintDeviceFactory extends Factory
{
    public function definition(): array
    {
        return [
            'company_id' => Company::factory(),
            'office_location_id' => null,
            'name' => 'Mesin '.fake()->word(),
            'brand' => fake()->randomElement(['zkteco', 'fingerspot', 'solution', 'other']),
            'serial_number' => fake()->unique()->bothify('SN########'),
            'ip_address' => fake()->localIpv4(),
            'port' => 4370,
            'webhook_secret' => fake()->uuid(),
            'last_sync_at' => null,
            'is_active' => true,
        ];
    }

    public function inactive(): static
    {
        return $this->state(['is_active' => false]);
    }
}
