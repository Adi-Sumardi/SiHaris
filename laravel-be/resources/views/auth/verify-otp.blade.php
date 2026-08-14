@extends('layouts.guest')

@section('title', 'Verifikasi Kode OTP - ' . brand_name())
@section('description', 'Masukkan 6 digit kode OTP verifikasi untuk masuk ke ' . brand_name())

@section('content')
<div class="min-h-screen flex items-center justify-center bg-secondary-50 px-4 py-12">
    <div class="w-full max-w-md">
        <!-- Logo -->
        <div class="mb-8 text-center">
            <a href="{{ url('/') }}" class="inline-flex items-center gap-3">
                <img src="{{ asset('images/gajipro-logo-new.png') }}" alt="{{ brand_name() }}" class="w-10 h-10 object-contain rounded-xl">
                <span class="text-xl font-bold text-secondary-900">{{ brand_name() }}</span>
            </a>
        </div>

        <!-- Card -->
        <div class="bg-white rounded-2xl shadow-sm border border-secondary-100 p-8">
            <!-- Header Icon & Title -->
            <div class="text-center mb-6">
                <div class="w-16 h-16 bg-primary-50 text-primary-600 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                    </svg>
                </div>
                <h1 class="text-2xl font-bold text-secondary-900 mb-1">Masukkan Kode OTP</h1>
                <p class="text-secondary-500 text-sm">
                    Kode verifikasi 6 digit telah dikirimkan via {{ ($otpType ?? '') === 'email' ? 'Email' : 'WhatsApp' }} ke:
                </p>
                <p class="text-secondary-900 font-semibold text-base mt-1">
                    {{ session('otp_destination', old('login')) }}
                </p>
            </div>

            @if(session('success'))
                <x-alert type="success" class="mb-4">{{ session('success') }}</x-alert>
            @endif

            @if(session('error'))
                <x-alert type="danger" class="mb-4">{{ session('error') }}</x-alert>
            @endif

            @if(session('debug_otp'))
                <x-alert type="warning" class="mb-4">
                    <strong>[DEMO/LOCAL OTP]</strong> Kode OTP Anda: <code>{{ session('debug_otp') }}</code>
                </x-alert>
            @endif

            <!-- Verify OTP Form -->
            <form method="POST" action="{{ route('login.verify-otp') }}" class="space-y-6">
                @csrf
                <input type="hidden" name="login" value="{{ session('otp_login', old('login')) }}">

                <!-- OTP Input 6 digits -->
                <div>
                    <label for="otp" class="block text-sm font-medium text-secondary-700 mb-2 text-center">Kode OTP (6 Digit)</label>
                    <input type="text" id="otp" name="otp" required autofocus maxlength="6"
                           class="input w-full text-center text-2xl font-mono tracking-[0.5em] py-3 uppercase @error('otp') border-danger-500 @enderror"
                           placeholder="000000">
                    @error('otp')
                        <p class="mt-1 text-sm text-danger-500 text-center">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Submit Button -->
                <button type="submit" class="btn btn-primary w-full py-3">
                    Verifikasi & Masuk
                </button>
            </form>

            <!-- Resend OTP Form -->
            <div class="mt-6 text-center pt-4 border-t border-secondary-100">
                <p class="text-sm text-secondary-500 mb-2">Tidak menerima kode OTP?</p>
                <form method="POST" action="{{ route('login.otp') }}">
                    @csrf
                    <input type="hidden" name="login" value="{{ session('otp_login', old('login')) }}">
                    <button type="submit" class="text-sm font-semibold text-primary-600 hover:text-primary-700 transition-colors">
                        Kirim Ulang Kode OTP
                    </button>
                </form>
                <div class="mt-4">
                    <a href="{{ route('login') }}" class="text-xs text-secondary-400 hover:text-secondary-600">
                        &larr; Kembali ke Halaman Login
                    </a>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <p class="text-center mt-6 text-sm text-secondary-400">
            &copy; {{ date('Y') }} {{ brand_name() }} &middot;
            <a href="https://adilabs.id" target="_blank" class="hover:text-secondary-600 transition-colors">Powered by adilabs.id</a>
        </p>
    </div>
</div>
@endsection
