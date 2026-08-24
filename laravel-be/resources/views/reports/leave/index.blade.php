@extends('layouts.admin')

@section('title', 'Laporan Cuti')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Laporan Cuti</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Laporan Cuti</h1>
            <p class="text-secondary-500 mt-1">Rekap pengajuan dan penggunaan cuti karyawan</p>
        </div>
        <div class="flex items-center gap-2">
            <a id="btn-export-excel" href="{{ route('reports.leave.export', array_merge(request()->query(), ['format' => 'excel'])) }}" class="btn btn-secondary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Export Excel
            </a>
            <a id="btn-export-pdf" href="{{ route('reports.leave.export', array_merge(request()->query(), ['format' => 'pdf'])) }}" class="btn btn-primary">
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
            <a href="{{ route('reports.leave.balance') }}" class="btn btn-ghost btn-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
                Saldo Cuti
            </a>
            <a href="{{ route('reports.leave.by-type') }}" class="btn btn-ghost btn-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/></svg>
                Per Jenis Cuti
            </a>
        </div>

        {{-- Summary Stats --}}
        <div class="grid grid-cols-2 sm:grid-cols-5 gap-4 mb-4">
            <div class="stat-card">
                <p class="stat-card-label">Total Pengajuan</p>
                <p class="text-lg font-bold text-secondary-900">{{ $summary['total_requests'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Disetujui</p>
                <p class="text-lg font-bold text-success-600">{{ $summary['approved'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Menunggu</p>
                <p class="text-lg font-bold text-warning-600">{{ $summary['pending'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Ditolak</p>
                <p class="text-lg font-bold text-danger-600">{{ $summary['rejected'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Total Hari Cuti</p>
                <p class="text-lg font-bold text-primary-600">{{ $summary['total_days_approved'] }}</p>
            </div>
        </div>

        {{-- Filters with Live Search --}}
        <div class="card mb-4">
            <div class="card-body-sm">
                <form id="report-filter-form" action="{{ route('reports.leave') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
                    <div class="flex-1 min-w-[200px]">
                        <label for="search" class="block text-xs font-medium text-secondary-500 mb-1">Cari Karyawan</label>
                        <input
                            type="text"
                            name="search"
                            id="search"
                            value="{{ request('search') }}"
                            placeholder="Nama, ID, NIK, atau email..."
                            class="input w-full"
                            autocomplete="off"
                            @input="onSearchInput($event)"
                        >
                    </div>
                    <div class="w-32">
                        <label for="start_date" class="block text-xs font-medium text-secondary-500 mb-1">Dari Tanggal</label>
                        <input type="date" name="start_date" id="start_date" value="{{ $startDate }}" class="input w-full" @change="fetchData()">
                    </div>
                    <div class="w-32">
                        <label for="end_date" class="block text-xs font-medium text-secondary-500 mb-1">Sampai Tanggal</label>
                        <input type="date" name="end_date" id="end_date" value="{{ $endDate }}" class="input w-full" @change="fetchData()">
                    </div>
                    <div class="w-36">
                        <label for="leave_type_id" class="block text-xs font-medium text-secondary-500 mb-1">Jenis Cuti</label>
                        <select name="leave_type_id" id="leave_type_id" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            @foreach($leaveTypes as $leaveType)
                                <option value="{{ $leaveType->id }}" {{ request('leave_type_id') == $leaveType->id ? 'selected' : '' }}>{{ $leaveType->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="w-36">
                        <label for="department_id" class="block text-xs font-medium text-secondary-500 mb-1">Departemen</label>
                        <select name="department_id" id="department_id" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            @foreach($departments as $department)
                                <option value="{{ $department->id }}" {{ request('department_id') == $department->id ? 'selected' : '' }}>{{ $department->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="w-28">
                        <label for="status" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                        <select name="status" id="status" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            <option value="pending" {{ request('status') == 'pending' ? 'selected' : '' }}>Menunggu</option>
                            <option value="approved" {{ request('status') == 'approved' ? 'selected' : '' }}>Disetujui</option>
                            <option value="rejected" {{ request('status') == 'rejected' ? 'selected' : '' }}>Ditolak</option>
                            <option value="cancelled" {{ request('status') == 'cancelled' ? 'selected' : '' }}>Dibatalkan</option>
                        </select>
                    </div>
                    <div class="flex items-center gap-2">
                        <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" id="reset-btn" style="{{ request()->hasAny(['search', 'start_date', 'end_date', 'leave_type_id', 'department_id', 'status']) ? '' : 'display: none;' }}">
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

        {{-- Leave Requests Table --}}
        <div class="card" id="leave-report-table-card">
            <x-table>
                <x-slot name="header">
                    <th>Karyawan</th>
                    <th>Departemen</th>
                    <th>Jenis Cuti</th>
                    <th class="text-center">Tanggal Mulai</th>
                    <th class="text-center">Tanggal Selesai</th>
                    <th class="text-center">Hari</th>
                    <th class="text-center">Status</th>
                    <th>Keterangan</th>
                </x-slot>

                @forelse($leaveRequests as $leave)
                    <tr class="hover:bg-secondary-50/60 transition-colors">
                        <td>
                            <span class="font-medium text-secondary-900">{{ $leave->employee->full_name ?? '-' }}</span>
                            <p class="text-xs text-secondary-400">{{ $leave->employee->employee_id ?? '-' }}</p>
                        </td>
                        <td class="text-secondary-600">{{ $leave->employee->department?->name ?? '-' }}</td>
                        <td>
                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800">
                                {{ $leave->leaveType->name ?? '-' }}
                            </span>
                        </td>
                        <td class="text-center text-xs text-secondary-900">
                            {{ $leave->start_date->format('d M Y') }}
                        </td>
                        <td class="text-center text-xs text-secondary-900">
                            {{ $leave->end_date->format('d M Y') }}
                        </td>
                        <td class="text-center font-semibold text-secondary-900">
                            {{ $leave->total_days }}
                        </td>
                        <td class="text-center">
                            @switch($leave->status)
                                @case('pending')
                                    <x-badge type="warning">Menunggu</x-badge>
                                    @break
                                @case('approved')
                                    <x-badge type="success">Disetujui</x-badge>
                                    @break
                                @case('rejected')
                                    <x-badge type="danger">Ditolak</x-badge>
                                    @break
                                @case('cancelled')
                                    <x-badge type="secondary">Dibatalkan</x-badge>
                                    @break
                                @default
                                    <x-badge type="secondary">{{ ucfirst($leave->status) }}</x-badge>
                            @endswitch
                        </td>
                        <td class="text-secondary-600 text-xs max-w-xs truncate">{{ $leave->reason ?? '-' }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="text-center py-12">
                            <div class="flex flex-col items-center">
                                <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                                <p class="text-secondary-500">Tidak ada data pengajuan cuti untuk filter yang dipilih.</p>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </x-table>

            <div class="card-footer">
                <p class="text-sm text-secondary-500">Menampilkan {{ $leaveRequests->count() }} data pengajuan cuti</p>
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
                    
                    const excelUrl = new URL('{{ route('reports.leave.export') }}', window.location.origin);
                    const pdfUrl = new URL('{{ route('reports.leave.export') }}', window.location.origin);
                    
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
                    const leaveTypeVal = document.getElementById('leave_type_id')?.value || '';
                    const statusVal = document.getElementById('status')?.value || '';
                    const resetBtn = document.getElementById('reset-btn');
                    if (resetBtn) {
                        resetBtn.style.display = (searchVal || deptVal || leaveTypeVal || statusVal) ? '' : 'none';
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
                    const leaveTypeInput = document.getElementById('leave_type_id');
                    const statusInput = document.getElementById('status');

                    if (searchInput) searchInput.value = '';
                    if (deptInput) deptInput.value = '';
                    if (leaveTypeInput) leaveTypeInput.value = '';
                    if (statusInput) statusInput.value = '';

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
                        const newTable = doc.getElementById('leave-report-table-card');
                        const currentTable = document.getElementById('leave-report-table-card');
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
