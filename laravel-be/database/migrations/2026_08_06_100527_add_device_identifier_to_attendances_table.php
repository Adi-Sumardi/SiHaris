<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->string('clock_in_app_device_id')->nullable()->after('clock_in_device_id');
            $table->string('clock_out_app_device_id')->nullable()->after('clock_out_device_id');
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropColumn(['clock_in_app_device_id', 'clock_out_app_device_id']);
        });
    }
};
