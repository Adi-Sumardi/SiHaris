<?php

namespace App\Http\Controllers\Import;

use App\Exports\Templates\LeaveTypeTemplateExport;
use App\Http\Controllers\Controller;
use App\Imports\LeaveTypeImport;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Maatwebsite\Excel\Validators\ValidationException;

class LeaveTypeImportController extends Controller
{
    public function index(): View
    {
        return view('imports.leave-types.index');
    }

    public function template()
    {
        return Excel::download(new LeaveTypeTemplateExport, 'template_jenis_cuti.xlsx');
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:xlsx,xls,csv', 'max:5120'],
        ]);

        $tenant = app('tenant');

        try {
            $import = new LeaveTypeImport($tenant->id);
            DB::transaction(function () use ($import, $request) {
                Excel::import($import, $request->file('file'));
            });

            $successCount = $import->getSuccessCount();
            $skipCount = $import->getSkipCount();
            $errors = $import->getErrors();

            $message = "Berhasil mengimpor {$successCount} jenis cuti.";
            if ($skipCount > 0) {
                $message .= " {$skipCount} data dilewati.";
            }

            if (count($errors) > 0) {
                return redirect()->route('imports.leave-types.index')
                    ->with('warning', $message)
                    ->with('import_errors', $errors);
            }

            return redirect()->route('imports.leave-types.index')
                ->with('success', $message);
        } catch (ValidationException $e) {
            $validationErrors = [];
            foreach ($e->failures() as $failure) {
                $row = $failure->row();
                $attribute = $failure->attribute();
                $errorsList = implode(', ', $failure->errors());
                $validationErrors[] = "Baris {$row} (Kolom {$attribute}): {$errorsList}";
            }

            return redirect()->route('imports.leave-types.index')
                ->with('error', 'Validasi gagal pada file yang diunggah.')
                ->with('import_errors', $validationErrors);
        } catch (\Exception $e) {
            return redirect()->route('imports.leave-types.index')
                ->with('error', 'Gagal mengimpor data: '.$e->getMessage());
        }
    }
}
