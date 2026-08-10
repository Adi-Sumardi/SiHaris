<?php

namespace App\Jobs;

use App\Exports\PayrollBankExport;
use App\Exports\Spt1721Export;
use App\Models\GeneratedExport;
use App\Models\TaxForm1721A1;
use App\Services\PushNotificationService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Storage;
use InvalidArgumentException;
use Maatwebsite\Excel\Facades\Excel;
use Throwable;

class GenerateExportJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 1;

    public int $timeout = 1800;

    public function __construct(
        public GeneratedExport $export,
    ) {}

    public function handle(PushNotificationService $notifications): void
    {
        $this->export->markProcessing();

        $path = "exports/{$this->export->company_id}/{$this->export->id}_{$this->export->filename}";

        match ($this->export->type) {
            'payroll_bank' => $this->generateExcel(new PayrollBankExport($this->export->source), $path),
            'spt_1721' => $this->generateExcel(
                new Spt1721Export($this->export->source, $this->export->meta['spt_type'] ?? null),
                $path,
            ),
            'tax_1721a1_bulk' => $this->generateBulk1721A1Pdf($path),
            default => throw new InvalidArgumentException("Unknown export type: {$this->export->type}"),
        };

        $this->export->markReady($path);

        $this->notify(
            $notifications,
            'Export siap diunduh',
            "{$this->export->title} telah selesai dibuat dan siap diunduh.",
            'export_ready',
        );
    }

    public function failed(Throwable $exception): void
    {
        $this->export->markFailed($exception->getMessage());

        $this->notify(
            app(PushNotificationService::class),
            'Export gagal dibuat',
            "Terjadi kesalahan saat membuat {$this->export->title}. Silakan coba lagi.",
            'export_failed',
        );
    }

    private function generateExcel(object $excelExport, string $path): void
    {
        Excel::store($excelExport, $path, $this->export->disk);
    }

    private function generateBulk1721A1Pdf(string $path): void
    {
        $year = $this->export->meta['year'] ?? now()->year;

        $taxForms = TaxForm1721A1::with(['employee', 'company'])
            ->where('company_id', $this->export->company_id)
            ->where('tax_year', $year)
            ->orderBy('employee_name')
            ->get();

        $pdf = Pdf::loadView('tax-forms.1721a1.pdf-bulk', [
            'taxForms' => $taxForms,
            'year' => $year,
        ]);

        Storage::disk($this->export->disk)->put($path, $pdf->output());
    }

    private function notify(
        PushNotificationService $notifications,
        string $title,
        string $message,
        string $type,
    ): void {
        $user = $this->export->user;
        if ($user === null) {
            return;
        }

        try {
            $notifications->sendToUser(
                $user,
                $title,
                $message,
                $type,
                ['export_id' => $this->export->id],
                route('exports.download', $this->export),
            );
        } catch (Throwable) {
            // Notifikasi best-effort; tidak boleh menggagalkan job.
        }
    }
}
