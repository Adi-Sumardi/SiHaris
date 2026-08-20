<?php

use App\Models\Company;
use App\Models\User;
use App\Models\WorkSchedule;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);
});

describe('WorkScheduleImport', function () {
    describe('import page', function () {
        it('displays the import page', function () {
            $response = $this->get(route('imports.work-schedules.index'));

            $response->assertOk();
            $response->assertViewIs('imports.work-schedules.index');
        });

        it('can download template', function () {
            $response = $this->get(route('imports.work-schedules.template'));

            $response->assertOk();
            $response->assertDownload('template_jadwal_kerja.xlsx');
        });
    });

    describe('import process', function () {
        it('validates required file', function () {
            $response = $this->post(route('imports.work-schedules.store'), []);

            $response->assertSessionHasErrors(['file']);
        });

        it('creates work schedules from import data', function () {
            $import = new \App\Imports\WorkScheduleImport($this->company->id);

            $pagi = $import->model([
                'nama' => 'Shift Pagi',
                'kode' => 'PAGI',
                'jam_masuk' => '08.00',
                'jam_keluar' => '17.00',
                'durasi_istirahat' => 60,
                'hari_kerja' => 'Senin, Selasa, Rabu, Kamis, Jumat',
                'toleransi_terlambat' => 15,
                'default' => 'Ya',
                'aktif' => 'Ya',
            ]);

            expect($pagi)->not->toBeNull();
            expect($pagi->start_time->format('H:i'))->toBe('08:00');
            expect($pagi->end_time->format('H:i'))->toBe('17:00');
            expect($pagi->working_hours)->toBe(8.0);
            expect($pagi->working_days)->toEqual([1, 2, 3, 4, 5]);
            expect($pagi->is_default)->toBeTrue();
        });

        it('parses working days correctly from various inputs', function () {
            $import = new \App\Imports\WorkScheduleImport($this->company->id);

            expect($import->parseWorkingDays('1,2,3,4,5,6'))->toEqual([1, 2, 3, 4, 5, 6]);
            expect($import->parseWorkingDays('Senin, Rabu, Jumat'))->toEqual([1, 3, 5]);
            expect($import->parseWorkingDays(''))->toEqual([1, 2, 3, 4, 5]);
        });

        it('skips soft-deleted work schedules without unique collision error', function () {
            $sched = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'code' => 'OLD_SCHED',
            ]);
            $sched->delete();

            $import = new \App\Imports\WorkScheduleImport($this->company->id);
            $res = $import->model([
                'nama' => 'New Sched',
                'kode' => 'OLD_SCHED',
                'jam_masuk' => '08:00',
                'jam_keluar' => '17:00',
                'aktif' => 'Ya',
            ]);

            expect($res)->toBeNull();
            expect($import->getSkipCount())->toBe(1);
        });
    });
});
