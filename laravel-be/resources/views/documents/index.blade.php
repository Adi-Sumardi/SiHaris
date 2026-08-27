@extends('layouts.admin')

@section('title', 'Dokumen & Berkas Pegawai')

@section('breadcrumb')
    <a href="{{ route('employees.index') }}" class="text-slate-500 hover:text-primary-600">Karyawan</a>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Dokumen Pegawai</span>
@endsection

@section('content')
<div x-data="{ 
    previewOpen: false, 
    previewTitle: '', 
    previewUrl: '', 
    previewIsPdf: false,
    previewEmployee: '',
    previewDocNumber: '',
    uploadModalOpen: false,
    openPreview(title, url, isPdf, employee, docNumber) {
        this.previewTitle = title;
        this.previewUrl = url;
        this.previewIsPdf = isPdf;
        this.previewEmployee = employee || '';
        this.previewDocNumber = docNumber || '';
        this.previewOpen = true;
    }
}">

    {{-- Page Header --}}
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Dokumen & Berkas Pegawai</h1>
            <p class="text-secondary-500 mt-1 text-sm">Pusat arsip berkas digital penting (SK, Sertifikat, KTP, KK, Ijazah, dll) seluruh pegawai yayasan.</p>
        </div>
        <div class="flex items-center gap-3">
            <a href="{{ route('employees.index') }}" class="btn btn-secondary btn-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                Daftar Karyawan
            </a>
            <button type="button" @click="uploadModalOpen = true" class="btn btn-primary btn-sm flex items-center gap-1.5 shadow-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
                <span>Upload Dokumen</span>
            </button>
        </div>
    </div>

    {{-- Stats Cards Grid --}}
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-6">
        {{-- Total Berkas --}}
        <div class="stat-card">
            <div class="flex items-start justify-between">
                <div>
                    <p class="stat-card-label">Total Berkas</p>
                    <p class="stat-card-value">{{ number_format($stats['total_documents']) }}</p>
                </div>
                <div class="stat-card-icon bg-primary-50 text-primary-600">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                </div>
            </div>
            <div class="mt-3">
                <span class="text-xs text-secondary-500 font-medium">Arsip tersimpan di sistem</span>
            </div>
        </div>

        {{-- Pegawai Terdata --}}
        <div class="stat-card">
            <div class="flex items-start justify-between">
                <div>
                    <p class="stat-card-label">Pegawai Terdata</p>
                    <p class="stat-card-value">{{ number_format($stats['total_employees_uploaded']) }}</p>
                </div>
                <div class="stat-card-icon bg-emerald-50 text-emerald-600">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                </div>
            </div>
            <div class="mt-3">
                <span class="text-xs text-emerald-600 font-medium">Memiliki berkas terlampir</span>
            </div>
        </div>

        {{-- Surat Keputusan (SK) --}}
        <div class="stat-card">
            <div class="flex items-start justify-between">
                <div>
                    <p class="stat-card-label">Surat Keputusan (SK)</p>
                    <p class="stat-card-value">{{ number_format($stats['total_sk']) }}</p>
                </div>
                <div class="stat-card-icon bg-indigo-50 text-indigo-600">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                </div>
            </div>
            <div class="mt-3">
                <span class="text-xs text-indigo-600 font-medium">Dokumen legalitas pegawai</span>
            </div>
        </div>

        {{-- Sertifikat & Pelatihan --}}
        <div class="stat-card">
            <div class="flex items-start justify-between">
                <div>
                    <p class="stat-card-label">Sertifikat & Pelatihan</p>
                    <p class="stat-card-value">{{ number_format($stats['total_sertifikat']) }}</p>
                </div>
                <div class="stat-card-icon bg-amber-50 text-amber-600">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
                </div>
            </div>
            <div class="mt-3">
                <span class="text-xs text-amber-600 font-medium">Kompetensi & sertifikasi</span>
            </div>
        </div>
    </div>

    {{-- Filters & Quick Search Card --}}
    <div class="card mb-6">
        <div class="card-body-sm">
            <form method="GET" action="{{ route('documents.index') }}" class="flex flex-wrap items-end gap-3">
                {{-- Search Input --}}
                <div class="flex-1 min-w-[240px]">
                    <label for="search" class="block text-xs font-medium text-secondary-500 mb-1">Cari Pegawai / Judul / No. Berkas</label>
                    <div class="relative">
                        <input
                            type="text"
                            name="search"
                            id="search"
                            value="{{ request('search') }}"
                            placeholder="Cari nama, NIP, judul, no. berkas..."
                            class="input w-full pl-9 text-sm"
                            autocomplete="off"
                        >
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-secondary-400">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                        </div>
                    </div>
                </div>

                {{-- Department Filter --}}
                <div class="w-full sm:w-52">
                    <label for="department_id" class="block text-xs font-medium text-secondary-500 mb-1">Departemen / Unit</label>
                    <select name="department_id" id="department_id" class="input w-full text-sm">
                        <option value="">Semua Departemen</option>
                        @foreach($departments as $dept)
                            <option value="{{ $dept->id }}" {{ request('department_id') == $dept->id ? 'selected' : '' }}>
                                {{ $dept->name }}
                            </option>
                        @endforeach
                    </select>
                </div>

                {{-- Document Type Filter --}}
                <div class="w-full sm:w-52">
                    <label for="document_type" class="block text-xs font-medium text-secondary-500 mb-1">Jenis Dokumen</label>
                    <select name="document_type" id="document_type" class="input w-full text-sm">
                        <option value="">Semua Jenis Dokumen</option>
                        @foreach($documentTypes as $key => $label)
                            <option value="{{ $key }}" {{ request('document_type') === $key ? 'selected' : '' }}>
                                {{ $label }}
                            </option>
                        @endforeach
                    </select>
                </div>

                {{-- Action Buttons --}}
                <div class="flex items-center gap-2">
                    @if(request()->hasAny(['search', 'department_id', 'document_type']))
                        <a href="{{ route('documents.index') }}" class="btn btn-ghost btn-sm text-secondary-600 hover:text-secondary-900" title="Reset Filter">
                            Reset
                        </a>
                    @endif
                    <button type="submit" class="btn btn-primary btn-sm flex items-center gap-1.5 shadow-xs">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"/></svg>
                        <span>Filter</span>
                    </button>
                </div>
            </form>
        </div>

        {{-- Quick Filter Pills --}}
        <div class="px-4 py-2.5 bg-secondary-50/70 border-t border-secondary-100 flex items-center gap-2 overflow-x-auto scrollbar-hide text-xs">
            <span class="text-secondary-400 font-medium shrink-0 flex items-center gap-1 mr-1">
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/></svg>
                Kategori:
            </span>
            <a href="{{ route('documents.index', array_merge(request()->except('document_type', 'page'))) }}" 
               class="px-2.5 py-1 rounded-lg font-medium transition-colors shrink-0 {{ !request('document_type') ? 'bg-primary-600 text-white shadow-xs' : 'bg-white text-secondary-600 hover:bg-secondary-100 border border-secondary-200' }}">
                Semua ({{ $stats['total_documents'] }})
            </a>
            <a href="{{ route('documents.index', array_merge(request()->except('page'), ['document_type' => 'sk'])) }}" 
               class="px-2.5 py-1 rounded-lg font-medium transition-colors shrink-0 {{ request('document_type') === 'sk' ? 'bg-indigo-600 text-white shadow-xs' : 'bg-white text-secondary-600 hover:bg-secondary-100 border border-secondary-200' }}">
                SK ({{ $stats['total_sk'] }})
            </a>
            <a href="{{ route('documents.index', array_merge(request()->except('page'), ['document_type' => 'sertifikat'])) }}" 
               class="px-2.5 py-1 rounded-lg font-medium transition-colors shrink-0 {{ request('document_type') === 'sertifikat' ? 'bg-amber-600 text-white shadow-xs' : 'bg-white text-secondary-600 hover:bg-secondary-100 border border-secondary-200' }}">
                Sertifikat ({{ $stats['total_sertifikat'] }})
            </a>
            <a href="{{ route('documents.index', array_merge(request()->except('page'), ['document_type' => 'ktp'])) }}" 
               class="px-2.5 py-1 rounded-lg font-medium transition-colors shrink-0 {{ request('document_type') === 'ktp' ? 'bg-blue-600 text-white shadow-xs' : 'bg-white text-secondary-600 hover:bg-secondary-100 border border-secondary-200' }}">
                KTP ({{ $stats['total_ktp'] }})
            </a>
            <a href="{{ route('documents.index', array_merge(request()->except('page'), ['document_type' => 'kk'])) }}" 
               class="px-2.5 py-1 rounded-lg font-medium transition-colors shrink-0 {{ request('document_type') === 'kk' ? 'bg-emerald-600 text-white shadow-xs' : 'bg-white text-secondary-600 hover:bg-secondary-100 border border-secondary-200' }}">
                KK ({{ $stats['total_kk'] }})
            </a>
            <a href="{{ route('documents.index', array_merge(request()->except('page'), ['document_type' => 'ijazah'])) }}" 
               class="px-2.5 py-1 rounded-lg font-medium transition-colors shrink-0 {{ request('document_type') === 'ijazah' ? 'bg-purple-600 text-white shadow-xs' : 'bg-white text-secondary-600 hover:bg-secondary-100 border border-secondary-200' }}">
                Ijazah ({{ $stats['total_ijazah'] }})
            </a>
        </div>
    </div>

    {{-- Main Document Table Card --}}
    <div class="card">
        <x-table>
            <x-slot name="header">
                <th>Pegawai</th>
                <th>Jenis Berkas</th>
                <th>Nama & No. Dokumen</th>
                <th>File & Ukuran</th>
                <th>Tanggal Unggah</th>
                <th class="text-right">Aksi</th>
            </x-slot>

            @forelse($documents as $doc)
                @php
                    $isPdf = $doc->mime_type === 'application/pdf' || str_ends_with(strtolower($doc->file_name), '.pdf');
                    $badgeType = match($doc->document_type) {
                        'sk' => 'primary',
                        'sertifikat' => 'warning',
                        'ktp', 'ijazah' => 'info',
                        'kk', 'npwp' => 'success',
                        default => 'secondary',
                    };
                @endphp
                <tr class="hover:bg-secondary-50/60 transition-colors">
                    {{-- Pegawai Info --}}
                    <td>
                        <div class="flex items-center gap-3">
                            <div class="w-9 h-9 rounded-full bg-gradient-to-br from-primary-500 to-primary-700 text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-xs">
                                {{ $doc->employee ? strtoupper(substr($doc->employee->first_name ?? 'P', 0, 1)) : '?' }}
                            </div>
                            <div class="min-w-0">
                                <a href="{{ $doc->employee ? route('employees.show', $doc->employee) : '#' }}" class="font-semibold text-secondary-900 hover:text-primary-600 block truncate text-sm">
                                    {{ $doc->employee->full_name ?? 'Karyawan Tidak Diketahui' }}
                                </a>
                                <div class="flex items-center gap-1.5 text-xs text-secondary-400 mt-0.5">
                                    <span class="font-mono">{{ $doc->employee->employee_id ?? '-' }}</span>
                                    @if($doc->employee?->department)
                                        <span>•</span>
                                        <span class="text-secondary-600 truncate">{{ $doc->employee->department->name }}</span>
                                    @endif
                                </div>
                            </div>
                        </div>
                    </td>

                    {{-- Jenis Berkas Badge --}}
                    <td>
                        <x-badge :type="$badgeType">
                            {{ $doc->document_type_label }}
                        </x-badge>
                    </td>

                    {{-- Judul & Nomor Dokumen --}}
                    <td>
                        <div>
                            <span class="font-medium text-secondary-900 text-sm block">{{ $doc->document_name ?? $doc->document_type_label }}</span>
                            @if($doc->document_number)
                                <span class="text-xs font-mono bg-secondary-100 text-secondary-600 px-1.5 py-0.5 rounded mt-0.5 inline-block">
                                    No: {{ $doc->document_number }}
                                </span>
                            @endif
                        </div>
                    </td>

                    {{-- File Info --}}
                    <td>
                        <div class="flex items-center gap-2">
                            @if($isPdf)
                                <div class="w-7 h-7 rounded-md bg-danger-50 border border-danger-100 flex items-center justify-center shrink-0">
                                    <span class="text-[10px] font-bold text-danger-600">PDF</span>
                                </div>
                            @else
                                <div class="w-7 h-7 rounded-md bg-info-50 border border-info-100 flex items-center justify-center shrink-0">
                                    <span class="text-[10px] font-bold text-info-600">IMG</span>
                                </div>
                            @endif
                            <div class="text-xs min-w-0">
                                <p class="text-secondary-800 font-medium truncate max-w-[150px]" title="{{ $doc->file_name }}">{{ $doc->file_name }}</p>
                                <p class="text-secondary-400">{{ $doc->human_file_size }}</p>
                            </div>
                        </div>
                    </td>

                    {{-- Tanggal Unggah --}}
                    <td class="text-xs text-secondary-500 whitespace-nowrap">
                        <span class="text-secondary-800 font-medium block">{{ $doc->created_at ? $doc->created_at->format('d M Y') : '-' }}</span>
                        <span class="text-secondary-400">{{ $doc->created_at ? $doc->created_at->format('H:i') : '' }} WIB</span>
                    </td>

                    {{-- Aksi --}}
                    <td class="text-right">
                        <div class="flex items-center justify-end gap-1">
                            {{-- Preview button --}}
                            <button 
                                type="button"
                                @click="openPreview('{{ addslashes($doc->document_name ?? $doc->document_type_label) }}', '{{ route('documents.preview', $doc) }}', {{ $isPdf ? 'true' : 'false' }}, '{{ addslashes($doc->employee->full_name ?? '') }}', '{{ addslashes($doc->document_number ?? '') }}')"
                                class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors"
                                title="Pratinjau Berkas">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                            </button>

                            {{-- Download button --}}
                            <a href="{{ route('documents.download', $doc) }}" 
                               class="p-1.5 text-secondary-400 hover:text-success-600 hover:bg-success-50 rounded-lg transition-colors"
                               title="Unduh Berkas">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                            </a>

                            {{-- Delete button --}}
                            <form action="{{ route('documents.destroy', $doc) }}" method="POST" onsubmit="return confirm('Apakah Anda yakin ingin menghapus berkas ini?')" class="inline-block">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="p-1.5 text-secondary-400 hover:text-danger-600 hover:bg-danger-50 rounded-lg transition-colors" title="Hapus Berkas">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="6" class="p-0">
                        <div class="empty-state py-12">
                            <div class="empty-state-icon bg-primary-50 text-primary-600">
                                <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                            </div>
                            @if(request()->hasAny(['search', 'department_id', 'document_type']))
                                <h3 class="empty-state-title">Tidak Ada Dokumen Yang Cocok</h3>
                                <p class="empty-state-description">Tidak ditemukan berkas dokumen yang sesuai dengan kata kunci pencarian atau filter yang dipilih.</p>
                                <a href="{{ route('documents.index') }}" class="btn btn-secondary btn-sm inline-flex">
                                    Reset Filter
                                </a>
                            @else
                                <h3 class="empty-state-title">Belum Ada Berkas Pegawai Yang Diunggah</h3>
                                <p class="empty-state-description max-w-md mx-auto">Pegawai dapat mengunggah berkas SK, Sertifikat, KTP, dan KK melalui aplikasi mobile, atau HR dapat mengunggahnya secara langsung di sini.</p>
                                <div class="flex items-center justify-center gap-3 mt-4">
                                    <button type="button" @click="uploadModalOpen = true" class="btn btn-primary btn-sm flex items-center gap-2">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
                                        Upload Dokumen Sekarang
                                    </button>
                                    <a href="{{ route('employees.index') }}" class="btn btn-secondary btn-sm">
                                        Lihat Karyawan
                                    </a>
                                </div>
                            @endif
                        </div>
                    </td>
                </tr>
            @endforelse
        </x-table>

        @if($documents->hasPages())
            <div class="p-4 border-t border-secondary-100 bg-secondary-50/50">
                {{ $documents->links() }}
            </div>
        @endif
    </div>

    {{-- Upload Document Modal --}}
    <div 
        x-show="uploadModalOpen" 
        x-cloak 
        class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6"
        @keydown.escape.window="uploadModalOpen = false"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0">
        
        {{-- Backdrop --}}
        <div class="fixed inset-0 bg-secondary-900/60 backdrop-blur-xs" @click="uploadModalOpen = false"></div>

        {{-- Modal Content --}}
        <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg flex flex-col z-10 overflow-hidden border border-secondary-200 max-h-[90vh]"
             x-transition:enter="transition ease-out duration-200"
             x-transition:enter-start="opacity-0 scale-95"
             x-transition:enter-end="opacity-100 scale-100"
             x-transition:leave="transition ease-in duration-150"
             x-transition:leave-start="opacity-100 scale-100"
             x-transition:leave-end="opacity-0 scale-95">
            
            {{-- Modal Header --}}
            <div class="px-6 py-4 border-b border-secondary-100 flex items-center justify-between bg-secondary-50/50">
                <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-xl bg-primary-100 text-primary-600 flex items-center justify-center shrink-0">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
                    </div>
                    <div>
                        <h3 class="text-base font-bold text-secondary-900">Upload Berkas Pegawai</h3>
                        <p class="text-xs text-secondary-500">Unggah berkas digital untuk arsip karyawan</p>
                    </div>
                </div>
                <button type="button" @click="uploadModalOpen = false" class="p-1.5 text-secondary-400 hover:text-secondary-600 hover:bg-secondary-100 rounded-lg transition-colors">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>

            {{-- Modal Form --}}
            <form action="{{ route('documents.store') }}" method="POST" enctype="multipart/form-data" class="p-6 space-y-4 overflow-y-auto">
                @csrf
                
                {{-- Pegawai Selection --}}
                <div>
                    <label for="employee_id" class="form-label form-label-required">Pilih Karyawan</label>
                    <select name="employee_id" id="employee_id" required class="input">
                        <option value="">-- Pilih Karyawan --</option>
                        @foreach($employees as $emp)
                            <option value="{{ $emp->id }}" {{ old('employee_id') == $emp->id ? 'selected' : '' }}>
                                {{ $emp->full_name }} ({{ $emp->employee_id }})
                            </option>
                        @endforeach
                    </select>
                    @error('employee_id')
                        <p class="form-error">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Jenis Dokumen --}}
                <div>
                    <label for="upload_document_type" class="form-label form-label-required">Jenis Dokumen</label>
                    <select name="document_type" id="upload_document_type" required class="input">
                        @foreach($documentTypes as $key => $label)
                            <option value="{{ $key }}" {{ old('document_type') === $key ? 'selected' : '' }}>
                                {{ $label }}
                            </option>
                        @endforeach
                    </select>
                    @error('document_type')
                        <p class="form-error">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Judul & Nomor Berkas in 2 columns --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                        <label for="document_name" class="form-label">Nama Dokumen</label>
                        <input type="text" name="document_name" id="document_name" value="{{ old('document_name') }}" placeholder="Contoh: SK Pengangkatan 2025" class="input">
                    </div>
                    <div>
                        <label for="document_number" class="form-label">Nomor Dokumen</label>
                        <input type="text" name="document_number" id="document_number" value="{{ old('document_number') }}" placeholder="Contoh: 045/SK/YAPI/2025" class="input">
                    </div>
                </div>

                {{-- File Upload --}}
                <div>
                    <label for="file" class="form-label form-label-required">Pilih File (PDF, JPG, PNG)</label>
                    <input type="file" name="file" id="file" required accept=".pdf,.jpg,.jpeg,.png" class="input file:mr-3 file:py-1 file:px-3 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100">
                    <p class="form-help">Ukuran maksimal 10 MB. Format yang didukung: PDF, JPG, JPEG, PNG.</p>
                    @error('file')
                        <p class="form-error">{{ $message }}</p>
                    @enderror
                </div>

                {{-- Tanggal in 2 columns --}}
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                        <label for="issue_date" class="form-label">Tanggal Terbit</label>
                        <input type="date" name="issue_date" id="issue_date" value="{{ old('issue_date') }}" class="input">
                    </div>
                    <div>
                        <label for="expiry_date" class="form-label">Tanggal Berakhir</label>
                        <input type="date" name="expiry_date" id="expiry_date" value="{{ old('expiry_date') }}" class="input">
                    </div>
                </div>

                {{-- Notes --}}
                <div>
                    <label for="notes" class="form-label">Catatan Tambahan</label>
                    <textarea name="notes" id="notes" rows="2" placeholder="Catatan atau keterangan opsional..." class="input">{{ old('notes') }}</textarea>
                </div>

                {{-- Modal Footer --}}
                <div class="pt-4 border-t border-secondary-100 flex items-center justify-end gap-3">
                    <button type="button" @click="uploadModalOpen = false" class="btn btn-secondary btn-sm">
                        Batal
                    </button>
                    <button type="submit" class="btn btn-primary btn-sm flex items-center gap-2">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
                        Upload Sekarang
                    </button>
                </div>
            </form>
        </div>
    </div>

    {{-- In-Browser Document Preview Modal --}}
    <div 
        x-show="previewOpen" 
        x-cloak 
        class="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6"
        @keydown.escape.window="previewOpen = false"
        x-transition:enter="transition ease-out duration-200"
        x-transition:enter-start="opacity-0"
        x-transition:enter-end="opacity-100"
        x-transition:leave="transition ease-in duration-150"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0">
        
        {{-- Backdrop --}}
        <div class="fixed inset-0 bg-secondary-900/60 backdrop-blur-xs" @click="previewOpen = false"></div>

        {{-- Modal Dialog --}}
        <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-4xl h-[85vh] flex flex-col z-10 overflow-hidden border border-secondary-200"
             x-transition:enter="transition ease-out duration-200"
             x-transition:enter-start="opacity-0 scale-95"
             x-transition:enter-end="opacity-100 scale-100"
             x-transition:leave="transition ease-in duration-150"
             x-transition:leave-start="opacity-100 scale-100"
             x-transition:leave-end="opacity-0 scale-95">
            
            {{-- Modal Header --}}
            <div class="px-6 py-4 border-b border-secondary-100 flex items-center justify-between bg-secondary-50/50">
                <div class="flex items-center gap-3 min-w-0">
                    <div class="w-9 h-9 rounded-xl bg-primary-100 text-primary-600 flex items-center justify-center shrink-0">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                    </div>
                    <div class="min-w-0">
                        <h3 class="text-base font-bold text-secondary-900 truncate" x-text="previewTitle"></h3>
                        <div class="flex items-center gap-2 text-xs text-secondary-500 mt-0.5">
                            <span x-show="previewEmployee" x-text="previewEmployee" class="font-medium"></span>
                            <span x-show="previewDocNumber" class="font-mono bg-secondary-100 text-secondary-600 px-1.5 py-0.2 rounded" x-text="'No: ' + previewDocNumber"></span>
                        </div>
                    </div>
                </div>
                <div class="flex items-center gap-2 shrink-0">
                    <a :href="previewUrl" target="_blank" class="btn btn-ghost btn-sm text-primary-600 hover:bg-primary-50 flex items-center gap-1.5">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/></svg>
                        <span>Tab Baru</span>
                    </a>
                    <button type="button" @click="previewOpen = false" class="p-1.5 text-secondary-400 hover:text-secondary-600 hover:bg-secondary-100 rounded-lg transition-colors">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                    </button>
                </div>
            </div>

            {{-- Modal Body --}}
            <div class="flex-1 bg-secondary-100/50 p-4 flex items-center justify-center overflow-auto">
                <template x-if="previewIsPdf">
                    <iframe :src="previewUrl" class="w-full h-full rounded-xl border border-secondary-200 bg-white shadow-xs"></iframe>
                </template>
                <template x-if="!previewIsPdf">
                    <img :src="previewUrl" :alt="previewTitle" class="max-w-full max-h-full object-contain rounded-xl shadow-md border border-secondary-200 bg-white">
                </template>
            </div>
        </div>
    </div>
</div>
@endsection
