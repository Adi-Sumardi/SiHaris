<?php

namespace App\Jobs;

use App\Http\Controllers\PayrollController;
use App\Models\Payroll;
use App\Models\User;
use App\Services\PushNotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Throwable;

class ProcessPayrollJob implements ShouldQueue
{
    use Queueable;

    /**
     * Number of times the job may be attempted.
     */
    public int $tries = 1;

    /**
     * Maximum seconds the job may run before timing out.
     */
    public int $timeout = 1800;

    public function __construct(
        public Payroll $payroll,
        public ?int $triggeredByUserId = null,
    ) {}

    /**
     * Run the (potentially long) payroll calculation for all employees.
     */
    public function handle(PushNotificationService $notifications): void
    {
        app(PayrollController::class)->calculatePayroll($this->payroll);

        $this->notifyTrigger(
            $notifications,
            'Payroll selesai diproses',
            "Payroll {$this->payroll->payroll_number} telah selesai dikalkulasi dan siap direview.",
            'payroll_completed',
        );
    }

    /**
     * Called when the job ultimately fails — kembalikan status agar dapat diproses ulang.
     */
    public function failed(Throwable $exception): void
    {
        $this->payroll->forceFill(['status' => 'draft'])->save();

        $this->notifyTrigger(
            app(PushNotificationService::class),
            'Payroll gagal diproses',
            "Terjadi kesalahan saat memproses payroll {$this->payroll->payroll_number}. Silakan coba lagi.",
            'payroll_failed',
        );
    }

    private function notifyTrigger(
        PushNotificationService $notifications,
        string $title,
        string $message,
        string $type,
    ): void {
        if ($this->triggeredByUserId === null) {
            return;
        }

        $user = User::find($this->triggeredByUserId);
        if ($user === null) {
            return;
        }

        try {
            $notifications->sendToUser(
                $user,
                $title,
                $message,
                $type,
                ['payroll_id' => $this->payroll->id],
                route('payrolls.show', $this->payroll),
            );
        } catch (Throwable) {
            // Notifikasi bersifat best-effort; kegagalannya tidak boleh menggagalkan job.
        }
    }
}
