<?php

use App\Imports\LeaveRequestImport;
use App\Models\Company;
use App\Models\Employee;
use App\Models\LeaveBalance;
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

    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'employee_id' => 'EMP001',
        'pin' => 101,
        'nik' => '3175012345670001',
        'first_name' => 'John',
        'last_name' => 'Doe',
    ]);

    $this->leaveType = LeaveType::factory()->create([
        'company_id' => $this->company->id,
        'name' => 'Cuti Tahunan',
        'code' => 'CT',
    ]);
});

describe('LeaveRequestImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.leave-requests.index'));

            $response->assertOk();
            $response->assertViewIs('imports.leave-requests.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.leave-requests.template'));

            $response->assertOk();
            $response->assertDownload('template_data_cuti.xlsx');
        });
    });

    describe('import process', function () {
        it('validates required file', function () {
            $response = $this->post(route('imports.leave-requests.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('imports an approved leave request and deducts the leave balance', function () {
            LeaveBalance::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => $this->employee->id,
                'leave_type_id' => $this->leaveType->id,
                'year' => 2026,
                'entitled_days' => 12,
                'used_days' => 0,
            ]);

            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-04',
                'alasan' => 'Liburan keluarga',
                'status' => 'Disetujui',
            ]);

            expect($leave)->not->toBeNull();
            expect($leave->employee_id)->toBe($this->employee->id);
            expect($leave->leave_type_id)->toBe($this->leaveType->id);
            expect((float) $leave->total_days)->toBe(3.0);
            expect($leave->status)->toBe('approved');
            expect($leave->reason)->toBe('Liburan keluarga');
            expect($leave->request_number)->not->toBeEmpty();
            expect($import->getSuccessCount())->toBe(1);

            $balance = LeaveBalance::where('employee_id', $this->employee->id)
                ->where('leave_type_id', $this->leaveType->id)
                ->where('year', 2026)
                ->first();

            expect((float) $balance->used_days)->toBe(3.0);
        });

        it('defaults status to approved when the column is empty', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-02',
            ]);

            expect($leave)->not->toBeNull();
            expect($leave->status)->toBe('approved');
        });

        it('computes total_days from the date range when not provided', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-06',
            ]);

            expect((float) $leave->total_days)->toBe(5.0);
        });

        it('respects an explicit jumlah_hari column over the computed date range', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-06',
                'jumlah_hari' => 2,
            ]);

            expect((float) $leave->total_days)->toBe(2.0);
        });

        it('imports a half-day leave request', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-02',
                'setengah_hari' => 'Ya',
                'sesi_setengah_hari' => 'Siang',
            ]);

            expect($leave->is_half_day)->toBeTrue();
            expect($leave->half_day_type)->toBe('afternoon');
            expect((float) $leave->total_days)->toBe(0.5);
        });

        it('adds pending days to the balance for a pending status import', function () {
            LeaveBalance::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => $this->employee->id,
                'leave_type_id' => $this->leaveType->id,
                'year' => 2026,
            ]);

            $import = new LeaveRequestImport($this->company->id);
            $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-03',
                'status' => 'Menunggu',
            ]);

            $balance = LeaveBalance::where('employee_id', $this->employee->id)
                ->where('leave_type_id', $this->leaveType->id)
                ->where('year', 2026)
                ->first();

            expect((float) $balance->pending_days)->toBe(2.0);
            expect((float) $balance->used_days)->toBe(0.0);
        });

        it('does not touch the balance for a rejected status import', function () {
            LeaveBalance::factory()->create([
                'company_id' => $this->company->id,
                'employee_id' => $this->employee->id,
                'leave_type_id' => $this->leaveType->id,
                'year' => 2026,
            ]);

            $import = new LeaveRequestImport($this->company->id);
            $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-03',
                'status' => 'Ditolak',
            ]);

            $balance = LeaveBalance::where('employee_id', $this->employee->id)
                ->where('leave_type_id', $this->leaveType->id)
                ->where('year', 2026)
                ->first();

            expect((float) $balance->used_days)->toBe(0.0);
            expect((float) $balance->pending_days)->toBe(0.0);
        });

        it('resolves employee by NIK, PIN, or name', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => '3175012345670001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-02',
            ]);

            expect($leave)->not->toBeNull();
            expect($leave->employee_id)->toBe($this->employee->id);
        });

        it('resolves leave type by name when code does not match', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'Cuti Tahunan',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-02',
            ]);

            expect($leave)->not->toBeNull();
            expect($leave->leave_type_id)->toBe($this->leaveType->id);
        });

        it('skips row when employee is not found and records error', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'NON_EXISTENT_EMP',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-02',
            ]);

            expect($leave)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
            expect($import->getErrors()[0])->toContain('tidak ditemukan');
        });

        it('skips row when leave type is not found and records error', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'NON_EXISTENT_TYPE',
                'tanggal_mulai' => '2026-03-02',
                'tanggal_selesai' => '2026-03-02',
            ]);

            expect($leave)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
            expect($import->getErrors()[0])->toContain('Jenis cuti');
        });

        it('skips row when required dates are missing', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
            ]);

            expect($leave)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });

        it('skips row when end date is before start date', function () {
            $import = new LeaveRequestImport($this->company->id);
            $leave = $import->model([
                'id_karyawan' => 'EMP001',
                'jenis_cuti' => 'CT',
                'tanggal_mulai' => '2026-03-10',
                'tanggal_selesai' => '2026-03-05',
            ]);

            expect($leave)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });
    });
});
