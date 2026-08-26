<?php

namespace App\Console\Commands;

use App\Models\AttendanceRecap;
use App\Models\Company;
use App\Models\Employee;
use App\Services\AttendanceRecapService;
use App\Services\EmailRecapNotificationService;
use App\Services\PushNotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Database\UniqueConstraintViolationException;

class SendAttendanceRecapCommand extends Command
{
    protected $signature = 'attendance:send-recap';

    protected $description = 'Send each due company\'s automatic attendance recap to employees via mobile push and email.';

    public function __construct(
        protected AttendanceRecapService $recapService,
        protected EmailRecapNotificationService $emailService,
        protected PushNotificationService $pushService,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $companies = Company::where('enable_attendance_recap', true)
            ->where('is_active', true)
            ->get();

        foreach ($companies as $company) {
            if (! $this->isDueNow($company)) {
                continue;
            }

            [$periodStart, $periodEnd] = $this->recapService->periodFor(
                $company->attendance_recap_frequency,
                $company->now(),
                $company
            );

            $employees = Employee::where('company_id', $company->id)
                ->where('is_active', true)
                ->get();

            foreach ($employees as $employee) {
                $this->sendRecapForEmployee($company, $employee, $periodStart, $periodEnd);
            }
        }

        return self::SUCCESS;
    }

    /**
     * Every company runs on its own local clock and its own configured
     * hour/day, so a company in Jakarta and one in Makassar fire at their
     * own 08:00, not a shared UTC instant.
     */
    private function isDueNow(Company $company): bool
    {
        $now = $company->now();

        if ($now->hour !== (int) $company->attendance_recap_send_hour) {
            return false;
        }

        return match ($company->attendance_recap_frequency) {
            'daily' => true,
            'weekly' => $now->isoWeekday() === (int) $company->attendance_recap_day_of_week,
            'monthly' => $now->day === min((int) ($company->attendance_recap_day_of_month ?? 1), $now->daysInMonth),
            default => false,
        };
    }

    private function sendRecapForEmployee(Company $company, Employee $employee, Carbon $periodStart, Carbon $periodEnd): void
    {
        // Idempotency: a period already recapped for this employee is never sent twice.
        $alreadySent = AttendanceRecap::where('employee_id', $employee->id)
            ->where('period_start', $periodStart->toDateString())
            ->where('period_end', $periodEnd->toDateString())
            ->exists();

        if ($alreadySent) {
            return;
        }

        $data = $this->recapService->compute($employee, $periodStart, $periodEnd);

        try {
            $recap = AttendanceRecap::create([
                'company_id' => $company->id,
                'employee_id' => $employee->id,
                'frequency' => $company->attendance_recap_frequency,
                'period_start' => $periodStart->toDateString(),
                'period_end' => $periodEnd->toDateString(),
                'working_days' => $data['working_days'],
                'present_days' => $data['present_days'],
                'absent_days' => $data['absent_days'],
                'late_days' => $data['late_days'],
                'leave_days' => $data['leave_days'],
                'attendance_percentage' => $data['attendance_percentage'],
            ]);
        } catch (UniqueConstraintViolationException) {
            // Lost the race to a concurrent run for the same period.
            return;
        }

        $title = $this->buildTitle($company);
        $message = $this->buildMessage($company, $employee, $periodStart, $periodEnd, $data);

        // Attendance recap is routed strictly to mobile application (WhatsApp is used solely for OTP)
        if ($employee->user) {
            $this->pushService->sendToUser(
                $employee->user,
                $title,
                $message,
                'attendance_recap',
                [
                    'period_start' => $periodStart->toDateString(),
                    'period_end' => $periodEnd->toDateString(),
                    ...$data,
                ]
            );
        }

        if ($company->attendance_recap_send_email && $employee->email) {
            $result = $this->emailService->sendEmail($employee->email, $title, $message);
            $recap->update([
                'email_sent_at' => now(),
                'email_status' => $result['success'] ? 'sent' : 'failed',
            ]);
        }
    }

    private function buildTitle(Company $company): string
    {
        $freqLabel = match ($company->attendance_recap_frequency) {
            'daily' => 'HARIAN',
            'weekly' => 'MINGGUAN',
            default => 'BULANAN',
        };

        return "📊 REKAP ABSEN {$freqLabel} {$company->name}";
    }

    /**
     * @param  array{
     *     working_days: int,
     *     present_days: int,
     *     weekday_present_days: int,
     *     saturday_present_days: int,
     *     total_present_days: int,
     *     absent_days: int,
     *     late_days: int,
     *     late_gt_5_days: int,
     *     leave_days: int,
     *     attendance_percentage: float
     * }  $data
     */
    private function buildMessage(Company $company, Employee $employee, Carbon $periodStart, Carbon $periodEnd, array $data): string
    {
        $period = $periodStart->format('d/m/Y').' - '.$periodEnd->format('d/m/Y');
        $title = $this->buildTitle($company);

        return "{$title}\n"
            ."Nama: {$employee->full_name}\n"
            ."Periode: {$period}\n"
            ."=============================\n"
            ."Hari Kerja (Senin-Jumat): {$data['weekday_present_days']} hari\n"
            ."Hari Sabtu: {$data['saturday_present_days']} hari\n"
            ."Total: {$data['total_present_days']} hari\n\n"
            ."⏰ Datang Terlambat:\n"
            ."• > 5 menit: {$data['late_gt_5_days']}x";
    }
}
