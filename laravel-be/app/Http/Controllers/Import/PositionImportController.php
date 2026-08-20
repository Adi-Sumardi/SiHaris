<?php

namespace App\Http\Controllers\Import;

use App\Exports\Templates\PositionTemplateExport;
use App\Http\Controllers\Controller;
use App\Imports\PositionImport;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;
use Maatwebsite\Excel\Validators\ValidationException;

class PositionImportController extends Controller
{
    public function index(): View
    {
        return view('imports.positions.index');
    }

    public function template()
    {
        return Excel::download(new PositionTemplateExport, 'template_jabatan.xlsx');
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'mimes:xlsx,xls,csv', 'max:5120'],
        ]);

        $tenant = app('tenant');

        try {
            $import = new PositionImport($tenant->id);
            DB::transaction(function () use ($import, $request) {
                Excel::import($import, $request->file('file'));
            });

            $successCount = $import->getSuccessCount();
            $skipCount = $import->getSkipCount();
            $errors = $import->getErrors();

            $message = "Berhasil mengimpor {$successCount} jabatan.";
            if ($skipCount > 0) {
                $message .= " {$skipCount} data dilewati.";
            }

            if (count($errors) > 0) {
                return redirect()->route('imports.positions.index')
                    ->with('warning', $message)
                    ->with('import_errors', $errors);
            }

            return redirect()->route('imports.positions.index')
                ->with('success', $message);
        } catch (ValidationException $e) {
            $validationErrors = [];
            foreach ($e->failures() as $failure) {
                $row = $failure->row();
                $attribute = $failure->attribute();
                $errorsList = implode(', ', $failure->errors());
                $validationErrors[] = "Baris {$row} (Kolom {$attribute}): {$errorsList}";
            }

            return redirect()->route('imports.positions.index')
                ->with('error', 'Validasi gagal pada file yang diunggah.')
                ->with('import_errors', $validationErrors);
        } catch (\Exception $e) {
            return redirect()->route('imports.positions.index')
                ->with('error', 'Gagal mengimpor data: '.$e->getMessage());
        }
    }
}
