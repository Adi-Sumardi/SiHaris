<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('raw_attendance_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->foreignId('employee_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('attendance_id')->nullable()->constrained()->nullOnDelete();
            $table->string('channel'); // app_face, fingerprint, web, manual
            $table->foreignId('fingerprint_device_id')->nullable()->constrained()->nullOnDelete();
            $table->string('device_user_pin')->nullable();
            $table->string('type'); // clock_in, clock_out
            $table->timestamp('event_time');
            $table->timestamp('received_at');
            $table->string('status'); // applied, duplicate_ignored, superseded, unmatched
            $table->string('dedup_hash');
            $table->json('payload')->nullable();
            $table->timestamps();

            $table->unique('dedup_hash');
            $table->index(['company_id', 'status']);
            $table->index(['employee_id', 'event_time']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('raw_attendance_logs');
    }
};
