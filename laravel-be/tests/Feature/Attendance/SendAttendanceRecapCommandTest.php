<?php

use App\Models\AttendanceRecap;
use App\Models\Company;
use App\Models\Employee;
use App\Models\Notification;
use App\Models\User;
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

    it('sends mobile notification and email formatted with standard recap template', function () {
        $company = Company::factory()->create([
            'name' => 'YAPI',
            'timezone' => 'Asia/Jakarta',
            'enable_attendance_recap' => true,
            'attendance_recap_frequency' => 'monthly',
            'attendance_recap_day_of_month' => 21,
            'attendance_recap_send_hour' => 8,
            'attendance_recap_send_email' => true,
        ]);
        $user = User::factory()->create(['company_id' => $company->id]);
        $employee = Employee::factory()->create([
            'company_id' => $company->id,
            'user_id' => $user->id,
            'first_name' => 'Adi',
            'last_name' => 'Sumardi',
            'email' => 'adi@example.com',
            'is_active' => true,
        ]);

        $this->travelTo(Carbon::create(2026, 8, 21, 8, 0, 0, 'Asia/Jakarta'));

        $this->artisan('attendance:send-recap')->assertExitCode(0);

        $recap = AttendanceRecap::first();
        expect($recap->period_start->toDateString())->toBe('2026-07-21');
        expect($recap->period_end->toDateString())->toBe('2026-08-20');
        expect($recap->email_status)->toBe('sent');

        $notification = Notification::where('user_id', $user->id)->first();
        expect($notification)->not->toBeNull();
        expect($notification->title)->toBe('📊 REKAP ABSEN BULANAN YAPI');
        expect($notification->message)->toContain('Periode: 21/07/2026 - 20/08/2026');
        expect($notification->message)->toContain('Hari Kerja (Senin-Jumat):');
        expect($notification->message)->toContain('Hari Sabtu:');
        expect($notification->message)->toContain('⏰ Datang Terlambat:');
        expect($notification->message)->toContain('• > 5 menit:');
    });
});
