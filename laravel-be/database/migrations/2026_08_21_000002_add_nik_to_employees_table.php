<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            $table->string('nik', 50)->nullable()->after('pin');
            $table->index(['company_id', 'nik']);
        });

        // Copy existing identity_number to nik if present
        DB::table('employees')
            ->whereNotNull('identity_number')
            ->update(['nik' => DB::raw('identity_number')]);
    }

    public function down(): void
    {
        Schema::table('employees', function (Blueprint $table) {
            $table->dropIndex(['company_id', 'nik']);
            $table->dropColumn('nik');
        });
    }
};
