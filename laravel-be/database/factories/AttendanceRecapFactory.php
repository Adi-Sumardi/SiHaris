<?php

namespace Database\Factories;

use App\Models\Company;
use App\Models\Employee;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\AttendanceRecap>
 */
class AttendanceRecapFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $periodStart = $this->faker->dateTimeBetween('-2 months', '-1 month');
        $periodEnd = (clone $periodStart)->modify('+6 days');

        return [
            'company_id' => Company::factory(),
            'employee_id' => Employee::factory(),
            'frequency' => 'weekly',
            'period_start' => $periodStart,
            'period_end' => $periodEnd,
            'working_days' => 5,
            'present_days' => 5,
            'absent_days' => 0,
            'late_days' => 0,
            'leave_days' => 0,
            'attendance_percentage' => 100,
        ];
    }
}
