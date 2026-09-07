<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

uses(RefreshDatabase::class);

describe('FaceRecognitionController', function () {
    beforeEach(function () {
        $this->company = Company::factory()->create();
        setPermissionsTeamId($this->company->id);
        \Spatie\Permission\Models\Role::create(['name' => 'admin']);
        $this->admin = User::factory()->create([
            'company_id' => $this->company->id,
            'is_active' => true,
        ]);
        $this->admin->assignRole('admin');
        $this->employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'is_active' => true,
            'first_name' => 'Adi',
            'last_name' => 'Sumardi',
        ]);
    });

    it('displays face recognition index page', function () {
        $response = $this->actingAs($this->admin)
            ->get(route('face-recognition.index'));

        $response->assertOk()
            ->assertSee('Pendaftaran Wajah')
            ->assertSee('Adi Sumardi');
    });

    it('displays face recognition show page', function () {
        $response = $this->actingAs($this->admin)
            ->get(route('face-recognition.show', $this->employee));

        $response->assertOk()
            ->assertSee('Daftarkan Wajah Baru')
            ->assertSee('Upload Foto')
            ->assertSee('Gunakan Kamera');
    });

    it('displays show page with balanced markup when employee already has an enrollment', function () {
        \App\Models\EmployeeFaceEmbedding::factory()->create([
            'employee_id' => $this->employee->id,
            'embedding_data' => ['descriptors' => array_fill(0, 128, 0.1)],
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->admin)
            ->get(route('face-recognition.show', $this->employee));

        $response->assertOk()
            ->assertSee('Status Pendaftaran')
            ->assertSee('Biometrik Wajah Aktif')
            // The Enrollment Form column must still render alongside the
            // "Status Pendaftaran" card — regression guard for a bug where
            // a stray closing </div> inside the @if($embedding) branch
            // closed the surrounding grid early, leaving this whole
            // right-hand column outside the grid and visually broken.
            ->assertSee('Daftarkan Ulang Wajah')
            ->assertSee('Upload Foto');

        // A stray/misplaced </div> anywhere in this view breaks the DOM
        // nesting without Blade ever raising an error, so assertSee alone
        // can't catch it — verify the raw HTML's div tags are balanced.
        $html = $response->getContent();
        expect(substr_count($html, '<div'))->toBe(substr_count($html, '</div>'));
    });

    it('enrolls face successfully with uploaded photo', function () {
        Storage::fake('public');

        $file = UploadedFile::fake()->image('face.jpg', 600, 600);

        $response = $this->actingAs($this->admin)
            ->post(route('face-recognition.store', $this->employee), [
                'photo' => $file,
            ]);

        $response->assertRedirect(route('face-recognition.show', $this->employee))
            ->assertSessionHas('success');

        $this->assertDatabaseHas('employee_face_embeddings', [
            'employee_id' => $this->employee->id,
            'is_active' => true,
        ]);
    });
});
