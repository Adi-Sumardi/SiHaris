<?php

namespace App\Services;

use App\Mail\OtpMail;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class OtpService
{
    private const OTP_EXPIRY_SECONDS = 180; // 3 minutes

    public function __construct(
        protected WhatsAppNotificationService $waService
    ) {}

    /**
     * Request an OTP for a user by Phone Number or Email.
     *
     * @return array{success: bool, type: string, destination: string, message: string, debug_otp?: string}
     */
    public function requestOtp(string $login): array
    {
        $login = trim($login);
        $type = filter_var($login, FILTER_VALIDATE_EMAIL) ? 'email' : 'phone';

        $user = $this->findUser($login, $type);

        if (! $user) {
            return [
                'success' => false,
                'type' => $type,
                'destination' => '',
                'message' => 'Akun dengan '.($type === 'email' ? 'email' : 'nomor HP').' tersebut tidak ditemukan.',
            ];
        }

        $otpCode = sprintf('%06d', random_int(100000, 999999));
        $cacheKey = $this->getCacheKey($login);

        Cache::put($cacheKey, [
            'user_id' => $user->id,
            'otp' => $otpCode,
            'type' => $type,
            'login' => $login,
        ], self::OTP_EXPIRY_SECONDS);

        $destinationMasked = $type === 'email'
            ? $this->maskEmail($login)
            : $this->maskPhone($login);

        if ($type === 'phone') {
            $message = "Kode verifikasi OTP SiHaris Anda adalah: *{$otpCode}*.\n\nKode ini berlaku selama 3 menit. Jangan bagikan kode ini kepada siapapun demi keamanan akun Anda.";
            $waResult = $this->waService->sendMessage($login, $message);

            if (! $waResult['success']) {
                Log::warning("OTP WhatsApp send failed for {$login}: {$waResult['error']}");
            }
        } else {
            try {
                Mail::to($user->email)->send(new OtpMail($otpCode, $user->name));
            } catch (\Throwable $e) {
                Log::error("OTP Email send failed for {$login}: {$e->getMessage()}");
            }
        }

        Log::info("OTP generated for {$login} ({$type}): {$otpCode}");

        $response = [
            'success' => true,
            'type' => $type,
            'destination' => $destinationMasked,
            'message' => 'Kode OTP berhasil dikirim ke '.($type === 'email' ? 'email' : 'WhatsApp').' Anda.',
        ];

        // Include debug OTP in local environment or demo mode
        if (config('app.env') === 'local' || config('app.debug')) {
            $response['debug_otp'] = $otpCode;
        }

        return $response;
    }

    /**
     * Verify the OTP code for a given login (phone/email).
     */
    public function verifyOtp(string $login, string $otpCode): ?User
    {
        $login = trim($login);
        $cacheKey = $this->getCacheKey($login);

        $cached = Cache::get($cacheKey);

        if (! $cached || ! is_array($cached)) {
            return null;
        }

        if ((string) ($cached['otp'] ?? '') !== trim($otpCode)) {
            return null;
        }

        // OTP is valid - clear cache to prevent re-use
        Cache::forget($cacheKey);

        return User::find($cached['user_id']);
    }

    protected function findUser(string $login, string $type): ?User
    {
        if ($type === 'email') {
            // Prioritize active employee by email first
            $employee = Employee::where('email', $login)
                ->where('is_active', true)
                ->whereNotNull('user_id')
                ->first();

            if ($employee && $employee->user) {
                return $employee->user;
            }

            return User::where('email', $login)
                ->whereHas('employee', fn ($q) => $q->where('is_active', true))
                ->first()
                ?? User::where('email', $login)->first();
        }

        // Phone normalization (strip non-digits)
        $digits = preg_replace('/\D/', '', $login);

        // Generate common Indonesian phone format variants
        $variants = array_unique(array_filter([
            $login,
            $digits,
            ltrim($digits, '0'), // e.g. 81292702075
            '0'.ltrim($digits, '0'), // e.g. 081292702075
            '62'.ltrim(preg_replace('/^62/', '', $digits), '0'), // e.g. 6281292702075
            '+62'.ltrim(preg_replace('/^62/', '', $digits), '0'),
        ]));

        // 1. Prioritize active Employee matching phone with an associated user
        $employee = Employee::whereIn('phone', $variants)
            ->where('is_active', true)
            ->whereNotNull('user_id')
            ->first();

        if ($employee && $employee->user) {
            return $employee->user;
        }

        // 2. Try User who has an active employee
        $user = User::whereIn('phone', $variants)
            ->whereHas('employee', fn ($q) => $q->where('is_active', true))
            ->first();

        if ($user) {
            return $user;
        }

        // 3. Direct matching on user phone (e.g. admin accounts)
        $user = User::whereIn('phone', $variants)->first();
        if ($user) {
            return $user;
        }

        // 4. Fallback to any employee phone
        $employee = Employee::whereIn('phone', $variants)->first();

        return $employee?->user;
    }

    protected function getCacheKey(string $login): string
    {
        $clean = strtolower(preg_replace('/[^a-zA-Z0-9@.]/', '', $login));

        return "otp_login:{$clean}";
    }

    protected function maskPhone(string $phone): string
    {
        $clean = preg_replace('/\D/', '', $phone);
        $len = strlen($clean);
        if ($len < 6) {
            return $phone;
        }

        return substr($clean, 0, 4).'***'.substr($clean, -3);
    }

    protected function maskEmail(string $email): string
    {
        $parts = explode('@', $email);
        if (count($parts) !== 2) {
            return $email;
        }

        $name = $parts[0];
        $domain = $parts[1];

        $maskedName = strlen($name) <= 2
            ? $name[0].'*'
            : substr($name, 0, 2).str_repeat('*', max(1, strlen($name) - 3)).substr($name, -1);

        return $maskedName.'@'.$domain;
    }
}
