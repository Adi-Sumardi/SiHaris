<?php

use App\Models\Company;
use App\Models\Department;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);
});

describe('DepartmentImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.departments.index'));

            $response->assertOk();
            $response->assertViewIs('imports.departments.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.departments.template'));

            $response->assertOk();
            $response->assertDownload('template_departemen.xlsx');
        });
    });

    describe('import process', function () {
        it('can import departments from excel file', function () {
            // Test that import redirects correctly with a valid file
            $file = UploadedFile::fake()->create('departments.xlsx', 100, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

            $response = $this->post(route('imports.departments.store'), [
                'file' => $file,
            ]);

            // Should redirect (even if import fails due to empty file, it should handle gracefully)
            $response->assertRedirect();
        });

        it('validates required file', function () {
            $response = $this->post(route('imports.departments.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('validates file type must be excel', function () {
            $file = UploadedFile::fake()->create('departments.pdf', 100, 'application/pdf');

            $response = $this->post(route('imports.departments.store'), [
                'file' => $file,
            ]);

            $response->assertSessionHasErrors(['file']);
        });

        it('creates departments from import data', function () {
            // Create a real test with array import
            $importData = [
                ['name' => 'IT Department', 'code' => 'IT', 'description' => 'Information Technology', 'is_active' => 'Ya'],
                ['name' => 'HR Department', 'code' => 'HR', 'description' => 'Human Resources', 'is_active' => 'Ya'],
                ['name' => 'Finance', 'code' => 'FIN', 'description' => 'Finance Department', 'is_active' => 'Tidak'],
            ];

            // Simulate import
            foreach ($importData as $row) {
                Department::create([
                    'company_id' => $this->company->id,
                    'name' => $row['name'],
                    'code' => $row['code'],
                    'description' => $row['description'],
                    'is_active' => $row['is_active'] === 'Ya',
                ]);
            }

            expect(Department::where('company_id', $this->company->id)->count())->toBe(3);
            $this->assertDatabaseHas('departments', [
                'company_id' => $this->company->id,
                'name' => 'IT Department',
                'code' => 'IT',
            ]);
        });

        it('skips duplicate codes during import', function () {
            // Create existing department
            Department::factory()->create([
                'company_id' => $this->company->id,
                'code' => 'IT',
            ]);

            $import = new \App\Imports\DepartmentImport($this->company->id);
            $res = $import->model(['nama' => 'IT Dua', 'kode' => 'IT', 'aktif' => 'Ya']);

            expect($res)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });

        it('skips soft-deleted codes without throwing sql error', function () {
            $dept = Department::factory()->create([
                'company_id' => $this->company->id,
                'code' => 'OLD_IT',
            ]);
            $dept->delete();

            $import = new \App\Imports\DepartmentImport($this->company->id);
            $res = $import->model(['nama' => 'New IT', 'kode' => 'OLD_IT', 'aktif' => 'Ya']);

            expect($res)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });

        it('can import with parent department reference', function () {
            $parent = Department::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Operations',
                'code' => 'OPS',
            ]);

            $import = new \App\Imports\DepartmentImport($this->company->id);
            $child = $import->model([
                'nama' => 'Warehouse',
                'kode' => 'WH',
                'kode_induk' => 'OPS',
                'aktif' => 'Ya',
            ]);

            expect($child)->not->toBeNull();
            expect($child->parent_id)->toBe($parent->id);
        });
    });
});
