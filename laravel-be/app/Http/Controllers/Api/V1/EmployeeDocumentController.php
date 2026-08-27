<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\EmployeeDocument;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use OpenApi\Attributes as OA;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\HttpFoundation\StreamedResponse;

class EmployeeDocumentController extends Controller
{
    #[OA\Get(
        path: '/documents',
        summary: 'Daftar Dokumen/Berkas Pegawai',
        description: 'Menampilkan seluruh berkas/dokumen yang diunggah oleh karyawan yang sedang login.',
        tags: ['Employee Documents'],
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'type',
                in: 'query',
                description: 'Filter berdasarkan jenis berkas (sk, sertifikat, ktp, kk, ijazah, npwp, bpjs_kesehatan, bpjs_ketenagakerjaan, kontrak_kerja, other)',
                required: false,
                schema: new OA\Schema(type: 'string')
            ),
            new OA\Parameter(
                name: 'search',
                in: 'query',
                description: 'Cari berdasarkan judul atau nomor dokumen',
                required: false,
                schema: new OA\Schema(type: 'string')
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Berhasil mendapatkan daftar berkas pegawai',
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: 'success', type: 'boolean', example: true),
                        new OA\Property(
                            property: 'data',
                            type: 'array',
                            items: new OA\Items(
                                properties: [
                                    new OA\Property(property: 'id', type: 'integer', example: 1),
                                    new OA\Property(property: 'document_type', type: 'string', example: 'sk'),
                                    new OA\Property(property: 'document_type_label', type: 'string', example: 'SK / Surat Keputusan'),
                                    new OA\Property(property: 'document_name', type: 'string', example: 'SK Guru Tetap Yayasan 2026'),
                                    new OA\Property(property: 'document_number', type: 'string', example: '800/123/YAPI/2026'),
                                    new OA\Property(property: 'file_name', type: 'string', example: 'SK_Hesti_2026.pdf'),
                                    new OA\Property(property: 'file_size', type: 'integer', example: 245760),
                                    new OA\Property(property: 'human_file_size', type: 'string', example: '240 KB'),
                                    new OA\Property(property: 'mime_type', type: 'string', example: 'application/pdf'),
                                    new OA\Property(property: 'is_image', type: 'boolean', example: false),
                                    new OA\Property(property: 'is_pdf', type: 'boolean', example: true),
                                    new OA\Property(property: 'preview_url', type: 'string', example: 'https://siharis.yapinet.id/api/v1/documents/1/preview'),
                                    new OA\Property(property: 'download_url', type: 'string', example: 'https://siharis.yapinet.id/api/v1/documents/1/download'),
                                    new OA\Property(property: 'issue_date', type: 'string', format: 'date', example: '2026-01-10'),
                                    new OA\Property(property: 'expiry_date', type: 'string', format: 'date', example: '2027-01-10'),
                                    new OA\Property(property: 'notes', type: 'string', example: 'SK mengajar semester genap'),
                                    new OA\Property(property: 'created_at', type: 'string', format: 'datetime', example: '2026-08-27T08:00:00Z'),
                                ]
                            )
                        ),
                    ]
                )
            ),
            new OA\Response(response: 401, description: 'Unauthenticated'),
        ]
    )]
    public function index(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json([
                'success' => false,
                'message' => 'Data karyawan tidak ditemukan.',
            ], 404);
        }

        $query = EmployeeDocument::where('employee_id', $employee->id)
            ->where('company_id', $employee->company_id);

        if ($request->filled('type')) {
            $query->where('document_type', $request->query('type'));
        }

        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('document_name', 'like', "%{$search}%")
                    ->orWhere('document_number', 'like', "%{$search}%");
            });
        }

        $documents = $query->orderBy('created_at', 'desc')->get();

        $data = $documents->map(fn (EmployeeDocument $doc) => $this->formatDocument($doc));

        return response()->json([
            'success' => true,
            'data' => $data,
            'summary' => [
                'total' => $documents->count(),
                'by_type' => $documents->groupBy('document_type')->map->count(),
            ],
        ]);
    }

    #[OA\Get(
        path: '/documents/types',
        summary: 'Daftar Jenis Berkas/Dokumen',
        description: 'Mendapatkan daftar kategori jenis berkas yang didukung sistem beserta label.',
        tags: ['Employee Documents'],
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Berhasil mendapatkan daftar tipe dokumen',
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: 'success', type: 'boolean', example: true),
                        new OA\Property(property: 'data', type: 'array', items: new OA\Items(type: 'object')),
                    ]
                )
            )
        ]
    )]
    public function types(): JsonResponse
    {
        $icons = [
            EmployeeDocument::TYPE_SK => 'description',
            EmployeeDocument::TYPE_SERTIFIKAT => 'workspace_premium',
            EmployeeDocument::TYPE_KTP => 'badge',
            EmployeeDocument::TYPE_KK => 'groups',
            EmployeeDocument::TYPE_IJAZAH => 'school',
            EmployeeDocument::TYPE_NPWP => 'credit_card',
            EmployeeDocument::TYPE_BPJS_KESEHATAN => 'health_and_safety',
            EmployeeDocument::TYPE_BPJS_KETENAGAKERJAAN => 'security',
            EmployeeDocument::TYPE_KONTRAK_KERJA => 'article',
            EmployeeDocument::TYPE_OTHER => 'folder',
        ];

        $types = collect(EmployeeDocument::DOCUMENT_TYPES)->map(function ($label, $key) use ($icons) {
            return [
                'type' => $key,
                'label' => $label,
                'icon' => $icons[$key] ?? 'folder',
            ];
        })->values();

        return response()->json([
            'success' => true,
            'data' => $types,
        ]);
    }

    #[OA\Post(
        path: '/documents',
        summary: 'Unggah Berkas Pegawai Baru',
        description: 'Mengunggah file berkas dokumen baru (PDF, JPG, PNG maksimal 10MB).',
        tags: ['Employee Documents'],
        security: [['sanctum' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\MediaType(
                mediaType: 'multipart/form-data',
                schema: new OA\Schema(
                    required: ['document_type', 'document_name', 'file'],
                    properties: [
                        new OA\Property(property: 'document_type', type: 'string', example: 'sk'),
                        new OA\Property(property: 'document_name', type: 'string', example: 'SK Pengangkatan Yayasan 2026'),
                        new OA\Property(property: 'document_number', type: 'string', example: '800/123/YAPI/2026'),
                        new OA\Property(property: 'issue_date', type: 'string', format: 'date', example: '2026-01-10'),
                        new OA\Property(property: 'expiry_date', type: 'string', format: 'date', example: '2027-01-10'),
                        new OA\Property(property: 'notes', type: 'string', example: 'Catatan dokumen'),
                        new OA\Property(property: 'file', type: 'string', format: 'binary'),
                    ]
                )
            )
        ),
        responses: [
            new OA\Response(response: 201, description: 'Berkas berhasil diunggah'),
            new OA\Response(response: 422, description: 'Validasi gagal'),
        ]
    )]
    public function store(Request $request): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json([
                'success' => false,
                'message' => 'Data karyawan tidak ditemukan.',
            ], 404);
        }

        $validated = $request->validate([
            'document_type' => ['required', 'string', 'in:'.implode(',', array_keys(EmployeeDocument::DOCUMENT_TYPES))],
            'document_name' => ['required', 'string', 'max:255'],
            'document_number' => ['nullable', 'string', 'max:100'],
            'issue_date' => ['nullable', 'date'],
            'expiry_date' => ['nullable', 'date', 'after_or_equal:issue_date'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'file' => ['required', 'file', 'max:10240', 'mimes:pdf,jpg,jpeg,png'],
        ], [
            'document_type.required' => 'Jenis dokumen wajib dipilih.',
            'document_type.in' => 'Jenis dokumen tidak valid.',
            'document_name.required' => 'Nama dokumen wajib diisi.',
            'file.required' => 'File dokumen wajib diunggah.',
            'file.max' => 'Ukuran file maksimal 10 MB.',
            'file.mimes' => 'Format file yang didukung hanya PDF, JPG, JPEG, dan PNG.',
        ]);

        try {
            $file = $request->file('file');
            $companyId = $employee->company_id;
            $targetDir = "documents/{$companyId}/{$employee->id}";

            if (! Storage::disk('public')->exists($targetDir)) {
                Storage::disk('public')->makeDirectory($targetDir);
            }

            $path = $file->store($targetDir, 'public');

            $document = EmployeeDocument::create([
                'company_id' => $companyId,
                'employee_id' => $employee->id,
                'document_type' => $validated['document_type'],
                'document_name' => $validated['document_name'],
                'document_number' => $validated['document_number'] ?? null,
                'file_path' => $path,
                'file_name' => $file->getClientOriginalName(),
                'file_size' => $file->getSize(),
                'mime_type' => $file->getMimeType(),
                'issue_date' => $validated['issue_date'] ?? null,
                'expiry_date' => $validated['expiry_date'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'uploaded_by' => $request->user()->id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Berkas berhasil disimpan.',
                'data' => $this->formatDocument($document),
            ], 201);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Failed to store employee document: '.$e->getMessage(), [
                'user_id' => $request->user()?->id,
                'employee_id' => $employee->id,
                'exception' => $e,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal menyimpan berkas: '.$e->getMessage(),
            ], 500);
        }
    }

    #[OA\Get(
        path: '/documents/{id}',
        summary: 'Detail Berkas Pegawai',
        description: 'Melihat detail berkas dokumen milik karyawan.',
        tags: ['Employee Documents'],
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(response: 200, description: 'Detail berkas ditemukan'),
            new OA\Response(response: 404, description: 'Berkas tidak ditemukan'),
        ]
    )]
    public function show(Request $request, int $id): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json([
                'success' => false,
                'message' => 'Data karyawan tidak ditemukan.',
            ], 404);
        }

        $document = EmployeeDocument::where('id', $id)
            ->where('employee_id', $employee->id)
            ->where('company_id', $employee->company_id)
            ->first();

        if (! $document) {
            return response()->json([
                'success' => false,
                'message' => 'Dokumen tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $this->formatDocument($document),
        ]);
    }

    #[OA\Get(
        path: '/documents/{id}/preview',
        summary: 'Preview File Berkas (In-App / Browser)',
        description: 'Menampilkan stream file dokumen (PDF atau Gambar) secara inline untuk preview.',
        tags: ['Employee Documents'],
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(response: 200, description: 'Stream file dokumen'),
            new OA\Response(response: 404, description: 'File tidak ditemukan'),
        ]
    )]
    public function preview(Request $request, int $id): BinaryFileResponse|JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Data karyawan tidak ditemukan.'], 404);
        }

        $document = EmployeeDocument::where('id', $id)
            ->where('employee_id', $employee->id)
            ->where('company_id', $employee->company_id)
            ->first();

        if (! $document || ! Storage::disk('public')->exists($document->file_path)) {
            return response()->json(['success' => false, 'message' => 'File tidak ditemukan.'], 404);
        }

        $fullPath = Storage::disk('public')->path($document->file_path);

        return response()->file($fullPath, [
            'Content-Type' => $document->mime_type ?? 'application/octet-stream',
            'Content-Disposition' => 'inline; filename="'.$document->file_name.'"',
        ]);
    }

    #[OA\Get(
        path: '/documents/{id}/download',
        summary: 'Unduh File Berkas',
        description: 'Mengunduh file dokumen asli milik karyawan.',
        tags: ['Employee Documents'],
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(response: 200, description: 'Download file'),
            new OA\Response(response: 404, description: 'File tidak ditemukan'),
        ]
    )]
    public function download(Request $request, int $id): StreamedResponse|JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Data karyawan tidak ditemukan.'], 404);
        }

        $document = EmployeeDocument::where('id', $id)
            ->where('employee_id', $employee->id)
            ->where('company_id', $employee->company_id)
            ->first();

        if (! $document || ! Storage::disk('public')->exists($document->file_path)) {
            return response()->json(['success' => false, 'message' => 'File tidak ditemukan.'], 404);
        }

        return Storage::disk('public')->download(
            $document->file_path,
            $document->file_name,
            ['Content-Type' => $document->mime_type ?? 'application/octet-stream']
        );
    }

    #[OA\Delete(
        path: '/documents/{id}',
        summary: 'Hapus Berkas Pegawai',
        description: 'Menghapus berkas yang diunggah oleh karyawan.',
        tags: ['Employee Documents'],
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(response: 200, description: 'Berkas berhasil dihapus'),
            new OA\Response(response: 404, description: 'Dokumen tidak ditemukan'),
        ]
    )]
    public function destroy(Request $request, int $id): JsonResponse
    {
        $employee = $request->user()->employee;

        if (! $employee) {
            return response()->json(['success' => false, 'message' => 'Data karyawan tidak ditemukan.'], 404);
        }

        $document = EmployeeDocument::where('id', $id)
            ->where('employee_id', $employee->id)
            ->where('company_id', $employee->company_id)
            ->first();

        if (! $document) {
            return response()->json([
                'success' => false,
                'message' => 'Dokumen tidak ditemukan.',
            ], 404);
        }

        $document->delete();

        return response()->json([
            'success' => true,
            'message' => 'Berkas berhasil dihapus.',
        ]);
    }

    private function formatDocument(EmployeeDocument $doc): array
    {
        $isImage = str_starts_with((string) $doc->mime_type, 'image/');
        $isPdf = $doc->mime_type === 'application/pdf' || str_ends_with(strtolower($doc->file_name), '.pdf');

        return [
            'id' => $doc->id,
            'document_type' => $doc->document_type,
            'document_type_label' => $doc->document_type_label,
            'document_name' => $doc->document_name ?? $doc->document_type_label,
            'document_number' => $doc->document_number,
            'file_name' => $doc->file_name,
            'file_size' => $doc->file_size,
            'human_file_size' => $doc->human_file_size,
            'mime_type' => $doc->mime_type,
            'is_image' => $isImage,
            'is_pdf' => $isPdf,
            'file_url' => Storage::disk('public')->url($doc->file_path),
            'preview_url' => url("/api/v1/documents/{$doc->id}/preview"),
            'download_url' => url("/api/v1/documents/{$doc->id}/download"),
            'issue_date' => $doc->issue_date?->toDateString(),
            'expiry_date' => $doc->expiry_date?->toDateString(),
            'is_expired' => $doc->is_expired,
            'is_expiring_soon' => $doc->is_expiring_soon,
            'notes' => $doc->notes,
            'created_at' => $doc->created_at?->toIso8601String(),
        ];
    }
}
