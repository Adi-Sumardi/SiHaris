<?php

use App\Exports\Templates\PinImportTemplateExport;
use App\Imports\PinImport;
use App\Models\Company;
use App\Models\Employee;
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

describe('PinImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.pins.index'));

            $response->assertOk();
            $response->assertViewIs('imports.pins.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.pins.template'));

            $response->assertOk();
            $response->assertDownload('template_pin.xlsx');
        });

        it('has the expected headings in template export', function () {
            $export = new PinImportTemplateExport;

            expect($export->headings())->toBe(['ID Karyawan', 'Nama Karyawan', 'PIN Baru']);
        });
    });

    describe('row processing', function () {
        it('updates the matched employee pin and returns the model unsaved for the package to persist', function () {
            $employee = Employee::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => 'EMP001',
                'pin' => '100001',
            ]);

            $import = new PinImport($this->company->id);

            $result = $import->model([
                'id_karyawan' => 'EMP001',
                'nama_karyawan' => 'John Doe',
                'pin_baru' => '999999',
            ]);

            expect($result)->not->toBeNull();
            expect($result->is($employee))->toBeTrue();
            expect($result->pin)->toBe('999999');
            expect($import->getSuccessCount())->toBe(1);
        });

        it('handles a numeric PIN Baru value from Excel correctly', function () {
            Employee::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => 'EMP002',
                'pin' => '100002',
            ]);

            $import = new PinImport($this->company->id);

            $result = $import->model([
                'id_karyawan' => 'EMP002',
                'pin_baru' => 100200,
            ]);

            expect($result)->not->toBeNull();
            expect($result->pin)->toBe('100200');
        });

        it('skips and records an error when ID Karyawan is missing', function () {
            $import = new PinImport($this->company->id);

            $result = $import->model(['id_karyawan' => '', 'pin_baru' => '999999']);

            expect($result)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
            expect($import->getErrors()[0])->toContain('wajib diisi');
        });

        it('skips and records an error when PIN Baru is missing', function () {
            Employee::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => 'EMP003',
            ]);

            $import = new PinImport($this->company->id);

            $result = $import->model(['id_karyawan' => 'EMP003', 'pin_baru' => '']);

            expect($result)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });

        it('skips and records an error when the employee id is not found', function () {
            $import = new PinImport($this->company->id);

            $result = $import->model(['id_karyawan' => 'DOES-NOT-EXIST', 'pin_baru' => '999999']);

            expect($result)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
            expect($import->getErrors()[0])->toContain('tidak ditemukan');
        });

        it('does not match an employee belonging to another company', function () {
            $otherCompany = Company::factory()->create();
            Employee::factory()->create([
                'company_id' => $otherCompany->id,
                'employee_id' => 'EMP-OTHER',
            ]);

            $import = new PinImport($this->company->id);

            $result = $import->model(['id_karyawan' => 'EMP-OTHER', 'pin_baru' => '999999']);

            expect($result)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });

        it('skips a row whose pin already matches, with a clear message', function () {
            Employee::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => 'EMP004',
                'pin' => '100004',
            ]);

            $import = new PinImport($this->company->id);

            $result = $import->model(['id_karyawan' => 'EMP004', 'pin_baru' => '100004']);

            expect($result)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
            expect($import->getErrors()[0])->toContain('tidak ada perubahan');
        });

        it('skips a duplicate ID Karyawan appearing twice in the same file', function () {
            Employee::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => 'EMP005',
                'pin' => '100005',
            ]);

            $import = new PinImport($this->company->id);

            $first = $import->model(['id_karyawan' => 'EMP005', 'pin_baru' => '111111']);
            $second = $import->model(['id_karyawan' => 'emp005', 'pin_baru' => '222222']);

            expect($first)->not->toBeNull();
            expect($second)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
            expect($import->getErrors()[0])->toContain('duplikat');
        });
    });
});
