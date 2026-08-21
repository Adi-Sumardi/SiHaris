<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RawAttendanceLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'employee_id',
        'attendance_id',
        'channel',
        'fingerprint_device_id',
        'device_user_pin',
        'type',
        'event_time',
        'received_at',
        'status',
        'dedup_hash',
        'payload',
    ];

    protected function casts(): array
    {
        return [
            'event_time' => 'datetime',
            'received_at' => 'datetime',
            'payload' => 'array',
        ];
    }

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class);
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class)->withTrashed();
    }

    public function attendance(): BelongsTo
    {
        return $this->belongsTo(Attendance::class);
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(FingerprintDevice::class, 'fingerprint_device_id');
    }

    public function scopeUnmatched($query)
    {
        return $query->where('status', 'unmatched');
    }
}
