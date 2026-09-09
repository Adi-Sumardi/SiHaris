<?php

use App\Models\Company;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    setPermissionsTeamId($this->company->id);
    Role::create(['name' => 'employee']);
});

describe('contacts:normalize', function () {
    it('normalizes punctuated phone numbers saved before the fix existed', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
        ]);
        $employee->newQuery()->where('id', $employee->id)->update(['phone' => '0812-9270 2075']);

        $this->artisan('contacts:normalize')->assertExitCode(0);

        expect($employee->fresh()->phone)->toBe('081292702075');
    });

    it('creates a login account for an employee whose email was saved without one', function () {
        $employee = Employee::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => null,
            'email' => 'newhire@company.com',
            'is_active' => true,
        ]);

        $this->artisan('contacts:normalize')->assertExitCode(0);

        $employee->refresh();
        expect($employee->user_id)->not->toBeNull();
        expect($employee->user->email)->toBe('newhire@company.com');
    });

    it('skips an employee whose email is already used by another account instead of crashing', function () {
        $existingUser = User::factory()->create([
            'company_id' => $this->company->id,
            'email' => 'shared@company.com',
        ]);
        Employee::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => $existingUser->id,
            'email' => 'shared@company.com',
        ]);

        $conflicting = Employee::factory()->create([
            'company_id' => $this->company->id,
            'user_id' => null,
            'email' => 'shared@company.com',
            'is_active' => true,
        ]);

        $this->artisan('contacts:normalize')->assertExitCode(0);

        expect($conflicting->fresh()->user_id)->toBeNull();
        expect(User::where('email', 'shared@company.com')->count())->toBe(1);
    });
});
