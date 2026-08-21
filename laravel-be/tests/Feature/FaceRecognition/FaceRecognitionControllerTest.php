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
