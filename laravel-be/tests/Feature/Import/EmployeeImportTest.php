<?php

use App\Imports\EmployeeImport;
use App\Models\Company;
use App\Models\Department;
use App\Models\Employee;
use App\Models\Position;
use App\Models\User;
use App\Models\WorkSchedule;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);

    // Create reference data
    $this->department = Department::factory()->create([
        'company_id' => $this->company->id,
        'name' => 'IT Department',
        'code' => 'IT',
    ]);

    $this->position = Position::factory()->create([
        'company_id' => $this->company->id,
        'department_id' => $this->department->id,
        'name' => 'Software Engineer',
        'code' => 'SE',
    ]);

    $this->workSchedule = WorkSchedule::factory()->create([
        'company_id' => $this->company->id,
        'name' => 'Shift Reguler',
        'code' => 'REG',
    ]);
});

describe('EmployeeImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.employees.index'));

            $response->assertOk();
            $response->assertViewIs('imports.employees.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.employees.template'));

            $response->assertOk();
            $response->assertDownload('template_karyawan.xlsx');
        });
    });

    describe('import process', function () {
        it('validates required file', function () {
            $response = $this->post(route('imports.employees.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('creates employees from import data', function () {
            $import = new EmployeeImport($this->company->id);

            $emp1 = $import->model([
                'nik' => 'EMP001',
                'nama_depan' => 'John',
                'nama_belakang' => 'Doe',
                'email' => 'john.doe@example.com',
                'telepon' => '081234567890',
                'jenis_kelamin' => 'laki-laki',
                'tanggal_lahir' => '1990-01-15',
                'tanggal_masuk' => '2023-01-01',
                'kode_departemen' => 'IT',
                'kode_jabatan' => 'SE',
                'kode_jadwal' => 'REG',
                'status_karyawan' => 'tetap',
                'gaji_pokok' => 'Rp 10.000.000,00',
            ]);

            expect($emp1)->not->toBeNull();
            expect($emp1->employee_id)->toBe('EMP001');
            expect($emp1->department_id)->toBe($this->department->id);
            expect($emp1->position_id)->toBe($this->position->id);
            expect($emp1->work_schedule_id)->toBe($this->workSchedule->id);
            expect($emp1->gender)->toBe('male');
            expect($emp1->employment_status)->toBe('permanent');
            expect($emp1->base_salary)->toBe(10000000);
        });

        it('falls back hire_date to today when empty and does not fail', function () {
            $import = new EmployeeImport($this->company->id);

            $emp = $import->model([
                'nik' => 'EMP_NO_HIRE',
                'nama_depan' => 'No',
                'nama_belakang' => 'HireDate',
                'tanggal_masuk' => '',
            ]);

            expect($emp)->not->toBeNull();
            expect($emp->hire_date->format('Y-m-d'))->toBe(now()->format('Y-m-d'));
        });

        it('skips soft-deleted employee NIK without database duplicate error', function () {
            $emp = Employee::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => 'EMP_OLD',
            ]);
            $emp->delete();

            $import = new EmployeeImport($this->company->id);
            $res = $import->model([
                'nik' => 'EMP_OLD',
                'nama_depan' => 'Revived',
            ]);

            expect($res)->toBeNull();
        });

        it('handles salary with Indonesian decimal format correctly', function () {
            $import = new EmployeeImport($this->company->id);

            expect($import->parseSalary('10.000.000,00'))->toBe(10000000);
            expect($import->parseSalary('Rp 7.500.000'))->toBe(7500000);
            expect($import->parseSalary('5,000,000.50'))->toBe(5000001);
            expect($import->parseSalary(''))->toBe(0);
        });

        it('parses date formats correctly', function () {
            $import = new EmployeeImport($this->company->id);

            expect($import->parseDate('1990-01-15'))->toBe('1990-01-15');
            expect($import->parseDate('15/01/1990'))->toBe('1990-01-15');
        });
    });

    describe('queued import', function () {
        it('initializes import with cache status', function () {
            $import = new EmployeeImport($this->company->id, 'test_import_123');
            $import->initializeImport();

            $status = EmployeeImport::getImportStatus('test_import_123');

            expect($status)->not->toBeNull();
            expect($status['status'])->toBe('processing');
            expect($status['success_count'])->toBe(0);
            expect($status['skip_count'])->toBe(0);
            expect($status['errors'])->toBe([]);
        });

        it('can check import status via API endpoint', function () {
            $importId = 'test_import_456';
            Cache::put("employee_import_{$importId}", [
                'status' => 'processing',
                'success_count' => 100,
                'skip_count' => 5,
                'errors' => ['NIK already exists'],
                'started_at' => now()->toDateTimeString(),
                'completed_at' => null,
            ], now()->addHours(24));

            $response = $this->getJson(route('imports.employees.status', $importId));

            $response->assertOk();
            $response->assertJson([
                'status' => 'processing',
                'success_count' => 100,
                'skip_count' => 5,
            ]);
        });

        it('returns 404 for non-existent import', function () {
            $response = $this->getJson(route('imports.employees.status', 'non_existent_id'));

            $response->assertNotFound();
            $response->assertJson([
                'status' => 'not_found',
            ]);
        });

        it('has correct chunk size', function () {
            $import = new EmployeeImport($this->company->id);

            expect($import->chunkSize())->toBe(200);
        });
    });
});
