<?php

namespace Database\Factories;

use App\Models\Company;
use App\Models\Employee;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class RawAttendanceLogFactory extends Factory
{
    public function definition(): array
    {
        $eventTime = fake()->dateTimeBetween('-1 day', 'now');

        return [
            'company_id' => Company::factory(),
            'employee_id' => Employee::factory(),
            'attendance_id' => null,
            'channel' => fake()->randomElement(['app_face', 'fingerprint']),
            'fingerprint_device_id' => null,
            'device_user_pin' => null,
            'type' => fake()->randomElement(['clock_in', 'clock_out']),
            'event_time' => $eventTime,
            'received_at' => $eventTime,
            'status' => 'applied',
            'dedup_hash' => Str::random(64),
            'payload' => [],
        ];
    }

    public function duplicateIgnored(): static
    {
        return $this->state(['status' => 'duplicate_ignored']);
    }

    public function unmatched(): static
    {
        return $this->state(['employee_id' => null, 'status' => 'unmatched']);
    }
}
