@extends('layouts.guest')

@section('title', 'Download SiHaris Mobile App - Android & iOS')
@section('description', 'Unduh aplikasi mobile SiHaris untuk absensi GPS, selfie face recognition, pengajuan cuti, lembur, dan slip gaji digital.')

@section('content')
    @include('components.navbar')

    {{-- Hero Section --}}
    <section class="bg-hero-gradient pt-32 pb-20 text-white">
        <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <div class="inline-flex items-center gap-2 bg-white/10 backdrop-blur-sm rounded-full px-4 py-1.5 mb-6 border border-white/20 shadow-sm">
                <span class="w-2.5 h-2.5 bg-accent-400 rounded-full animate-pulse"></span>
                <span class="text-sm font-medium tracking-wide">Versi Terbaru v{{ $version }}</span>
            </div>

            <h1 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-extrabold tracking-tight leading-tight mb-6">
                Download Aplikasi<br>
                <span class="text-primary-300">SiHaris Mobile</span>
            </h1>

            <p class="text-base sm:text-lg md:text-xl text-primary-100 max-w-2xl mx-auto leading-relaxed">
                Kelola presensi GPS & face recognition, pengajuan cuti, lembur, serta cek slip gaji digital kapan saja langsung dari smartphone Anda.
            </p>
        </div>
    </section>

    {{-- Main Content Section --}}
    <section class="py-12 bg-slate-50 min-h-[60vh]">
        <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
            
            {{-- Smart Auto-Download Banner for Mobile --}}
            @if ($device === 'android')
                <div id="auto-download-box" class="max-w-2xl mx-auto mb-10 bg-white border-2 border-emerald-400 rounded-3xl p-6 text-center shadow-lg shadow-emerald-500/10">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto mb-3">
                        <svg class="w-6 h-6 animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                        </svg>
                    </div>
                    <h3 class="text-lg font-bold text-slate-900 mb-1">Perangkat Android Terdeteksi</h3>
                    <p class="text-sm text-slate-600 mb-4" id="countdown-text">
                        Download APK dimulai otomatis dalam <span id="countdown" class="font-bold text-emerald-600 text-base">2</span> detik...
                    </p>
                    <div class="w-full bg-slate-100 rounded-full h-2 overflow-hidden max-w-xs mx-auto mb-4">
                        <div id="countdown-bar" class="bg-emerald-500 h-2 rounded-full transition-all duration-1000 ease-linear" style="width: 100%"></div>
                    </div>
                    <p class="text-xs text-slate-400">
                        Jika download tidak berjalan otomatis, silakan klik tombol hijau di bawah.
                    </p>
                </div>
            @elseif ($device === 'ios')
                <div class="max-w-2xl mx-auto mb-10 bg-white border-2 border-blue-400 rounded-3xl p-6 text-center shadow-lg shadow-blue-500/10">
                    <div class="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mx-auto mb-3">
                        <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 3.5c.62-.75 1.04-1.8 1.01-2.85-.92.04-2.04.62-2.7 1.39-.58.67-1.09 1.74-1.04 2.8 1.03.08 2.11-.59 2.73-1.34z"/>
                        </svg>
                    </div>
                    <h3 class="text-lg font-bold text-slate-900 mb-1">Perangkat iPhone / iPad Terdeteksi</h3>
                    <p class="text-sm text-slate-600">
                        Aplikasi SiHaris dapat diakses langsung via Web App (PWA) di Safari atau melalui paket instalasi iOS.
                    </p>
                </div>
            @endif

            {{-- Main Download Cards --}}
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-16">
                
                {{-- Android Card --}}
                <div class="relative bg-white rounded-3xl p-8 border {{ $device === 'android' ? 'border-emerald-400 ring-4 ring-emerald-400/10 shadow-xl' : 'border-slate-200 shadow-sm hover:shadow-md' }} transition-all duration-300 flex flex-col justify-between">
                    @if ($device === 'android')
                        <div class="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-emerald-600 text-white text-xs font-bold px-4 py-1 rounded-full uppercase tracking-wider shadow-sm flex items-center gap-1.5">
                            <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                            </svg>
                            Sesuai Perangkat Anda
                        </div>
                    @endif

                    <div>
                        <div class="flex items-center justify-between mb-6">
                            <div class="w-16 h-16 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-100 shadow-inner">
                                <svg class="w-9 h-9" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.551 0 .9993.4482.9993.9993.0001.5511-.4483.9997-.9993.9997m-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.5511 0 .9993.4482.9993.9993 0 .5511-.4482.9997-.9993.9997m11.4045-6.02l1.996-3.4572c.1556-.2696.0633-.6139-.2064-.7695-.2692-.1555-.6135-.0633-.7691.2064l-2.0231 3.504c-1.5034-.6873-3.1772-1.0716-4.9789-1.0716-1.8018 0-3.4756.3843-4.979 1.0716L4.898 6.3011c-.1556-.2697-.4999-.3619-.7691-.2064-.2697.1556-.362.4999-.2064.7695l1.996 3.4572C2.6841 12.0833.5 15.6983.5 19.8213h23c0-4.123-2.1841-7.738-5.6185-9.5z"/>
                                </svg>
                            </div>
                            <span class="text-xs font-semibold px-3 py-1 rounded-full bg-slate-100 text-slate-700 border border-slate-200">
                                Android 8.0+
                            </span>
                        </div>

                        <h3 class="text-2xl font-bold text-slate-900 mb-2">Android (.APK)</h3>
                        <p class="text-sm text-slate-600 mb-6 leading-relaxed">
                            Unduh dan instal langsung berkas APK resmi SiHaris dengan performa maksimal.
                        </p>

                        <div class="space-y-2.5 mb-8 text-xs text-slate-600 bg-slate-50 p-4 rounded-2xl border border-slate-100">
                            <div class="flex justify-between">
                                <span class="text-slate-400">Versi:</span>
                                <span class="font-semibold text-slate-800">v{{ $version }}</span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-slate-400">Ukuran File:</span>
                                <span class="font-semibold text-slate-800">{{ $apkSize }}</span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-slate-400">Pembaruan:</span>
                                <span class="font-semibold text-slate-800">{{ $apkModifiedAt }}</span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-slate-400">Keamanan:</span>
                                <span class="font-semibold text-emerald-600 flex items-center gap-1">
                                    <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 1.944A11.954 11.954 0 012.166 5C2.056 5.649 2 6.319 2 7c0 5.225 3.34 9.67 8 11.317C14.66 16.67 18 12.225 18 7c0-.682-.057-1.35-.166-2.001A11.954 11.954 0 0110 1.944zM11 14a1 1 0 11-2 0 1 1 0 012 0zm0-7a1 1 0 10-2 0v3a1 1 0 102 0V7z" clip-rule="evenodd"/></svg>
                                    Terverifikasi &amp; Aman
                                </span>
                            </div>
                        </div>
                    </div>

                    <a href="{{ route('app.download.android') }}" id="btn-download-android" class="w-full py-4 px-6 rounded-2xl bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 text-white font-bold text-center shadow-lg shadow-emerald-600/30 hover:shadow-emerald-600/40 transition-all duration-200 flex items-center justify-center gap-2 group text-base">
                        <svg class="w-5 h-5 transition-transform group-hover:-translate-y-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                        </svg>
                        <span>Download APK Android</span>
                    </a>
                </div>

                {{-- iOS Card --}}
                <div class="relative bg-white rounded-3xl p-8 border {{ $device === 'ios' ? 'border-blue-400 ring-4 ring-blue-400/10 shadow-xl' : 'border-slate-200 shadow-sm hover:shadow-md' }} transition-all duration-300 flex flex-col justify-between">
                    @if ($device === 'ios')
                        <div class="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-blue-600 text-white text-xs font-bold px-4 py-1 rounded-full uppercase tracking-wider shadow-sm flex items-center gap-1.5">
                            <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                            </svg>
                            Sesuai Perangkat Anda
                        </div>
                    @endif

                    <div>
                        <div class="flex items-center justify-between mb-6">
                            <div class="w-16 h-16 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center border border-blue-100 shadow-inner">
                                <svg class="w-9 h-9" fill="currentColor" viewBox="0 0 24 24">
                                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 3.5c.62-.75 1.04-1.8 1.01-2.85-.92.04-2.04.62-2.7 1.39-.58.67-1.09 1.74-1.04 2.8 1.03.08 2.11-.59 2.73-1.34z"/>
                                </svg>
                            </div>
                            <span class="text-xs font-semibold px-3 py-1 rounded-full bg-slate-100 text-slate-700 border border-slate-200">
                                iOS 14.0+
                            </span>
                        </div>

                        <h3 class="text-2xl font-bold text-slate-900 mb-2">Apple iPhone & iPad</h3>
                        <p class="text-sm text-slate-600 mb-6 leading-relaxed">
                            Akses cepat tanpa instalasi lewat Safari Web App (PWA) atau pasang paket iOS.
                        </p>

                        <div class="space-y-2.5 mb-8 text-xs text-slate-600 bg-slate-50 p-4 rounded-2xl border border-slate-100">
                            <div class="flex justify-between">
                                <span class="text-slate-400">Bundle ID:</span>
                                <span class="font-mono font-semibold text-slate-800">id.yapinet.siharis</span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-slate-400">Metode Utama:</span>
                                <span class="font-semibold text-blue-600">Safari &gt; Add to Home Screen</span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-slate-400">Status Server:</span>
                                <span class="font-semibold text-emerald-600">HTTPS SSL Aktif</span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-slate-400">Domain:</span>
                                <span class="font-mono font-semibold text-slate-800">siharis.yapinet.id</span>
                            </div>
                        </div>
                    </div>

                    @if ($ipaExists)
                        <a href="{{ route('app.download.ios') }}" class="w-full py-4 px-6 rounded-2xl bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white font-bold text-center shadow-lg shadow-blue-600/30 hover:shadow-blue-600/40 transition-all duration-200 flex items-center justify-center gap-2 group text-base">
                            <svg class="w-5 h-5 transition-transform group-hover:-translate-y-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                            </svg>
                            <span>Download Paket iOS (.IPA)</span>
                        </a>
                    @else
                        <a href="{{ route('portal.dashboard') }}" class="w-full py-4 px-6 rounded-2xl bg-slate-900 hover:bg-slate-800 active:bg-black text-white font-bold text-center shadow-lg shadow-slate-900/20 hover:shadow-slate-900/30 transition-all duration-200 flex items-center justify-center gap-2 group text-base">
                            <svg class="w-5 h-5 text-blue-400 transition-transform group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"/>
                            </svg>
                            <span>Buka Web App di iPhone</span>
                        </a>
                    @endif
                </div>
            </div>

            {{-- QR Code for Desktop Viewers --}}
            @if ($device === 'desktop')
                <div class="max-w-2xl mx-auto mb-16 bg-white rounded-3xl p-8 border border-slate-200 shadow-sm text-center">
                    <div class="w-12 h-12 rounded-2xl bg-primary-50 text-primary-600 flex items-center justify-center mx-auto mb-3">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-slate-900 mb-2">Buka Langsung di Smartphone Anda</h3>
                    <p class="text-sm text-slate-600 mb-6">Scan QR code berikut dengan kamera HP Anda untuk langsung membuka halaman download otomatis:</p>
                    
                    <div class="inline-block p-4 bg-white rounded-2xl border-2 border-dashed border-primary-200 shadow-inner mb-4">
                        <img src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data={{ urlencode(route('app.download')) }}" alt="QR Code Download SiHaris" class="w-44 h-44 rounded-lg mx-auto" />
                    </div>
                    
                    <div class="text-xs font-mono text-slate-600 bg-slate-50 py-2.5 px-4 rounded-xl max-w-sm mx-auto border border-slate-200">
                        {{ route('app.download') }}
                    </div>
                </div>
            @endif

            {{-- Step-by-Step Installation Guides --}}
            <div class="max-w-4xl mx-auto">
                <div class="text-center mb-8">
                    <h2 class="text-2xl font-bold text-slate-900">Panduan Pemasangan Aplikasi</h2>
                    <p class="text-sm text-slate-500">Ikuti petunjuk praktis di bawah untuk memulai</p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {{-- Android Guide --}}
                    <div class="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm">
                        <div class="flex items-center gap-3 mb-4">
                            <div class="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
                                1
                            </div>
                            <h4 class="font-bold text-slate-900">Panduan Pengguna Android</h4>
                        </div>
                        <ol class="space-y-3 text-sm text-slate-600 list-decimal list-inside">
                            <li>Klik tombol <strong>Download APK Android</strong> di atas.</li>
                            <li>Buka file hasil unduhan pada menu notifikasi atau berkas Download.</li>
                            <li>Jika muncul peringatan <em>"Instal dari sumber tidak dikenal"</em>, pilih <strong>Izinkan / Lanjutkan</strong>.</li>
                            <li>Ketuk <strong>Instal</strong> dan buka aplikasi SiHaris untuk login.</li>
                        </ol>
                    </div>

                    {{-- iOS Guide --}}
                    <div class="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm">
                        <div class="flex items-center gap-3 mb-4">
                            <div class="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
                                2
                            </div>
                            <h4 class="font-bold text-slate-900">Panduan Pengguna iPhone (Safari)</h4>
                        </div>
                        <ol class="space-y-3 text-sm text-slate-600 list-decimal list-inside">
                            <li>Buka alamat <strong>siharis.yapinet.id</strong> menggunakan <strong>Safari</strong>.</li>
                            <li>Ketuk tombol <strong>Share</strong> (ikon kotak dengan panah ke atas di bagian bawah Safari).</li>
                            <li>Gulir ke bawah dan pilih <strong>"Add to Home Screen" (Tambah ke Layar Utama)</strong>.</li>
                            <li>Ikon SiHaris akan terpasang di layar utama iPhone Anda seperti aplikasi bawaan.</li>
                        </ol>
                    </div>
                </div>
            </div>

        </div>
    </section>

    {{-- Auto-Download Script for Android --}}
    @if ($device === 'android')
        <script>
            document.addEventListener('DOMContentLoaded', function() {
                let seconds = 2;
                const countdownEl = document.getElementById('countdown');
                const barEl = document.getElementById('countdown-bar');
                const countdownText = document.getElementById('countdown-text');

                const interval = setInterval(function() {
                    seconds--;
                    if (countdownEl) {
                        countdownEl.textContent = seconds;
                    }
                    if (barEl) {
                        barEl.style.width = (seconds / 2 * 100) + '%';
                    }

                    if (seconds <= 0) {
                        clearInterval(interval);
                        if (countdownText) {
                            countdownText.innerHTML = '<span class="text-emerald-700 font-bold">Sedang mengunduh APK...</span> Jika belum berjalan otomatis, klik tombol hijau di bawah.';
                        }
                        window.location.href = "{{ route('app.download.android') }}";
                    }
                }, 1000);
            });
        </script>
    @endif

@endsection
