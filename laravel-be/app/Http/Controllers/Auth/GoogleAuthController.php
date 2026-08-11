<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Laravel\Socialite\Facades\Socialite;

class GoogleAuthController extends Controller
{
    public function redirectToGoogle(): RedirectResponse
    {
        return Socialite::driver('google')->redirect();
    }

    public function handleGoogleCallback(): RedirectResponse
    {
        try {
            $googleUser = Socialite::driver('google')->user();
            $email = strtolower(trim($googleUser->getEmail()));

            // First check if user exists
            $user = User::where('email', $email)->first();

            if (! $user) {
                // Check if employee exists with this email
                $employee = Employee::where('email', $email)->first();

                if ($employee) {
                    // Create user account for this employee automatically
                    $user = User::create([
                        'company_id' => $employee->company_id,
                        'name' => $employee->full_name,
                        'email' => $email,
                        'password' => bcrypt(\Illuminate\Support\Str::random(16)),
                        'is_active' => true,
                    ]);

                    $user->assignRole('employee');
                    $employee->update(['user_id' => $user->id]);
                }
            }

            if (! $user) {
                return redirect()->route('login')
                    ->with('error', "Email Google ({$email}) tidak terdaftar dalam data karyawan. Silakan hubungi HR / Admin.");
            }

            if (! $user->is_active) {
                return redirect()->route('login')
                    ->with('error', 'Akun Anda telah dinonaktifkan. Silakan hubungi administrator.');
            }

            if ($user->company_id && $user->company && ! $user->company->is_active) {
                return redirect()->route('login')
                    ->with('error', 'Perusahaan Anda telah dinonaktifkan. Silakan hubungi administrator.');
            }

            Auth::login($user, true);
            request()->session()->regenerate();

            $userName = $user->first_name ?? $user->name ?? 'User';

            if ($user->hasRole('employee') && ! $user->hasAnyRole(['admin', 'hr-manager', 'payroll-manager', 'manager'])) {
                return redirect()->intended(route('portal.dashboard'))
                    ->with('success', "Berhasil masuk via Google! Selamat datang, {$userName}.");
            }

            return redirect()->intended('/dashboard')
                ->with('success', "Berhasil masuk via Google! Selamat datang, {$userName}.");
        } catch (\Throwable $e) {
            return redirect()->route('login')
                ->with('error', 'Gagal melakukan login Google: '.$e->getMessage());
        }
    }
}
