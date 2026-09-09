<?php

namespace App\Console\Commands;

use App\Models\Employee;
use App\Models\User;
use Illuminate\Console\Command;

class NormalizeContactFieldsCommand extends Command
{
    protected $signature = 'contacts:normalize';

    protected $description = 'Backfill existing employee/user phone numbers into digit-only form and trim emails, so OTP login lookups can find records saved before normalization was added.';

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

        $this->info("Normalized {$employeesFixed} employee record(s) and {$usersFixed} user record(s).");

        return self::SUCCESS;
    }
}
