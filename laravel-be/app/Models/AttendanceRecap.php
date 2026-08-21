<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AttendanceRecap extends Model
{
    /** @use HasFactory<\Database\Factories\AttendanceRecapFactory> */
    use HasFactory;

    protected $fillable = [
        'company_id',
        'employee_id',
        'frequency',
        'period_start',
        'period_end',
        'working_days',
        'present_days',
        'absent_days',
        'late_days',
        'leave_days',
        'attendance_percentage',
        'whatsapp_sent_at',
        'whatsapp_status',
        'email_sent_at',
        'email_status',
    ];

    protected function casts(): array
    {
        return [
            'period_start' => 'date',
            'period_end' => 'date',
            'attendance_percentage' => 'decimal:2',
            'whatsapp_sent_at' => 'datetime',
            'email_sent_at' => 'datetime',
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
}
