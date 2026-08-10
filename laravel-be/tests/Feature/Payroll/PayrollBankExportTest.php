<?php

use App\Jobs\GenerateExportJob;
use App\Models\Company;
use App\Models\Employee;
use App\Models\GeneratedExport;
use App\Models\Payroll;
use App\Models\PayrollItem;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->company = Company::factory()->create();
    createStandardRoles($this->company->id);

    $this->user = User::factory()->create(['company_id' => $this->company->id]);
    $this->user->assignRole('admin');
    $this->actingAs($this->user);

    $this->employee = Employee::factory()->create([
        'company_id' => $this->company->id,
        'first_name' => 'John',
        'last_name' => 'Doe',
    ]);

    $this->payroll = Payroll::factory()->create([
        'company_id' => $this->company->id,
        'status' => 'approved',
        'period_month' => 1,
        'period_year' => 2026,
    ]);

    $this->payrollItem = PayrollItem::factory()->create([
        'payroll_id' => $this->payroll->id,
        'employee_id' => $this->employee->id,
        'employee_name' => 'John Doe',
        'employee_number' => 'EMP001',
        'net_salary' => 10000000,
        'payment_method' => 'transfer',
        'bank_name' => 'BCA',
        'bank_account_number' => '1234567890',
        'bank_account_name' => 'John Doe',
        'status' => 'approved',
    ]);
});

describe('PayrollBankExport (async)', function () {
    describe('export bank transfer list', function () {
        it('queues bank export job for approved payroll', function () {
            Queue::fake();

            $response = $this->get(route('payrolls.export-bank', $this->payroll));

            $response->assertRedirect(route('payrolls.show', $this->payroll));
            $response->assertSessionHas('success');

            Queue::assertPushed(GenerateExportJob::class);
        });

        it('creates a generated export record with the period filename', function () {
            Queue::fake();

            $this->get(route('payrolls.export-bank', $this->payroll));

            $this->assertDatabaseHas('generated_exports', [
                'company_id' => $this->company->id,
                'user_id' => $this->user->id,
                'type' => 'payroll_bank',
                'filename' => 'bank_transfer_januari_2026.xlsx',
                'status' => 'pending',
            ]);
        });

        it('cannot export bank for draft payroll', function () {
            $draftPayroll = Payroll::factory()->create([
                'company_id' => $this->company->id,
                'status' => 'draft',
            ]);

            $response = $this->get(route('payrolls.export-bank', $draftPayroll));

            $response->assertRedirect();
            $response->assertSessionHas('error');
        });

        it('cannot export bank for other company payroll', function () {
            $otherCompany = Company::factory()->create();
            $otherPayroll = Payroll::factory()->create([
                'company_id' => $otherCompany->id,
                'status' => 'approved',
            ]);

            $response = $this->get(route('payrolls.export-bank', $otherPayroll));

            $response->assertNotFound();
        });
    });

    describe('export generation and download', function () {
        it('generates the file and serves it through the download route', function () {
            $this->get(route('payrolls.export-bank', $this->payroll));

            $export = GeneratedExport::where('type', 'payroll_bank')->firstOrFail();

            // Job ran synchronously (QUEUE_CONNECTION=sync in tests).
            expect($export->fresh()->status)->toBe('ready');

            $response = $this->get(route('exports.download', $export));
            $response->assertOk();
            $response->assertDownload('bank_transfer_januari_2026.xlsx');
        });

        it('download is scoped to the owning company', function () {
            $this->get(route('payrolls.export-bank', $this->payroll));
            $export = GeneratedExport::where('type', 'payroll_bank')->firstOrFail();

            $otherCompany = Company::factory()->create();
            createStandardRoles($otherCompany->id);
            $otherUser = User::factory()->create(['company_id' => $otherCompany->id]);
            $otherUser->assignRole('admin');

            $response = $this->actingAs($otherUser)->get(route('exports.download', $export));
            $response->assertNotFound();
        });
    });
});
