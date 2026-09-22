<?php

namespace App\Http\Controllers\Import;

use App\Exports\Templates\PinImportTemplateExport;
use App\Http\Controllers\Controller;
use App\Imports\PinImport;
use App\Jobs\PushEmployeePinsToAdmsJob;
use App\Services\AdmsApiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Maatwebsite\Excel\Validators\ValidationException;

class PinImportController extends Controller
{
    public function index(): View
    {
        return view('imports.pins.index');
    }

    public function template()
    {
        return Excel::download(new PinImportTemplateExport, 'template_pin.xlsx');
    }

    /**
     * Bulk-updates Employee::pin from the uploaded file, then pushes every
     * resulting difference to ADMS via PushEmployeePinsToAdmsJob - reusing
     * the same job the single "Push PIN ke ADMS" button uses, so there's
     * one place that actually talks to ADMS for pin changes.
     */
    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:xlsx,xls,csv', 'max:20480'],
        ]);

        $tenant = app('tenant');

        $importId = uniqid('pin_import_');
        $import = new PinImport($tenant->id, $importId);
        $import->initializeImport();

        try {
            DB::transaction(function () use ($import, $request) {
                Excel::import($import, $request->file('file'));
            });

            $skipCount = $import->getSkipCount();
            $parseErrors = $import->getErrors();

            $pushResult = (new PushEmployeePinsToAdmsJob($tenant->id))->handle(app(AdmsApiService::class));

            Cache::put("pin_import_{$importId}", [
                'status' => 'completed',
                'success_count' => $pushResult['updated'],
                'failed_count' => $pushResult['failed'],
                'skip_count' => $skipCount,
                'errors' => array_merge($parseErrors, $pushResult['failures']),
                'completed_at' => now()->toDateTimeString(),
            ], now()->addHours(24));

            $message = "{$pushResult['updated']} PIN berhasil dipush ke ADMS.";
            if ($pushResult['failed'] > 0) {
                $message .= " {$pushResult['failed']} gagal.";
            }
            if ($skipCount > 0) {
                $message .= " {$skipCount} baris dilewati.";
            }

            return redirect()->route('imports.pins.index')
                ->with('import_id', $importId)
                ->with($pushResult['failed'] > 0 || $skipCount > 0 ? 'warning' : 'success', $message);
        } catch (ValidationException $e) {
            $validationErrors = [];
            foreach ($e->failures() as $failure) {
                $validationErrors[] = "Baris {$failure->row()} (Kolom {$failure->attribute()}): ".implode(', ', $failure->errors());
            }

            $import->markAsFailed('Validasi gagal pada file yang diunggah.');

            return redirect()->route('imports.pins.index')
                ->with('import_id', $importId)
                ->with('error', 'Validasi gagal pada file yang diunggah.')
                ->with('import_errors', $validationErrors);
        } catch (\Throwable $e) {
            $import->markAsFailed($e->getMessage());

            return redirect()->route('imports.pins.index')
                ->with('import_id', $importId)
                ->with('error', 'Gagal mengimpor data PIN: '.$e->getMessage());
        }
    }

    public function status(string $importId): JsonResponse
    {
        $status = PinImport::getImportStatus($importId);

        if (! $status) {
            return response()->json([
                'status' => 'not_found',
                'message' => 'Import tidak ditemukan.',
            ], 404);
        }

        return response()->json($status);
    }
}
