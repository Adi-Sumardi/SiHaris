@extends('layouts.admin')

@section('title', 'Laporan Karyawan')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Laporan Karyawan</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Laporan Karyawan</h1>
            <p class="text-secondary-500 mt-1">Lihat dan export data karyawan perusahaan</p>
        </div>
        <div class="flex items-center gap-2">
            <a id="btn-export-excel" href="{{ route('reports.employees.export', array_merge(request()->query(), ['format' => 'excel'])) }}" class="btn btn-secondary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Export Excel
            </a>
            <a id="btn-export-pdf" href="{{ route('reports.employees.export', array_merge(request()->query(), ['format' => 'pdf'])) }}" class="btn btn-primary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
                Export PDF
            </a>
        </div>
    </div>
@endsection

@section('content')
    <div x-data="reportLiveFilter()">
        {{-- Summary Stats --}}
        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4 mb-4">
            <div class="stat-card">
                <p class="stat-card-label">Total</p>
                <p class="text-lg font-bold text-secondary-900">{{ $summary['total'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Aktif</p>
                <p class="text-lg font-bold text-success-600">{{ $summary['active'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Tidak Aktif</p>
                <p class="text-lg font-bold text-danger-600">{{ $summary['inactive'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Tetap</p>
                <p class="text-lg font-bold text-primary-600">{{ $summary['permanent'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Kontrak</p>
                <p class="text-lg font-bold text-warning-600">{{ $summary['contract'] }}</p>
            </div>
            <div class="stat-card">
                <p class="stat-card-label">Probation</p>
                <p class="text-lg font-bold text-info-600">{{ $summary['probation'] }}</p>
            </div>
        </div>

        {{-- Filters with Live Search --}}
        <div class="card mb-4">
            <div class="card-body-sm">
                <form id="report-filter-form" action="{{ route('reports.employees') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
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
                    <div class="w-40">
                        <label for="department_id" class="block text-xs font-medium text-secondary-500 mb-1">Departemen</label>
                        <select name="department_id" id="department_id" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            @foreach($departments as $department)
                                <option value="{{ $department->id }}" {{ request('department_id') == $department->id ? 'selected' : '' }}>{{ $department->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="w-36">
                        <label for="employment_type" class="block text-xs font-medium text-secondary-500 mb-1">Kepegawaian</label>
                        <select name="employment_type" id="employment_type" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            <option value="YPI Al Azhar" {{ request('employment_type') === 'YPI Al Azhar' ? 'selected' : '' }}>YPI Al Azhar</option>
                            <option value="YAPI" {{ request('employment_type') === 'YAPI' ? 'selected' : '' }}>YAPI</option>
                        </select>
                    </div>
                    <div class="w-32">
                        <label for="employment_status" class="block text-xs font-medium text-secondary-500 mb-1">Status Kerja</label>
                        <select name="employment_status" id="employment_status" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            <option value="permanent" {{ request('employment_status') === 'permanent' ? 'selected' : '' }}>Tetap</option>
                            <option value="contract" {{ request('employment_status') === 'contract' ? 'selected' : '' }}>Kontrak</option>
                            <option value="probation" {{ request('employment_status') === 'probation' ? 'selected' : '' }}>Probation</option>
                            <option value="intern" {{ request('employment_status') === 'intern' ? 'selected' : '' }}>Magang</option>
                        </select>
                    </div>
                    <div class="w-28">
                        <label for="is_active" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                        <select name="is_active" id="is_active" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            <option value="1" {{ request('is_active') === '1' ? 'selected' : '' }}>Aktif</option>
                            <option value="0" {{ request('is_active') === '0' ? 'selected' : '' }}>Tidak Aktif</option>
                        </select>
                    </div>
                    <div class="flex items-center gap-2">
                        <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" id="reset-btn" style="{{ request()->hasAny(['search', 'department_id', 'employment_type', 'employment_status', 'is_active']) ? '' : 'display: none;' }}">
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

        {{-- Employee Table --}}
        <div class="card" id="employee-report-table-card">
            <x-table>
                <x-slot name="header">
                    <th class="w-12 text-center">No</th>
                    <th>Karyawan</th>
                    <th>ID / PIN</th>
                    <th>Departemen</th>
                    <th>Jabatan</th>
                    <th>Kepegawaian</th>
                    <th>Status Kerja</th>
                    <th>Bergabung</th>
                    <th>Status</th>
                </x-slot>

                @forelse($employees as $index => $employee)
                    <tr class="hover:bg-secondary-50/60 transition-colors">
                        <td class="text-center text-secondary-500 text-xs">{{ $index + 1 }}</td>
                        <td>
                            <div class="flex items-center gap-2.5">
                                <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center flex-shrink-0">
                                    <span class="text-primary-700 text-xs font-medium">{{ substr($employee->first_name, 0, 1) }}</span>
                                </div>
                                <div class="min-w-0">
                                    <span class="font-medium text-secondary-900 block truncate">{{ $employee->full_name }}</span>
                                    @if($employee->email)
                                        <p class="text-xs text-secondary-400 truncate">{{ $employee->email }}</p>
                                    @endif
                                </div>
                            </div>
                        </td>
                        <td>
                            <span class="font-mono text-xs text-secondary-600">{{ $employee->employee_id }}</span>
                            @if($employee->pin)
                                <span class="block font-mono text-[10px] text-primary-600">PIN: {{ $employee->pin }}</span>
                            @endif
                        </td>
                        <td class="text-secondary-600">{{ $employee->department?->name ?? '-' }}</td>
                        <td class="text-secondary-600">{{ $employee->position?->name ?? '-' }}</td>
                        <td>
                            @if($employee->employment_type === 'YPI Al Azhar' || $employee->employment_type === 'YPI')
                                <x-badge type="primary">YPI Al Azhar</x-badge>
                            @elseif($employee->employment_type === 'YAPI')
                                <x-badge type="info">YAPI</x-badge>
                            @elseif($employee->employment_type)
                                <x-badge type="secondary">{{ $employee->employment_type }}</x-badge>
                            @else
                                <span class="text-secondary-400 text-xs">-</span>
                            @endif
                        </td>
                        <td>
                            @switch($employee->employment_status)
                                @case('permanent')
                                    <x-badge type="success">Tetap</x-badge>
                                    @break
                                @case('contract')
                                    <x-badge type="warning">Kontrak</x-badge>
                                    @break
                                @case('probation')
                                    <x-badge type="info">Probation</x-badge>
                                    @break
                                @case('intern')
                                    <x-badge type="secondary">Magang</x-badge>
                                    @break
                                @default
                                    <x-badge type="secondary">-</x-badge>
                            @endswitch
                        </td>
                        <td class="text-secondary-600 text-xs">{{ $employee->hire_date?->format('d/m/Y') ?? '-' }}</td>
                        <td>
                            @if($employee->is_active)
                                <x-badge type="success">Aktif</x-badge>
                            @else
                                <x-badge type="danger">Nonaktif</x-badge>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="9" class="text-center py-12">
                            <div class="flex flex-col items-center">
                                <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                                <p class="text-secondary-500">Tidak ada data karyawan yang sesuai dengan filter.</p>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </x-table>

            <div class="card-footer">
                <p class="text-sm text-secondary-500">Menampilkan {{ $employees->count() }} data karyawan</p>
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
                    
                    const excelUrl = new URL('{{ route('reports.employees.export') }}', window.location.origin);
                    const pdfUrl = new URL('{{ route('reports.employees.export') }}', window.location.origin);
                    
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
                    const empTypeVal = document.getElementById('employment_type')?.value || '';
                    const empStatusVal = document.getElementById('employment_status')?.value || '';
                    const activeVal = document.getElementById('is_active')?.value || '';
                    const resetBtn = document.getElementById('reset-btn');
                    if (resetBtn) {
                        resetBtn.style.display = (searchVal || deptVal || empTypeVal || empStatusVal || activeVal) ? '' : 'none';
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
                    const empTypeInput = document.getElementById('employment_type');
                    const empStatusInput = document.getElementById('employment_status');
                    const activeInput = document.getElementById('is_active');

                    if (searchInput) searchInput.value = '';
                    if (deptInput) deptInput.value = '';
                    if (empTypeInput) empTypeInput.value = '';
                    if (empStatusInput) empStatusInput.value = '';
                    if (activeInput) activeInput.value = '';

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
                        const newTable = doc.getElementById('employee-report-table-card');
                        const currentTable = document.getElementById('employee-report-table-card');
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
