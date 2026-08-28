<?php

use App\Models\Announcement;
use App\Models\Company;
use App\Models\Department;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    $this->department = Department::factory()->create([
        'company_id' => $this->company->id,
    ]);
    $this->user = User::factory()->create([
        'company_id' => $this->company->id,
    ]);
    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'user_id' => $this->user->id,
        'department_id' => $this->department->id,
    ]);
});

describe('GET /api/v1/announcements', function () {
    it('returns list of announcements for user', function () {
        Sanctum::actingAs($this->user);

        // Create announcement for all employees
        Announcement::factory()->count(3)->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        $response = $this->getJson('/api/v1/announcements');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'title',
                        'content',
                        'priority',
                        'priority_label',
                        'is_pinned',
                        'is_read',
                        'has_attachment',
                        'published_at',
                        'created_at',
                    ],
                ],
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
            ]);

        expect(count($response->json('data')))->toBe(3);
    });

    it('shows announcements targeted to user department', function () {
        Sanctum::actingAs($this->user);

        // Announcement for user's department
        Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_DEPARTMENT,
            'target_ids' => [$this->department->id],
            'is_published' => true,
        ]);

        // Announcement for other department
        $otherDept = Department::factory()->create(['company_id' => $this->company->id]);
        Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_DEPARTMENT,
            'target_ids' => [$otherDept->id],
            'is_published' => true,
        ]);

        $response = $this->getJson('/api/v1/announcements');

        $response->assertOk();
        expect(count($response->json('data')))->toBe(1);
    });

    it('does not show unpublished announcements', function () {
        Sanctum::actingAs($this->user);

        Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => false,
        ]);

        Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        $response = $this->getJson('/api/v1/announcements');

        $response->assertOk();
        expect(count($response->json('data')))->toBe(1);
    });

    it('does not show expired announcements', function () {
        Sanctum::actingAs($this->user);

        Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
            'expires_at' => now()->subDay(), // Expired
        ]);

        Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
            'expires_at' => now()->addDay(), // Not expired
        ]);

        $response = $this->getJson('/api/v1/announcements');

        $response->assertOk();
        expect(count($response->json('data')))->toBe(1);
    });

    it('orders pinned announcements first', function () {
        Sanctum::actingAs($this->user);

        $regularAnnouncement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
            'is_pinned' => false,
            'created_at' => now(),
        ]);

        $pinnedAnnouncement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
            'is_pinned' => true,
            'created_at' => now()->subDay(),
        ]);

        $response = $this->getJson('/api/v1/announcements');

        $response->assertOk();
        $data = $response->json('data');
        expect($data[0]['id'])->toBe($pinnedAnnouncement->id);
    });

    it('shows read status correctly', function () {
        Sanctum::actingAs($this->user);

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        // Mark as read
        $announcement->markAsRead($this->user->id);

        $response = $this->getJson('/api/v1/announcements');

        $response->assertOk();
        expect($response->json('data.0.is_read'))->toBeTrue();
    });
});

describe('GET /api/v1/announcements/{id}', function () {
    it('returns announcement detail', function () {
        Sanctum::actingAs($this->user);

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        $response = $this->getJson("/api/v1/announcements/{$announcement->id}");

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id',
                    'title',
                    'content',
                    'priority',
                    'priority_label',
                    'is_pinned',
                    'is_read',
                    'has_attachment',
                    'published_at',
                    'created_at',
                    'creator' => [
                        'name',
                    ],
                ],
            ]);
    });

    it('returns 404 for unpublished announcement', function () {
        Sanctum::actingAs($this->user);

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => false,
        ]);

        $response = $this->getJson("/api/v1/announcements/{$announcement->id}");

        $response->assertStatus(404);
    });

    it('returns 404 for announcement not targeted to user', function () {
        Sanctum::actingAs($this->user);

        $otherDept = Department::factory()->create(['company_id' => $this->company->id]);

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_DEPARTMENT,
            'target_ids' => [$otherDept->id],
            'is_published' => true,
        ]);

        $response = $this->getJson("/api/v1/announcements/{$announcement->id}");

        $response->assertStatus(404);
    });

    it('includes attachment fields and a working signed preview/download URL when an attachment exists', function () {
        Sanctum::actingAs($this->user);

        $file = UploadedFile::fake()->create('edaran.pdf', 300, 'application/pdf');
        $path = $file->store("announcements/{$this->company->id}", 'local');

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
            'attachment_path' => $path,
            'attachment_name' => 'edaran.pdf',
            'attachment_size' => 307200,
            'attachment_mime_type' => 'application/pdf',
        ]);

        $response = $this->getJson("/api/v1/announcements/{$announcement->id}");

        $response->assertOk()
            ->assertJsonPath('data.has_attachment', true)
            ->assertJsonPath('data.attachment_name', 'edaran.pdf')
            ->assertJsonPath('data.is_attachment_image', false)
            ->assertJsonPath('data.is_attachment_pdf', true);

        $body = $response->json('data');
        $this->get($body['attachment_preview_url'])->assertOk();
        $this->get($body['attachment_download_url'])->assertOk();
    });

    it('omits attachment fields when there is no attachment', function () {
        Sanctum::actingAs($this->user);

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
            'attachment_path' => null,
        ]);

        $response = $this->getJson("/api/v1/announcements/{$announcement->id}");

        $response->assertOk()
            ->assertJsonPath('data.has_attachment', false)
            ->assertJsonPath('data.attachment_preview_url', null)
            ->assertJsonPath('data.attachment_download_url', null);
    });

    it('rejects announcement attachment preview/download with a missing or invalid token', function () {
        Sanctum::actingAs($this->user);

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'attachment_path' => 'announcements/1/edaran.pdf',
            'attachment_name' => 'edaran.pdf',
        ]);

        $this->get("/api/v1/announcements/{$announcement->id}/preview")->assertForbidden();
        $this->get("/api/v1/announcements/{$announcement->id}/download?token=invalid&expires=".now()->addMinutes(5)->timestamp)
            ->assertForbidden();
    });
});

describe('POST /api/v1/announcements/{id}/read', function () {
    it('marks announcement as read', function () {
        Sanctum::actingAs($this->user);

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        $response = $this->postJson("/api/v1/announcements/{$announcement->id}/read");

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'message' => 'Pengumuman ditandai sudah dibaca.',
            ]);

        expect($announcement->isReadBy($this->user->id))->toBeTrue();
    });

    it('handles already read announcement', function () {
        Sanctum::actingAs($this->user);

        $announcement = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        $announcement->markAsRead($this->user->id);

        $response = $this->postJson("/api/v1/announcements/{$announcement->id}/read");

        // Should still succeed (idempotent)
        $response->assertOk();
    });
});

describe('GET /api/v1/announcements/unread-count', function () {
    it('returns unread announcement count', function () {
        Sanctum::actingAs($this->user);

        Announcement::factory()->count(3)->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        $response = $this->getJson('/api/v1/announcements/unread-count');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    'count',
                ],
            ]);

        expect($response->json('data.count'))->toBe(3);
    });

    it('excludes read announcements from count', function () {
        Sanctum::actingAs($this->user);

        $announcement1 = Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        Announcement::factory()->create([
            'company_id' => $this->company->id,
            'target_audience' => Announcement::TARGET_ALL,
            'is_published' => true,
        ]);

        $announcement1->markAsRead($this->user->id);

        $response = $this->getJson('/api/v1/announcements/unread-count');

        $response->assertOk();
        expect($response->json('data.count'))->toBe(1);
    });
});
