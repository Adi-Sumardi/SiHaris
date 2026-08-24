<?php

use App\Models\Company;
use App\Models\Department;
use App\Models\Position;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);

    // Create departments for position reference
    $this->itDepartment = Department::factory()->create([
        'company_id' => $this->company->id,
        'name' => 'IT Department',
        'code' => 'IT',
    ]);
});

describe('PositionImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.positions.index'));

            $response->assertOk();
            $response->assertViewIs('imports.positions.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.positions.template'));

            $response->assertOk();
            $response->assertDownload('template_jabatan.xlsx');
        });
    });

    describe('import process', function () {
        it('validates required file', function () {
            $response = $this->post(route('imports.positions.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('creates positions with department reference by code', function () {
            $import = new \App\Imports\PositionImport($this->company->id);
            $position = $import->model([
                'nama' => 'Software Engineer',
                'kode' => 'SE',
                'kode_departemen' => 'IT',
                'level' => 3,
                'gaji_pokok' => 10000000,
                'aktif' => 'Ya',
            ]);

            expect($position)->not->toBeNull();
            expect($position->department_id)->toBe($this->itDepartment->id);
            expect($position->code)->toBe('SE');
        });

        it('can import positions with salary formatting including indonesian decimals', function () {
            $import = new \App\Imports\PositionImport($this->company->id);

            $pos1 = $import->model([
                'nama' => 'Junior Developer',
                'kode' => 'JD',
                'kode_departemen' => 'IT',
                'level' => 1,
                'gaji_pokok' => 'Rp 5.000.000,00',
                'aktif' => 'Ya',
            ]);

            $pos2 = $import->model([
                'nama' => 'Senior Developer',
                'kode' => 'SD',
                'kode_departemen' => 'IT',
                'level' => 4,
                'gaji_pokok' => '15.000.000',
                'aktif' => 'Ya',
            ]);

            expect($pos1->base_salary)->toBe(5000000);
            expect($pos2->base_salary)->toBe(15000000);
        });

        it('skips soft-deleted positions without unique constraint error', function () {
            $pos = Position::factory()->create([
                'company_id' => $this->company->id,
                'department_id' => $this->itDepartment->id,
                'code' => 'OLD_POS',
            ]);
            $pos->delete();

            $import = new \App\Imports\PositionImport($this->company->id);
            $result = $import->model([
                'nama' => 'New Pos',
                'kode' => 'OLD_POS',
                'kode_departemen' => 'IT',
                'aktif' => 'Ya',
            ]);

            expect($result)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });

        it('allows importing same position code in different departments', function () {
            $hrDepartment = Department::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'HR Department',
                'code' => 'HR',
            ]);

            Position::factory()->create([
                'company_id' => $this->company->id,
                'department_id' => $this->itDepartment->id,
                'code' => 'MGR',
                'name' => 'IT Manager',
            ]);

            $import = new \App\Imports\PositionImport($this->company->id);
            $result = $import->model([
                'nama' => 'HR Manager',
                'kode' => 'MGR',
                'kode_departemen' => 'HR',
                'level' => 3,
                'gaji_pokok' => 12000000,
                'aktif' => 'Ya',
            ]);

            expect($result)->not->toBeNull();
            expect($result->department_id)->toBe($hrDepartment->id);
            expect($result->code)->toBe('MGR');
            expect($import->getSuccessCount())->toBe(1);
        });
    });
});
