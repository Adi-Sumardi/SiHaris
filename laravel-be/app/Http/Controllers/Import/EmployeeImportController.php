<?php

namespace App\Http\Controllers\Import;

use App\Exports\Templates\EmployeeTemplateExport;
use App\Http\Controllers\Controller;
use App\Imports\EmployeeImport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Maatwebsite\Excel\Validators\ValidationException;

class EmployeeImportController extends Controller
{
    public function index(): View
    {
        return view('imports.employees.index');
    }

    public function template()
    {
        return Excel::download(new EmployeeTemplateExport, 'template_karyawan.xlsx');
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:xlsx,xls,csv', 'max:20480'],
        ]);

        $tenant = app('tenant');

        $importId = uniqid('emp_import_');
        $import = new EmployeeImport($tenant->id, $importId);
        $import->initializeImport();

        try {
            DB::transaction(function () use ($import, $request) {
                Excel::import($import, $request->file('file'));
            });

            $import->attachPendingOfficeLocations();
            $import->markAsCompleted();

            $successCount = $import->getSuccessCount();
            $skipCount = $import->getSkipCount();
            $errors = $import->getErrors();

            $message = "Berhasil mengimpor {$successCount} karyawan.";
            if ($skipCount > 0) {
                $message .= " {$skipCount} data dilewati.";
            }

            return redirect()->route('imports.employees.index')
                ->with('import_id', $importId)
                ->with(count($errors) > 0 ? 'warning' : 'success', $message)
                ->with('import_errors', $errors);
        } catch (ValidationException $e) {
            $validationErrors = [];
            foreach ($e->failures() as $failure) {
                $row = $failure->row();
                $attribute = $failure->attribute();
                $errorsList = implode(', ', $failure->errors());
                $validationErrors[] = "Baris {$row} (Kolom {$attribute}): {$errorsList}";
            }

            $import->markAsFailed('Validasi gagal pada file yang diunggah.');

            return redirect()->route('imports.employees.index')
                ->with('import_id', $importId)
                ->with('error', 'Validasi gagal pada file yang diunggah.')
                ->with('import_errors', $validationErrors);
        } catch (\Exception $e) {
            $import->markAsFailed($e->getMessage());

            return redirect()->route('imports.employees.index')
                ->with('import_id', $importId)
                ->with('error', 'Gagal mengimpor data: '.$e->getMessage());
        }
    }

    public function status(string $importId): JsonResponse
    {
        $status = EmployeeImport::getImportStatus($importId);

        if (! $status) {
            return response()->json([
                'status' => 'not_found',
                'message' => 'Import tidak ditemukan.',
            ], 404);
        }

        return response()->json($status);
    }
}

