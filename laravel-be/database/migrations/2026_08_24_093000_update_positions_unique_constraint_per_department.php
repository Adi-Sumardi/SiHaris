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
        Schema::table('positions', function (Blueprint $table) {
            $table->dropUnique(['company_id', 'code']);
            $table->unique(['company_id', 'department_id', 'code'], 'positions_company_dept_code_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('positions', function (Blueprint $table) {
            $table->dropUnique('positions_company_dept_code_unique');
            $table->unique(['company_id', 'code']);
        });
    }
};
