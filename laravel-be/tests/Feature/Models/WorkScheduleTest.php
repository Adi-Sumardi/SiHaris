<?php

use App\Models\Company;
use App\Models\WorkSchedule;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('WorkSchedule Model', function () {
    beforeEach(function () {
        $this->company = Company::factory()->create();
    });

    describe('factory', function () {
        it('can create work schedule using factory', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
            ]);

            expect($schedule)->toBeInstanceOf(WorkSchedule::class);
            expect($schedule->company_id)->toBe($this->company->id);
        });

        it('can create morning shift', function () {
            $schedule = WorkSchedule::factory()->morning()->create([
                'company_id' => $this->company->id,
            ]);

            expect($schedule->name)->toBe('Shift Pagi');
            expect($schedule->start_time->format('H:i'))->toBe('06:00');
            expect($schedule->end_time->format('H:i'))->toBe('14:00');
        });

        it('can create afternoon shift', function () {
            $schedule = WorkSchedule::factory()->afternoon()->create([
                'company_id' => $this->company->id,
            ]);

            expect($schedule->name)->toBe('Shift Siang');
            expect($schedule->start_time->format('H:i'))->toBe('14:00');
            expect($schedule->end_time->format('H:i'))->toBe('22:00');
        });

        it('can create night shift', function () {
            $schedule = WorkSchedule::factory()->night()->create([
                'company_id' => $this->company->id,
            ]);

            expect($schedule->name)->toBe('Shift Malam');
            expect($schedule->start_time->format('H:i'))->toBe('22:00');
            expect($schedule->end_time->format('H:i'))->toBe('06:00');
        });

        it('can create flexible schedule', function () {
            $schedule = WorkSchedule::factory()->flexible()->create([
                'company_id' => $this->company->id,
            ]);

            expect($schedule->name)->toBe('Flexible');
            expect($schedule->is_flexible)->toBeTrue();
            expect($schedule->late_tolerance)->toBe(60);
        });
    });

    describe('relationships', function () {
        it('belongs to a company', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
            ]);

            expect($schedule->company)->toBeInstanceOf(Company::class);
            expect($schedule->company->id)->toBe($this->company->id);
        });
    });

    describe('scopes', function () {
        it('can filter active schedules', function () {
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_active' => true,
            ]);
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_active' => false,
            ]);

            $activeSchedules = WorkSchedule::active()->get();

            expect($activeSchedules)->toHaveCount(1);
            expect($activeSchedules->first()->is_active)->toBeTrue();
        });

        it('can filter default schedule', function () {
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_default' => true,
            ]);
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_default' => false,
            ]);

            $defaultSchedules = WorkSchedule::default()->get();

            expect($defaultSchedules)->toHaveCount(1);
            expect($defaultSchedules->first()->is_default)->toBeTrue();
        });
    });

    describe('accessors', function () {
        it('returns formatted working hours', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'start_time' => '08:00',
                'end_time' => '17:00',
            ]);

            expect($schedule->formatted_working_hours)->toBe('08:00 - 17:00');
        });

        it('returns working days text', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'working_days' => [1, 2, 3, 4, 5],
            ]);

            expect($schedule->working_days_text)->toBe('Senin, Selasa, Rabu, Kamis, Jumat');
        });
    });

    describe('methods', function () {
        it('can check if day is working day', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'working_days' => [1, 2, 3, 4, 5], // Mon-Fri
            ]);

            expect($schedule->isWorkingDay(1))->toBeTrue(); // Monday
            expect($schedule->isWorkingDay(6))->toBeFalse(); // Saturday
            expect($schedule->isWorkingDay(7))->toBeFalse(); // Sunday
        });

        it('can detect late clock in', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'start_time' => '08:00',
                'late_tolerance' => 15,
            ]);

            $onTime = Carbon::today()->setTime(8, 10, 0);
            $late = Carbon::today()->setTime(8, 20, 0);

            expect($schedule->isLate($onTime))->toBeFalse();
            expect($schedule->isLate($late))->toBeTrue();
        });

        it('calculates late minutes correctly', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'start_time' => '08:00',
            ]);

            $clockIn = Carbon::today()->setTime(8, 30, 0);

            expect($schedule->getLateMinutes($clockIn))->toBe(30);
        });

        it('returns zero late minutes when on time', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'start_time' => '08:00',
            ]);

            $clockIn = Carbon::today()->setTime(7, 55, 0);

            expect($schedule->getLateMinutes($clockIn))->toBe(0);
        });

        it('calculates flexi minutes and shifts scheduled end correctly', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'start_time' => '07:00',
                'end_time' => '16:00',
                'late_tolerance' => 60,
                'early_leave_tolerance' => 5,
                'is_flexible' => true,
            ]);

            $shiftDate = Carbon::parse('2026-08-26');
            $clockInOnTime = Carbon::parse('2026-08-26 07:00');
            $clockInFlexi = Carbon::parse('2026-08-26 07:25'); // 25 mins flexi
            $clockInPastTolerance = Carbon::parse('2026-08-26 08:15'); // 75 mins late, capped at 60

            expect($schedule->getFlexiMinutes($clockInOnTime, $shiftDate))->toBe(0);
            expect($schedule->getFlexiMinutes($clockInFlexi, $shiftDate))->toBe(25);
            expect($schedule->getFlexiMinutes($clockInPastTolerance, $shiftDate))->toBe(60);

            // Dynamic scheduled end
            expect($schedule->getScheduledEnd($shiftDate, $clockInOnTime)->format('H:i'))->toBe('16:00');
            expect($schedule->getScheduledEnd($shiftDate, $clockInFlexi)->format('H:i'))->toBe('16:25');
            expect($schedule->getScheduledEnd($shiftDate, $clockInPastTolerance)->format('H:i'))->toBe('17:00');

            // Early leave evaluation with dynamic clockIn (arrived at 07:25 -> target 16:25)
            $clockOutAt1600 = Carbon::parse('2026-08-26 16:00'); // Early by 25 mins
            $clockOutAt1622 = Carbon::parse('2026-08-26 16:22'); // Within 5 min tolerance (16:20-16:25)
            $clockOutAt1625 = Carbon::parse('2026-08-26 16:25'); // Exactly on time
            $clockOutAt1645 = Carbon::parse('2026-08-26 16:45'); // Overtime 20 mins

            expect($schedule->isEarlyLeave($clockOutAt1600, $shiftDate, $clockInFlexi))->toBeTrue();
            expect($schedule->getEarlyLeaveMinutes($clockOutAt1600, $shiftDate, $clockInFlexi))->toBe(25);

            expect($schedule->isEarlyLeave($clockOutAt1622, $shiftDate, $clockInFlexi))->toBeFalse();
            expect($schedule->getEarlyLeaveMinutes($clockOutAt1622, $shiftDate, $clockInFlexi))->toBe(3); // 3 mins before 16:25

            expect($schedule->isEarlyLeave($clockOutAt1625, $shiftDate, $clockInFlexi))->toBeFalse();
            expect($schedule->getEarlyLeaveMinutes($clockOutAt1625, $shiftDate, $clockInFlexi))->toBe(0);

            expect($schedule->getOvertimeMinutes($clockOutAt1645, $shiftDate, $clockInFlexi))->toBe(20);
        });
    });

    describe('casts', function () {
        it('casts working_days to array', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'working_days' => [1, 2, 3, 4, 5],
            ]);

            expect($schedule->working_days)->toBeArray();
            expect($schedule->working_days)->toContain(1, 2, 3, 4, 5);
        });

        it('casts boolean fields correctly', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_flexible' => true,
                'is_default' => false,
                'is_active' => true,
            ]);

            expect($schedule->is_flexible)->toBeTrue();
            expect($schedule->is_default)->toBeFalse();
            expect($schedule->is_active)->toBeTrue();
        });
    });
});
