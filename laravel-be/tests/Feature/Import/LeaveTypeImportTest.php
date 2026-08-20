<?php

use App\Models\Company;
use App\Models\LeaveType;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);
});

describe('LeaveTypeImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.leave-types.index'));

            $response->assertOk();
            $response->assertViewIs('imports.leave-types.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.leave-types.template'));

            $response->assertOk();
            $response->assertDownload('template_jenis_cuti.xlsx');
        });
    });

    describe('import process', function () {
        it('validates required file', function () {
            $response = $this->post(route('imports.leave-types.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('creates leave types from import data', function () {
            $import = new \App\Imports\LeaveTypeImport($this->company->id);

            $lt1 = $import->model([
                'nama' => 'Cuti Tahunan',
                'kode' => 'CT',
                'jatah_hari' => '12',
                'berbayar' => 'Ya',
                'perlu_persetujuan' => 'Ya',
                'tahunan' => 'Ya',
                'warna' => '',
                'maksimal_hari_berturut' => '',
                'aktif' => 'Ya',
            ]);

            expect($lt1)->not->toBeNull();
            expect($lt1->default_days)->toBe(12);
            expect($lt1->max_consecutive_days)->toBeNull();
            expect($lt1->color)->toBe('primary');
            expect($lt1->is_annual)->toBeTrue();
        });

        it('handles boolean fields and empty integer sanitization', function () {
            $import = new \App\Imports\LeaveTypeImport($this->company->id);

            $lt = $import->model([
                'nama' => 'Izin Tanpa Gaji',
                'kode' => 'ITG',
                'jatah_hari' => 0,
                'berbayar' => 'Tidak',
                'perlu_persetujuan' => 'Ya',
                'perlu_lampiran' => 'Tidak',
                'maksimal_hari_dibawa' => '',
                'warna' => 'secondary',
            ]);

            expect($lt)->not->toBeNull();
            expect($lt->is_paid)->toBeFalse();
            expect($lt->max_carry_forward_days)->toBeNull();
            expect($lt->color)->toBe('secondary');
        });

        it('skips soft-deleted leave types without unique error', function () {
            $lt = LeaveType::factory()->create([
                'company_id' => $this->company->id,
                'code' => 'OLD_LEAVE',
            ]);
            $lt->delete();

            $import = new \App\Imports\LeaveTypeImport($this->company->id);
            $res = $import->model([
                'nama' => 'New Leave',
                'kode' => 'OLD_LEAVE',
            ]);

            expect($res)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });
    });
});
