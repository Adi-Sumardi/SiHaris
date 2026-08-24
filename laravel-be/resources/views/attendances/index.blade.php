@extends('layouts.admin')

@section('title', 'Daftar Kehadiran')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Kehadiran</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Daftar Kehadiran</h1>
            <p class="text-secondary-500 mt-1">Kelola data kehadiran karyawan.</p>
        </div>
        <div class="flex items-center gap-3">
            <form action="{{ route('attendances.sync-adms') }}" method="POST" class="inline">
                @csrf
                <input type="hidden" name="date" value="{{ request('date', date('Y-m-d')) }}">
                <button type="submit" class="btn btn-primary flex items-center gap-2" title="Tarik log presensi terbaru dari ADMS Cloud">
                    <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                    </svg>
                    Sync Presensi ADMS
                </button>
            </form>
        </div>
    </div>
@endsection

@section('content')
    {{-- Filters with Live Search --}}
    <div class="card mb-4" x-data="attendanceLiveFilter()">
        <div class="card-body-sm">
            <form id="attendance-filter-form" action="{{ route('attendances.index') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
                {{-- Search Employee --}}
                <div class="flex-1 min-w-[220px]">
                    <label for="search" class="block text-xs font-medium text-secondary-500 mb-1">Cari Karyawan</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                            </svg>
                        </div>
                        <input
                            type="text"
                            name="search"
                            id="search"
                            value="{{ request('search') }}"
                            placeholder="Ketik nama, NIK, atau email..."
                            class="input w-full pl-9 pr-8"
                            autocomplete="off"
                            x-ref="searchInput"
                            @input="onSearchInput($event)"
                        >
                        {{-- Clear Button --}}
                        <button
                            type="button"
                            x-show="searchQuery.length > 0"
                            @click="clearSearch()"
                            class="absolute inset-y-0 right-0 pr-2.5 flex items-center text-slate-400 hover:text-slate-600 transition-colors"
                            style="display: none;"
                            title="Hapus pencarian"
                        >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                            </svg>
                        </button>
                    </div>
                </div>

                {{-- Date --}}
                <div class="w-36">
                    <label for="date" class="block text-xs font-medium text-secondary-500 mb-1">Tanggal</label>
                    <input type="date" name="date" id="date" value="{{ request('date') }}" class="input w-full" @change="fetchData()">
                </div>

                {{-- Month --}}
                <div class="w-36">
                    <label for="month" class="block text-xs font-medium text-secondary-500 mb-1">Bulan</label>
                    <input type="month" name="month" id="month" value="{{ request('month') }}" class="input w-full" @change="fetchData()">
                </div>

                {{-- Status --}}
                <div class="w-36">
                    <label for="status" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                    <select name="status" id="status" class="input w-full" @change="fetchData()">
                        <option value="">Semua Status</option>
                        <option value="present" {{ request('status') === 'present' ? 'selected' : '' }}>Hadir</option>
                        <option value="absent" {{ request('status') === 'absent' ? 'selected' : '' }}>Tidak Hadir</option>
                        <option value="late" {{ request('status') === 'late' ? 'selected' : '' }}>Terlambat</option>
                        <option value="half_day" {{ request('status') === 'half_day' ? 'selected' : '' }}>Setengah Hari</option>
                        <option value="leave" {{ request('status') === 'leave' ? 'selected' : '' }}>Cuti</option>
                    </select>
                </div>

                <div class="flex items-center gap-2">
                    <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" x-show="hasActiveFilters" style="display: none;">
                        Reset
                    </button>
                    <div class="h-8 flex items-center px-1" x-show="loading" style="display: none;">
                        <svg class="animate-spin w-5 h-5 text-primary-600" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                        </svg>
                    </div>
                </div>
            </form>
        </div>
    </div>

    {{-- Attendance List Card --}}
    <div class="card relative" id="attendance-table-card">
        {{-- Loading Overlay --}}
        <div id="table-loading-overlay" class="hidden absolute inset-0 bg-white/60 backdrop-blur-[1px] z-10 flex items-center justify-center rounded-xl transition-all duration-200">
            <div class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-white shadow-md border border-slate-200 text-xs font-medium text-slate-600">
                <svg class="animate-spin w-4 h-4 text-primary-600" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                </svg>
                Memuat data...
            </div>
        </div>

        <x-table>
            <x-slot name="header">
                <th>Tanggal</th>
                <th>Karyawan</th>
                <th>Jam Masuk</th>
                <th>Jam Pulang</th>
                <th>Durasi</th>
                <th>Status</th>
                <th class="text-right">Aksi</th>
            </x-slot>

            @forelse($attendances as $attendance)
                <tr>
                    <td>
                        <span class="font-medium text-secondary-900">{{ $attendance->date->format('d M Y') }}</span>
                        <p class="text-xs text-secondary-400">{{ $attendance->date->translatedFormat('l') }}</p>
                    </td>
                    <td>
                        <div class="flex items-center gap-2.5">
                            <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center flex-shrink-0">
                                <span class="text-primary-700 text-xs font-medium">{{ substr($attendance->employee?->first_name ?? '?', 0, 1) }}</span>
                            </div>
                            <div class="min-w-0">
                                <span class="font-medium text-secondary-900 block truncate">{{ $attendance->employee?->full_name ?? 'Karyawan (Dihapus)' }}</span>
                                <p class="text-xs text-secondary-400">{{ $attendance->employee?->employee_id ?? '-' }}</p>
                            </div>
                        </div>
                    </td>
                    <td>
                        @if($attendance->clock_in)
                            <span class="font-medium text-secondary-900">{{ $attendance->formatted_clock_in }}</span>
                            @if($attendance->clock_in_status === 'late')
                                <p class="text-xs text-warning-600">Terlambat {{ $attendance->late_minutes }}m</p>
                            @elseif($attendance->clock_in_status === 'very_late')
                                <p class="text-xs text-danger-600">Sangat Terlambat</p>
                            @endif
                        @else
                            <span class="text-secondary-400">-</span>
                        @endif
                    </td>
                    <td>
                        @if($attendance->clock_out)
                            <span class="font-medium text-secondary-900">{{ $attendance->formatted_clock_out }}</span>
                            @if($attendance->clock_out_status === 'early')
                                <p class="text-xs text-warning-600">Pulang Awal</p>
                            @elseif($attendance->clock_out_status === 'overtime')
                                <p class="text-xs text-primary-600">Lembur {{ $attendance->overtime_minutes }}m</p>
                            @endif
                        @else
                            <span class="text-secondary-400">-</span>
                        @endif
                    </td>
                    <td>
                        @if($attendance->working_minutes > 0)
                            <span class="text-secondary-700">{{ $attendance->working_hours }}</span>
                        @else
                            <span class="text-secondary-400">-</span>
                        @endif
                    </td>
                    <td>
                        <x-badge :type="$attendance->status_color">{{ $attendance->status_label }}</x-badge>
                        @if($attendance->is_manual_entry)
                            <span class="text-xs text-secondary-400 block mt-0.5">Manual</span>
                        @endif
                    </td>
                    <td>
                        <div class="flex items-center justify-end gap-1">
                            <a href="{{ route('attendances.show', $attendance) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Detail">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                            </a>
                            <a href="{{ route('attendances.edit', $attendance) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Edit">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                            </a>
                            <button
                                type="button"
                                @click="$dispatch('confirm-dialog', {
                                    title: 'Hapus Data Kehadiran',
                                    message: 'Apakah Anda yakin ingin menghapus data kehadiran ini?',
                                    confirmText: 'Ya, Hapus',
                                    type: 'danger',
                                    formAction: '{{ route('attendances.destroy', $attendance) }}'
                                })"
                                class="p-1.5 text-secondary-400 hover:text-danger-600 hover:bg-danger-50 rounded-md transition-colors"
                                title="Hapus"
                            >
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                            </button>
                        </div>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" class="text-center py-12">
                        <div class="flex flex-col items-center">
                            <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>
                            <p class="text-secondary-500 font-medium">Belum ada data kehadiran untuk filter yang dipilih.</p>
                            <p class="text-xs text-secondary-400 mt-1">Data kehadiran otomatis tercatat dari mesin fingerprint ADMS dan absensi mobile face recognition.</p>
                        </div>
                    </td>
                </tr>
            @endforelse
        </x-table>

        @if($attendances->hasPages())
            <div class="card-footer" id="attendance-pagination">
                {{ $attendances->links() }}
            </div>
        @endif
    </div>

    <script>
        function attendanceLiveFilter() {
            return {
                searchQuery: '{{ addslashes(request('search', '')) }}',
                loading: false,
                debounceTimer: null,

                get hasActiveFilters() {
                    return this.searchQuery.length > 0 ||
                        (document.getElementById('date') && document.getElementById('date').value !== '') ||
                        (document.getElementById('month') && document.getElementById('month').value !== '') ||
                        (document.getElementById('status') && document.getElementById('status').value !== '');
                },

                onSearchInput(event) {
                    this.searchQuery = event.target.value;
                    clearTimeout(this.debounceTimer);
                    this.debounceTimer = setTimeout(() => {
                        this.fetchData();
                    }, 300);
                },

                clearSearch() {
                    this.searchQuery = '';
                    const searchInput = document.getElementById('search');
                    if (searchInput) {
                        searchInput.value = '';
                        searchInput.focus();
                    }
                    this.fetchData();
                },

                resetFilters() {
                    const form = document.getElementById('attendance-filter-form');
                    if (form) {
                        const dateInput = document.getElementById('date');
                        const monthInput = document.getElementById('month');
                        const statusInput = document.getElementById('status');
                        const searchInput = document.getElementById('search');

                        if (dateInput) dateInput.value = '';
                        if (monthInput) monthInput.value = '';
                        if (statusInput) statusInput.value = '';
                        if (searchInput) searchInput.value = '';

                        this.searchQuery = '';
                        this.fetchData(true);
                    }
                },

                fetchData(isReset = false) {
                    const form = document.getElementById('attendance-filter-form');
                    if (!form) return;

                    const url = new URL(form.action, window.location.origin);
                    if (!isReset) {
                        const formData = new FormData(form);
                        for (const [key, value] of formData.entries()) {
                            if (value && value.trim() !== '') {
                                url.searchParams.set(key, value.trim());
                            }
                        }
                    }

                    this.loading = true;
                    const overlay = document.getElementById('table-loading-overlay');
                    if (overlay) overlay.classList.remove('hidden');

                    fetch(url.toString(), {
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest'
                        }
                    })
                    .then(res => {
                        if (!res.ok) throw new Error('HTTP ' + res.status);
                        return res.text();
                    })
                    .then(html => {
                        const parser = new DOMParser();
                        const doc = parser.parseFromString(html, 'text/html');
                        const newTable = doc.getElementById('attendance-table-card');
                        const currentTable = document.getElementById('attendance-table-card');
                        if (newTable && currentTable) {
                            currentTable.innerHTML = newTable.innerHTML;
                        }
                        window.history.replaceState({}, '', url.toString());
                    })
                    .catch(err => {
                        console.error('Live search error:', err);
                    })
                    .finally(() => {
                        this.loading = false;
                        const ov = document.getElementById('table-loading-overlay');
                        if (ov) ov.classList.add('hidden');
                    });
                }
            };
        }

        // Handle AJAX navigation for pagination inside table
        document.addEventListener('click', function(e) {
            const pageLink = e.target.closest('#attendance-table-card .pagination a, #attendance-table-card nav a');
            if (pageLink && pageLink.href && !pageLink.href.includes('#')) {
                e.preventDefault();
                const overlay = document.getElementById('table-loading-overlay');
                if (overlay) overlay.classList.remove('hidden');

                fetch(pageLink.href, {
                    headers: { 'X-Requested-With': 'XMLHttpRequest' }
                })
                .then(res => res.text())
                .then(html => {
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(html, 'text/html');
                    const newTable = doc.getElementById('attendance-table-card');
                    const currentTable = document.getElementById('attendance-table-card');
                    if (newTable && currentTable) {
                        currentTable.innerHTML = newTable.innerHTML;
                    }
                    window.history.replaceState({}, '', pageLink.href);
                })
                .catch(err => {
                    window.location.href = pageLink.href;
                })
                .finally(() => {
                    const ov = document.getElementById('table-loading-overlay');
                    if (ov) ov.classList.add('hidden');
                });
            }
        });
    </script>
@endsection
