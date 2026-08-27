@extends('layouts.admin')

@section('title', 'Dokumen & Berkas Pegawai')

@section('breadcrumb')
    <a href="{{ route('employees.index') }}" class="text-slate-500 hover:text-primary-600">Karyawan</a>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Dokumen Pegawai</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-slate-900">Dokumen & Berkas Pegawai</h1>
            <p class="text-slate-500 mt-1">Pusat arsip berkas digital penting (SK, Sertifikat, KTP, KK, Ijazah, dll) seluruh pegawai yayasan</p>
        </div>
    </div>
@endsection

@section('content')
<div x-data="{ 
    previewOpen: false, 
    previewTitle: '', 
    previewUrl: '', 
    previewIsPdf: false,
    openPreview(title, url, isPdf) {
        this.previewTitle = title;
        this.previewUrl = url;
        this.previewIsPdf = isPdf;
        this.previewOpen = true;
    }
}" class="space-y-6">

    {{-- Stats Cards --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="card p-5 bg-white border border-slate-100 shadow-sm rounded-2xl flex items-center gap-4">
            <div class="w-12 h-12 rounded-xl bg-primary-50 text-primary-600 flex items-center justify-center shrink-0">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            </div>
            <div>
                <p class="text-xs font-medium text-slate-400 uppercase tracking-wider">Total Berkas</p>
                <h3 class="text-2xl font-bold text-slate-800 mt-0.5">{{ number_format($stats['total_documents']) }}</h3>
            </div>
        </div>

        <div class="card p-5 bg-white border border-slate-100 shadow-sm rounded-2xl flex items-center gap-4">
            <div class="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            </div>
            <div>
                <p class="text-xs font-medium text-slate-400 uppercase tracking-wider">Pegawai Terdata</p>
                <h3 class="text-2xl font-bold text-slate-800 mt-0.5">{{ number_format($stats['total_employees_uploaded']) }}</h3>
            </div>
        </div>

        <div class="card p-5 bg-white border border-slate-100 shadow-sm rounded-2xl flex items-center gap-4">
            <div class="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
            </div>
            <div>
                <p class="text-xs font-medium text-slate-400 uppercase tracking-wider">Surat Keputusan (SK)</p>
                <h3 class="text-2xl font-bold text-slate-800 mt-0.5">{{ number_format($stats['total_sk']) }}</h3>
            </div>
        </div>

        <div class="card p-5 bg-white border border-slate-100 shadow-sm rounded-2xl flex items-center gap-4">
            <div class="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shrink-0">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
            </div>
            <div>
                <p class="text-xs font-medium text-slate-400 uppercase tracking-wider">Sertifikat & Pelatihan</p>
                <h3 class="text-2xl font-bold text-slate-800 mt-0.5">{{ number_format($stats['total_sertifikat']) }}</h3>
            </div>
        </div>
    </div>

    {{-- Filter & Search Form --}}
    <div class="card p-5 bg-white border border-slate-100 shadow-sm rounded-2xl">
        <form method="GET" action="{{ route('documents.index') }}" class="grid grid-cols-1 sm:grid-cols-12 gap-3 items-end">
            {{-- Search input --}}
            <div class="sm:col-span-4">
                <label for="search" class="block text-xs font-semibold text-slate-600 mb-1.5">Cari Pegawai / Judul / No. Berkas</label>
                <div class="relative">
                    <input type="text" name="search" id="search" value="{{ request('search') }}" placeholder="Cari nama, NIP, judul berkas..." class="input w-full pl-9 text-sm rounded-xl border-slate-200">
                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    </div>
                </div>
            </div>

            {{-- Department Filter --}}
            <div class="sm:col-span-3">
                <label for="department_id" class="block text-xs font-semibold text-slate-600 mb-1.5">Departemen / Unit</label>
                <select name="department_id" id="department_id" class="input w-full text-sm rounded-xl border-slate-200">
                    <option value="">Semua Departemen</option>
                    @foreach($departments as $dept)
                        <option value="{{ $dept->id }}" {{ request('department_id') == $dept->id ? 'selected' : '' }}>
                            {{ $dept->name }}
                        </option>
                    @endforeach
                </select>
            </div>

            {{-- Document Type Filter --}}
            <div class="sm:col-span-3">
                <label for="document_type" class="block text-xs font-semibold text-slate-600 mb-1.5">Jenis Dokumen</label>
                <select name="document_type" id="document_type" class="input w-full text-sm rounded-xl border-slate-200">
                    <option value="">Semua Jenis Dokumen</option>
                    @foreach($documentTypes as $key => $label)
                        <option value="{{ $key }}" {{ request('document_type') === $key ? 'selected' : '' }}>
                            {{ $label }}
                        </option>
                    @endforeach
                </select>
            </div>

            {{-- Action buttons --}}
            <div class="sm:col-span-2 flex items-center gap-2">
                <button type="submit" class="btn btn-primary flex-1 justify-center rounded-xl">
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"/></svg>
                    Filter
                </button>
                @if(request()->hasAny(['search', 'department_id', 'document_type']))
                    <a href="{{ route('documents.index') }}" class="btn btn-ghost px-3 text-slate-500 hover:text-slate-700" title="Reset Filter">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                    </a>
                @endif
            </div>
        </form>
    </div>

    {{-- Main Document Table --}}
    <div class="card bg-white border border-slate-100 shadow-sm rounded-2xl overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm text-slate-600">
                <thead class="bg-slate-50/80 text-xs uppercase font-semibold text-slate-500 border-b border-slate-100">
                    <tr>
                        <th class="px-5 py-3.5">Pegawai</th>
                        <th class="px-4 py-3.5">Jenis Berkas</th>
                        <th class="px-4 py-3.5">Nama & No. Dokumen</th>
                        <th class="px-4 py-3.5">File & Ukuran</th>
                        <th class="px-4 py-3.5">Tanggal Unggah</th>
                        <th class="px-5 py-3.5 text-right">Aksi</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($documents as $doc)
                        @php
                            $isPdf = $doc->mime_type === 'application/pdf' || str_ends_with(strtolower($doc->file_name), '.pdf');
                            $isImg = str_starts_with((string)$doc->mime_type, 'image/');
                            $typeBadgeClass = match($doc->document_type) {
                                'sk' => 'bg-indigo-50 text-indigo-700 border-indigo-200/60',
                                'sertifikat' => 'bg-amber-50 text-amber-700 border-amber-200/60',
                                'ktp' => 'bg-blue-50 text-blue-700 border-blue-200/60',
                                'kk' => 'bg-emerald-50 text-emerald-700 border-emerald-200/60',
                                'ijazah' => 'bg-purple-50 text-purple-700 border-purple-200/60',
                                'npwp' => 'bg-teal-50 text-teal-700 border-teal-200/60',
                                'bpjs_kesehatan', 'bpjs_ketenagakerjaan' => 'bg-cyan-50 text-cyan-700 border-cyan-200/60',
                                default => 'bg-slate-100 text-slate-700 border-slate-200',
                            };
                        @endphp
                        <tr class="hover:bg-slate-50/50 transition-colors">
                            {{-- Pegawai Info --}}
                            <td class="px-5 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-full bg-gradient-to-br from-primary-500 to-primary-700 text-white flex items-center justify-center font-bold text-sm shrink-0 shadow-sm">
                                        {{ $doc->employee ? strtoupper(substr($doc->employee->name ?? 'P', 0, 1)) : '?' }}
                                    </div>
                                    <div>
                                        <a href="{{ $doc->employee ? route('employees.show', $doc->employee) : '#' }}" class="font-semibold text-slate-900 hover:text-primary-600 transition-colors">
                                            {{ $doc->employee->name ?? 'Karyawan Tidak Diketahui' }}
                                        </a>
                                        <div class="flex items-center gap-2 text-xs text-slate-500 mt-0.5">
                                            <span>NIP: {{ $doc->employee->employee_id ?? '-' }}</span>
                                            @if($doc->employee?->department)
                                                <span>•</span>
                                                <span class="text-slate-600">{{ $doc->employee->department->name }}</span>
                                            @endif
                                        </div>
                                    </div>
                                </div>
                            </td>

                            {{-- Jenis Berkas Badge --}}
                            <td class="px-4 py-4">
                                <span class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-semibold border {{ $typeBadgeClass }}">
                                    {{ $doc->document_type_label }}
                                </span>
                            </td>

                            {{-- Judul & Nomor Dokumen --}}
                            <td class="px-4 py-4">
                                <div>
                                    <p class="font-medium text-slate-900">{{ $doc->document_name ?? $doc->document_type_label }}</p>
                                    @if($doc->document_number)
                                        <p class="text-xs font-mono text-slate-500 mt-0.5">No: {{ $doc->document_number }}</p>
                                    @endif
                                </div>
                            </td>

                            {{-- File Info --}}
                            <td class="px-4 py-4">
                                <div class="flex items-center gap-2">
                                    @if($isPdf)
                                        <div class="w-7 h-7 rounded-lg bg-rose-50 border border-rose-100 flex items-center justify-center shrink-0">
                                            <span class="text-[10px] font-bold text-rose-600">PDF</span>
                                        </div>
                                    @else
                                        <div class="w-7 h-7 rounded-lg bg-blue-50 border border-blue-100 flex items-center justify-center shrink-0">
                                            <span class="text-[10px] font-bold text-blue-600">IMG</span>
                                        </div>
                                    @endif
                                    <div class="text-xs">
                                        <p class="text-slate-800 font-medium truncate max-w-[140px]" title="{{ $doc->file_name }}">{{ $doc->file_name }}</p>
                                        <p class="text-slate-400">{{ $doc->human_file_size }}</p>
                                    </div>
                                </div>
                            </td>

                            {{-- Tanggal Unggah --}}
                            <td class="px-4 py-4 text-xs text-slate-500 whitespace-nowrap">
                                <p class="text-slate-800 font-medium">{{ $doc->created_at ? $doc->created_at->format('d M Y') : '-' }}</p>
                                <p class="text-slate-400">{{ $doc->created_at ? $doc->created_at->format('H:i') : '' }} WIB</p>
                            </td>

                            {{-- Aksi --}}
                            <td class="px-5 py-4 text-right">
                                <div class="flex items-center justify-end gap-1.5">
                                    {{-- Preview button --}}
                                    <button 
                                        type="button"
                                        @click="openPreview('{{ addslashes($doc->document_name ?? $doc->document_type_label) }}', '{{ route('documents.preview', $doc) }}', {{ $isPdf ? 'true' : 'false' }})"
                                        class="p-2 text-slate-500 hover:text-primary-600 hover:bg-primary-50 rounded-xl transition-colors"
                                        title="Preview Berkas">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                    </button>

                                    {{-- Download button --}}
                                    <a href="{{ route('documents.download', $doc) }}" 
                                       class="p-2 text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 rounded-xl transition-colors"
                                       title="Download Berkas">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                                    </a>

                                    {{-- Delete button --}}
                                    <form action="{{ route('documents.destroy', $doc) }}" method="POST" onsubmit="return confirm('Apakah Anda yakin ingin menghapus berkas ini?')" class="inline-block">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors" title="Hapus Berkas">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-5 py-12 text-center text-slate-400">
                                <div class="flex flex-col items-center justify-center">
                                    <div class="w-16 h-16 rounded-2xl bg-slate-50 flex items-center justify-center mb-3 text-slate-300">
                                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                                    </div>
                                    <p class="font-medium text-slate-600">Belum ada berkas pegawai yang diunggah</p>
                                    <p class="text-xs text-slate-400 mt-1">Pegawai dapat mengunggah berkas SK, Sertifikat, KTP, dan KK melalui aplikasi mobile</p>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($documents->hasPages())
            <div class="p-4 border-t border-slate-100 bg-slate-50/50">
                {{ $documents->links() }}
            </div>
        @endif
    </div>

    {{-- In-Browser Document Preview Modal --}}
    <div 
        x-show="previewOpen" 
        x-cloak 
        class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0">
        
        {{-- Backdrop --}}
        <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm" @click="previewOpen = false"></div>

        {{-- Modal Dialog --}}
        <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-4xl h-[85vh] flex flex-col z-10 overflow-hidden border border-slate-100">
            {{-- Modal Header --}}
            <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-primary-50 text-primary-600 flex items-center justify-center font-bold">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                    </div>
                    <div>
                        <h3 class="text-base font-bold text-slate-800" x-text="previewTitle"></h3>
                        <p class="text-xs text-slate-400">Pratinjau Dokumen Digital</p>
                    </div>
                </div>
                <div class="flex items-center gap-2">
                    <a :href="previewUrl" target="_blank" class="btn btn-ghost btn-sm text-primary-600 hover:bg-primary-50">
                        Buka di Tab Baru
                    </a>
                    <button type="button" @click="previewOpen = false" class="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-xl transition-colors">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                    </button>
                </div>
            </div>

            {{-- Modal Body --}}
            <div class="flex-1 bg-slate-900/5 p-4 flex items-center justify-center overflow-auto">
                <template x-if="previewIsPdf">
                    <iframe :src="previewUrl" class="w-full h-full rounded-xl border border-slate-200 bg-white shadow-inner"></iframe>
                </template>
                <template x-if="!previewIsPdf">
                    <img :src="previewUrl" :alt="previewTitle" class="max-w-full max-h-full object-contain rounded-xl shadow-lg border border-slate-200 bg-white">
                </template>
            </div>
        </div>
    </div>
</div>
@endsection
