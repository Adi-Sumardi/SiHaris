@extends('layouts.admin')

@section('title', 'Daftar Pengajuan Cuti')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Pengajuan Cuti</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Daftar Pengajuan Cuti</h1>
            <p class="text-secondary-500 mt-1">Kelola pengajuan cuti dan izin karyawan.</p>
        </div>
        <div class="flex items-center gap-3">
            <a href="{{ route('leave-requests.create') }}" class="btn btn-primary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
                Ajukan Cuti
            </a>
        </div>
    </div>
@endsection

@section('content')
    <div x-data="leaveRequestLiveFilter()">
        {{-- Filters with Live Search --}}
        <div class="card mb-4">
            <div class="card-body-sm">
                <form id="leave-requests-filter-form" action="{{ route('leave-requests.index') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
                    {{-- Live Search --}}
                    <div class="flex-1 min-w-[200px]">
                        <label for="search" class="block text-xs font-medium text-secondary-500 mb-1">Cari Karyawan / No. Pengajuan</label>
                        <input
                            type="text"
                            name="search"
                            id="search"
                            value="{{ request('search') }}"
                            placeholder="Nama, ID, NIK, PIN, No. Pengajuan..."
                            class="input w-full"
                            autocomplete="off"
                            @input="onSearchInput($event)"
                        >
                    </div>

                    {{-- Status --}}
                    <div class="w-32">
                        <label for="status" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                        <select name="status" id="status" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            <option value="pending" {{ request('status') === 'pending' ? 'selected' : '' }}>Menunggu</option>
                            <option value="approved" {{ request('status') === 'approved' ? 'selected' : '' }}>Disetujui</option>
                            <option value="rejected" {{ request('status') === 'rejected' ? 'selected' : '' }}>Ditolak</option>
                            <option value="cancelled" {{ request('status') === 'cancelled' ? 'selected' : '' }}>Dibatalkan</option>
                        </select>
                    </div>

                    {{-- Leave Type --}}
                    <div class="w-36">
                        <label for="leave_type_id" class="block text-xs font-medium text-secondary-500 mb-1">Jenis Cuti</label>
                        <select name="leave_type_id" id="leave_type_id" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            @foreach($leaveTypes as $type)
                                <option value="{{ $type->id }}" {{ request('leave_type_id') == $type->id ? 'selected' : '' }}>
                                    {{ $type->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    {{-- Date Range --}}
                    <div class="w-36">
                        <label for="date_from" class="block text-xs font-medium text-secondary-500 mb-1">Dari Tanggal</label>
                        <input type="date" name="date_from" id="date_from" value="{{ request('date_from') }}" class="input w-full" @change="fetchData()">
                    </div>
                    <div class="w-36">
                        <label for="date_to" class="block text-xs font-medium text-secondary-500 mb-1">Sampai Tanggal</label>
                        <input type="date" name="date_to" id="date_to" value="{{ request('date_to') }}" class="input w-full" @change="fetchData()">
                    </div>

                    <div class="flex items-center gap-2">
                        <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" id="reset-btn" style="{{ request()->hasAny(['search', 'status', 'leave_type_id', 'date_from', 'date_to']) ? '' : 'display: none;' }}">
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

        {{-- Leave Requests List --}}
        <div class="card" id="leave-requests-card">
            <x-table>
                <x-slot name="header">
                    <th>No. Pengajuan</th>
                    <th>Karyawan</th>
                    <th>Jenis Cuti</th>
                    <th>Tanggal</th>
                    <th>Durasi</th>
                    <th>Status</th>
                    <th class="text-right">Aksi</th>
                </x-slot>

                @forelse($leaveRequests as $leaveReq)
                    <tr class="hover:bg-secondary-50/60 transition-colors">
                        <td>
                            <span class="font-mono text-xs bg-secondary-100 text-secondary-700 font-semibold px-2 py-0.5 rounded">{{ $leaveReq->request_number }}</span>
                        </td>
                        <td>
                            <div class="flex items-center gap-2.5">
                                <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center flex-shrink-0">
                                    <span class="text-primary-700 text-xs font-medium">{{ strtoupper(substr($leaveReq->employee?->full_name ?? 'K', 0, 1)) }}</span>
                                </div>
                                <div class="min-w-0">
                                    <span class="font-medium text-secondary-900 block truncate">{{ $leaveReq->employee?->full_name ?? '-' }}</span>
                                    <p class="text-xs text-secondary-400 font-mono">{{ $leaveReq->employee?->employee_id ?? '-' }}</p>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div class="flex items-center gap-2">
                                <div class="w-2 h-2 rounded-full bg-{{ $leaveReq->leaveType->color_class ?? 'primary' }}-500"></div>
                                <span class="text-secondary-700">{{ $leaveReq->leaveType->name ?? '-' }}</span>
                            </div>
                        </td>
                        <td class="text-secondary-700 text-xs">{{ $leaveReq->date_range }}</td>
                        <td class="text-secondary-700 font-medium text-xs">{{ $leaveReq->duration_text }}</td>
                        <td>
                            <x-badge type="{{ $leaveReq->status_color }}">{{ $leaveReq->status_label }}</x-badge>
                        </td>
                        <td>
                            <div class="flex items-center justify-end gap-1">
                                <a href="{{ route('leave-requests.show', $leaveReq) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Detail">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                </a>
                                @if($leaveReq->isPending())
                                    <form action="{{ route('leave-requests.approve', $leaveReq) }}" method="POST" class="inline">
                                        @csrf
                                        <button type="submit" class="p-1.5 text-secondary-400 hover:text-success-600 hover:bg-success-50 rounded-md transition-colors" title="Setujui">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                                        </button>
                                    </form>
                                    <button
                                        type="button"
                                        @click="$dispatch('reject-dialog', { url: '{{ route('leave-requests.reject', $leaveReq) }}' })"
                                        class="p-1.5 text-secondary-400 hover:text-danger-600 hover:bg-danger-50 rounded-md transition-colors"
                                        title="Tolak"
                                    >
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                                    </button>
                                @endif
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="text-center py-12">
                            <div class="flex flex-col items-center">
                                <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                                <p class="text-secondary-500">Belum ada pengajuan cuti yang sesuai dengan filter.</p>
                                <a href="{{ route('leave-requests.create') }}" class="btn btn-primary mt-4">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
                                    Ajukan Cuti
                                </a>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </x-table>

            @if($leaveRequests->hasPages())
                <div class="card-footer">
                    {{ $leaveRequests->links() }}
                </div>
            @endif
        </div>
    </div>

    {{-- Reject Modal --}}
    <div
        x-data="{ open: false, url: '' }"
        @reject-dialog.window="open = true; url = $event.detail.url"
        x-show="open"
        x-cloak
        class="fixed inset-0 z-50 overflow-y-auto"
    >
        <div class="flex items-center justify-center min-h-screen px-4">
            <div x-show="open" x-transition:enter="ease-out duration-300" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100" class="fixed inset-0 bg-black/50" @click="open = false"></div>

            <div x-show="open" x-transition:enter="ease-out duration-300" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100" class="relative bg-white rounded-xl shadow-xl max-w-md w-full p-6">
                <h3 class="text-lg font-semibold text-secondary-900 mb-4">Tolak Pengajuan Cuti</h3>
                <form :action="url" method="POST">
                    @csrf
                    <div class="mb-4">
                        <label for="reject_reason" class="block text-sm font-medium text-secondary-700 mb-1">Alasan Penolakan <span class="text-danger-500">*</span></label>
                        <textarea name="reason" id="reject_reason" rows="3" class="input w-full" placeholder="Masukkan alasan penolakan..." required></textarea>
                    </div>
                    <div class="flex justify-end gap-3">
                        <button type="button" @click="open = false" class="btn btn-ghost">Batal</button>
                        <button type="submit" class="btn btn-danger">Tolak Pengajuan</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        function leaveRequestLiveFilter() {
            return {
                loading: false,
                debounceTimer: null,

                updateResetVisibility() {
                    const searchVal = document.getElementById('search')?.value || '';
                    const statusVal = document.getElementById('status')?.value || '';
                    const leaveTypeIdVal = document.getElementById('leave_type_id')?.value || '';
                    const dateFromVal = document.getElementById('date_from')?.value || '';
                    const dateToVal = document.getElementById('date_to')?.value || '';
                    const resetBtn = document.getElementById('reset-btn');
                    if (resetBtn) {
                        resetBtn.style.display = (searchVal || statusVal || leaveTypeIdVal || dateFromVal || dateToVal) ? '' : 'none';
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
                    const leaveTypeIdInput = document.getElementById('leave_type_id');
                    const dateFromInput = document.getElementById('date_from');
                    const dateToInput = document.getElementById('date_to');

                    if (searchInput) searchInput.value = '';
                    if (statusInput) statusInput.value = '';
                    if (leaveTypeIdInput) leaveTypeIdInput.value = '';
                    if (dateFromInput) dateFromInput.value = '';
                    if (dateToInput) dateToInput.value = '';

                    this.updateResetVisibility();
                    this.fetchData(true);
                },

                fetchData(isReset = false) {
                    const form = document.getElementById('leave-requests-filter-form');
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
                        const newCard = doc.getElementById('leave-requests-card');
                        const currentCard = document.getElementById('leave-requests-card');
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
