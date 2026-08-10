<?php

namespace Database\Seeders;

use App\Models\Company;
use App\Models\Employee;
use App\Models\OfficeLocation;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Seed branch office locations for the single-tenant YAPI company.
 *
 * YAPI runs as one company with a head office (seeded by YapiCompanySeeder)
 * plus several branches. Idempotent — safe to run multiple times.
 */
class YapiBranchSeeder extends Seeder
{
    public function run(): void
    {
        $company = Company::where('name', 'YAPI')->first();

        if (! $company) {
            $this->command->error('Company YAPI tidak ditemukan. Jalankan YapiCompanySeeder terlebih dahulu.');

            return;
        }

        $branches = [
            [
                'code' => 'BR-BDG',
                'name' => 'Cabang Bandung',
                'address' => 'Jl. Asia Afrika No. 141-149, Braga',
                'city' => 'Bandung',
                'province' => 'Jawa Barat',
                'latitude' => -6.9214740,
                'longitude' => 107.6072710,
                'radius' => 100,
            ],
            [
                'code' => 'BR-SBY',
                'name' => 'Cabang Surabaya',
                'address' => 'Jl. Embong Malang No. 1-5',
                'city' => 'Surabaya',
                'province' => 'Jawa Timur',
                'latitude' => -7.2620330,
                'longitude' => 112.7527190,
                'radius' => 100,
            ],
            [
                'code' => 'BR-SMG',
                'name' => 'Cabang Semarang',
                'address' => 'Jl. Pemuda No. 150',
                'city' => 'Semarang',
                'province' => 'Jawa Tengah',
                'latitude' => -6.9666420,
                'longitude' => 110.4166410,
                'radius' => 100,
            ],
        ];

        foreach ($branches as $data) {
            OfficeLocation::updateOrCreate(
                ['company_id' => $company->id, 'code' => $data['code']],
                [
                    'name' => $data['name'],
                    'address' => $data['address'],
                    'city' => $data['city'],
                    'province' => $data['province'],
                    'latitude' => $data['latitude'],
                    'longitude' => $data['longitude'],
                    'radius' => $data['radius'],
                    'is_active' => true,
                    'is_headquarters' => false,
                ]
            );
        }

        $this->assignSampleEmployees($company);

        $this->command->info('Cabang YAPI berhasil dibuat: '.count($branches).' lokasi.');
    }

    /**
     * Assign a couple of existing employees to branches as a working example.
     */
    private function assignSampleEmployees(Company $company): void
    {
        $bandung = OfficeLocation::where('company_id', $company->id)->where('code', 'BR-BDG')->first();
        $surabaya = OfficeLocation::where('company_id', $company->id)->where('code', 'BR-SBY')->first();

        $marketing = Employee::where('company_id', $company->id)
            ->where('email', 'dewi@yapi.test')
            ->first();

        $hrStaff = Employee::where('company_id', $company->id)
            ->where('email', 'rina@yapi.test')
            ->first();

        if ($marketing && $bandung) {
            DB::table('employee_office_locations')->updateOrInsert(
                ['employee_id' => $marketing->id, 'office_location_id' => $bandung->id],
                ['is_primary' => true, 'created_at' => now(), 'updated_at' => now()]
            );
        }

        if ($hrStaff && $surabaya) {
            DB::table('employee_office_locations')->updateOrInsert(
                ['employee_id' => $hrStaff->id, 'office_location_id' => $surabaya->id],
                ['is_primary' => true, 'created_at' => now(), 'updated_at' => now()]
            );
        }
    }
}
