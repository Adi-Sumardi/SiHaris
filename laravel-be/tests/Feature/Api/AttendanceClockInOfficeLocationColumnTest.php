<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\OfficeLocation;
use App\Models\User;
use App\Models\WorkSchedule;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    Storage::fake('public');

    $this->company = Company::factory()->create([
        'enable_gps_validation' => true,
        'enable_face_recognition' => true,
        'require_liveness_detection' => true,
        'face_match_threshold' => 0.6,
    ]);
    $this->workSchedule = WorkSchedule::factory()->create([
        'company_id' => $this->company->id,
        'start_time' => '08:00:00',
        'end_time' => '17:00:00',
    ]);
    $this->user = User::factory()->create([
        'company_id' => $this->company->id,
    ]);
    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'user_id' => $this->user->id,
        'work_schedule_id' => $this->workSchedule->id,
    ]);

    $this->office = OfficeLocation::factory()->create([
        'company_id' => $this->company->id,
        'latitude' => -6.2088,
        'longitude' => 106.8456,
        'radius' => 100,
        'is_active' => true,
    ]);
    $this->employee->officeLocations()->attach($this->office->id, ['is_primary' => true]);

    $this->employee->faceEmbedding()->create([
        'embedding_data' => ['embedding' => array_fill(0, 128, 0.1)],
        'enrollment_photo' => 'face-enrollments/test.jpg',
        'enrolled_at' => now(),
        'is_active' => true,
    ]);
});

it('clocks in exactly like the mobile app: gps + client-verified face + liveness + descriptors + photo', function () {
    Sanctum::actingAs($this->user);

    $photo = UploadedFile::fake()->image('selfie.jpg');

    $response = $this->post('/api/v1/attendance/clock-in', [
        'app_device_id' => 'test-device-001',
        'latitude' => -6.2088,
        'longitude' => 106.8456,
        'gps_verified' => '1',
        'office_location_id' => (string) $this->office->id,
        'face_verified' => '1',
        'liveness_passed' => '1',
        'face_confidence' => '0.87',
        'face_descriptors' => json_encode(array_fill(0, 128, 0.11)),
        'photo' => $photo,
    ], ['Accept' => 'application/json']);

    $response->assertOk();

    $this->assertDatabaseHas('attendances', [
        'employee_id' => $this->employee->id,
        'office_location_id' => $this->office->id,
    ]);
});
