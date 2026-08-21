<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\EmployeeFaceEmbedding;
use App\Models\FaceResetRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

describe('FaceResetRequest Feature', function () {
    beforeEach(function () {
        $this->company = Company::factory()->create([
            'enable_face_recognition' => true,
        ]);
        setPermissionsTeamId($this->company->id);
        \Spatie\Permission\Models\Role::create(['name' => 'admin']);

        $this->admin = User::factory()->create([
            'company_id' => $this->company->id,
            'is_active' => true,
        ]);
        $this->admin->assignRole('admin');

        $this->user = User::factory()->create([
            'company_id' => $this->company->id,
            'is_active' => true,
        ]);

        $this->employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
            'is_active' => true,
        ]);

        $this->embedding = EmployeeFaceEmbedding::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'embedding_data' => ['descriptors' => array_fill(0, 128, 0.1)],
            'is_active' => true,
            'enrolled_at' => now(),
            'enrolled_by' => $this->admin->id,
        ]);
    });

    it('allows employee to submit face reset request via API', function () {
        Sanctum::actingAs($this->user);

        $response = $this->postJson(route('api.v1.face-recognition.reset-request'), [
            'reason' => 'Perubahan kacamata dan pencahayaan kamera baru',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.reason', 'Perubahan kacamata dan pencahayaan kamera baru');

        $this->assertDatabaseHas('face_reset_requests', [
            'employee_id' => $this->employee->id,
            'status' => 'pending',
        ]);
    });

    it('prevents submitting duplicate pending reset request', function () {
        FaceResetRequest::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'reason' => 'Permintaan pertama',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->postJson(route('api.v1.face-recognition.reset-request'), [
            'reason' => 'Permintaan kedua',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('message', 'Permohonan pendaftaran ulang wajah Anda sebelumnya masih menunggu konfirmasi dari Administrator.');
    });

    it('returns reset request status for employee', function () {
        FaceResetRequest::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'reason' => 'Ganti perangkat',
            'status' => 'pending',
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->getJson(route('api.v1.face-recognition.reset-request.status'));

        $response->assertOk()
            ->assertJsonPath('data.has_pending_request', true)
            ->assertJsonPath('data.pending_request.reason', 'Ganti perangkat');
    });

    it('allows admin to view face reset requests page', function () {
        FaceResetRequest::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'reason' => 'Wajah sering gagal terdeteksi',
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->admin)
            ->get(route('face-recognition.requests'));

        $response->assertOk()
            ->assertSee('Permintaan Reset Wajah')
            ->assertSee('Wajah sering gagal terdeteksi');
    });

    it('allows admin to approve face reset request and resets face data', function () {
        $request = FaceResetRequest::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'reason' => 'Ingin daftar ulang',
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->admin)
            ->post(route('face-recognition.requests.approve', $request));

        $response->assertRedirect(route('face-recognition.requests'))
            ->assertSessionHas('success');

        $this->assertDatabaseHas('face_reset_requests', [
            'id' => $request->id,
            'status' => 'approved',
            'reviewed_by' => $this->admin->id,
        ]);

        // Existing embedding should be deleted
        $this->assertDatabaseMissing('employee_face_embeddings', [
            'id' => $this->embedding->id,
        ]);
    });

    it('allows admin to reject face reset request with notes', function () {
        $request = FaceResetRequest::create([
            'company_id' => $this->company->id,
            'employee_id' => $this->employee->id,
            'reason' => 'Ingin daftar ulang',
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->admin)
            ->post(route('face-recognition.requests.reject', $request), [
                'admin_notes' => 'Data wajah saat ini masih sangat valid dan sesuai.',
            ]);

        $response->assertRedirect(route('face-recognition.requests'))
            ->assertSessionHas('success');

        $this->assertDatabaseHas('face_reset_requests', [
            'id' => $request->id,
            'status' => 'rejected',
            'admin_notes' => 'Data wajah saat ini masih sangat valid dan sesuai.',
            'reviewed_by' => $this->admin->id,
        ]);
    });
});
