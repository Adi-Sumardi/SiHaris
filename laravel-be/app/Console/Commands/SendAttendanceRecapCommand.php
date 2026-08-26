<?php

namespace App\Console\Commands;

use App\Models\AttendanceRecap;
use App\Models\Company;
use App\Models\Employee;
use App\Services\AttendanceRecapService;
use App\Services\EmailRecapNotificationService;
use App\Services\PushNotificationService;
use App\Services\WhatsAppNotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Database\UniqueConstraintViolationException;

class SendAttendanceRecapCommand extends Command
{
    protected $signature = 'attendance:send-recap';

    protected $description = 'Send each due company\'s automatic attendance recap to employees via WhatsApp and email.';

    public function __construct(
        protected AttendanceRecapService $recapService,
        protected WhatsAppNotificationService $whatsAppService,
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
                $company->now()
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
            'monthly' => $now->day === min((int) $company->attendance_recap_day_of_month, $now->daysInMonth),
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
                ...$data,
            ]);
        } catch (UniqueConstraintViolationException) {
            // Lost the race to a concurrent run for the same period.
            return;
        }

        $message = $this->buildMessage($employee, $periodStart, $periodEnd, $data);

        if ($company->attendance_recap_send_whatsapp && $employee->phone) {
            $result = $this->whatsAppService->sendMessage($employee->phone, $message);
            $recap->update([
                'whatsapp_sent_at' => now(),
                'whatsapp_status' => $result['success'] ? 'sent' : 'failed',
            ]);
        }

        if ($company->attendance_recap_send_email && $employee->email) {
            $result = $this->emailService->sendEmail($employee->email, 'Rekap Kehadiran Anda', $message);
            $recap->update([
                'email_sent_at' => now(),
                'email_status' => $result['success'] ? 'sent' : 'failed',
            ]);
        }

        if ($employee->user) {
            $this->pushService->sendToUser(
                $employee->user,
                'Rekap Kehadiran Anda',
                $message,
                'attendance_recap',
                [
                    'period_start' => $periodStart->toDateString(),
                    'period_end' => $periodEnd->toDateString(),
                    ...$data,
                ]
            );
        }
    }

    /**
     * @param  array{working_days: int, present_days: int, absent_days: int, late_days: int, leave_days: int, attendance_percentage: float}  $data
     */
    private function buildMessage(Employee $employee, Carbon $periodStart, Carbon $periodEnd, array $data): string
    {
        $period = $periodStart->translatedFormat('d M Y').' - '.$periodEnd->translatedFormat('d M Y');

        return "Halo {$employee->full_name}, berikut rekap kehadiran Anda periode {$period} (hari libur & akhir pekan tidak dihitung):\n"
            ."Hari kerja: {$data['working_days']} hari\n"
            ."Hadir: {$data['present_days']} hari\n"
            ."Terlambat: {$data['late_days']} hari\n"
            ."Tidak hadir: {$data['absent_days']} hari\n"
            ."Cuti: {$data['leave_days']} hari\n"
            ."Persentase kehadiran: {$data['attendance_percentage']}%";
    }
}
