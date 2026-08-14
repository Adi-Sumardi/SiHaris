<?php

namespace Tests\Feature\Auth;

use App\Models\Company;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class OtpAuthTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected Employee $employee;

    protected function setUp(): void
    {
        parent::setUp();

        $company = Company::factory()->create(['name' => 'PT Test']);

        $this->user = User::factory()->create([
            'company_id' => $company->id,
            'email' => 'karyawan@test.com',
            'phone' => '081234567890',
        ]);

        $this->employee = Employee::factory()->create([
            'company_id' => $company->id,
            'user_id' => $this->user->id,
            'email' => 'karyawan@test.com',
            'phone' => '081234567890',
            'is_active' => true,
        ]);
    }

    public function test_request_otp_via_email_returns_success(): void
    {
        $response = $this->postJson('/api/v1/auth/request-otp', [
            'login' => 'karyawan@test.com',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'type' => 'email',
                ],
            ]);

        $this->assertTrue(Cache::has('otp_login:karyawan@test.com'));
    }

    public function test_request_otp_via_phone_returns_success(): void
    {
        $response = $this->postJson('/api/v1/auth/request-otp', [
            'login' => '081234567890',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'type' => 'phone',
                ],
            ]);
    }

    public function test_verify_otp_returns_30_day_sanctum_token(): void
    {
        $this->postJson('/api/v1/auth/request-otp', [
            'login' => 'karyawan@test.com',
        ]);

        $cached = Cache::get('otp_login:karyawan@test.com');
        $otpCode = $cached['otp'];

        $response = $this->postJson('/api/v1/auth/verify-otp', [
            'login' => 'karyawan@test.com',
            'otp' => $otpCode,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Verifikasi OTP berhasil. Login sukses.',
            ])
            ->assertJsonStructure([
                'data' => [
                    'token',
                    'user' => ['id', 'name', 'email'],
                    'employee' => ['id', 'employee_id', 'full_name'],
                ],
            ]);

        $token = $this->user->tokens()->latest()->first();
        $this->assertNotNull($token);
        $this->assertNotNull($token->expires_at);
        $this->assertTrue($token->expires_at->isAfter(now()->addDays(29)));
    }

    public function test_verify_otp_fails_with_invalid_code(): void
    {
        $this->postJson('/api/v1/auth/request-otp', [
            'login' => 'karyawan@test.com',
        ]);

        $response = $this->postJson('/api/v1/auth/verify-otp', [
            'login' => 'karyawan@test.com',
            'otp' => '000000',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Kode OTP tidak valid atau sudah kadaluarsa.',
            ]);
    }
}
