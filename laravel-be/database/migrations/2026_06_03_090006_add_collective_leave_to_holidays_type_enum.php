<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Tambahkan nilai 'collective_leave' (Cuti Bersama) pada enum kolom type.
     */
    public function up(): void
    {
        // MODIFY COLUMN ... ENUM is MySQL-specific syntax. Other drivers
        // (sqlite in tests) enforce the enum via a CHECK constraint that
        // Schema::table(...)->change() knows how to rebuild instead.
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE holidays MODIFY COLUMN type ENUM('national', 'company', 'religious', 'collective_leave') NOT NULL DEFAULT 'national'");

            return;
        }

        Schema::table('holidays', function (Blueprint $table) {
            $table->enum('type', ['national', 'company', 'religious', 'collective_leave'])
                ->default('national')
                ->change();
        });
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement("UPDATE holidays SET type = 'national' WHERE type = 'collective_leave'");
            DB::statement("ALTER TABLE holidays MODIFY COLUMN type ENUM('national', 'company', 'religious') NOT NULL DEFAULT 'national'");

            return;
        }

        DB::table('holidays')->where('type', 'collective_leave')->update(['type' => 'national']);

        Schema::table('holidays', function (Blueprint $table) {
            $table->enum('type', ['national', 'company', 'religious'])
                ->default('national')
                ->change();
        });
    }
};
