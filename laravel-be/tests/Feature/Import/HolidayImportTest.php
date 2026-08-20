<?php

use App\Models\Company;
use App\Models\Holiday;
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

describe('HolidayImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.holidays.index'));

            $response->assertOk();
            $response->assertViewIs('imports.holidays.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.holidays.template'));

            $response->assertOk();
            $response->assertDownload('template_hari_libur.xlsx');
        });
    });

    describe('import process', function () {
        it('validates required file', function () {
            $response = $this->post(route('imports.holidays.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('creates holidays from import data', function () {
            $import = new \App\Imports\HolidayImport($this->company->id, $this->user->id);

            $h1 = $import->model([
                'nama' => 'Tahun Baru',
                'tanggal' => '2026-01-01',
                'jenis' => 'Nasional',
                'deskripsi' => 'Perayaan Tahun Baru',
                'berulang' => 'Ya',
                'aktif' => 'Ya',
            ]);

            $h2 = $import->model([
                'nama' => 'Cuti Bersama Lebaran',
                'tanggal' => '2026-03-31',
                'jenis' => 'Cuti Bersama',
                'deskripsi' => 'Cuti bersama',
                'berulang' => 'Tidak',
                'aktif' => 'Ya',
            ]);

            expect($h1)->not->toBeNull();
            expect($h1->type)->toBe('national');
            expect($h1->is_recurring)->toBeTrue();

            expect($h2)->not->toBeNull();
            expect($h2->type)->toBe('collective_leave');
            expect($h2->is_recurring)->toBeFalse();
        });

        it('handles type mapping from Indonesian text including cuti bersama', function () {
            $import = new \App\Imports\HolidayImport($this->company->id);

            expect($import->parseType('Nasional'))->toBe('national');
            expect($import->parseType('nasional'))->toBe('national');
            expect($import->parseType('Perusahaan'))->toBe('company');
            expect($import->parseType('Keagamaan'))->toBe('religious');
            expect($import->parseType('religious'))->toBe('religious');
            expect($import->parseType('Cuti Bersama'))->toBe('collective_leave');
            expect($import->parseType('cuti_bersama'))->toBe('collective_leave');
        });

        it('handles boolean fields from yes/no text', function () {
            $import = new \App\Imports\HolidayImport($this->company->id);

            $h = $import->model([
                'nama' => 'Test Holiday',
                'tanggal' => '2026-11-10',
                'aktif' => 'Ya',
                'berulang' => 'Tidak',
            ]);

            expect($h->is_active)->toBeTrue();
            expect($h->is_recurring)->toBeFalse();
        });

        it('skips duplicate dates for same company', function () {
            // Create existing holiday
            Holiday::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Existing Holiday',
                'date' => '2026-01-01',
            ]);

            $import = new \App\Imports\HolidayImport($this->company->id);
            $res = $import->model([
                'nama' => 'New Holiday',
                'tanggal' => '2026-01-01',
            ]);

            expect($res)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });

        it('skips soft-deleted holiday dates for same company', function () {
            $h = Holiday::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Deleted Holiday',
                'date' => '2026-02-02',
            ]);
            $h->delete();

            $import = new \App\Imports\HolidayImport($this->company->id);
            $res = $import->model([
                'nama' => 'Imported Holiday',
                'tanggal' => '2026-02-02',
            ]);

            expect($res)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });
    });
});
