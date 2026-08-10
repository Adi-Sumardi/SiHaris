<?php

namespace App\Models;

use App\Traits\LogsActivityTrait;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class FingerprintDevice extends Model
{
    use HasFactory, LogsActivityTrait, SoftDeletes;

    protected $fillable = [
        'company_id',
        'office_location_id',
        'name',
        'brand',
        'serial_number',
        'ip_address',
        'port',
        'webhook_secret',
        'last_sync_at',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'port' => 'integer',
            'last_sync_at' => 'datetime',
            'is_active' => 'boolean',
        ];
    }

    protected $hidden = [
        'webhook_secret',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class);
    }

    public function officeLocation(): BelongsTo
    {
        return $this->belongsTo(OfficeLocation::class);
    }

    public function userMappings(): HasMany
    {
        return $this->hasMany(FingerprintUserMapping::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
