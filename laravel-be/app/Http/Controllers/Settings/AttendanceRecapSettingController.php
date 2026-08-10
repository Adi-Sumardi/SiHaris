<?php

namespace App\Http\Controllers\Settings;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class AttendanceRecapSettingController extends Controller
{
    public function update(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'enable_attendance_recap' => ['nullable', 'boolean'],
            'attendance_recap_frequency' => ['required', 'in:daily,weekly,monthly'],
            'attendance_recap_send_hour' => ['required', 'integer', 'min:0', 'max:23'],
            'attendance_recap_day_of_week' => ['required', 'integer', 'min:1', 'max:7'],
            'attendance_recap_day_of_month' => ['required', 'integer', 'min:1', 'max:28'],
            'attendance_recap_send_whatsapp' => ['nullable', 'boolean'],
            'attendance_recap_send_email' => ['nullable', 'boolean'],
        ]);

        $company = auth()->user()->company;
        $company->update([
            'enable_attendance_recap' => $request->boolean('enable_attendance_recap'),
            'attendance_recap_frequency' => $validated['attendance_recap_frequency'],
            'attendance_recap_send_hour' => $validated['attendance_recap_send_hour'],
            'attendance_recap_day_of_week' => $validated['attendance_recap_day_of_week'],
            'attendance_recap_day_of_month' => $validated['attendance_recap_day_of_month'],
            'attendance_recap_send_whatsapp' => $request->boolean('attendance_recap_send_whatsapp'),
            'attendance_recap_send_email' => $request->boolean('attendance_recap_send_email'),
        ]);

        return redirect()->route('settings.attendance.index')
            ->with('success', 'Pengaturan rekap kehadiran berhasil diperbarui.');
    }
}
