@extends('layouts.admin')

@section('title', 'Pengajuan Reimbursement')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Keuangan</span>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Reimbursement</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Pengajuan Reimbursement</h1>
            <p class="text-secondary-500 mt-1">Kelola pengajuan penggantian biaya karyawan.</p>
        </div>
        <div class="flex items-center gap-2">
            <a href="{{ route('reimbursement-categories.index') }}" class="btn btn-secondary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/>
                </svg>
                Kategori
            </a>
            <a href="{{ route('reimbursements.create') }}" class="btn btn-primary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                </svg>
                Tambah Pengajuan
            </a>
        </div>
    </div>
@endsection

@section('content')
    <div x-data="reimbursementLiveFilter()">
        {{-- Filter with Live Search --}}
        <div class="card mb-4">
            <div class="card-body-sm">
                <form id="reimbursements-filter-form" action="{{ route('reimbursements.index') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
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
                    <div class="w-32">
                        <label for="status" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                        <select name="status" id="status" class="input w-full" @change="fetchData()">
                            <option value="">Semua Status</option>
                            <option value="pending" {{ request('status') == 'pending' ? 'selected' : '' }}>Menunggu</option>
                            <option value="approved" {{ request('status') == 'approved' ? 'selected' : '' }}>Disetujui</option>
                            <option value="rejected" {{ request('status') == 'rejected' ? 'selected' : '' }}>Ditolak</option>
                            <option value="paid" {{ request('status') == 'paid' ? 'selected' : '' }}>Dibayar</option>
                        </select>
                    </div>
                    <div class="w-36">
                        <label for="category_id" class="block text-xs font-medium text-secondary-500 mb-1">Kategori</label>
                        <select name="category_id" id="category_id" class="input w-full" @change="fetchData()">
                            <option value="">Semua Kategori</option>
                            @foreach($categories as $category)
                                <option value="{{ $category->id }}" {{ request('category_id') == $category->id ? 'selected' : '' }}>
                                    {{ $category->name }}
                                </option>
                            @endforeach
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
                        <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" id="reset-btn" style="{{ request()->hasAny(['search', 'status', 'category_id', 'start_date', 'end_date']) ? '' : 'display: none;' }}">
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
        <div class="card" id="reimbursements-card">
            <x-table>
                <x-slot name="header">
                    <th>Karyawan</th>
                    <th>Kategori</th>
                    <th>Tanggal Pengeluaran</th>
                    <th class="text-right">Jumlah</th>
                    <th>Deskripsi</th>
                    <th>Status</th>
                    <th class="text-right">Aksi</th>
                </x-slot>

                @forelse($reimbursements as $reimbursement)
                    <tr class="hover:bg-secondary-50/60 transition-colors">
                        <td>
                            <div class="flex items-center gap-2.5">
                                <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center flex-shrink-0">
                                    <span class="text-primary-700 text-xs font-medium">{{ strtoupper(substr($reimbursement->employee?->full_name ?? 'K', 0, 1)) }}</span>
                                </div>
                                <div class="min-w-0">
                                    <span class="font-medium text-secondary-900 block truncate">{{ $reimbursement->employee?->full_name ?? '-' }}</span>
                                    <p class="text-xs text-secondary-400 font-mono">{{ $reimbursement->employee?->employee_id ?? '-' }} @if($reimbursement->employee?->department) &bull; {{ $reimbursement->employee->department->name }} @endif</p>
                                </div>
                            </div>
                        </td>
                        <td>
                            <span class="text-secondary-800 font-medium text-xs">{{ $reimbursement->category?->name ?? '-' }}</span>
                        </td>
                        <td class="text-secondary-700 text-xs">{{ $reimbursement->expense_date?->format('d M Y') ?? '-' }}</td>
                        <td class="text-right font-mono font-semibold text-secondary-900 text-xs">{{ $reimbursement->formatted_amount }}</td>
                        <td class="text-secondary-600 text-xs">{{ Str::limit($reimbursement->description, 35) }}</td>
                        <td>
                            <x-badge type="{{ match($reimbursement->status) { 'approved' => 'info', 'rejected' => 'danger', 'paid' => 'success', default => 'warning' } }}">
                                {{ $reimbursement->status_label }}
                            </x-badge>
                        </td>
                        <td class="text-right">
                            <div class="flex items-center justify-end gap-1">
                                <a href="{{ route('reimbursements.show', $reimbursement) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Detail">
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
                        <td colspan="7" class="text-center py-12">
                            <div class="flex flex-col items-center">
                                <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                                <p class="text-secondary-500">Belum ada pengajuan reimbursement yang sesuai dengan filter.</p>
                                <a href="{{ route('reimbursements.create') }}" class="btn btn-primary mt-4">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                                    Tambah Pengajuan
                                </a>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </x-table>

            @if($reimbursements->hasPages())
                <div class="card-footer">
                    {{ $reimbursements->links() }}
                </div>
            @endif
        </div>
    </div>

    <script>
        function reimbursementLiveFilter() {
            return {
                loading: false,
                debounceTimer: null,

                updateResetVisibility() {
                    const searchVal = document.getElementById('search')?.value || '';
                    const statusVal = document.getElementById('status')?.value || '';
                    const categoryIdVal = document.getElementById('category_id')?.value || '';
                    const startDateVal = document.getElementById('start_date')?.value || '';
                    const endDateVal = document.getElementById('end_date')?.value || '';
                    const resetBtn = document.getElementById('reset-btn');
                    if (resetBtn) {
                        resetBtn.style.display = (searchVal || statusVal || categoryIdVal || startDateVal || endDateVal) ? '' : 'none';
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
                    const categoryIdInput = document.getElementById('category_id');
                    const startDateInput = document.getElementById('start_date');
                    const endDateInput = document.getElementById('end_date');

                    if (searchInput) searchInput.value = '';
                    if (statusInput) statusInput.value = '';
                    if (categoryIdInput) categoryIdInput.value = '';
                    if (startDateInput) startDateInput.value = '';
                    if (endDateInput) endDateInput.value = '';

                    this.updateResetVisibility();
                    this.fetchData(true);
                },

                fetchData(isReset = false) {
                    const form = document.getElementById('reimbursements-filter-form');
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
                        const newCard = doc.getElementById('reimbursements-card');
                        const currentCard = document.getElementById('reimbursements-card');
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
