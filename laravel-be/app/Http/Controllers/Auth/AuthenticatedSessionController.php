<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class AuthenticatedSessionController extends Controller
{
    public function create(): View
    {
        return view('auth.login');
    }

    public function store(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials, $request->boolean('remember'))) {
            return back()->withErrors([
                'email' => __('auth.failed'),
            ])->onlyInput('email');
        }

        $user = Auth::user();

        // Check if user is active
        if (! $user->is_active) {
            Auth::logout();

            return back()->withErrors([
                'email' => 'Akun Anda telah dinonaktifkan. Silakan hubungi administrator.',
            ])->onlyInput('email');
        }

        // Check if company is active (for non-super-admin)
        if ($user->company_id && $user->company && ! $user->company->is_active) {
            Auth::logout();

            return back()->withErrors([
                'email' => 'Perusahaan Anda telah dinonaktifkan. Silakan hubungi administrator.',
            ])->onlyInput('email');
        }

        $request->session()->regenerate();

        $userName = $user->first_name ?? $user->name ?? 'User';

        // Redirect employee to portal, admin/hr to dashboard
        if ($user->hasRole('employee') && ! $user->hasAnyRole(['admin', 'hr-manager', 'payroll-manager', 'manager'])) {
            return redirect()->intended(route('portal.dashboard'))
                ->with('success', "Berhasil masuk! Selamat datang kembali, {$userName}.");
        }

        return redirect()->intended('/dashboard')
            ->with('success', "Berhasil masuk! Selamat datang kembali, {$userName}.");
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auth::guard('web')->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/login')
            ->with('success', 'Anda telah berhasil keluar (logout). Sampai jumpa!');
    }

    public function requestOtp(Request $request, \App\Services\OtpService $otpService): RedirectResponse
    {
        $request->validate([
            'login' => ['required', 'string'],
        ], [
            'login.required' => 'Nomor HP atau Email wajib diisi.',
        ]);

        $result = $otpService->requestOtp($request->login);

        if (! $result['success']) {
            return back()->withErrors(['login' => $result['message']])->withInput();
        }

        session([
            'otp_login' => $request->login,
            'otp_destination' => $result['destination'],
            'otp_type' => $result['type'],
        ]);

        $redirect = redirect()->route('login.verify-otp')
            ->with('success', $result['message']);

        if (! empty($result['debug_otp'])) {
            $redirect->with('debug_otp', $result['debug_otp']);
        }

        return $redirect;
    }

    public function showVerifyOtp(Request $request): View|RedirectResponse
    {
        if (! session('otp_login') && ! $request->old('login')) {
            return redirect()->route('login');
        }

        return view('auth.verify-otp', [
            'otpType' => session('otp_type'),
        ]);
    }

    public function verifyOtp(Request $request, \App\Services\OtpService $otpService): RedirectResponse
    {
        $request->validate([
            'login' => ['required', 'string'],
            'otp' => ['required', 'string', 'size:6'],
        ], [
            'login.required' => 'Nomor HP atau Email wajib diisi.',
            'otp.required' => 'Kode OTP 6 digit wajib diisi.',
            'otp.size' => 'Kode OTP harus berjumlah 6 digit.',
        ]);

        $user = $otpService->verifyOtp($request->login, $request->otp);

        if (! $user) {
            return back()->withErrors(['otp' => 'Kode OTP tidak valid atau sudah kadaluarsa.'])->withInput();
        }

        if (! $user->is_active) {
            return back()->withErrors(['otp' => 'Akun Anda telah dinonaktifkan. Silakan hubungi administrator.'])->withInput();
        }

        if ($user->company_id && $user->company && ! $user->company->is_active) {
            return back()->withErrors(['otp' => 'Perusahaan Anda telah dinonaktifkan. Silakan hubungi administrator.'])->withInput();
        }

        Auth::login($user, true);
        $request->session()->regenerate();
        session()->forget(['otp_login', 'otp_destination', 'otp_type']);

        $userName = $user->first_name ?? $user->name ?? 'User';

        if ($user->hasRole('employee') && ! $user->hasAnyRole(['admin', 'hr-manager', 'payroll-manager', 'manager'])) {
            return redirect()->intended(route('portal.dashboard'))
                ->with('success', "Berhasil masuk via OTP! Selamat datang kembali, {$userName}.");
        }

        return redirect()->intended('/dashboard')
            ->with('success', "Berhasil masuk via OTP! Selamat datang kembali, {$userName}.");
    }
}
