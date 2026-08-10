<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Binds a physical device (mobile app install) to exactly one employee per
     * company, so a single phone cannot be used to clock in for several
     * employees ("buddy punching" via a shared device).
     */
    public function up(): void
    {
        Schema::create('employee_devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('device_id');
            $table->string('device_name')->nullable();
            $table->string('platform')->nullable();
            $table->timestamp('first_seen_at');
            $table->timestamp('last_seen_at');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['company_id', 'device_id']);
            $table->index(['employee_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_devices');
    }
};
