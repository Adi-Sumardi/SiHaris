@extends('layouts.admin')

@section('title', 'Pengajuan Lembur')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Lembur</span>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Pengajuan Lembur</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Pengajuan Lembur</h1>
            <p class="text-secondary-500 mt-1">Kelola pengajuan lembur karyawan.</p>
        </div>
        <div class="flex items-center gap-2">
            <a href="{{ route('overtime-settings.index') }}" class="btn btn-secondary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
                Pengaturan
            </a>
            <a href="{{ route('overtime-requests.create') }}" class="btn btn-primary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
                Ajukan Lembur
            </a>
        </div>
    </div>
@endsection

@section('content')
    <div x-data="overtimeRequestLiveFilter()">
        {{-- Filters with Live Search --}}
        <div class="card mb-4">
            <div class="card-body-sm">
                <form id="overtime-requests-filter-form" action="{{ route('overtime-requests.index') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
                    <div class="flex-1 min-w-[200px]">
                        <label for="search" class="block text-xs font-medium text-secondary-500 mb-1">Cari Karyawan</label>
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
                    <div class="w-32">
                        <label for="status" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                        <select name="status" id="status" class="input w-full" @change="fetchData()">
                            <option value="">Semua Status</option>
                            <option value="pending" {{ request('status') == 'pending' ? 'selected' : '' }}>Menunggu</option>
                            <option value="approved" {{ request('status') == 'approved' ? 'selected' : '' }}>Disetujui</option>
                            <option value="rejected" {{ request('status') == 'rejected' ? 'selected' : '' }}>Ditolak</option>
                            <option value="cancelled" {{ request('status') == 'cancelled' ? 'selected' : '' }}>Dibatalkan</option>
                        </select>
                    </div>
                    <div class="w-36">
                        <label for="overtime_type" class="block text-xs font-medium text-secondary-500 mb-1">Tipe Lembur</label>
                        <select name="overtime_type" id="overtime_type" class="input w-full" @change="fetchData()">
                            <option value="">Semua Tipe</option>
                            <option value="weekday" {{ request('overtime_type') == 'weekday' ? 'selected' : '' }}>Hari Kerja</option>
                            <option value="weekend" {{ request('overtime_type') == 'weekend' ? 'selected' : '' }}>Akhir Pekan</option>
                            <option value="holiday" {{ request('overtime_type') == 'holiday' ? 'selected' : '' }}>Hari Libur</option>
                        </select>
                    </div>
                    <div class="w-36">
                        <label for="start_date" class="block text-xs font-medium text-secondary-500 mb-1">Dari Tanggal</label>
                        <input type="date" name="start_date" id="start_date" value="{{ request('start_date') }}" class="input w-full" @change="fetchData()">
                    </div>
                    <div class="w-36">
                        <label for="end_date" class="block text-xs font-medium text-secondary-500 mb-1">Sampai Tanggal</label>
                        <input type="date" name="end_date" id="end_date" value="{{ request('end_date') }}" class="input w-full" @change="fetchData()">
                    </div>

                    <div class="flex items-center gap-2">
                        <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" id="reset-btn" style="{{ request()->hasAny(['search', 'status', 'overtime_type', 'start_date', 'end_date']) ? '' : 'display: none;' }}">
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

        {{-- Table --}}
        <div class="card" id="overtime-requests-card">
            <x-table>
                <x-slot name="header">
                    <th>Karyawan</th>
                    <th>Tanggal</th>
                    <th>Waktu</th>
                    <th>Durasi</th>
                    <th>Tipe</th>
                    <th>Nilai</th>
                    <th>Status</th>
                    <th class="text-right">Aksi</th>
                </x-slot>

                @forelse($requests as $request)
                    <tr class="hover:bg-secondary-50/60 transition-colors">
                        <td>
                            <div class="flex items-center gap-2.5">
                                <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center flex-shrink-0">
                                    <span class="text-primary-700 text-xs font-medium">{{ strtoupper(substr($request->employee?->full_name ?? 'K', 0, 1)) }}</span>
                                </div>
                                <div class="min-w-0">
                                    <span class="font-medium text-secondary-900 block truncate">{{ $request->employee?->full_name ?? 'Karyawan Dihapus' }}</span>
                                    <p class="text-xs text-secondary-400 font-mono">{{ $request->employee?->employee_id ?? '-' }} @if($request->employee?->department) &bull; {{ $request->employee->department->name }} @endif</p>
                                </div>
                            </div>
                        </td>
                        <td class="text-secondary-700 text-xs">{{ $request->date->format('d M Y') }}</td>
                        <td class="text-secondary-700 font-mono text-xs">{{ \Carbon\Carbon::parse($request->start_time)->format('H:i') }} - {{ \Carbon\Carbon::parse($request->end_time)->format('H:i') }}</td>
                        <td class="text-secondary-900 font-semibold text-xs">{{ $request->overtime_hours }} jam</td>
                        <td>
                            <x-badge type="{{ $request->overtime_type == 'holiday' ? 'danger' : ($request->overtime_type == 'weekend' ? 'warning' : 'info') }}">
                                {{ $request->overtime_type_label }}
                            </x-badge>
                        </td>
                        <td class="font-mono font-medium text-secondary-900 text-xs">{{ $request->formatted_overtime_amount }}</td>
                        <td>
                            <x-badge type="{{ match($request->status) { 'approved' => 'success', 'rejected' => 'danger', 'cancelled' => 'secondary', default => 'warning' } }}">
                                {{ $request->status_label }}
                            </x-badge>
                        </td>
                        <td class="text-right">
                            <div class="flex items-center justify-end gap-1">
                                @if($request->isPending())
                                    <form action="{{ route('overtime-requests.approve', $request) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" class="p-1.5 text-secondary-400 hover:text-success-600 hover:bg-success-50 rounded-md transition-colors" title="Setujui">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                            </svg>
                                        </button>
                                    </form>
                                    <button type="button"
                                            @click="$dispatch('confirm-dialog', {
                                                title: 'Tolak Pengajuan',
                                                message: 'Apakah Anda yakin ingin menolak pengajuan lembur ini?',
                                                confirmText: 'Ya, Tolak',
                                                type: 'danger',
                                                formAction: '{{ route('overtime-requests.reject', $request) }}',
                                                showReasonField: true
                                            })"
                                            class="p-1.5 text-secondary-400 hover:text-danger-600 hover:bg-danger-50 rounded-md transition-colors"
                                            title="Tolak">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                                        </svg>
                                    </button>
                                @endif
                                <a href="{{ route('overtime-requests.show', $request) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Detail">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                    </svg>
                                </a>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="text-center py-12">
                            <div class="flex flex-col items-center">
                                <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                <p class="text-secondary-500">Belum ada pengajuan lembur yang sesuai dengan filter.</p>
                                <a href="{{ route('overtime-requests.create') }}" class="btn btn-primary mt-4">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                                    Ajukan Lembur
                                </a>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </x-table>

            @if($requests->hasPages())
                <div class="card-footer">
                    {{ $requests->links() }}
                </div>
            @endif
        </div>
    </div>

    <script>
        function overtimeRequestLiveFilter() {
            return {
                loading: false,
                debounceTimer: null,

                updateResetVisibility() {
                    const searchVal = document.getElementById('search')?.value || '';
                    const statusVal = document.getElementById('status')?.value || '';
                    const overtimeTypeVal = document.getElementById('overtime_type')?.value || '';
                    const startDateVal = document.getElementById('start_date')?.value || '';
                    const endDateVal = document.getElementById('end_date')?.value || '';
                    const resetBtn = document.getElementById('reset-btn');
                    if (resetBtn) {
                        resetBtn.style.display = (searchVal || statusVal || overtimeTypeVal || startDateVal || endDateVal) ? '' : 'none';
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
                    const overtimeTypeInput = document.getElementById('overtime_type');
                    const startDateInput = document.getElementById('start_date');
                    const endDateInput = document.getElementById('end_date');

                    if (searchInput) searchInput.value = '';
                    if (statusInput) statusInput.value = '';
                    if (overtimeTypeInput) overtimeTypeInput.value = '';
                    if (startDateInput) startDateInput.value = '';
                    if (endDateInput) endDateInput.value = '';

                    this.updateResetVisibility();
                    this.fetchData(true);
                },

                fetchData(isReset = false) {
                    const form = document.getElementById('overtime-requests-filter-form');
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
                        const newCard = doc.getElementById('overtime-requests-card');
                        const currentCard = document.getElementById('overtime-requests-card');
                        if (newCard && currentCard) {
                            currentCard.innerHTML = newCard.innerHTML;
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
