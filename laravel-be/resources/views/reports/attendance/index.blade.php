@extends('layouts.admin')

@section('title', 'Laporan Kehadiran')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Laporan Kehadiran</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Laporan Kehadiran</h1>
            <p class="text-secondary-500 mt-1">Rekap kehadiran karyawan</p>
        </div>
        <div class="flex items-center gap-2">
            <a id="btn-export-excel" href="{{ route('reports.attendance.export', array_merge(request()->query(), ['format' => 'excel'])) }}" class="btn btn-secondary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Export Excel
            </a>
            <a id="btn-export-pdf" href="{{ route('reports.attendance.export', array_merge(request()->query(), ['format' => 'pdf'])) }}" class="btn btn-primary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
                Export PDF
            </a>
        </div>
    </div>
@endsection

@section('content')
    <div x-data="reportLiveFilter()">
        {{-- Quick Links --}}
        <div class="flex flex-wrap gap-2 mb-6">
            <a href="{{ route('reports.attendance.daily') }}" class="btn btn-ghost btn-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                Harian
            </a>
            <a href="{{ route('reports.attendance.lateness') }}" class="btn btn-ghost btn-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                Keterlambatan
            </a>
        </div>

        {{-- Summary Stats --}}
        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4 mb-4">
            <div class="stat-card">
                <p class="stat-card-label">Total Record</p>
                <p class="text-lg font-bold text-secondary-900">{{ $summary['total'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Tepat Waktu</p>
                <p class="text-lg font-bold text-success-600">{{ $summary['present'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Terlambat</p>
                <p class="text-lg font-bold text-warning-600">{{ $summary['late'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Tidak Hadir</p>
                <p class="text-lg font-bold text-danger-600">{{ $summary['absent'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Total Terlambat</p>
                <p class="text-lg font-bold text-warning-600">{{ floor($summary['total_late_minutes'] / 60) }}j {{ $summary['total_late_minutes'] % 60 }}m</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Total Lembur</p>
                <p class="text-lg font-bold text-primary-600">{{ floor($summary['total_overtime_minutes'] / 60) }}j {{ $summary['total_overtime_minutes'] % 60 }}m</p>
            </div>
        </div>

        {{-- Filters with Live Search --}}
        <div class="card mb-4">
            <div class="card-body-sm">
                <form id="report-filter-form" action="{{ route('reports.attendance') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
                    <div class="flex-1 min-w-[200px]">
                        <label for="search" class="block text-xs font-medium text-secondary-500 mb-1">Cari Karyawan (Live)</label>
                        <input
                            type="text"
                            name="search"
                            id="search"
                            value="{{ request('search') }}"
                            placeholder="Nama, ID, NIK, PIN, atau email..."
                            class="input w-full"
                            autocomplete="off"
                            @input="onSearchInput($event)"
                        >
                    </div>
                    <div class="w-36">
                        <label for="start_date" class="block text-xs font-medium text-secondary-500 mb-1">Dari Tanggal</label>
                        <input type="date" name="start_date" id="start_date" value="{{ $startDate }}" class="input w-full" @change="fetchData()">
                    </div>
                    <div class="w-36">
                        <label for="end_date" class="block text-xs font-medium text-secondary-500 mb-1">Sampai Tanggal</label>
                        <input type="date" name="end_date" id="end_date" value="{{ $endDate }}" class="input w-full" @change="fetchData()">
                    </div>
                    <div class="w-40">
                        <label for="department_id" class="block text-xs font-medium text-secondary-500 mb-1">Departemen</label>
                        <select name="department_id" id="department_id" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            @foreach($departments as $department)
                                <option value="{{ $department->id }}" {{ request('department_id') == $department->id ? 'selected' : '' }}>{{ $department->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="flex items-center gap-2">
                        <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" id="reset-btn" style="{{ request()->hasAny(['search', 'start_date', 'end_date', 'department_id']) ? '' : 'display: none;' }}">
                            Reset
                        </button>
                        <button type="submit" class="btn btn-primary btn-sm flex items-center gap-1.5">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                            <span>Cari</span>
                        </button>
                        <div class="h-8 flex items-center px-1" x-show="loading" style="display: none;">
                            <svg class="animate-spin w-4 h-4 text-primary-600" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
                            </svg>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        {{-- Attendance Table --}}
        <div class="card" id="attendance-report-table-card">
            <x-table>
                <x-slot name="header">
                    <th>Tanggal</th>
                    <th>Karyawan</th>
                    <th>Departemen</th>
                    <th class="text-center">Clock In</th>
                    <th class="text-center">Clock Out</th>
                    <th class="text-center">Status</th>
                    <th class="text-right">Terlambat</th>
                    <th class="text-right">Lembur</th>
                </x-slot>

                @forelse($attendances as $attendance)
                    <tr class="hover:bg-secondary-50/60 transition-colors">
                        <td class="text-secondary-900 text-xs font-medium">{{ $attendance->date->format('d M Y') }}</td>
                        <td>
                            <span class="font-medium text-secondary-900">{{ $attendance->employee->full_name ?? '-' }}</span>
                            <p class="text-xs text-secondary-400">
                                {{ $attendance->employee->employee_id ?? '-' }}
                                @if($attendance->employee?->pin) | PIN: {{ $attendance->employee->pin }} @endif
                            </p>
                        </td>
                        <td class="text-secondary-600">{{ $attendance->employee->department?->name ?? '-' }}</td>
                        <td class="text-center text-secondary-900 font-mono text-xs">{{ $attendance->formatted_clock_in ?? '-' }}</td>
                        <td class="text-center text-secondary-900 font-mono text-xs">{{ $attendance->formatted_clock_out ?? '-' }}</td>
                        <td class="text-center">
                            @switch($attendance->clock_in_status)
                                @case('on_time')
                                    <x-badge type="success">Tepat Waktu</x-badge>
                                    @break
                                @case('late')
                                    <x-badge type="warning">Terlambat</x-badge>
                                    @break
                                @case('very_late')
                                    <x-badge type="danger">Sangat Terlambat</x-badge>
                                    @break
                                @default
                                    <x-badge type="secondary">{{ ucfirst($attendance->status) }}</x-badge>
                            @endswitch
                        </td>
                        <td class="text-right">
                            @if($attendance->late_minutes > 0)
                                <span class="text-warning-600 font-medium">{{ $attendance->late_minutes }}m</span>
                            @else
                                <span class="text-secondary-400">-</span>
                            @endif
                        </td>
                        <td class="text-right">
                            @if($attendance->overtime_minutes > 0)
                                <span class="text-primary-600 font-medium">{{ $attendance->overtime_minutes }}m</span>
                            @else
                                <span class="text-secondary-400">-</span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="text-center py-12">
                            <div class="flex flex-col items-center">
                                <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                <p class="text-secondary-500">Tidak ada data kehadiran untuk filter yang dipilih.</p>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </x-table>

            <div class="card-footer">
                <p class="text-sm text-secondary-500">Menampilkan {{ $attendances->count() }} data kehadiran</p>
            </div>
        </div>
    </div>

    <script>
        function reportLiveFilter() {
            return {
                loading: false,
                debounceTimer: null,

                updateExportLinks(url) {
                    const exportExcel = document.getElementById('btn-export-excel');
                    const exportPdf = document.getElementById('btn-export-pdf');
                    
                    const excelUrl = new URL('{{ route('reports.attendance.export') }}', window.location.origin);
                    const pdfUrl = new URL('{{ route('reports.attendance.export') }}', window.location.origin);
                    
                    for (const [k, v] of url.searchParams.entries()) {
                        excelUrl.searchParams.set(k, v);
                        pdfUrl.searchParams.set(k, v);
                    }
                    excelUrl.searchParams.set('format', 'excel');
                    pdfUrl.searchParams.set('format', 'pdf');
                    
                    if (exportExcel) exportExcel.href = excelUrl.toString();
                    if (exportPdf) exportPdf.href = pdfUrl.toString();
                },

                updateResetVisibility() {
                    const searchVal = document.getElementById('search')?.value || '';
                    const deptVal = document.getElementById('department_id')?.value || '';
                    const resetBtn = document.getElementById('reset-btn');
                    if (resetBtn) {
                        resetBtn.style.display = (searchVal || deptVal) ? '' : 'none';
                    }
                },

                onSearchInput(event) {
                    this.updateResetVisibility();
                    clearTimeout(this.debounceTimer);
                    this.debounceTimer = setTimeout(() => {
                        this.fetchData();
                    }, 300);
                },

                resetFilters() {
                    const searchInput = document.getElementById('search');
                    const deptInput = document.getElementById('department_id');

                    if (searchInput) searchInput.value = '';
                    if (deptInput) deptInput.value = '';

                    this.updateResetVisibility();
                    this.fetchData(true);
                },

                fetchData(isReset = false) {
                    const form = document.getElementById('report-filter-form');
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

                    this.updateExportLinks(url);
                    this.loading = true;

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
                        const newTable = doc.getElementById('attendance-report-table-card');
                        const currentTable = document.getElementById('attendance-report-table-card');
                        if (newTable && currentTable) {
                            currentTable.innerHTML = newTable.innerHTML;
                        }
                        window.history.replaceState({}, '', url.toString());
                        this.updateResetVisibility();
                    })
                    .catch(err => {
                        console.error('Live search error:', err);
                    })
                    .finally(() => {
                        this.loading = false;
                    });
                }
            };
        }
    </script>
@endsection
