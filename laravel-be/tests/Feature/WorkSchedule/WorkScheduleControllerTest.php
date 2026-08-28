<?php

use App\Models\Company;
use App\Models\Employee;
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

describe('WorkScheduleController', function () {
    describe('index', function () {
        it('displays list of work schedules', function () {
            $schedules = WorkSchedule::factory()->count(3)->create([
                'company_id' => $this->company->id,
            ]);

            $response = $this->get(route('work-schedules.index'));

            $response->assertOk();
            $response->assertViewIs('work-schedules.index');
            $response->assertViewHas('workSchedules');
        });

        it('only shows work schedules belonging to current company', function () {
            $mySchedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'My Schedule',
            ]);

            $otherCompany = Company::factory()->create();
            $otherSchedule = WorkSchedule::factory()->create([
                'company_id' => $otherCompany->id,
                'name' => 'Other Schedule',
            ]);

            $response = $this->get(route('work-schedules.index'));

            $response->assertOk();
            $response->assertSee('My Schedule');
            $response->assertDontSee('Other Schedule');
        });

        it('can search work schedules by name', function () {
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Regular Office',
            ]);
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Night Shift',
            ]);

            $response = $this->get(route('work-schedules.index', ['search' => 'Regular']));

            $response->assertOk();
            $response->assertSee('Regular Office');
            // "Night Shift" may still appear in the bulk-assign modal's
            // schedule picker (which intentionally lists ALL schedules,
            // independent of the table's search filter) — assert against
            // the filtered table data itself instead of raw page text.
            expect($response->viewData('workSchedules')->pluck('name'))->not->toContain('Night Shift');
        });

        it('can filter by active status', function () {
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Active Schedule',
                'is_active' => true,
            ]);
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Inactive Schedule',
                'is_active' => false,
            ]);

            $response = $this->get(route('work-schedules.index', ['status' => 'active']));

            $response->assertOk();
            $response->assertSee('Active Schedule');
            $response->assertDontSee('Inactive Schedule');
        });
    });

    describe('create', function () {
        it('displays create work schedule form', function () {
            $response = $this->get(route('work-schedules.create'));

            $response->assertOk();
            $response->assertViewIs('work-schedules.create');
        });
    });

    describe('store', function () {
        it('creates a new work schedule', function () {
            $data = [
                'name' => 'Regular Office Hours',
                'code' => 'REG-01',
                'start_time' => '08:00',
                'end_time' => '17:00',
                'break_start' => '12:00',
                'break_end' => '13:00',
                'break_duration' => 60,
                'working_hours' => 8,
                'working_days' => [1, 2, 3, 4, 5],
                'late_tolerance' => 15,
                'early_leave_tolerance' => 15,
                'is_flexible' => false,
                'is_default' => false,
                'is_active' => true,
            ];

            $response = $this->post(route('work-schedules.store'), $data);

            $response->assertRedirect(route('work-schedules.index'));
            $this->assertDatabaseHas('work_schedules', [
                'company_id' => $this->company->id,
                'name' => 'Regular Office Hours',
                'code' => 'REG-01',
            ]);
        });

        it('validates required fields', function () {
            $response = $this->post(route('work-schedules.store'), []);

            $response->assertSessionHasErrors(['name', 'start_time', 'end_time']);
        });

        it('validates unique code within company', function () {
            WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'code' => 'REG-01',
            ]);

            $response = $this->post(route('work-schedules.store'), [
                'name' => 'New Schedule',
                'code' => 'REG-01',
                'start_time' => '08:00',
                'end_time' => '17:00',
            ]);

            $response->assertSessionHasErrors(['code']);
        });

        it('validates time format', function () {
            $response = $this->post(route('work-schedules.store'), [
                'name' => 'Test Schedule',
                'start_time' => 'invalid',
                'end_time' => 'invalid',
            ]);

            $response->assertSessionHasErrors(['start_time', 'end_time']);
        });

        it('sets only one schedule as default', function () {
            $existingDefault = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_default' => true,
            ]);

            $data = [
                'name' => 'New Default Schedule',
                'start_time' => '08:00',
                'end_time' => '17:00',
                'is_default' => true,
                'is_active' => true,
            ];

            $response = $this->post(route('work-schedules.store'), $data);

            $response->assertRedirect(route('work-schedules.index'));

            $existingDefault->refresh();
            expect($existingDefault->is_default)->toBeFalse();

            $this->assertDatabaseHas('work_schedules', [
                'name' => 'New Default Schedule',
                'is_default' => true,
            ]);
        });
    });

    describe('edit', function () {
        it('displays edit work schedule form', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
            ]);

            $response = $this->get(route('work-schedules.edit', $schedule));

            $response->assertOk();
            $response->assertViewIs('work-schedules.edit');
            $response->assertViewHas('workSchedule');
        });

        it('returns 404 for work schedule from another company', function () {
            $otherCompany = Company::factory()->create();
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $otherCompany->id,
            ]);

            $response = $this->get(route('work-schedules.edit', $schedule));

            $response->assertNotFound();
        });
    });

    describe('update', function () {
        it('updates work schedule', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'name' => 'Old Name',
            ]);

            $response = $this->put(route('work-schedules.update', $schedule), [
                'name' => 'New Name',
                'start_time' => '09:00',
                'end_time' => '18:00',
                'is_active' => true,
            ]);

            $response->assertRedirect(route('work-schedules.index'));
            $this->assertDatabaseHas('work_schedules', [
                'id' => $schedule->id,
                'name' => 'New Name',
            ]);
        });

        it('cannot update work schedule from another company', function () {
            $otherCompany = Company::factory()->create();
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $otherCompany->id,
            ]);

            $response = $this->put(route('work-schedules.update', $schedule), [
                'name' => 'Hacked Name',
                'start_time' => '08:00',
                'end_time' => '17:00',
            ]);

            $response->assertNotFound();
        });

        it('resets other default when setting as default', function () {
            $existingDefault = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_default' => true,
            ]);

            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_default' => false,
            ]);

            $response = $this->put(route('work-schedules.update', $schedule), [
                'name' => $schedule->name,
                'start_time' => '08:00',
                'end_time' => '17:00',
                'is_default' => true,
                'is_active' => true,
            ]);

            $response->assertRedirect(route('work-schedules.index'));

            $existingDefault->refresh();
            expect($existingDefault->is_default)->toBeFalse();
        });
    });

    describe('destroy', function () {
        it('deletes work schedule without employees', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
            ]);

            $response = $this->delete(route('work-schedules.destroy', $schedule));

            $response->assertRedirect(route('work-schedules.index'));
            $this->assertSoftDeleted('work_schedules', ['id' => $schedule->id]);
        });

        it('cannot delete work schedule with employees assigned', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
            ]);

            Employee::factory()->create([
                'company_id' => $this->company->id,
                'work_schedule_id' => $schedule->id,
            ]);

            $response = $this->delete(route('work-schedules.destroy', $schedule));

            $response->assertRedirect();
            $response->assertSessionHas('error');
            $this->assertDatabaseHas('work_schedules', ['id' => $schedule->id]);
        });

        it('cannot delete default work schedule', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
                'is_default' => true,
            ]);

            $response = $this->delete(route('work-schedules.destroy', $schedule));

            $response->assertRedirect();
            $response->assertSessionHas('error');
            $this->assertDatabaseHas('work_schedules', ['id' => $schedule->id]);
        });

        it('cannot delete work schedule from another company', function () {
            $otherCompany = Company::factory()->create();
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $otherCompany->id,
            ]);

            $response = $this->delete(route('work-schedules.destroy', $schedule));

            $response->assertNotFound();
        });
    });

    describe('show', function () {
        it('displays work schedule details', function () {
            $schedule = WorkSchedule::factory()->create([
                'company_id' => $this->company->id,
            ]);

            $response = $this->get(route('work-schedules.show', $schedule));

            $response->assertOk();
            $response->assertViewIs('work-schedules.show');
            $response->assertViewHas('workSchedule');
        });
    });

    describe('bulkAssign', function () {
        it('assigns the schedule to all employees when target_type is all', function () {
            $schedule = WorkSchedule::factory()->create(['company_id' => $this->company->id]);
            $employees = Employee::factory()->count(3)->create(['company_id' => $this->company->id]);

            $response = $this->post(route('work-schedules.bulk-assign'), [
                'work_schedule_id' => $schedule->id,
                'target_type' => 'all',
            ]);

            $response->assertRedirect(route('work-schedules.index'));
            $response->assertSessionHas('success');

            foreach ($employees as $employee) {
                $this->assertDatabaseHas('employees', [
                    'id' => $employee->id,
                    'work_schedule_id' => $schedule->id,
                ]);
            }
        });

        it('assigns the schedule only to employees in the selected department', function () {
            $schedule = WorkSchedule::factory()->create(['company_id' => $this->company->id]);
            $department = \App\Models\Department::factory()->create(['company_id' => $this->company->id]);
            $otherDepartment = \App\Models\Department::factory()->create(['company_id' => $this->company->id]);

            $inDepartment = Employee::factory()->create([
                'company_id' => $this->company->id,
                'department_id' => $department->id,
            ]);
            $outsideDepartment = Employee::factory()->create([
                'company_id' => $this->company->id,
                'department_id' => $otherDepartment->id,
            ]);

            $response = $this->post(route('work-schedules.bulk-assign'), [
                'work_schedule_id' => $schedule->id,
                'target_type' => 'department',
                'department_id' => $department->id,
            ]);

            $response->assertRedirect(route('work-schedules.index'));

            $this->assertDatabaseHas('employees', [
                'id' => $inDepartment->id,
                'work_schedule_id' => $schedule->id,
            ]);
            $this->assertDatabaseMissing('employees', [
                'id' => $outsideDepartment->id,
                'work_schedule_id' => $schedule->id,
            ]);
        });

        it('assigns the schedule only to employees in the selected position', function () {
            $schedule = WorkSchedule::factory()->create(['company_id' => $this->company->id]);
            $position = \App\Models\Position::factory()->create(['company_id' => $this->company->id]);
            $otherPosition = \App\Models\Position::factory()->create(['company_id' => $this->company->id]);

            $inPosition = Employee::factory()->create([
                'company_id' => $this->company->id,
                'position_id' => $position->id,
            ]);
            $outsidePosition = Employee::factory()->create([
                'company_id' => $this->company->id,
                'position_id' => $otherPosition->id,
            ]);

            $response = $this->post(route('work-schedules.bulk-assign'), [
                'work_schedule_id' => $schedule->id,
                'target_type' => 'position',
                'position_id' => $position->id,
            ]);

            $response->assertRedirect(route('work-schedules.index'));

            $this->assertDatabaseHas('employees', [
                'id' => $inPosition->id,
                'work_schedule_id' => $schedule->id,
            ]);
            $this->assertDatabaseMissing('employees', [
                'id' => $outsidePosition->id,
                'work_schedule_id' => $schedule->id,
            ]);
        });

        it('clears weekly schedule overrides for assigned employees', function () {
            $schedule = WorkSchedule::factory()->create(['company_id' => $this->company->id]);
            $employee = Employee::factory()->create(['company_id' => $this->company->id]);

            \App\Models\EmployeeWeeklySchedule::factory()->forDay(1)->create([
                'company_id' => $this->company->id,
                'employee_id' => $employee->id,
            ]);

            $this->post(route('work-schedules.bulk-assign'), [
                'work_schedule_id' => $schedule->id,
                'target_type' => 'all',
            ]);

            $this->assertDatabaseMissing('employee_weekly_schedules', [
                'employee_id' => $employee->id,
            ]);
        });

        it('requires department_id when target_type is department', function () {
            $schedule = WorkSchedule::factory()->create(['company_id' => $this->company->id]);

            $response = $this->post(route('work-schedules.bulk-assign'), [
                'work_schedule_id' => $schedule->id,
                'target_type' => 'department',
            ]);

            $response->assertSessionHasErrors('department_id');
        });

        it('requires position_id when target_type is position', function () {
            $schedule = WorkSchedule::factory()->create(['company_id' => $this->company->id]);

            $response = $this->post(route('work-schedules.bulk-assign'), [
                'work_schedule_id' => $schedule->id,
                'target_type' => 'position',
            ]);

            $response->assertSessionHasErrors('position_id');
        });

        it('rejects a work schedule belonging to another company', function () {
            $otherCompany = Company::factory()->create();
            $otherSchedule = WorkSchedule::factory()->create(['company_id' => $otherCompany->id]);

            $response = $this->post(route('work-schedules.bulk-assign'), [
                'work_schedule_id' => $otherSchedule->id,
                'target_type' => 'all',
            ]);

            $response->assertSessionHasErrors('work_schedule_id');
        });

        it('shows an error and does not fail when no employees match the target', function () {
            $schedule = WorkSchedule::factory()->create(['company_id' => $this->company->id]);
            $emptyDepartment = \App\Models\Department::factory()->create(['company_id' => $this->company->id]);

            $response = $this->post(route('work-schedules.bulk-assign'), [
                'work_schedule_id' => $schedule->id,
                'target_type' => 'department',
                'department_id' => $emptyDepartment->id,
            ]);

            $response->assertRedirect(route('work-schedules.index'));
            $response->assertSessionHas('error');
        });
    });
});
