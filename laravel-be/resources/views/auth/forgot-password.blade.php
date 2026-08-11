@extends('layouts.guest')

@section('title', 'Lupa Password - ' . brand_name())
@section('description', 'Reset password akun ' . brand_name() . ' Anda.')

@section('content')
<div class="min-h-screen flex">
    <!-- Left Panel - Branding -->
    <div class="hidden lg:flex lg:w-1/2 bg-hero-gradient p-12 flex-col justify-between relative overflow-hidden">
        <div>
            <a href="{{ url('/') }}" class="flex items-center gap-3">
                <img src="{{ asset('images/gajipro-logo-new.png') }}" alt="{{ brand_name() }}" class="w-12 h-12 rounded-xl object-cover">
                <span class="text-2xl font-bold text-white">{{ brand_name() }}</span>
            </a>
        </div>

        <div class="text-white relative z-10">
            <h1 class="text-4xl font-bold mb-4">Lupa Password?</h1>
            <p class="text-primary-200 text-lg mb-8">Tenang, kami akan bantu Anda mengatur ulang password akun Anda.</p>

            <div class="space-y-4">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center">
                        <svg class="w-5 h-5 text-primary-200" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                    </div>
                    <span class="text-primary-100">Masukkan email terdaftar</span>
                </div>
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center">
                        <svg class="w-5 h-5 text-primary-200" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
                    </div>
                    <span class="text-primary-100">Cek email untuk link reset</span>
                </div>
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center">
                        <svg class="w-5 h-5 text-primary-200" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    </div>
                    <span class="text-primary-100">Buat password baru</span>
                </div>
            </div>
        </div>

        <div class="text-primary-300 text-sm relative z-10">
            &copy; {{ date('Y') }} {{ brand_name() }}. All rights reserved.
        </div>
    </div>

    <!-- Right Panel - Form -->
    <div class="w-full lg:w-1/2 flex items-center justify-center p-8">
        <div class="w-full max-w-md">
            <!-- Mobile Logo -->
            <div class="lg:hidden mb-8 text-center">
                <a href="{{ url('/') }}" class="inline-flex items-center gap-3">
                    <img src="{{ asset('images/gajipro-logo-new.png') }}" alt="{{ brand_name() }}" class="w-10 h-10 rounded-xl object-cover">
                    <span class="text-xl font-bold text-secondary-900">{{ brand_name() }}</span>
                </a>
            </div>

            <div class="text-center mb-8">
                <h2 class="text-2xl font-bold text-secondary-900 mb-2">Reset Password</h2>
                <p class="text-secondary-500">Masukkan email Anda dan kami akan mengirimkan link untuk reset password</p>
            </div>

            <!-- Success Message -->
            @if (session('status'))
                <div class="mb-6 p-4 bg-success-50 border border-success-200 rounded-xl">
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 bg-success-100 rounded-lg flex items-center justify-center">
                            <svg class="w-5 h-5 text-success-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                        </div>
                        <p class="text-sm text-success-700">{{ session('status') }}</p>
                    </div>
                </div>
            @endif

            <!-- Forgot Password Form -->
            <form method="POST" action="{{ route('password.email') }}" class="space-y-5">
                @csrf

                <!-- Email -->
                <div>
                    <label for="email" class="block text-sm font-medium text-secondary-700 mb-2">Email</label>
                    <input type="email" id="email" name="email" value="{{ old('email') }}" required autofocus
                           class="form-input @error('email') border-danger-500 @enderror"
                           placeholder="nama@perusahaan.com">
                    @error('email')
                        <p class="mt-1 text-sm text-danger-500">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Submit -->
                <button type="submit" class="btn btn-primary w-full py-3.5">
                    Kirim Link Reset Password
                </button>
            </form>

            <!-- Back to Login -->
            <p class="text-center mt-8 text-secondary-600">
                Ingat password Anda?
                <a href="{{ route('login') }}" class="text-primary-600 hover:text-primary-700 font-semibold">Kembali ke Login</a>
            </p>
        </div>
    </div>
</div>
@endsection
