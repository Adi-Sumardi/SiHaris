<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fingerprint_user_mappings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fingerprint_device_id')->constrained()->cascadeOnDelete();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('device_user_pin');
            $table->timestamps();

            $table->unique(['fingerprint_device_id', 'device_user_pin'], 'fp_mapping_device_pin_unique');
            $table->unique(['fingerprint_device_id', 'employee_id'], 'fp_mapping_device_employee_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fingerprint_user_mappings');
    }
};
