<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\EmployeeDocument;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

beforeEach(function () {
    Storage::fake('local');

    $this->company = Company::factory()->create([
        'name' => 'Yayasan Pendidikan Islam',
    ]);
    $this->user = User::factory()->create([
        'company_id' => $this->company->id,
    ]);
    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'user_id' => $this->user->id,
        'first_name' => 'Hesti',
        'last_name' => 'Suryadi',
    ]);

    // Other company & employee for tenant isolation tests
    $this->otherCompany = Company::factory()->create();
    $this->otherUser = User::factory()->create(['company_id' => $this->otherCompany->id]);
    $this->otherEmployee = Employee::factory()->create([
        'company_id' => $this->otherCompany->id,
        'user_id' => $this->otherUser->id,
    ]);
});

describe('GET /api/v1/documents/types', function () {
    it('returns available document types for mobile client', function () {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/v1/documents/types');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => ['type', 'label', 'icon'],
                ],
            ]);

        $types = collect($response->json('data'))->pluck('type')->toArray();
        expect($types)->toContain('sk', 'sertifikat', 'ktp', 'kk', 'ijazah', 'npwp', 'bpjs_kesehatan', 'bpjs_ketenagakerjaan', 'kontrak_kerja', 'other');
    });
});

describe('GET /api/v1/documents', function () {
    it('returns 401 when not authenticated', function () {
        $this->getJson('/api/v1/documents')->assertUnauthorized();
    });

    it('returns list of documents for authenticated employee', function () {
        Sanctum::actingAs($this->user);

        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'sk',
            'document_name' => 'SK Guru Tetap 2026',
            'document_number' => '800/SK/2026',
            'file_path' => 'documents/1/1/sk.pdf',
            'file_name' => 'sk.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->user->id,
        ]);

        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'ktp',
            'document_name' => 'KTP Hesti',
            'document_number' => '3201234567890001',
            'file_path' => 'documents/1/1/ktp.jpg',
            'file_name' => 'ktp.jpg',
            'file_size' => 204800,
            'mime_type' => 'image/jpeg',
            'uploaded_by' => $this->user->id,
        ]);

        // Document for another employee
        EmployeeDocument::create([
            'company_id' => $this->otherCompany->id,
            'employee_id' => $this->otherEmployee->id,
            'document_type' => 'sk',
            'document_name' => 'SK Other',
            'file_path' => 'documents/2/2/sk.pdf',
            'file_name' => 'sk.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->otherUser->id,
        ]);

        $response = $this->getJson('/api/v1/documents');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('summary.total', 2);
    });

    it('filters documents by document type', function () {
        Sanctum::actingAs($this->user);

        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'sk',
            'document_name' => 'SK Mengajar',
            'file_path' => 'documents/1/1/sk.pdf',
            'file_name' => 'sk.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->user->id,
        ]);

        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'sertifikat',
            'document_name' => 'Sertifikat Pendidik',
            'file_path' => 'documents/1/1/serdik.pdf',
            'file_name' => 'serdik.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->user->id,
        ]);

        $response = $this->getJson('/api/v1/documents?type=sk');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.document_type', 'sk')
            ->assertJsonPath('data.0.document_name', 'SK Mengajar');
    });

    it('searches documents by query keyword', function () {
        Sanctum::actingAs($this->user);

        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'sertifikat',
            'document_name' => 'Sertifikat TOEFL ITP',
            'document_number' => 'TOEFL-2026-99',
            'file_path' => 'documents/1/1/toefl.pdf',
            'file_name' => 'toefl.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->user->id,
        ]);

        $response = $this->getJson('/api/v1/documents?search=TOEFL');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.document_number', 'TOEFL-2026-99');
    });
});

describe('POST /api/v1/documents', function () {
    it('uploads a valid PDF document successfully', function () {
        Sanctum::actingAs($this->user);

        $file = UploadedFile::fake()->create('sk_pengangkatan.pdf', 500, 'application/pdf');

        $payload = [
            'document_type' => 'sk',
            'document_name' => 'SK Guru Tetap Yayasan 2026',
            'document_number' => '800/10/YAPI/2026',
            'issue_date' => '2026-01-15',
            'notes' => 'Dokumen resmi yayasan',
            'file' => $file,
        ];

        $response = $this->postJson('/api/v1/documents', $payload);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.document_type', 'sk')
            ->assertJsonPath('data.document_name', 'SK Guru Tetap Yayasan 2026')
            ->assertJsonPath('data.is_pdf', true)
            ->assertJsonPath('data.is_image', false);

        $this->assertDatabaseHas('employee_documents', [
            'employee_id' => $this->employee->id,
            'company_id' => $this->company->id,
            'document_type' => 'sk',
            'document_number' => '800/10/YAPI/2026',
        ]);
    });

    it('uploads a valid image document (KTP / KK) successfully', function () {
        Sanctum::actingAs($this->user);

        $file = UploadedFile::fake()->image('ktp.jpg');

        $payload = [
            'document_type' => 'ktp',
            'document_name' => 'Foto KTP',
            'document_number' => '3201123456780001',
            'file' => $file,
        ];

        $response = $this->postJson('/api/v1/documents', $payload);

        $response->assertCreated()
            ->assertJsonPath('data.document_type', 'ktp')
            ->assertJsonPath('data.is_image', true)
            ->assertJsonPath('data.is_pdf', false);
    });

    it('fails validation when required fields or file are missing', function () {
        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/v1/documents', []);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['document_type', 'document_name', 'file']);
    });

    it('rejects unsupported file extensions', function () {
        Sanctum::actingAs($this->user);

        $file = UploadedFile::fake()->create('document.exe', 100);

        $response = $this->postJson('/api/v1/documents', [
            'document_type' => 'sk',
            'document_name' => 'Malicious file',
            'file' => $file,
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['file']);
    });
});

describe('GET /api/v1/documents/{id}/preview and download', function () {
    it('previews and downloads file successfully using the signed URL from the document payload', function () {
        Sanctum::actingAs($this->user);

        $file = UploadedFile::fake()->create('sertifikat.pdf', 300, 'application/pdf');
        $path = $file->store("documents/{$this->company->id}/{$this->employee->id}", 'local');

        $doc = EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'sertifikat',
            'document_name' => 'Sertifikat Guru Penggerak',
            'file_path' => $path,
            'file_name' => 'sertifikat.pdf',
            'file_size' => 307200,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->user->id,
        ]);

        // preview_url/download_url carry their own signed token so they can be
        // opened directly (e.g. by an external browser/PDF viewer) without the
        // mobile app's Bearer token.
        $body = $this->getJson("/api/v1/documents/{$doc->id}")->json('data');

        $this->get($body['preview_url'])->assertOk();
        $this->get($body['download_url'])->assertOk();
    });

    it('rejects preview/download requests with a missing or invalid token', function () {
        Sanctum::actingAs($this->user);

        $doc = EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'sertifikat',
            'document_name' => 'Sertifikat Guru Penggerak',
            'file_path' => 'documents/1/1/sertifikat.pdf',
            'file_name' => 'sertifikat.pdf',
            'file_size' => 307200,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->user->id,
        ]);

        $this->get("/api/v1/documents/{$doc->id}/preview")->assertForbidden();
        $this->get("/api/v1/documents/{$doc->id}/download?token=invalid&expires=".now()->addMinutes(5)->timestamp)
            ->assertForbidden();
    });

    it('rejects the signed URL once it has expired', function () {
        Sanctum::actingAs($this->user);

        $file = UploadedFile::fake()->create('sertifikat.pdf', 300, 'application/pdf');
        $path = $file->store("documents/{$this->company->id}/{$this->employee->id}", 'local');

        $doc = EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'sertifikat',
            'document_name' => 'Sertifikat Guru Penggerak',
            'file_path' => $path,
            'file_name' => 'sertifikat.pdf',
            'file_size' => 307200,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->user->id,
        ]);

        $previewUrl = $this->getJson("/api/v1/documents/{$doc->id}")->json('data.preview_url');

        $this->travel(20)->minutes();

        $this->get($previewUrl)->assertForbidden();
    });

    it('returns 404 when accessing document belonging to another employee', function () {
        Sanctum::actingAs($this->user);

        $doc = EmployeeDocument::create([
            'company_id' => $this->otherCompany->id,
            'employee_id' => $this->otherEmployee->id,
            'document_type' => 'sk',
            'document_name' => 'SK Other Employee',
            'file_path' => 'documents/2/2/sk.pdf',
            'file_name' => 'sk.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->otherUser->id,
        ]);

        $this->getJson("/api/v1/documents/{$doc->id}")->assertNotFound();
        $this->deleteJson("/api/v1/documents/{$doc->id}")->assertNotFound();
    });
});

describe('DELETE /api/v1/documents/{id}', function () {
    it('deletes document belonging to authenticated employee', function () {
        Sanctum::actingAs($this->user);

        $doc = EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'document_type' => 'ijazah',
            'document_name' => 'Ijazah S1',
            'file_path' => 'documents/1/1/ijazah.pdf',
            'file_name' => 'ijazah.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->user->id,
        ]);

        $response = $this->deleteJson("/api/v1/documents/{$doc->id}");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertSoftDeleted('employee_documents', [
            'id' => $doc->id,
        ]);
    });
});
