<?php

namespace Database\Seeders;

use App\Models\Company;
use App\Models\Department;
use App\Models\Employee;
use App\Models\EmployeeSalary;
use App\Models\OfficeLocation;
use App\Models\Position;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

/**
 * Seeder perusahaan YAPI beserta struktur organisasi dan karyawannya.
 *
 * Idempoten — aman dijalankan berulang. Setiap karyawan memiliki akun user
 * (password: "password") sehingga dapat login melalui aplikasi mobile.
 *
 * Jalankan: php artisan db:seed --class=YapiCompanySeeder
 * (pastikan RolePermissionSeeder sudah dijalankan agar permission tersedia)
 */
class YapiCompanySeeder extends Seeder
{
    /**
     * Koordinat kantor dari Plus Code "RV3M+QJ Rawamangun" (area Jl. Sunan Giri,
     * Rawamangun, Pulo Gadung, Jakarta Timur). Sesuaikan bila perlu lebih presisi.
     */
    private const OFFICE_LAT = -6.1939;

    private const OFFICE_LNG = 106.8806;

    private const ADDRESS = 'Jl. Sunan Giri No.1, RT.12/RW.15, Rawamangun, Kec. Pulo Gadung, Kota Jakarta Timur, Daerah Khusus Ibukota Jakarta 13220';

    private Company $company;

    /** @var array<string, Department> */
    private array $departments = [];

    /** @var array<string, Position> */
    private array $positions = [];

    public function run(): void
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $this->company = Company::updateOrCreate(
            ['name' => 'YAPI'],
            [
                'slug' => 'yapi',
                'email' => 'info@yapi.test',
                'phone' => '021-47865432',
                'address' => self::ADDRESS,
                'website' => 'https://yapi.test',
                'npwp' => '01.234.567.8-077.000',
                'timezone' => 'Asia/Jakarta',
                'is_active' => true,
                'is_demo_mode' => false,
                'subscription_plan' => 'professional',
                'max_employees' => 100,
                'office_latitude' => self::OFFICE_LAT,
                'office_longitude' => self::OFFICE_LNG,
                'office_radius' => 150,
                'enable_gps_validation' => true,
                'enable_face_recognition' => true,
                'face_match_threshold' => 0.6,
            ]
        );

        $this->createRoles();
        $this->createAdminUser();
        $this->createOfficeLocation();
        $this->createDepartmentsAndPositions();
        $this->createEmployees();

        $this->command->info("Perusahaan YAPI berhasil dibuat (ID: {$this->company->id}) dengan ".count($this->departments).' departemen dan karyawan.');
    }

    private function createRoles(): void
    {
        $roles = [
            'admin' => Permission::pluck('name')->all(),
            'hr-manager' => [
                'view employees', 'create employees', 'edit employees',
                'import employees', 'export employees',
                'view attendance', 'create attendance', 'edit attendance',
                'approve attendance', 'export attendance',
                'view leaves', 'create leaves', 'edit leaves',
                'approve leaves', 'manage leave types',
                'view reports', 'export reports',
            ],
            'payroll-manager' => [
                'view employees',
                'view attendance', 'export attendance',
                'view leaves',
                'view payroll', 'create payroll', 'edit payroll',
                'process payroll', 'approve payroll', 'export payroll',
                'view salary components', 'create salary components',
                'edit salary components', 'delete salary components',
                'view reports', 'export reports',
            ],
            'employee' => [
                'view attendance', 'create attendance',
                'view leaves', 'create leaves',
            ],
        ];

        setPermissionsTeamId($this->company->id);
        $teamColumn = config('permission.column_names.team_foreign_key', 'team_id');

        foreach ($roles as $roleName => $permissions) {
            $role = Role::query()
                ->where('name', $roleName)
                ->where('guard_name', 'web')
                ->where($teamColumn, $this->company->id)
                ->first();

            if (! $role) {
                $role = Role::query()->create([
                    'name' => $roleName,
                    'guard_name' => 'web',
                    $teamColumn => $this->company->id,
                ]);
            }

            $available = Permission::whereIn('name', $permissions)->pluck('name')->all();
            if (! empty($available)) {
                $role->syncPermissions($available);
            }
        }
    }

    private function createAdminUser(): void
    {
        $admin = User::updateOrCreate(
            ['email' => 'admin@yapi.test'],
            [
                'company_id' => $this->company->id,
                'name' => 'Admin YAPI',
                'password' => Hash::make('password'),
                'is_active' => true,
                'is_superadmin' => false,
            ]
        );

        setPermissionsTeamId($this->company->id);
        if (! $admin->hasRole('admin')) {
            $admin->assignRole('admin');
        }
    }

    private function createOfficeLocation(): void
    {
        OfficeLocation::updateOrCreate(
            ['company_id' => $this->company->id, 'code' => 'HQ-YAPI'],
            [
                'name' => 'Kantor Pusat YAPI',
                'address' => self::ADDRESS,
                'city' => 'Jakarta Timur',
                'province' => 'DKI Jakarta',
                'latitude' => self::OFFICE_LAT,
                'longitude' => self::OFFICE_LNG,
                'radius' => 150,
                'is_active' => true,
                'is_headquarters' => true,
            ]
        );
    }

    private function createDepartmentsAndPositions(): void
    {
        // [code => [name, [ [posCode, posName, level, baseSalary] ... ] ]]
        // level: 5 = direktur, 3 = manager, 1 = staff (unsignedTinyInteger)
        $structure = [
            'DIR' => ['Direksi', [
                ['DIR-01', 'Direktur Utama', 5, 30000000],
            ]],
            'HRD' => ['Human Resources', [
                ['HRD-MGR', 'HR Manager', 3, 12000000],
                ['HRD-STF', 'Staff HRD', 1, 6500000],
            ]],
            'FIN' => ['Keuangan', [
                ['FIN-MGR', 'Finance & Payroll Manager', 3, 13000000],
                ['FIN-STF', 'Staff Keuangan', 1, 7000000],
            ]],
            'ITD' => ['Teknologi Informasi', [
                ['ITD-STF', 'Software Engineer', 1, 9000000],
            ]],
            'MKT' => ['Marketing', [
                ['MKT-STF', 'Staff Marketing', 1, 7500000],
            ]],
        ];

        foreach ($structure as $deptCode => [$deptName, $posList]) {
            $dept = Department::updateOrCreate(
                ['company_id' => $this->company->id, 'code' => $deptCode],
                ['name' => $deptName, 'is_active' => true]
            );
            $this->departments[$deptCode] = $dept;

            foreach ($posList as [$posCode, $posName, $level, $baseSalary]) {
                $this->positions[$posCode] = Position::updateOrCreate(
                    ['company_id' => $this->company->id, 'code' => $posCode],
                    [
                        'department_id' => $dept->id,
                        'name' => $posName,
                        'level' => $level,
                        'base_salary' => $baseSalary,
                        'is_active' => true,
                    ]
                );
            }
        }
    }

    private function createEmployees(): void
    {
        // [first, last, gender, deptCode, posCode, taxStatus, baseSalary, role, loginEmail]
        $employees = [
            ['Hadi', 'Santoso', 'male', 'DIR', 'DIR-01', 'K/2', 30000000, 'admin', 'hadi@yapi.test'],
            ['Budi', 'Hartono', 'male', 'HRD', 'HRD-MGR', 'K/1', 12000000, 'hr-manager', 'hr@yapi.test'],
            ['Siti', 'Nurhaliza', 'female', 'FIN', 'FIN-MGR', 'TK/0', 13000000, 'payroll-manager', 'payroll@yapi.test'],
            ['Andi', 'Wijaya', 'male', 'ITD', 'ITD-STF', 'TK/0', 9000000, 'employee', 'andi@yapi.test'],
            ['Dewi', 'Lestari', 'female', 'MKT', 'MKT-STF', 'K/0', 7500000, 'employee', 'dewi@yapi.test'],
            ['Rina', 'Anggraini', 'female', 'HRD', 'HRD-STF', 'TK/0', 6500000, 'employee', 'rina@yapi.test'],
            ['Eko', 'Prasetyo', 'male', 'FIN', 'FIN-STF', 'K/0', 7000000, 'employee', 'eko@yapi.test'],
        ];

        setPermissionsTeamId($this->company->id);
        $hireDate = Carbon::create(2024, 1, 15);

        foreach ($employees as $index => [$first, $last, $gender, $deptCode, $posCode, $taxStatus, $salary, $role, $loginEmail]) {
            $user = User::updateOrCreate(
                ['email' => $loginEmail],
                [
                    'company_id' => $this->company->id,
                    'name' => "{$first} {$last}",
                    'password' => Hash::make('password'),
                    'is_active' => true,
                    'is_superadmin' => false,
                ]
            );

            if (! $user->hasRole($role)) {
                $user->assignRole($role);
            }

            $employee = Employee::updateOrCreate(
                ['company_id' => $this->company->id, 'email' => $loginEmail],
                [
                    'department_id' => $this->departments[$deptCode]->id,
                    'position_id' => $this->positions[$posCode]->id,
                    'user_id' => $user->id,
                    'first_name' => $first,
                    'last_name' => $last,
                    'phone' => '0812'.str_pad((string) (1000000 + $index), 8, '0', STR_PAD_LEFT),
                    'gender' => $gender,
                    'marital_status' => str_starts_with($taxStatus, 'K') ? 'married' : 'single',
                    'date_of_birth' => Carbon::create(1990, 1, 1)->addDays($index * 137),
                    'identity_number' => '31750'.str_pad((string) (10000000 + $index), 11, '0', STR_PAD_LEFT),
                    'address' => self::ADDRESS,
                    'city' => 'Jakarta Timur',
                    'province' => 'DKI Jakarta',
                    'postal_code' => '13220',
                    'hire_date' => $hireDate->copy()->addDays($index * 10),
                    'employment_status' => 'permanent',
                    'base_salary' => $salary,
                    'bank_name' => 'BCA',
                    'bank_account_number' => '8'.str_pad((string) (100000000 + $index), 9, '0', STR_PAD_LEFT),
                    'bank_account_name' => "{$first} {$last}",
                    'npwp' => '0'.str_pad((string) (12345678 + $index), 8, '0', STR_PAD_LEFT).'.9-077.000',
                    'tax_status' => $taxStatus,
                    'is_active' => true,
                ]
            );

            EmployeeSalary::updateOrCreate(
                ['company_id' => $this->company->id, 'employee_id' => $employee->id, 'is_active' => true],
                [
                    'basic_salary' => $salary,
                    'effective_date' => $employee->hire_date,
                    'payment_method' => 'transfer',
                    'bank_name' => 'BCA',
                    'bank_account_number' => $employee->bank_account_number,
                    'bank_account_name' => $employee->bank_account_name,
                ]
            );
        }
    }
}
