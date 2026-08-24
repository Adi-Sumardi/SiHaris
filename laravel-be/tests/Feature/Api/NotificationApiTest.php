<?php

use App\Models\Company;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    $this->user = User::factory()->create([
        'company_id' => $this->company->id,
    ]);
    $this->otherUser = User::factory()->create([
        'company_id' => $this->company->id,
    ]);
});

describe('GET /api/v1/notifications', function () {
    it('requires authentication', function () {
        $response = $this->getJson('/api/v1/notifications');

        $response->assertUnauthorized();
    });

    it('returns only the authenticated user\'s notifications', function () {
        Sanctum::actingAs($this->user);

        Notification::factory()->count(3)->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
        ]);
        Notification::factory()->count(2)->create([
            'company_id' => $this->company->id,
            'user_id' => $this->otherUser->id,
        ]);

        $response = $this->getJson('/api/v1/notifications');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'title',
                        'message',
                        'type',
                        'link',
                        'is_read',
                        'read_at',
                        'created_at',
                    ],
                ],
                'meta' => ['current_page', 'last_page', 'per_page', 'total'],
            ]);

        expect(count($response->json('data')))->toBe(3);
    });

    it('orders notifications newest first', function () {
        Sanctum::actingAs($this->user);

        $old = Notification::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
            'created_at' => now()->subDays(2),
        ]);
        $new = Notification::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
            'created_at' => now(),
        ]);

        $response = $this->getJson('/api/v1/notifications');

        expect($response->json('data.0.id'))->toBe($new->id);
        expect($response->json('data.1.id'))->toBe($old->id);
    });
});

describe('GET /api/v1/notifications/unread-count', function () {
    it('counts only unread notifications for the authenticated user', function () {
        Sanctum::actingAs($this->user);

        Notification::factory()->count(2)->unread()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
        ]);
        Notification::factory()->read()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
        ]);
        Notification::factory()->unread()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->otherUser->id,
        ]);

        $response = $this->getJson('/api/v1/notifications/unread-count');

        $response->assertOk();
        expect($response->json('data.count'))->toBe(2);
    });
});

describe('POST /api/v1/notifications/{notification}/read', function () {
    it('marks the notification as read', function () {
        Sanctum::actingAs($this->user);

        $notification = Notification::factory()->unread()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
        ]);

        $response = $this->postJson("/api/v1/notifications/{$notification->id}/read");

        $response->assertOk();
        expect($notification->fresh()->isRead())->toBeTrue();
    });

    it('returns 404 for another user\'s notification', function () {
        Sanctum::actingAs($this->user);

        $notification = Notification::factory()->unread()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->otherUser->id,
        ]);

        $response = $this->postJson("/api/v1/notifications/{$notification->id}/read");

        $response->assertNotFound();
        expect($notification->fresh()->isRead())->toBeFalse();
    });
});

describe('POST /api/v1/notifications/mark-all-read', function () {
    it('marks all of the authenticated user\'s notifications as read without touching others', function () {
        Sanctum::actingAs($this->user);

        Notification::factory()->count(3)->unread()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
        ]);
        $otherUnread = Notification::factory()->unread()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->otherUser->id,
        ]);

        $response = $this->postJson('/api/v1/notifications/mark-all-read');

        $response->assertOk();
        expect(Notification::where('user_id', $this->user->id)->unread()->count())->toBe(0);
        expect($otherUnread->fresh()->isUnread())->toBeTrue();
    });
});

describe('DELETE /api/v1/notifications/{notification}', function () {
    it('deletes the notification', function () {
        Sanctum::actingAs($this->user);

        $notification = Notification::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->user->id,
        ]);

        $response = $this->deleteJson("/api/v1/notifications/{$notification->id}");

        $response->assertOk();
        $this->assertDatabaseMissing('notifications', ['id' => $notification->id]);
    });

    it('returns 404 for another user\'s notification and does not delete it', function () {
        Sanctum::actingAs($this->user);

        $notification = Notification::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => $this->otherUser->id,
        ]);

        $response = $this->deleteJson("/api/v1/notifications/{$notification->id}");

        $response->assertNotFound();
        $this->assertDatabaseHas('notifications', ['id' => $notification->id]);
    });
});
