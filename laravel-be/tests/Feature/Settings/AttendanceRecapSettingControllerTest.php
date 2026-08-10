<?php

use App\Models\Company;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create([
        'enable_attendance_recap' => false,
        'attendance_recap_frequency' => 'weekly',
        'attendance_recap_send_hour' => 8,
        'attendance_recap_day_of_week' => 1,
        'attendance_recap_day_of_month' => 1,
    ]);
    createStandardRoles($this->company->id);

    $this->admin = User::factory()->create(['company_id' => $this->company->id]);
    $this->admin->assignRole('admin');
});

describe('Update Attendance Recap Settings', function () {
    it('can enable the recap and set a weekly schedule', function () {
        $this->actingAs($this->admin);

        $response = $this->put('/settings/attendance/recap', [
            'enable_attendance_recap' => '1',
            'attendance_recap_frequency' => 'weekly',
            'attendance_recap_send_hour' => 9,
            'attendance_recap_day_of_week' => 5,
            'attendance_recap_day_of_month' => 1,
            'attendance_recap_send_whatsapp' => '1',
            'attendance_recap_send_email' => '1',
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->company->refresh();
        expect($this->company->enable_attendance_recap)->toBeTrue();
        expect($this->company->attendance_recap_frequency)->toBe('weekly');
        expect($this->company->attendance_recap_send_hour)->toBe(9);
        expect($this->company->attendance_recap_day_of_week)->toBe(5);
        expect($this->company->attendance_recap_send_whatsapp)->toBeTrue();
        expect($this->company->attendance_recap_send_email)->toBeTrue();
    });

    it('turns off whatsapp/email channels when their checkboxes are unchecked', function () {
        $this->company->update([
            'enable_attendance_recap' => true,
            'attendance_recap_send_whatsapp' => true,
            'attendance_recap_send_email' => true,
        ]);
        $this->actingAs($this->admin);

        $response = $this->put('/settings/attendance/recap', [
            'enable_attendance_recap' => '1',
            'attendance_recap_frequency' => 'weekly',
            'attendance_recap_send_hour' => 8,
            'attendance_recap_day_of_week' => 1,
            'attendance_recap_day_of_month' => 1,
            // whatsapp/email checkboxes intentionally omitted (unchecked)
        ]);

        $response->assertRedirect();

        $this->company->refresh();
        expect($this->company->attendance_recap_send_whatsapp)->toBeFalse();
        expect($this->company->attendance_recap_send_email)->toBeFalse();
    });

    it('validates frequency is one of the supported values', function () {
        $this->actingAs($this->admin);

        $response = $this->put('/settings/attendance/recap', [
            'enable_attendance_recap' => '1',
            'attendance_recap_frequency' => 'yearly',
            'attendance_recap_send_hour' => 8,
            'attendance_recap_day_of_week' => 1,
            'attendance_recap_day_of_month' => 1,
        ]);

        $response->assertSessionHasErrors(['attendance_recap_frequency']);
    });

    it('validates send hour range', function () {
        $this->actingAs($this->admin);

        $response = $this->put('/settings/attendance/recap', [
            'enable_attendance_recap' => '1',
            'attendance_recap_frequency' => 'weekly',
            'attendance_recap_send_hour' => 25,
            'attendance_recap_day_of_week' => 1,
            'attendance_recap_day_of_month' => 1,
        ]);

        $response->assertSessionHasErrors(['attendance_recap_send_hour']);
    });

    it('denies access to employee role', function () {
        $employee = User::factory()->create(['company_id' => $this->company->id]);
        $employee->assignRole('employee');
        $this->actingAs($employee);

        $response = $this->put('/settings/attendance/recap', [
            'enable_attendance_recap' => '1',
            'attendance_recap_frequency' => 'weekly',
            'attendance_recap_send_hour' => 8,
            'attendance_recap_day_of_week' => 1,
            'attendance_recap_day_of_month' => 1,
        ]);

        $response->assertRedirect('/portal');

        $this->company->refresh();
        expect($this->company->enable_attendance_recap)->toBeFalse();
    });
});
