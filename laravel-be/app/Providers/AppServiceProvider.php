<?php

namespace App\Providers;

use App\Events\AttendanceClockIn;
use App\Events\AttendanceClockOut;
use App\Events\LeaveRequestApproved;
use App\Events\LeaveRequestRejected;
use App\Listeners\LogEmailActivity;
use App\Listeners\SendAttendanceClockInNotification;
use App\Listeners\SendAttendanceClockOutNotification;
use App\Listeners\SendLeaveApprovalNotification;
use Illuminate\Mail\Events\MessageSending;
use Illuminate\Mail\Events\MessageSent;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if ($this->app->environment('production') || str_starts_with((string) config('app.url'), 'https')) {
            URL::forceScheme('https');
        }
        // Register event listeners for push notifications
        Event::listen(AttendanceClockIn::class, SendAttendanceClockInNotification::class);
        Event::listen(AttendanceClockOut::class, SendAttendanceClockOutNotification::class);
        Event::listen(LeaveRequestApproved::class, SendLeaveApprovalNotification::class);
        Event::listen(LeaveRequestRejected::class, SendLeaveApprovalNotification::class);

        // Register email logging listeners
        Event::listen(MessageSending::class, [LogEmailActivity::class, 'handleSending']);
        Event::listen(MessageSent::class, [LogEmailActivity::class, 'handleSent']);

        // Register custom SendagoMail Transport
        \Illuminate\Support\Facades\Mail::extend('sendagomail', function (array $config = []) {
            return new \App\Mail\SendagoMailTransport(
                config('services.sendagomail.base_url', 'https://sendagomail.adilabs.id'),
                config('services.sendagomail.member_id'),
                config('services.sendagomail.secret')
            );
        });
    }
}
