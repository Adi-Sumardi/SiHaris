<?php

use App\Exports\Templates\EmployeeTemplateExport;
use App\Imports\EmployeeImport;
use App\Models\Company;
use App\Models\Department;
use App\Models\Employee;
use App\Models\OfficeLocation;
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

    $this->officeLocation = OfficeLocation::factory()->create([
        'company_id' => $this->company->id,
        'name' => 'Head Office',
        'code' => 'HO',
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

        it('has expected headings in template export', function () {
            $export = new EmployeeTemplateExport;
            $headings = $export->headings();

            expect($headings)->toContain('ID Karyawan')
                ->toContain('PIN')
                ->toContain('Nama Depan')
                ->toContain('Nama Belakang')
                ->toContain('NIK (No KTP)')
                ->toContain('Kode Departemen')
                ->toContain('Kode Jabatan')
                ->toContain('Kode Jadwal')
                ->toContain('NIK Manajer')
                ->toContain('Kode Lokasi Kantor')
                ->toContain('Aktif');
        });
    });

    describe('import process', function () {
        it('validates required file', function () {
            $response = $this->post(route('imports.employees.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('creates employees with distinct ID Karyawan, PIN, and NIK KTP from import data', function () {
            $import = new EmployeeImport($this->company->id);

            $emp1 = $import->model([
                'id_karyawan' => 'EMP001',
                'pin' => '101',
                'nik_no_ktp' => '3175012345670001',
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
            expect($emp1->pin)->toBe('101');
            expect($emp1->nik)->toBe('3175012345670001');
            expect($emp1->identity_number)->toBe('3175012345670001');
            expect($emp1->department_id)->toBe($this->department->id);
            expect($emp1->position_id)->toBe($this->position->id);
            expect($emp1->work_schedule_id)->toBe($this->workSchedule->id);
            expect($emp1->gender)->toBe('male');
            expect($emp1->employment_status)->toBe('permanent');
            expect($emp1->base_salary)->toBe(10000000);
        });

        it('handles numeric ID Karyawan, PIN, NIK KTP, and phone from Excel correctly', function () {
            $import = new EmployeeImport($this->company->id);

            $emp = $import->model([
                'id_karyawan' => 1001,
                'pin' => 123,
                'nik_no_ktp' => 1234567890123456,
                'nama_depan' => 'Numeric',
                'nama_belakang' => 'Test',
                'telepon' => 81234567890,
            ]);

            expect($emp)->not->toBeNull();
            expect($emp->employee_id)->toBe('1001');
            expect($emp->pin)->toBe('123');
            expect($emp->nik)->toBe('1234567890123456');
            expect($emp->identity_number)->toBe('1234567890123456');
            expect($emp->phone)->toBe('81234567890');
        });

        it('matches department, position, schedule case-insensitively and by name', function () {
            $import = new EmployeeImport($this->company->id);

            // Lowercase codes
            $emp1 = $import->model([
                'nik' => 'EMP_CASE_1',
                'nama_depan' => 'Case',
                'nama_belakang' => 'Test',
                'kode_departemen' => 'it',
                'kode_jabatan' => 'se',
                'kode_jadwal' => 'reg',
            ]);

            expect($emp1)->not->toBeNull();
            expect($emp1->department_id)->toBe($this->department->id);
            expect($emp1->position_id)->toBe($this->position->id);
            expect($emp1->work_schedule_id)->toBe($this->workSchedule->id);

            // Names instead of codes
            $emp2 = $import->model([
                'nik' => 'EMP_NAME_1',
                'nama_depan' => 'Name',
                'nama_belakang' => 'Test',
                'kode_departemen' => 'IT Department',
                'kode_jabatan' => 'Software Engineer',
                'kode_jadwal' => 'Shift Reguler',
            ]);

            expect($emp2)->not->toBeNull();
            expect($emp2->department_id)->toBe($this->department->id);
            expect($emp2->position_id)->toBe($this->position->id);
            expect($emp2->work_schedule_id)->toBe($this->workSchedule->id);
        });

        it('resolves position scoped by department when same position code exists in multiple departments', function () {
            $hrDept = Department::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'HR Department',
                'code' => 'HR',
            ]);

            $itStaff = Position::factory()->create([
                'company_id' => $this->company->id,
                'department_id' => $this->department->id,
                'name' => 'Staff',
                'code' => 'STF',
            ]);

            $hrStaff = Position::factory()->create([
                'company_id' => $this->company->id,
                'department_id' => $hrDept->id,
                'name' => 'Staff',
                'code' => 'STF',
            ]);

            $import = new EmployeeImport($this->company->id);

            $emp = $import->model([
                'id_karyawan' => 'EMP_HR_1',
                'nama_depan' => 'Jane',
                'kode_departemen' => 'HR',
                'kode_jabatan' => 'STF',
            ]);

            expect($emp)->not->toBeNull();
            expect($emp->department_id)->toBe($hrDept->id);
            expect($emp->position_id)->toBe($hrStaff->id);
        });

        it('resolves manager by NIK', function () {
            $manager = Employee::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => 'MGR001',
                'first_name' => 'Boss',
            ]);

            $import = new EmployeeImport($this->company->id);

            $emp = $import->model([
                'nik' => 'EMP_SUB_1',
                'nama_depan' => 'Staff',
                'nik_manajer' => 'MGR001',
            ]);

            expect($emp)->not->toBeNull();
            expect($emp->manager_id)->toBe($manager->id);
        });

        it('attaches office location via pending queue', function () {
            $import = new EmployeeImport($this->company->id);

            $emp = $import->model([
                'nik' => 'EMP_OFFICE_1',
                'nama_depan' => 'Office',
                'kode_lokasi_kantor' => 'HO',
            ]);

            expect($emp)->not->toBeNull();
            $emp->save();

            $import->attachPendingOfficeLocations();

            $savedEmp = Employee::where('employee_id', 'EMP_OFFICE_1')->first();
            expect($savedEmp->officeLocations)->toHaveCount(1);
            expect($savedEmp->officeLocations->first()->id)->toBe($this->officeLocation->id);
        });

        it('splits full name when nama_depan is missing', function () {
            $import = new EmployeeImport($this->company->id);

            $emp = $import->model([
                'nik' => 'EMP_FULLNAME',
                'nama' => 'Budi Santoso Sudirman',
            ]);

            expect($emp)->not->toBeNull();
            expect($emp->first_name)->toBe('Budi');
            expect($emp->last_name)->toBe('Santoso Sudirman');
        });

        it('skips duplicate NIK in the same import file', function () {
            $import = new EmployeeImport($this->company->id);

            $emp1 = $import->model([
                'nik' => 'EMP_DUP',
                'nama_depan' => 'First',
            ]);

            $emp2 = $import->model([
                'nik' => 'EMP_DUP',
                'nama_depan' => 'Second',
            ]);

            expect($emp1)->not->toBeNull();
            expect($emp2)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });

        it('parses Indonesian marital status variations', function () {
            $import = new EmployeeImport($this->company->id);

            expect($import->parseMaritalStatus('Belum Kawin'))->toBe('single');
            expect($import->parseMaritalStatus('Belum Menikah'))->toBe('single');
            expect($import->parseMaritalStatus('Kawin'))->toBe('married');
            expect($import->parseMaritalStatus('Menikah'))->toBe('married');
            expect($import->parseMaritalStatus('Cerai Hidup'))->toBe('divorced');
            expect($import->parseMaritalStatus('Cerai Mati'))->toBe('widowed');
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
            expect($import->parseDate('15.01.1990'))->toBe('1990-01-15');
        });
    });

    describe('status and tracking', function () {
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

