<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->boolean('enable_attendance_recap')->default(false);
            $table->enum('attendance_recap_frequency', ['daily', 'weekly', 'monthly'])->default('weekly');
            $table->unsignedTinyInteger('attendance_recap_send_hour')->default(8);
            $table->unsignedTinyInteger('attendance_recap_day_of_week')->default(1); // ISO 1 (Monday) - 7 (Sunday), used when frequency=weekly
            $table->unsignedTinyInteger('attendance_recap_day_of_month')->default(1); // 1-28, used when frequency=monthly
            $table->boolean('attendance_recap_send_whatsapp')->default(true);
            $table->boolean('attendance_recap_send_email')->default(true);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->dropColumn([
                'enable_attendance_recap',
                'attendance_recap_frequency',
                'attendance_recap_send_hour',
                'attendance_recap_day_of_week',
                'attendance_recap_day_of_month',
                'attendance_recap_send_whatsapp',
                'attendance_recap_send_email',
            ]);
        });
    }
};
