@extends('layouts.admin')

@section('title', 'Import Data PIN')

@section('breadcrumb')
    <a href="{{ route('fingerprint-devices.index') }}" class="text-slate-500 hover:text-primary-600">Mesin Fingerprint</a>
    <svg class="w-4 h-4 mx-2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Import Data PIN</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Import Data PIN</h1>
            <p class="text-secondary-500 mt-1">Upload file Excel untuk memperbarui PIN banyak karyawan sekaligus, lalu otomatis dipush ke ADMS.</p>
        </div>
        <div class="flex items-center gap-3">
            <a href="{{ route('fingerprint-devices.index') }}" class="btn btn-ghost">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
                Kembali
            </a>
        </div>
    </div>
@endsection

@section('content')
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {{-- Import Status (shown when processing/completed) --}}
        @if(session('import_id'))
            <div class="lg:col-span-2" x-data="pinImportStatus('{{ session('import_id') }}')" x-init="startPolling()">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title">Status Import</h3>
                    </div>
                    <div class="card-body">
                        {{-- Processing State --}}
                        <div x-show="status === 'processing'" class="text-center py-8">
                            <svg class="animate-spin w-12 h-12 mx-auto text-primary-500 mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            <p class="text-lg font-medium text-secondary-700 mb-2">Sedang Memproses &amp; Push ke ADMS...</p>
                            <p class="text-sm text-secondary-500">Proses berjalan di background. Anda bisa meninggalkan halaman ini.</p>
                        </div>

                        {{-- Completed / Failed content --}}
                        <div x-show="status === 'completed'" x-cloak>
                            <div class="grid grid-cols-3 gap-3 mb-6">
                                <div class="rounded-xl p-4 bg-success-50">
                                    <div class="text-2xl font-bold text-success-700" x-text="successCount"></div>
                                    <div class="text-xs font-medium text-success-700 mt-1">Berhasil di-push ke ADMS</div>
                                </div>
                                <div class="rounded-xl p-4 bg-danger-50">
                                    <div class="text-2xl font-bold text-danger-700" x-text="failedCount"></div>
                                    <div class="text-xs font-medium text-danger-700 mt-1">Gagal &mdash; perlu ditinjau</div>
                                </div>
                                <div class="rounded-xl p-4 bg-secondary-100">
                                    <div class="text-2xl font-bold text-secondary-600" x-text="skipCount"></div>
                                    <div class="text-xs font-medium text-secondary-600 mt-1">Dilewati</div>
                                </div>
                            </div>

                            <div class="flex justify-center gap-3 mb-2">
                                <a href="{{ route('fingerprint-devices.index') }}" class="btn btn-primary">Lihat Mesin Fingerprint</a>
                                <button @click="resetForm()" class="btn btn-secondary">Import Lagi</button>
                            </div>
                        </div>

                        <div x-show="status === 'failed'" x-cloak class="text-center py-8">
                            <svg class="w-16 h-16 mx-auto text-danger-500 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                            </svg>
                            <p class="text-lg font-medium text-danger-700 mb-2">Import Gagal</p>
                            <p class="text-sm text-secondary-500" x-text="errorMessage"></p>
                            <div class="mt-6">
                                <button @click="resetForm()" class="btn btn-primary">Coba Lagi</button>
                            </div>
                        </div>

                        {{-- Errors / Failures List --}}
                        <div x-show="errors.length > 0" x-cloak class="mt-6 border-t pt-4">
                            <h4 class="font-medium text-danger-700 mb-2">Detail Baris Gagal / Dilewati:</h4>
                            <div class="max-h-60 overflow-y-auto">
                                <ul class="list-disc list-inside space-y-1 text-sm text-secondary-600">
                                    <template x-for="error in errors.slice(0, 100)" :key="error">
                                        <li x-text="error"></li>
                                    </template>
                                </ul>
                                <p x-show="errors.length > 100" class="mt-2 text-sm text-secondary-500">
                                    ... dan <span x-text="errors.length - 100"></span> lainnya
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        @else
        {{-- Upload Form --}}
        <div class="lg:col-span-2">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Upload File</h3>
                </div>
                <div class="card-body">
                    <form action="{{ route('imports.pins.store') }}" method="POST" enctype="multipart/form-data">
                        @csrf

                        <div class="mb-6">
                            <label class="block text-sm font-medium text-secondary-700 mb-2">File Excel</label>
                            <div class="border-2 border-dashed border-secondary-300 rounded-lg p-8 text-center hover:border-primary-400 transition-colors cursor-pointer"
                                 id="dropzone"
                                 ondragover="event.preventDefault(); this.classList.add('border-primary-500', 'bg-primary-50');"
                                 ondragleave="this.classList.remove('border-primary-500', 'bg-primary-50');"
                                 ondrop="handleFileDrop(event, 'file')">
                                <input type="file" name="file" id="file" accept=".xlsx,.xls,.csv" class="hidden" onchange="updateFileName(this)">
                                <label for="file" class="cursor-pointer">
                                    <svg class="w-12 h-12 mx-auto text-secondary-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
                                    </svg>
                                    <p class="text-secondary-600 mb-1" id="file-name">Klik untuk memilih file atau drag &amp; drop</p>
                                    <p class="text-sm text-secondary-400">Format: .xlsx, .xls, .csv (Maks. 20MB)</p>
                                </label>
                            </div>
                            @error('file')
                                <p class="mt-2 text-sm text-danger-600">{{ $message }}</p>
                            @enderror
                        </div>

                        <div class="flex items-center justify-end gap-3">
                            <a href="{{ route('imports.pins.template') }}" class="btn btn-secondary">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                                Download Template
                            </a>
                            <button type="submit" class="btn btn-primary">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 11l5-5m0 0l5 5m-5-5v12"/></svg>
                                Import &amp; Push ke ADMS
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            @if(session('import_errors'))
                <div class="card mt-6">
                    <div class="card-header">
                        <h3 class="card-title text-danger-600">Peringatan Import</h3>
                    </div>
                    <div class="card-body max-h-60 overflow-y-auto">
                        <ul class="list-disc list-inside space-y-1 text-sm text-secondary-600">
                            @foreach(session('import_errors') as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                </div>
            @endif
        </div>
        @endif

        {{-- Instructions --}}
        <div class="lg:col-span-1">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Panduan Import PIN</h3>
                </div>
                <div class="card-body space-y-4 text-sm text-secondary-600">
                    <div class="bg-warning-50 text-warning-700 p-3 rounded-lg">
                        <p class="font-medium mb-1">Hanya untuk karyawan yang sudah terdaftar di ADMS.</p>
                        <p class="text-xs">Karyawan baru yang belum pernah di-enroll sidik jarinya tetap perlu didaftarkan langsung di mesin &mdash; import ini tidak bisa menggantikan proses itu.</p>
                    </div>

                    <div>
                        <h4 class="font-medium text-secondary-900 mb-2">Kolom Template:</h4>
                        <ul class="space-y-1 text-xs">
                            <li><span class="font-medium">ID Karyawan</span> (wajib) &ndash; NIP internal SiHaris, dipakai untuk mencocokkan baris</li>
                            <li><span class="font-medium">Nama Karyawan</span> (referensi) &ndash; boleh diisi bebas, tidak dipakai untuk mencocokkan</li>
                            <li><span class="font-medium">PIN Baru</span> (wajib) &ndash; nilai PIN yang akan dipush ke ADMS</li>
                        </ul>
                    </div>

                    <div>
                        <h4 class="font-medium text-secondary-900 mb-2">Yang terjadi setelah upload:</h4>
                        <ul class="space-y-1 text-xs list-decimal list-inside">
                            <li>Setiap baris dicocokkan ke data karyawan di SiHaris.</li>
                            <li>PIN karyawan di SiHaris diperbarui.</li>
                            <li>PIN baru otomatis dikirim ke ADMS untuk setiap karyawan yang sudah terdaftar sidik jarinya.</li>
                            <li>Ringkasan hasil (berhasil / gagal / dilewati) ditampilkan setelah proses selesai.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function updateFileName(input) {
            const fileNameEl = document.getElementById('file-name');
            if (!fileNameEl) return;
            if (input.files && input.files[0]) {
                const file = input.files[0];
                const sizeInMb = (file.size / (1024 * 1024)).toFixed(2);
                fileNameEl.innerHTML = `<span class="font-medium text-secondary-900">${file.name}</span> <span class="text-xs text-secondary-500">(${sizeInMb} MB)</span>`;
            } else {
                fileNameEl.textContent = 'Klik untuk memilih file atau drag & drop';
            }
        }

        function handleFileDrop(event, inputId) {
            event.preventDefault();
            event.currentTarget.classList.remove('border-primary-500', 'bg-primary-50');
            const files = event.dataTransfer?.files;
            if (files && files.length > 0) {
                const fileInput = document.getElementById(inputId);
                if (fileInput) {
                    fileInput.files = files;
                    updateFileName(fileInput);
                }
            }
        }

        function pinImportStatus(importId) {
            return {
                importId: importId,
                status: 'processing',
                successCount: 0,
                failedCount: 0,
                skipCount: 0,
                errors: [],
                errorMessage: '',
                polling: null,

                async checkStatus() {
                    try {
                        const response = await fetch(`{{ url('imports/pins/status') }}/${this.importId}`, {
                            headers: {
                                'Accept': 'application/json',
                                'X-Requested-With': 'XMLHttpRequest'
                            }
                        });
                        if (!response.ok) {
                            if (response.status === 404) {
                                this.status = 'failed';
                                this.errorMessage = 'Sesi import tidak ditemukan atau telah kedaluwarsa.';
                                this.stopPolling();
                            }
                            return;
                        }

                        const data = await response.json();
                        this.status = data.status;
                        this.successCount = data.success_count || 0;
                        this.failedCount = data.failed_count || 0;
                        this.skipCount = data.skip_count || 0;
                        this.errors = data.errors || [];
                        this.errorMessage = data.error_message || '';

                        if (this.status === 'completed' || this.status === 'failed') {
                            this.stopPolling();
                        }
                    } catch (error) {
                        console.error('Error checking import status:', error);
                    }
                },

                startPolling() {
                    this.checkStatus();
                    this.polling = setInterval(() => this.checkStatus(), 2000);
                },

                stopPolling() {
                    if (this.polling) {
                        clearInterval(this.polling);
                        this.polling = null;
                    }
                },

                resetForm() {
                    window.location.href = '{{ route('imports.pins.index') }}';
                }
            };
        }
    </script>
@endsection
