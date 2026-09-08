<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('reimbursements', function (Blueprint $table) {
            $table->foreignId('approval_workflow_id')->nullable()->after('status')->constrained()->nullOnDelete();
            $table->integer('current_approval_step')->nullable()->after('approval_workflow_id');
            $table->text('approval_notes')->nullable()->after('approved_at');
            $table->foreignId('rejected_by')->nullable()->after('rejection_reason')->constrained('users')->nullOnDelete();
            $table->datetime('rejected_at')->nullable()->after('rejected_by');
        });
    }

    public function down(): void
    {
        Schema::table('reimbursements', function (Blueprint $table) {
            $table->dropConstrainedForeignId('approval_workflow_id');
            $table->dropColumn('current_approval_step');
            $table->dropColumn('approval_notes');
            $table->dropConstrainedForeignId('rejected_by');
            $table->dropColumn('rejected_at');
        });
    }
};
