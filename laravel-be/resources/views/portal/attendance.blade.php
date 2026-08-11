@extends('layouts.portal')

@section('title', 'Absensi')

@section('breadcrumb')
    <a href="{{ route('portal.dashboard') }}" class="text-slate-500 hover:text-primary-600">Dashboard</a>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Absensi</span>
@endsection

@section('header')
    <div>
        <h1 class="text-2xl font-bold text-secondary-900">Absensi</h1>
        <p class="text-secondary-500 mt-1">Kelola absensi harian Anda.</p>
    </div>
@endsection

@section('content')
    <div class="grid gap-6 lg:grid-cols-3">
        {{-- Clock In/Out Card --}}
        <div class="card lg:col-span-1">
            <div class="card-header">
                <h3 class="card-title">Absensi Hari Ini</h3>
            </div>
            <div class="card-body">
                <div class="text-center mb-6">
                    <div class="text-4xl font-bold text-secondary-900" x-data x-init="
                        setInterval(() => {
                            $el.textContent = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
                        }, 1000);
                    ">{{ now()->format('H:i:s') }}</div>
                    <div class="text-secondary-500 mt-1">{{ now()->translatedFormat('l, d F Y') }}</div>
                </div>

                @if($todayAttendance)
                    <div class="space-y-4">
                        <div class="flex items-center justify-between p-3 bg-success-50 rounded-lg">
                            <div class="flex items-center gap-3">
                                <div class="w-10 h-10 rounded-full bg-success-100 flex items-center justify-center">
                                    <svg class="w-5 h-5 text-success-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"/></svg>
                                </div>
                                <div>
                                    <div class="text-sm text-secondary-500">Clock In</div>
                                    <div class="font-semibold text-secondary-900">{{ $todayAttendance->formatted_clock_in }}</div>
                                </div>
                            </div>
                            @if($todayAttendance->status === 'late')
                                <x-badge type="warning">Terlambat</x-badge>
                            @else
                                <x-badge type="success">Tepat Waktu</x-badge>
                            @endif
                        </div>

                        @if($todayAttendance->clock_out)
                            <div class="flex items-center justify-between p-3 bg-danger-50 rounded-lg">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-full bg-danger-100 flex items-center justify-center">
                                        <svg class="w-5 h-5 text-danger-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
                                    </div>
                                    <div>
                                        <div class="text-sm text-secondary-500">Clock Out</div>
                                        <div class="font-semibold text-secondary-900">{{ $todayAttendance->formatted_clock_out }}</div>
                                    </div>
                                </div>
                            </div>
                        @else
                            <div x-data="attendanceGpsForm({{ $employee->company->enable_gps_validation ? 'true' : 'false' }})">
                                <form action="{{ route('portal.attendance.clock-out') }}" method="POST" x-ref="form" @submit.prevent="submitWithLocation">
                                    @csrf
                                    <input type="hidden" name="latitude" x-model="latitude">
                                    <input type="hidden" name="longitude" x-model="longitude">
                                    <button type="submit" class="btn btn-danger w-full" :disabled="loading">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
                                        <span x-text="loading ? 'Mengambil lokasi...' : 'Clock Out'"></span>
                                    </button>
                                    <p x-show="error" x-cloak x-text="error" class="mt-2 text-sm text-danger-600"></p>
                                </form>
                            </div>
                        @endif
                    </div>
                @else
                    <div x-data="attendanceGpsForm({{ $employee->company->enable_gps_validation ? 'true' : 'false' }})">
                        <form action="{{ route('portal.attendance.clock-in') }}" method="POST" x-ref="form" @submit.prevent="submitWithLocation">
                            @csrf
                            <input type="hidden" name="latitude" x-model="latitude">
                            <input type="hidden" name="longitude" x-model="longitude">
                            <button type="submit" class="btn btn-primary btn-lg w-full" :disabled="loading">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"/></svg>
                                <span x-text="loading ? 'Mengambil lokasi...' : 'Clock In'"></span>
                            </button>
                            <p x-show="error" x-cloak x-text="error" class="mt-2 text-sm text-danger-600"></p>
                        </form>
                    </div>
                @endif
            </div>
        </div>

        {{-- Face Verification Card --}}
        @if($faceRecognitionEnabled)
            <div class="card lg:col-span-1">
                <div class="card-header">
                    <h3 class="card-title">Verifikasi Wajah</h3>
                </div>
                <div class="card-body">
                    @if($hasFaceEnrolled)
                        <div class="text-center">
                            <div class="w-16 h-16 bg-success-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                <svg class="w-8 h-8 text-success-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                            </div>
                            <h4 class="font-medium text-secondary-900 mb-1">Wajah Terdaftar (Dikunci)</h4>
                            <p class="text-sm text-secondary-500 mb-3">
                                Wajah Anda telah terdaftar untuk verifikasi absensi.
                            </p>
                            <div class="p-3 bg-secondary-50 rounded-lg text-xs text-secondary-500 mb-3">
                                🔒 Pendaftaran mandiri telah dikunci. Jika ingin memperbarui foto wajah, silakan hubungi Admin / HR.
                            </div>
                            <p class="text-xs text-secondary-400">
                                Terdaftar: {{ $employee->faceEmbedding->enrolled_at->format('d M Y H:i') }}
                            </p>
                        </div>
                    @else
                        <div class="text-center" x-data="faceEnrollComp()">
                            <div class="w-16 h-16 bg-warning-100 rounded-full flex items-center justify-center mx-auto mb-3">
                                <svg class="w-8 h-8 text-warning-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                                </svg>
                            </div>
                            <h4 class="font-medium text-warning-600 mb-1">Wajah Belum Terdaftar</h4>
                            <p class="text-xs text-secondary-500 mb-4">
                                Wajah Anda belum terdaftar. Anda dapat mendaftarkan foto wajah <strong>1 kali secara mandiri dari Kamera Depan</strong>. Pendaftaran akan langsung dikunci setelah tersimpan.
                            </p>

                            <div x-show="!showForm">
                                <button type="button" @click="openForm()" class="btn btn-primary w-full text-sm py-2">
                                    📸 Buka Kamera Depan (1x)
                                </button>
                            </div>

                            <div x-show="showForm" x-transition class="mt-4 text-left border-t border-secondary-200 pt-4">
                                <!-- Mode Switcher -->
                                <div class="flex border-b border-secondary-200 mb-3 text-xs">
                                    <button type="button" @click="setMode('camera')" :class="mode === 'camera' ? 'border-b-2 border-primary-600 text-primary-600 font-semibold' : 'text-secondary-500'" class="pb-2 px-3">📷 Kamera HP Depan</button>
                                    <button type="button" @click="setMode('file')" :class="mode === 'file' ? 'border-b-2 border-primary-600 text-primary-600 font-semibold' : 'text-secondary-500'" class="pb-2 px-3">📁 Upload File Foto</button>
                                </div>

                                <form action="{{ route('portal.face-recognition.enroll') }}" method="POST" enctype="multipart/form-data" @submit="beforeSubmit($event)">
                                    @csrf
                                    <input type="hidden" name="photo_base64" x-model="photoBase64">

                                    <!-- Camera View -->
                                    <div x-show="mode === 'camera'" class="mb-3">
                                        <div class="relative w-full aspect-[4/3] bg-black rounded-xl overflow-hidden mb-2 flex items-center justify-center">
                                            <video x-ref="video" autoplay playsinline class="w-full h-full object-cover transform scale-x-[-1]" x-show="isCameraOn && !capturedImage"></video>
                                            <img :src="capturedImage" class="w-full h-full object-cover transform scale-x-[-1]" x-show="capturedImage">
                                            
                                            <div x-show="!isCameraOn && !capturedImage" class="text-center p-4 text-white text-xs">
                                                <p class="mb-2">Kamera depan belum aktif.</p>
                                                <button type="button" @click="startCamera()" class="btn btn-sm btn-primary text-xs">▶️ Aktifkan Kamera Depan</button>
                                            </div>

                                            <!-- Overlay Oval Guideline -->
                                            <div x-show="isCameraOn && !capturedImage" class="absolute inset-0 border-2 border-dashed border-white/60 rounded-full my-4 mx-12 pointer-events-none flex items-center justify-center">
                                                <span class="text-[10px] text-white bg-black/50 px-2 py-0.5 rounded">Posisikan Wajah Di Sini</span>
                                            </div>
                                        </div>

                                        <div class="flex gap-2 mb-2">
                                            <button type="button" x-show="isCameraOn && !capturedImage" @click="snapPhoto()" class="btn btn-primary w-full text-xs py-2">📸 Ambil Foto Wajah</button>
                                            <button type="button" x-show="capturedImage" @click="retakePhoto()" class="btn btn-secondary w-full text-xs py-2">🔄 Ambil Ulang</button>
                                        </div>
                                    </div>

                                    <!-- File View -->
                                    <div x-show="mode === 'file'" class="mb-3">
                                        <label class="block text-xs font-semibold text-secondary-700 mb-2">Pilih File Foto Wajah</label>
                                        <input type="file" name="photo" accept="image/*" capture="user" :required="mode === 'file'"
                                               class="block w-full text-xs text-secondary-500 file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100">
                                    </div>

                                    <p class="text-[11px] text-secondary-400 mb-3">
                                        ⚠️ Pastikan foto wajah terlihat jelas dan pencahayaan terang. Setelah disimpan, pendaftaran mandiri dikunci.
                                    </p>

                                    <div class="flex gap-2">
                                        <button type="submit" class="btn btn-primary flex-1 text-xs py-2" :disabled="mode === 'camera' && !capturedImage">💾 Simpan & Kunci (1x)</button>
                                        <button type="button" @click="closeForm()" class="btn btn-secondary text-xs py-2">Batal</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    @endif
                </div>
            </div>
        @endif

        {{-- Attendance History --}}
        <div class="card {{ $faceRecognitionEnabled ? 'lg:col-span-1' : 'lg:col-span-2' }}">
            <div class="card-header">
                <h3 class="card-title">Riwayat Absensi</h3>
            </div>
            <div class="card-body p-0">
                <div class="overflow-x-auto">
                    <table class="w-full">
                        <thead class="bg-secondary-50">
                            <tr>
                                <th class="px-4 py-3 text-left text-sm font-medium text-secondary-500">Tanggal</th>
                                <th class="px-4 py-3 text-center text-sm font-medium text-secondary-500">Clock In</th>
                                <th class="px-4 py-3 text-center text-sm font-medium text-secondary-500">Clock Out</th>
                                <th class="px-4 py-3 text-center text-sm font-medium text-secondary-500">Status</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-secondary-100">
                            @forelse($attendanceHistory as $attendance)
                                <tr>
                                    <td class="px-4 py-3">
                                        <div class="font-medium text-secondary-900">{{ $attendance->date->format('d M Y') }}</div>
                                        <div class="text-sm text-secondary-500">{{ $attendance->date->translatedFormat('l') }}</div>
                                    </td>
                                    <td class="px-4 py-3 text-center">
                                        {{ $attendance->clock_in?->format('H:i') ?? '-' }}
                                    </td>
                                    <td class="px-4 py-3 text-center">
                                        {{ $attendance->clock_out?->format('H:i') ?? '-' }}
                                    </td>
                                    <td class="px-4 py-3 text-center">
                                        @switch($attendance->status)
                                            @case('present')
                                                <x-badge type="success">Hadir</x-badge>
                                                @break
                                            @case('late')
                                                <x-badge type="warning">Terlambat</x-badge>
                                                @break
                                            @case('absent')
                                                <x-badge type="danger">Tidak Hadir</x-badge>
                                                @break
                                            @default
                                                <x-badge type="secondary">{{ ucfirst($attendance->status) }}</x-badge>
                                        @endswitch
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="4" class="px-4 py-8 text-center text-secondary-500">
                                        Belum ada riwayat absensi
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
            @if($attendanceHistory->hasPages())
                <div class="card-footer">
                    {{ $attendanceHistory->links() }}
                </div>
            @endif
        </div>
    </div>
@endsection

@push('scripts')
<script>
    document.addEventListener('alpine:init', () => {
        Alpine.data('faceEnrollComp', () => ({
            showForm: false,
            mode: 'camera',
            isCameraOn: false,
            capturedImage: null,
            photoBase64: '',
            stream: null,

            openForm() {
                this.showForm = true;
                this.setMode('camera');
            },

            closeForm() {
                this.stopCamera();
                this.showForm = false;
            },

            setMode(newMode) {
                this.mode = newMode;
                if (newMode === 'camera' && !this.capturedImage && !this.isCameraOn) {
                    this.startCamera();
                } else if (newMode === 'file') {
                    this.stopCamera();
                }
            },

            async startCamera() {
                this.capturedImage = null;
                this.photoBase64 = '';
                try {
                    this.stream = await navigator.mediaDevices.getUserMedia({
                        video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } }
                    });
                    this.$refs.video.srcObject = this.stream;
                    this.isCameraOn = true;
                } catch (err) {
                    console.error("Camera access error:", err);
                    alert("Gagal mengaktifkan kamera depan. Pastikan izin kamera telah diberikan di browser atau gunakan tab 'Upload File Foto'.");
                    this.mode = 'file';
                }
            },

            stopCamera() {
                if (this.stream) {
                    this.stream.getTracks().forEach(track => track.stop());
                    this.stream = null;
                }
                this.isCameraOn = false;
            },

            snapPhoto() {
                const video = this.$refs.video;
                const canvas = document.createElement('canvas');
                canvas.width = video.videoWidth || 640;
                canvas.height = video.videoHeight || 480;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                this.capturedImage = canvas.toDataURL('image/jpeg', 0.85);
                this.photoBase64 = this.capturedImage;
                this.stopCamera();
            },

            retakePhoto() {
                this.capturedImage = null;
                this.photoBase64 = '';
                this.startCamera();
            },

            beforeSubmit(e) {
                if (this.mode === 'camera' && !this.photoBase64) {
                    e.preventDefault();
                    alert('Silakan ambil foto wajah terlebih dahulu menggunakan kamera depan.');
                }
            }
        }));

        Alpine.data('attendanceGpsForm', (gpsRequired) => ({
            latitude: '',
            longitude: '',
            loading: false,
            error: '',

            submitWithLocation() {
                if (!gpsRequired) {
                    this.$refs.form.submit();
                    return;
                }

                if (!navigator.geolocation) {
                    this.error = 'Perangkat Anda tidak mendukung layanan lokasi. Gunakan aplikasi mobile untuk absen.';
                    return;
                }

                this.loading = true;
                this.error = '';

                navigator.geolocation.getCurrentPosition(
                    (position) => {
                        this.latitude = position.coords.latitude;
                        this.longitude = position.coords.longitude;
                        this.$nextTick(() => this.$refs.form.submit());
                    },
                    () => {
                        this.loading = false;
                        this.error = 'Izin lokasi ditolak. Aktifkan akses lokasi untuk melakukan absensi.';
                    },
                    { enableHighAccuracy: true, timeout: 10000 }
                );
            },
        }));
    });
</script>
@endpush
