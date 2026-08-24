<?php

namespace App\Http\Controllers\Import;

use App\Exports\Templates\EmployeeSalaryTemplateExport;
use App\Http\Controllers\Controller;
use App\Imports\EmployeeSalaryImport;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Maatwebsite\Excel\Validators\ValidationException;

class EmployeeSalaryImportController extends Controller
{
    public function index(): View
    {
        return view('imports.employee-salaries.index');
    }

    public function template()
    {
        return Excel::download(new EmployeeSalaryTemplateExport, 'template_gaji_karyawan.xlsx');
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:xlsx,xls,csv', 'max:5120'],
        ], [
            'file.required' => 'File Excel wajib diunggah.',
            'file.file' => 'File tidak valid.',
            'file.mimes' => 'Format file harus berupa .xlsx, .xls, atau .csv.',
            'file.max' => 'Ukuran file maksimal 5MB.',
        ]);

        $tenant = app('tenant');

        try {
            $import = new EmployeeSalaryImport($tenant->id);
            DB::transaction(function () use ($import, $request) {
                Excel::import($import, $request->file('file'));
            });

            $successCount = $import->getSuccessCount();
            $skipCount = $import->getSkipCount();
            $errors = $import->getErrors();

            $message = "Berhasil mengimpor {$successCount} data gaji karyawan.";
            if ($skipCount > 0) {
                $message .= " {$skipCount} data dilewati.";
            }

            if (count($errors) > 0) {
                return redirect()->route('imports.employee-salaries.index')
                    ->with('warning', $message)
                    ->with('import_errors', $errors);
            }

            return redirect()->route('imports.employee-salaries.index')
                ->with('success', $message);
        } catch (ValidationException $e) {
            $validationErrors = [];
            foreach ($e->failures() as $failure) {
                $row = $failure->row();
                $attribute = $failure->attribute();
                $errorsList = implode(', ', $failure->errors());
                $validationErrors[] = "Baris {$row} (Kolom {$attribute}): {$errorsList}";
            }

            return redirect()->route('imports.employee-salaries.index')
                ->with('error', 'Validasi gagal pada file yang diunggah.')
                ->with('import_errors', $validationErrors);
        } catch (\Exception $e) {
            return redirect()->route('imports.employee-salaries.index')
                ->with('error', 'Gagal mengimpor data: '.$e->getMessage());
        }
    }
}
