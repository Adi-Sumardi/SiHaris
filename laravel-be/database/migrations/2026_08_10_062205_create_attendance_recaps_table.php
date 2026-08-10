<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * One row per employee per recap period. The unique constraint on
     * (employee_id, period_start, period_end) is what makes sending
     * idempotent — the scheduled command never sends the same period twice.
     */
    public function up(): void
    {
        Schema::create('attendance_recaps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->cascadeOnDelete();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('frequency');
            $table->date('period_start');
            $table->date('period_end');

            $table->unsignedSmallInteger('working_days')->default(0);
            $table->unsignedSmallInteger('present_days')->default(0);
            $table->unsignedSmallInteger('absent_days')->default(0);
            $table->unsignedSmallInteger('late_days')->default(0);
            $table->unsignedSmallInteger('leave_days')->default(0);
            $table->decimal('attendance_percentage', 5, 2)->default(0);

            $table->timestamp('whatsapp_sent_at')->nullable();
            $table->string('whatsapp_status')->nullable();
            $table->timestamp('email_sent_at')->nullable();
            $table->string('email_status')->nullable();

            $table->timestamps();

            $table->unique(['employee_id', 'period_start', 'period_end']);
            $table->index(['company_id', 'period_start']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_recaps');
    }
};
