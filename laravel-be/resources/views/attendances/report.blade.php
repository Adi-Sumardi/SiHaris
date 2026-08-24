@extends('layouts.admin')

@section('title', 'Laporan Kehadiran')

@section('breadcrumb')
    <a href="{{ route('attendances.index') }}" class="text-slate-500 hover:text-primary-600">Kehadiran</a>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Laporan</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Laporan Kehadiran</h1>
            <p class="text-secondary-500 mt-1">Rekap dan statistik kehadiran karyawan.</p>
        </div>
        <div class="flex items-center gap-3">
            <a href="{{ route('attendances.export', request()->query()) }}" id="btn-export-csv" class="btn btn-outline">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                Export CSV
            </a>
        </div>
    </div>
@endsection

@section('content')
    <div x-data="attendanceReportLiveFilter()">
        {{-- Filters with Live Search --}}
        <div class="card mb-4">
            <div class="card-body-sm">
                <form id="attendance-report-filter-form" action="{{ route('attendances.report') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
                    {{-- Month --}}
                    <div class="w-40">
                        <label for="month" class="block text-xs font-medium text-secondary-500 mb-1">Bulan</label>
                        <input
                            type="month"
                            name="month"
                            id="month"
                            value="{{ request('month', now()->format('Y-m')) }}"
                            class="input w-full"
                            @change="fetchData()"
                        >
                    </div>

                    {{-- Live Search Employee --}}
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

                    {{-- Status --}}
                    <div class="w-36">
                        <label for="status" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                        <select name="status" id="status" class="input w-full" @change="fetchData()">
                            <option value="">Semua Status</option>
                            <option value="present" {{ request('status') === 'present' ? 'selected' : '' }}>Hadir</option>
                            <option value="late" {{ request('status') === 'late' ? 'selected' : '' }}>Terlambat</option>
                            <option value="absent" {{ request('status') === 'absent' ? 'selected' : '' }}>Tidak Hadir</option>
                            <option value="leave" {{ request('status') === 'leave' ? 'selected' : '' }}>Cuti</option>
                        </select>
                    </div>

                    <div class="flex items-center gap-2">
                        <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" id="reset-btn" style="{{ (request('search') || request('status') || (request('month') && request('month') !== now()->format('Y-m'))) ? '' : 'display: none;' }}">
                            Reset
                        </button>
                        <button type="submit" class="btn btn-primary btn-sm flex items-center gap-1.5">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                            <span>Tampilkan</span>
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

        {{-- Dynamic Content Area --}}
        <div id="attendance-report-content">
            {{-- Summary Stats --}}
            <div class="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-3 mb-4">
                <div class="stat-card">
                    <p class="stat-card-label">Total Hadir</p>
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
                    <p class="stat-card-label">Cuti</p>
                    <p class="text-lg font-bold text-info-600">{{ $summary['leave'] }}</p>
                </div>
                <div class="stat-card">
                    <p class="stat-card-label">Jam Kerja</p>
                    <p class="text-lg font-bold text-primary-600">{{ $summary['total_working_hours'] }}j</p>
                </div>
                <div class="stat-card">
                    <p class="stat-card-label">Total Lembur</p>
                    <p class="text-lg font-bold text-primary-600">{{ $summary['total_overtime_hours'] }}j</p>
                </div>
                <div class="stat-card">
                    <p class="stat-card-label">Keterlambatan</p>
                    <p class="text-lg font-bold text-warning-600">{{ $summary['total_late_hours'] }}j</p>
                </div>
                <div class="stat-card">
                    <p class="stat-card-label">Karyawan</p>
                    <p class="text-lg font-bold text-secondary-900">{{ $summary['total_employees'] }}</p>
                </div>
            </div>

            {{-- Per Employee Report --}}
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Rekap Per Karyawan</h3>
                </div>
                <x-table>
                    <x-slot name="header">
                        <th>Karyawan</th>
                        <th class="text-center">Hadir</th>
                        <th class="text-center">Terlambat</th>
                        <th class="text-center">Tidak Hadir</th>
                        <th class="text-center">Cuti</th>
                        <th class="text-center">Jam Kerja</th>
                        <th class="text-center">Lembur</th>
                    </x-slot>

                    @forelse($reportData as $data)
                        <tr class="hover:bg-secondary-50/60 transition-colors">
                            <td>
                                <div class="flex items-center gap-2.5">
                                    <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center flex-shrink-0">
                                        <span class="text-primary-700 text-xs font-medium">{{ substr($data['employee']->first_name ?? 'K', 0, 1) }}</span>
                                    </div>
                                    <div class="min-w-0">
                                        <span class="font-medium text-secondary-900 block truncate">{{ $data['employee']->full_name ?? '-' }}</span>
                                        <p class="text-xs text-secondary-400 font-mono">{{ $data['employee']->employee_id ?? '-' }}</p>
                                    </div>
                                </div>
                            </td>
                            <td class="text-center">
                                <span class="text-success-600 font-semibold">{{ $data['present'] }}</span>
                            </td>
                            <td class="text-center">
                                <span class="text-warning-600 font-semibold">{{ $data['late'] }}</span>
                            </td>
                            <td class="text-center">
                                <span class="text-danger-600 font-semibold">{{ $data['absent'] }}</span>
                            </td>
                            <td class="text-center">
                                <span class="text-info-600 font-semibold">{{ $data['leave'] }}</span>
                            </td>
                            <td class="text-center font-mono text-xs">
                                <span class="font-medium text-secondary-700">{{ $data['working_hours'] }}j</span>
                            </td>
                            <td class="text-center font-mono text-xs">
                                @if($data['overtime_hours'] > 0)
                                    <span class="text-primary-600 font-semibold">{{ $data['overtime_hours'] }}j</span>
                                @else
                                    <span class="text-secondary-400">-</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="text-center py-12">
                                <div class="flex flex-col items-center">
                                    <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                                    <p class="text-secondary-500">Tidak ada data kehadiran yang sesuai dengan filter.</p>
                                </div>
                            </td>
                        </tr>
                    @endforelse
                </x-table>
            </div>
        </div>
    </div>

    <script>
        function attendanceReportLiveFilter() {
            return {
                loading: false,
                debounceTimer: null,

                updateExportUrl(url) {
                    const exportBtn = document.getElementById('btn-export-csv');
                    if (exportBtn) {
                        const exportBase = '{{ route("attendances.export") }}';
                        const exportUrl = new URL(exportBase, window.location.origin);
                        url.searchParams.forEach((value, key) => {
                            exportUrl.searchParams.set(key, value);
                        });
                        exportBtn.href = exportUrl.toString();
                    }
                },

                updateResetVisibility() {
                    const searchVal = document.getElementById('search')?.value || '';
                    const statusVal = document.getElementById('status')?.value || '';
                    const monthVal = document.getElementById('month')?.value || '';
                    const currentMonth = '{{ now()->format("Y-m") }}';
                    const resetBtn = document.getElementById('reset-btn');
                    if (resetBtn) {
                        resetBtn.style.display = (searchVal || statusVal || (monthVal && monthVal !== currentMonth)) ? '' : 'none';
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
                    const statusInput = document.getElementById('status');
                    const monthInput = document.getElementById('month');

                    if (searchInput) searchInput.value = '';
                    if (statusInput) statusInput.value = '';
                    if (monthInput) monthInput.value = '{{ now()->format("Y-m") }}';

                    this.updateResetVisibility();
                    this.fetchData(true);
                },

                fetchData(isReset = false) {
                    const form = document.getElementById('attendance-report-filter-form');
                    if (!form) return;

                    const url = new URL(form.action, window.location.origin);
                    if (!isReset) {
                        const formData = new FormData(form);
                        for (const [key, value] of formData.entries()) {
                            if (value && value.trim() !== '') {
                                url.searchParams.set(key, value.trim());
                            }
                        }
                    } else {
                        url.searchParams.set('month', '{{ now()->format("Y-m") }}');
                    }

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
                        const newContent = doc.getElementById('attendance-report-content');
                        const currentContent = document.getElementById('attendance-report-content');
                        if (newContent && currentContent) {
                            currentContent.innerHTML = newContent.innerHTML;
                        }
                        window.history.replaceState({}, '', url.toString());
                        this.updateExportUrl(url);
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
