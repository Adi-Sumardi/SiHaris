<?php

namespace App\Http\Controllers;

use App\Models\Department;
use App\Models\Employee;
use App\Models\EmployeeDocument;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\StreamedResponse;

class DocumentController extends Controller
{
    /**
     * Display a centralized list of all employee documents across the company.
     */
    public function index(Request $request): View
    {
        $tenant = app('tenant');

        $query = EmployeeDocument::query()
            ->where('company_id', $tenant->id)
            ->with(['employee.department', 'employee.position', 'uploadedBy']);

        // Search by employee name, NIP, document name, or document number
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('document_name', 'like', "%{$search}%")
                    ->orWhere('document_number', 'like', "%{$search}%")
                    ->orWhereHas('employee', function ($eq) use ($search) {
                        $eq->where('first_name', 'like', "%{$search}%")
                            ->orWhere('last_name', 'like', "%{$search}%")
                            ->orWhere('employee_id', 'like', "%{$search}%")
                            ->orWhere('identity_number', 'like', "%{$search}%")
                            ->orWhere('nik', 'like', "%{$search}%");
                    });
            });
        }

        // Filter by document type
        if ($request->filled('document_type')) {
            $query->where('document_type', $request->input('document_type'));
        }

        // Filter by department
        if ($request->filled('department_id')) {
            $deptId = $request->input('department_id');
            $query->whereHas('employee', function ($eq) use ($deptId) {
                $eq->where('department_id', $deptId);
            });
        }

        $documents = $query->orderBy('created_at', 'desc')->paginate(15)->withQueryString();

        $departments = Department::where('company_id', $tenant->id)->orderBy('name')->get();
        $documentTypes = EmployeeDocument::DOCUMENT_TYPES;

        // Compute summary statistics
        $stats = [
            'total_documents' => EmployeeDocument::where('company_id', $tenant->id)->count(),
            'total_employees_uploaded' => EmployeeDocument::where('company_id', $tenant->id)->distinct('employee_id')->count('employee_id'),
            'total_sk' => EmployeeDocument::where('company_id', $tenant->id)->where('document_type', EmployeeDocument::TYPE_SK)->count(),
            'total_sertifikat' => EmployeeDocument::where('company_id', $tenant->id)->where('document_type', EmployeeDocument::TYPE_SERTIFIKAT)->count(),
            'total_ktp' => EmployeeDocument::where('company_id', $tenant->id)->where('document_type', EmployeeDocument::TYPE_KTP)->count(),
            'total_kk' => EmployeeDocument::where('company_id', $tenant->id)->where('document_type', EmployeeDocument::TYPE_KK)->count(),
            'total_ijazah' => EmployeeDocument::where('company_id', $tenant->id)->where('document_type', EmployeeDocument::TYPE_IJAZAH)->count(),
        ];

        $employees = Employee::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('first_name')
            ->get();

        return view('documents.index', compact('documents', 'departments', 'documentTypes', 'stats', 'employees'));
    }

    /**
     * Store a newly created employee document.
     */
    public function store(Request $request): RedirectResponse
    {
        $tenant = app('tenant');

        $validated = $request->validate([
            'employee_id' => ['required', 'exists:employees,id'],
            'document_type' => ['required', 'string', 'in:'.implode(',', array_keys(EmployeeDocument::DOCUMENT_TYPES))],
            'document_number' => ['nullable', 'string', 'max:100'],
            'document_name' => ['nullable', 'string', 'max:255'],
            'file' => ['required', 'file', 'max:10240', 'mimes:pdf,jpg,jpeg,png'],
            'issue_date' => ['nullable', 'date'],
            'expiry_date' => ['nullable', 'date', 'after_or_equal:issue_date'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $employee = Employee::where('company_id', $tenant->id)->findOrFail($validated['employee_id']);

        $file = $request->file('file');
        $path = $file->store("documents/{$tenant->id}/{$employee->id}", 'local');

        EmployeeDocument::create([
            'company_id' => $tenant->id,
            'employee_id' => $employee->id,
            'document_type' => $validated['document_type'],
            'document_number' => $validated['document_number'] ?? null,
            'document_name' => $validated['document_name'] ?? null,
            'file_path' => $path,
            'file_name' => $file->getClientOriginalName(),
            'file_size' => $file->getSize(),
            'mime_type' => $file->getMimeType(),
            'issue_date' => $validated['issue_date'] ?? null,
            'expiry_date' => $validated['expiry_date'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'uploaded_by' => $request->user()->id,
        ]);

        return redirect()
            ->route('documents.index')
            ->with('success', 'Dokumen berkas pegawai berhasil diunggah.');
    }

    /**
     * Preview the document file directly in browser.
     */
    public function preview(EmployeeDocument $document): BinaryFileResponse
    {
        $tenant = app('tenant');

        if ($document->company_id !== $tenant->id) {
            abort(404);
        }

        if (! Storage::disk('local')->exists($document->file_path)) {
            abort(404, 'File dokumen tidak ditemukan.');
        }

        $fullPath = Storage::disk('local')->path($document->file_path);

        return response()->file($fullPath, [
            'Content-Type' => $document->mime_type ?? 'application/octet-stream',
            'Content-Disposition' => 'inline; filename="'.$document->file_name.'"',
        ]);
    }

    /**
     * Download the document file.
     */
    public function download(EmployeeDocument $document): StreamedResponse
    {
        $tenant = app('tenant');

        if ($document->company_id !== $tenant->id) {
            abort(404);
        }

        if (! Storage::disk('local')->exists($document->file_path)) {
            abort(404, 'File dokumen tidak ditemukan.');
        }

        return Storage::disk('local')->download(
            $document->file_path,
            $document->file_name,
            ['Content-Type' => $document->mime_type ?? 'application/octet-stream']
        );
    }

    /**
     * Remove the specified document.
     */
    public function destroy(EmployeeDocument $document): RedirectResponse
    {
        $tenant = app('tenant');

        if ($document->company_id !== $tenant->id) {
            abort(404);
        }

        $document->delete();

        return redirect()
            ->back()
            ->with('success', 'Dokumen berhasil dihapus.');
    }
}
