<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class GeneratedExport extends Model
{
    protected $fillable = [
        'company_id',
        'user_id',
        'type',
        'title',
        'filename',
        'disk',
        'path',
        'status',
        'error',
        'source_type',
        'source_id',
        'meta',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'meta' => 'array',
            'expires_at' => 'datetime',
        ];
    }

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function source(): MorphTo
    {
        return $this->morphTo();
    }

    public function markProcessing(): void
    {
        $this->update(['status' => 'processing']);
    }

    public function markReady(string $path): void
    {
        $this->update(['status' => 'ready', 'path' => $path]);
    }

    public function markFailed(string $error): void
    {
        $this->update(['status' => 'failed', 'error' => $error]);
    }

    public function isReady(): bool
    {
        return $this->status === 'ready';
    }
}
