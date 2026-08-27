<?php

use App\Models\Company;
use App\Models\Department;
use App\Models\Employee;
use App\Models\EmployeeDocument;
use App\Models\User;
use App\Models\WorkSchedule;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\Models\Role;

uses(RefreshDatabase::class);

beforeEach(function () {
    Storage::fake('public');

    $this->company = Company::factory()->create();
    setPermissionsTeamId($this->company->id);
    Role::findOrCreate('admin', 'web');

    $this->admin = User::factory()->create([
        'company_id' => $this->company->id,
    ]);
    $this->admin->assignRole('admin');

    $this->workSchedule = WorkSchedule::factory()->create([
        'company_id' => $this->company->id,
    ]);

    $this->deptA = Department::factory()->create([
        'company_id' => $this->company->id,
        'name' => 'Guru SD',
    ]);

    $this->deptB = Department::factory()->create([
        'company_id' => $this->company->id,
        'name' => 'Guru SMP',
    ]);

    $this->employeeA = Employee::factory()->create([
        'company_id' => $this->company->id,
        'department_id' => $this->deptA->id,
        'work_schedule_id' => $this->workSchedule->id,
        'first_name' => 'Ahmad',
        'last_name' => 'Dahlan',
    ]);

    $this->employeeB = Employee::factory()->create([
        'company_id' => $this->company->id,
        'department_id' => $this->deptB->id,
        'work_schedule_id' => $this->workSchedule->id,
        'first_name' => 'Budi',
        'last_name' => 'Santoso',
    ]);
});

describe('Central Document Explorer - Index', function () {
    it('displays all employee documents across the company with stats', function () {
        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employeeA->id,
            'document_type' => 'sk',
            'document_name' => 'SK Guru Tetap Ahmad',
            'file_path' => 'documents/1/1/sk.pdf',
            'file_name' => 'sk.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->admin->id,
        ]);

        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employeeB->id,
            'document_type' => 'sertifikat',
            'document_name' => 'Sertifikat Pendidik Budi',
            'file_path' => 'documents/1/2/serdik.pdf',
            'file_name' => 'serdik.pdf',
            'file_size' => 204800,
            'mime_type' => 'application/pdf',
            'uploaded_by' => $this->admin->id,
        ]);

        $response = $this->actingAs($this->admin)
            ->get(route('documents.index'));

        $response->assertOk()
            ->assertViewIs('documents.index')
            ->assertViewHas('documents')
            ->assertViewHas('stats')
            ->assertSee('SK Guru Tetap Ahmad')
            ->assertSee('Sertifikat Pendidik Budi')
            ->assertSee('Ahmad Dahlan')
            ->assertSee('Budi Santoso');
    });

    it('filters documents by department and document type', function () {
        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employeeA->id,
            'document_type' => 'sk',
            'document_name' => 'SK Ahmad',
            'file_path' => 'documents/1/1/sk.pdf',
            'file_name' => 'sk.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
        ]);

        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employeeB->id,
            'document_type' => 'ktp',
            'document_name' => 'KTP Budi',
            'file_path' => 'documents/1/2/ktp.jpg',
            'file_name' => 'ktp.jpg',
            'file_size' => 102400,
            'mime_type' => 'image/jpeg',
        ]);

        $response = $this->actingAs($this->admin)
            ->get(route('documents.index', [
                'department_id' => $this->deptA->id,
                'document_type' => 'sk',
            ]));

        $response->assertOk()
            ->assertSee('SK Ahmad')
            ->assertDontSee('KTP Budi');
    });

    it('searches documents by employee name or document name', function () {
        EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employeeA->id,
            'document_type' => 'sk',
            'document_name' => 'SK Khusus Guru',
            'file_path' => 'documents/1/1/sk.pdf',
            'file_name' => 'sk.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
        ]);

        $response = $this->actingAs($this->admin)
            ->get(route('documents.index', ['search' => 'Dahlan']));

        $response->assertOk()
            ->assertSee('SK Khusus Guru')
            ->assertSee('Ahmad Dahlan');
    });
});

describe('Central Document Explorer - Preview, Download & Delete', function () {
    it('allows admin to preview and download document', function () {
        $file = UploadedFile::fake()->create('dokumen.pdf', 200, 'application/pdf');
        $path = $file->store("documents/{$this->company->id}/{$this->employeeA->id}", 'public');

        $doc = EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employeeA->id,
            'document_type' => 'sk',
            'document_name' => 'SK Preview',
            'file_path' => $path,
            'file_name' => 'dokumen.pdf',
            'file_size' => 204800,
            'mime_type' => 'application/pdf',
        ]);

        $previewRes = $this->actingAs($this->admin)->get(route('documents.preview', $doc));
        $previewRes->assertOk();

        $downloadRes = $this->actingAs($this->admin)->get(route('documents.download', $doc));
        $downloadRes->assertOk();
    });

    it('allows admin to delete document', function () {
        $doc = EmployeeDocument::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employeeA->id,
            'document_type' => 'sk',
            'document_name' => 'SK Delete',
            'file_path' => 'documents/1/1/sk.pdf',
            'file_name' => 'sk.pdf',
            'file_size' => 102400,
            'mime_type' => 'application/pdf',
        ]);

        $response = $this->actingAs($this->admin)->delete(route('documents.destroy', $doc));

        $response->assertRedirect();
        $this->assertSoftDeleted('employee_documents', ['id' => $doc->id]);
    });
});
