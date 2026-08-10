<?php

use App\Models\AttendanceRecap;
use App\Models\Company;
use App\Models\Employee;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('attendance:send-recap', function () {
    it('does nothing for companies with the recap feature disabled', function () {
        $company = Company::factory()->create([
            'timezone' => 'Asia/Jakarta',
            'enable_attendance_recap' => false,
        ]);
        Employee::factory()->create(['company_id' => $company->id]);

        $this->travelTo(Carbon::create(2026, 2, 9, 8, 0, 0, 'Asia/Jakarta')); // Monday 08:00

        $this->artisan('attendance:send-recap')->assertExitCode(0);

        $this->assertDatabaseCount('attendance_recaps', 0);
    });

    it('sends the weekly recap to active employees exactly when the configured day/hour is reached', function () {
        $company = Company::factory()->create([
            'timezone' => 'Asia/Jakarta',
            'enable_attendance_recap' => true,
            'attendance_recap_frequency' => 'weekly',
            'attendance_recap_day_of_week' => 1, // Monday
            'attendance_recap_send_hour' => 8,
        ]);
        $employee = Employee::factory()->create([
            'company_id' => $company->id,
            'is_active' => true,
            'phone' => '081234567890',
            'email' => 'employee@example.com',
        ]);
        $inactiveEmployee = Employee::factory()->create([
            'company_id' => $company->id,
            'is_active' => false,
        ]);

        // Not due yet: Monday but wrong hour.
        $this->travelTo(Carbon::create(2026, 2, 9, 7, 0, 0, 'Asia/Jakarta'));
        $this->artisan('attendance:send-recap');
        $this->assertDatabaseCount('attendance_recaps', 0);

        // Due: Monday 08:00.
        $this->travelTo(Carbon::create(2026, 2, 9, 8, 0, 0, 'Asia/Jakarta'));
        $this->artisan('attendance:send-recap')->assertExitCode(0);

        $this->assertDatabaseCount('attendance_recaps', 1);

        $recap = AttendanceRecap::first();
        expect($recap->employee_id)->toBe($employee->id);
        expect($recap->period_start->toDateString())->toBe('2026-02-02');
        expect($recap->period_end->toDateString())->toBe('2026-02-08');
        expect($recap->whatsapp_status)->toBe('sent');
        expect($recap->email_status)->toBe('sent');

        // The inactive employee never gets a recap row.
        $this->assertDatabaseMissing('attendance_recaps', ['employee_id' => $inactiveEmployee->id]);
    });

    it('never sends the same period twice even if the command runs again in the same due window', function () {
        $company = Company::factory()->create([
            'timezone' => 'Asia/Jakarta',
            'enable_attendance_recap' => true,
            'attendance_recap_frequency' => 'weekly',
            'attendance_recap_day_of_week' => 1,
            'attendance_recap_send_hour' => 8,
        ]);
        Employee::factory()->create(['company_id' => $company->id, 'is_active' => true]);

        $this->travelTo(Carbon::create(2026, 2, 9, 8, 0, 0, 'Asia/Jakarta'));

        $this->artisan('attendance:send-recap');
        $this->artisan('attendance:send-recap');

        $this->assertDatabaseCount('attendance_recaps', 1);
    });

    it('skips WhatsApp when the employee has no phone number but still sends email', function () {
        $company = Company::factory()->create([
            'timezone' => 'Asia/Jakarta',
            'enable_attendance_recap' => true,
            'attendance_recap_frequency' => 'weekly',
            'attendance_recap_day_of_week' => 1,
            'attendance_recap_send_hour' => 8,
        ]);
        Employee::factory()->create([
            'company_id' => $company->id,
            'is_active' => true,
            'phone' => null,
            'email' => 'noWaPhone@example.com',
        ]);

        $this->travelTo(Carbon::create(2026, 2, 9, 8, 0, 0, 'Asia/Jakarta'));

        $this->artisan('attendance:send-recap')->assertExitCode(0);

        $recap = AttendanceRecap::first();
        expect($recap->whatsapp_sent_at)->toBeNull();
        expect($recap->email_status)->toBe('sent');
    });
});
