<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FingerprintUserMapping extends Model
{
    use HasFactory;

    protected $fillable = [
        'fingerprint_device_id',
        'employee_id',
        'device_user_pin',
    ];

    public function device(): BelongsTo
    {
        return $this->belongsTo(FingerprintDevice::class, 'fingerprint_device_id');
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}
