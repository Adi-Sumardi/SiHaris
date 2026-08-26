<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Send attendance recap (WhatsApp & Email) per company, based on each company's
// enable_attendance_recap / attendance_recap_* settings. ADMS only supplies raw
// attendance logs (see sync-adms-attendance below); GajiPro computes and sends the recap.
Schedule::command('attendance:send-recap')->hourly();

// Automatically pull attendance logs from ADMS Cloud for all active companies
Schedule::call(function () {
    \App\Models\Company::where('is_active', true)->each(function ($company) {
        \App\Jobs\SyncAdmsAttendanceJob::dispatch($company->id);
    });
})->everyFiveMinutes()->name('sync-adms-attendance')->withoutOverlapping();
