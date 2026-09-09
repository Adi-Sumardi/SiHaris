<?php

namespace App\Console\Commands;

use App\Models\Employee;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class NormalizeContactFieldsCommand extends Command
{
    protected $signature = 'contacts:normalize';

    protected $description = 'Backfill existing employee/user phone numbers into digit-only form, trim emails, and create login accounts for employees whose email was saved without one — so OTP login can find every eligible record.';

    public function handle(): int
    {
        $employeesFixed = 0;
        Employee::whereNotNull('phone')->orWhereNotNull('email')->chunkById(200, function ($employees) use (&$employeesFixed) {
            foreach ($employees as $employee) {
                $normalizedPhone = Employee::normalizePhone($employee->phone);
                $trimmedEmail = $employee->email !== null ? trim($employee->email) : null;

                if ($normalizedPhone !== $employee->phone || $trimmedEmail !== $employee->email) {
                    $employee->phone = $normalizedPhone;
                    $employee->email = $trimmedEmail;
                    $employee->saveQuietly();
                    $employeesFixed++;
                }
            }
        });

        $usersFixed = 0;
        User::whereNotNull('phone')->orWhereNotNull('email')->chunkById(200, function ($users) use (&$usersFixed) {
            foreach ($users as $user) {
                $normalizedPhone = Employee::normalizePhone($user->phone);
                $trimmedEmail = $user->email !== null ? trim($user->email) : null;

                if ($normalizedPhone !== $user->phone || $trimmedEmail !== $user->email) {
                    $user->phone = $normalizedPhone;
                    $user->email = $trimmedEmail;
                    $user->saveQuietly();
                    $usersFixed++;
                }
            }
        });

        $accountsCreated = 0;
        $skipped = [];
        Employee::whereNull('user_id')
            ->whereNotNull('email')
            ->where('is_active', true)
            ->chunkById(200, function ($employees) use (&$accountsCreated, &$skipped) {
                foreach ($employees as $employee) {
                    // Two employees sharing one email is a pre-existing data-entry
                    // mistake (not something safe to fix automatically — it would
                    // let two different people share one login/OTP identity), so
                    // skip and report it instead of creating a duplicate account.
                    if (User::withTrashed()->where('email', $employee->email)->exists()) {
                        $skipped[] = "#{$employee->id} {$employee->full_name} <{$employee->email}> — email already used by another account";

                        continue;
                    }

                    setPermissionsTeamId($employee->company_id);

                    $user = User::create([
                        'company_id' => $employee->company_id,
                        'name' => $employee->full_name,
                        'email' => $employee->email,
                        'phone' => $employee->phone,
                        'password' => Hash::make(Str::random(32)),
                        'is_active' => true,
                    ]);

                    $user->assignRole('employee');
                    $employee->user_id = $user->id;
                    $employee->saveQuietly();
                    $accountsCreated++;
                }
            });

        $this->info("Normalized {$employeesFixed} employee record(s), {$usersFixed} user record(s), and created {$accountsCreated} missing login account(s).");

        if ($skipped !== []) {
            $this->warn('Skipped '.count($skipped).' employee(s) with a conflicting email — fix these manually:');
            foreach ($skipped as $line) {
                $this->line("  - {$line}");
            }
        }

        return self::SUCCESS;
    }
}
