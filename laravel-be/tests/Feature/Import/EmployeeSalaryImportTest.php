<?php

use App\Imports\EmployeeSalaryImport;
use App\Models\Company;
use App\Models\Employee;
use App\Models\EmployeeSalary;
use App\Models\SalaryComponent;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);

    // Create a default BASIC salary component
    $this->basicComponent = SalaryComponent::factory()->create([
        'company_id' => $this->company->id,
        'name' => 'Gaji Pokok',
        'code' => 'BASIC',
        'type' => 'earning',
        'category' => 'fixed',
        'calculation_type' => 'fixed',
    ]);

    // Create an employee
    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'employee_id' => 'EMP001',
        'pin' => 101,
        'nik' => '3175012345670001',
        'first_name' => 'John',
        'last_name' => 'Doe',
    ]);
});

describe('EmployeeSalaryImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.employee-salaries.index'));

            $response->assertOk();
            $response->assertViewIs('imports.employee-salaries.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.employee-salaries.template'));

            $response->assertOk();
            $response->assertDownload('template_gaji_karyawan.xlsx');
        });
    });

    describe('import process', function () {
        it('validates required file', function () {
            $response = $this->post(route('imports.employee-salaries.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('imports employee salary successfully and auto-creates BASIC component', function () {
            $import = new EmployeeSalaryImport($this->company->id);
            $salary = $import->model([
                'id_karyawan' => 'EMP001',
                'gaji_pokok' => 'Rp 10.000.000,00',
                'tanggal_berlaku' => '2026-01-01',
                'tanggal_berakhir' => '',
                'metode_pembayaran' => 'Transfer',
                'nama_bank' => 'BCA',
                'nomor_rekening' => '1234567890',
                'nama_rekening' => 'John Doe',
                'aktif' => 'Ya',
                'catatan' => 'Gaji pokok standar',
            ]);

            expect($salary)->not->toBeNull();
            expect($salary->employee_id)->toBe($this->employee->id);
            expect((float) $salary->basic_salary)->toBe(10000000.0);
            expect($salary->payment_method)->toBe('transfer');
            expect($salary->bank_name)->toBe('BCA');
            expect($salary->bank_account_number)->toBe('1234567890');
            expect($salary->is_active)->toBeTrue();
            expect($import->getSuccessCount())->toBe(1);

            // Verify BASIC component was created
            $this->assertDatabaseHas('employee_salary_components', [
                'employee_salary_id' => $salary->id,
                'salary_component_id' => $this->basicComponent->id,
                'amount' => 10000000,
            ]);

            // Verify employee base_salary and bank info updated
            $this->employee->refresh();
            expect((float) $this->employee->base_salary)->toBe(10000000.0);
            expect($this->employee->bank_name)->toBe('BCA');
            expect($this->employee->bank_account_number)->toBe('1234567890');
        });

        it('deactivates previous active salary when new active salary is imported', function () {
            $oldSalary = EmployeeSalary::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => $this->employee->id,
                'basic_salary' => 8000000,
                'is_active' => true,
            ]);

            $import = new EmployeeSalaryImport($this->company->id);
            $newSalary = $import->model([
                'id_karyawan' => 'EMP001',
                'gaji_pokok' => 12000000,
                'tanggal_berlaku' => '2026-06-01',
                'aktif' => 'Ya',
            ]);

            expect($newSalary)->not->toBeNull();
            expect($newSalary->is_active)->toBeTrue();

            $oldSalary->refresh();
            expect($oldSalary->is_active)->toBeFalse();
            expect($oldSalary->end_date?->format('Y-m-d'))->toBe('2026-06-01');
        });

        it('resolves employee by NIK, PIN, or name', function () {
            $empByNik = Employee::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => 'EMP_NIK_TEST',
                'nik' => '3201019999990001',
            ]);

            $import = new EmployeeSalaryImport($this->company->id);
            $salary = $import->model([
                'id_karyawan' => '3201019999990001',
                'gaji_pokok' => 7500000,
                'aktif' => 'Ya',
            ]);

            expect($salary)->not->toBeNull();
            expect($salary->employee_id)->toBe($empByNik->id);
        });

        it('skips row when employee is not found and records error', function () {
            $import = new EmployeeSalaryImport($this->company->id);
            $salary = $import->model([
                'id_karyawan' => 'NON_EXISTENT_EMP',
                'gaji_pokok' => 5000000,
            ]);

            expect($salary)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
            expect($import->getErrors())->toHaveCount(1);
            expect($import->getErrors()[0])->toContain('tidak ditemukan');
        });

        it('attaches additional salary components from dynamic columns', function () {
            $transportComp = SalaryComponent::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Tunjangan Transport',
                'code' => 'TJ_TRANS',
                'type' => 'earning',
            ]);

            $import = new EmployeeSalaryImport($this->company->id);
            $salary = $import->model([
                'id_karyawan' => 'EMP001',
                'gaji_pokok' => 10000000,
                'tj_trans' => '500.000',
                'aktif' => 'Ya',
            ]);

            expect($salary)->not->toBeNull();

            $this->assertDatabaseHas('employee_salary_components', [
                'employee_salary_id' => $salary->id,
                'salary_component_id' => $transportComp->id,
                'amount' => 500000,
            ]);
        });
    });
});
