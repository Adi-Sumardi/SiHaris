<?php

namespace Tests\Feature\Auth;

use App\Models\Company;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class WebOtpAuthTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $company = Company::factory()->create(['name' => 'PT Web Test']);

        $this->user = User::factory()->create([
            'company_id' => $company->id,
            'email' => 'admin@webtest.com',
            'phone' => '081999888777',
            'is_active' => true,
        ]);

        \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'admin', 'guard_name' => 'web']);
        $this->user->assignRole('admin');
    }

    public function test_request_web_otp_redirects_to_verify_page(): void
    {
        $response = $this->post('/login/otp', [
            'login' => 'admin@webtest.com',
        ]);

        $response->assertRedirect('/login/verify-otp');
        $response->assertSessionHas('otp_login', 'admin@webtest.com');
        $this->assertTrue(Cache::has('otp_login:admin@webtest.com'));
    }

    public function test_show_verify_otp_page(): void
    {
        $response = $this->withSession([
            'otp_login' => 'admin@webtest.com',
            'otp_destination' => 'ad***@webtest.com',
            'otp_type' => 'email',
        ])->get('/login/verify-otp');

        $response->assertStatus(200);
        $response->assertSee('Masukkan Kode OTP');
    }

    public function test_verify_web_otp_authenticates_session_and_redirects_to_dashboard(): void
    {
        $this->post('/login/otp', [
            'login' => 'admin@webtest.com',
        ]);

        $cached = Cache::get('otp_login:admin@webtest.com');
        $otpCode = $cached['otp'];

        $response = $this->withSession([
            'otp_login' => 'admin@webtest.com',
        ])->post('/login/verify-otp', [
            'login' => 'admin@webtest.com',
            'otp' => $otpCode,
        ]);

        $response->assertRedirect('/dashboard');
        $this->assertAuthenticatedAs($this->user);
    }

    public function test_verify_web_otp_fails_with_wrong_code(): void
    {
        $this->post('/login/otp', [
            'login' => 'admin@webtest.com',
        ]);

        $response = $this->withSession([
            'otp_login' => 'admin@webtest.com',
        ])->post('/login/verify-otp', [
            'login' => 'admin@webtest.com',
            'otp' => '999999',
        ]);

        $response->assertSessionHasErrors('otp');
        $this->assertGuest();
    }
}
