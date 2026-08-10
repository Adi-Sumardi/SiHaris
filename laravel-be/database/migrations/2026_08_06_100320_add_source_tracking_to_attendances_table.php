<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->string('clock_in_source')->nullable()->after('clock_in');
            $table->string('clock_out_source')->nullable()->after('clock_out');
            $table->foreignId('clock_in_device_id')->nullable()->after('clock_in_source')
                ->constrained('fingerprint_devices')->nullOnDelete();
            $table->foreignId('clock_out_device_id')->nullable()->after('clock_out_source')
                ->constrained('fingerprint_devices')->nullOnDelete();
            $table->boolean('needs_review')->default(false)->after('admin_notes');
            $table->boolean('liveness_passed')->nullable()->after('face_confidence');
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropConstrainedForeignId('clock_in_device_id');
            $table->dropConstrainedForeignId('clock_out_device_id');
            $table->dropColumn(['clock_in_source', 'clock_out_source', 'needs_review', 'liveness_passed']);
        });
    }
};
