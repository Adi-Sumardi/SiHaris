<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Runs every hour; each company only actually sends when its own configured
// local hour/day is reached (see SendAttendanceRecapCommand::isDueNow()).
Schedule::command('attendance:send-recap')->hourly();
