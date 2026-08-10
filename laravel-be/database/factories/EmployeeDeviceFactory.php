<?php

namespace Database\Factories;

use App\Models\Company;
use App\Models\Employee;
use Illuminate\Database\Eloquent\Factories\Factory;

class EmployeeDeviceFactory extends Factory
{
    public function definition(): array
    {
        $now = now();

        return [
            'company_id' => Company::factory(),
            'employee_id' => Employee::factory(),
            'device_id' => fake()->unique()->uuid(),
            'device_name' => fake()->randomElement(['Samsung Galaxy A54', 'iPhone 13', 'Xiaomi Redmi Note 12']),
            'platform' => fake()->randomElement(['android', 'ios']),
            'first_seen_at' => $now,
            'last_seen_at' => $now,
            'is_active' => true,
        ];
    }
}
