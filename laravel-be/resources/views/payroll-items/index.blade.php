@extends('layouts.admin')

@section('title', 'Riwayat Payroll')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Riwayat Payroll</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Riwayat Payroll</h1>
            <p class="text-secondary-500 mt-1">Lihat riwayat slip gaji semua karyawan</p>
        </div>
    </div>
@endsection

@section('content')
    <div x-data="payrollItemLiveFilter()">
        {{-- Filters with Live Search --}}
        <div class="card mb-4">
            <div class="card-body-sm">
                <form id="payroll-items-filter-form" action="{{ route('payroll-items.index') }}" method="GET" class="flex flex-wrap items-end gap-3" @submit.prevent="fetchData()">
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
                    <div class="w-28">
                        <label for="year" class="block text-xs font-medium text-secondary-500 mb-1">Tahun</label>
                        <select name="year" id="year" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            @foreach($years as $year)
                                <option value="{{ $year }}" {{ request('year') == $year ? 'selected' : '' }}>{{ $year }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="w-32">
                        <label for="status" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                        <select name="status" id="status" class="input w-full" @change="fetchData()">
                            <option value="">Semua</option>
                            <option value="pending" {{ request('status') === 'pending' ? 'selected' : '' }}>Menunggu</option>
                            <option value="calculated" {{ request('status') === 'calculated' ? 'selected' : '' }}>Terhitung</option>
                            <option value="approved" {{ request('status') === 'approved' ? 'selected' : '' }}>Disetujui</option>
                            <option value="paid" {{ request('status') === 'paid' ? 'selected' : '' }}>Dibayar</option>
                        </select>
                    </div>
                    <div class="flex items-center gap-2">
                        <button type="button" @click="resetFilters()" class="btn btn-ghost btn-sm" id="reset-btn" style="{{ request()->hasAny(['search', 'year', 'status']) ? '' : 'display: none;' }}">
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

        {{-- Payroll Items List --}}
        <div class="card" id="payroll-items-card">
            <x-table>
                <x-slot name="header">
                    <th>Karyawan</th>
                    <th>Periode</th>
                    <th class="text-right">Gaji Pokok</th>
                    <th class="text-right">Pendapatan</th>
                    <th class="text-right">Potongan</th>
                    <th class="text-right">Gaji Bersih</th>
                    <th>Status</th>
                    <th class="text-right">Aksi</th>
                </x-slot>

                @forelse($payrollItems as $item)
                    <tr class="hover:bg-secondary-50/60 transition-colors">
                        <td>
                            <div class="flex items-center gap-2.5">
                                <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center flex-shrink-0">
                                    <span class="text-primary-700 text-xs font-medium">{{ substr($item->employee_name ?? 'K', 0, 1) }}</span>
                                </div>
                                <div class="min-w-0">
                                    <span class="font-medium text-secondary-900 block truncate">{{ $item->employee_name }}</span>
                                    <p class="text-xs text-secondary-400 font-mono">{{ $item->employee_number }}</p>
                                </div>
                            </div>
                        </td>
                        <td>
                            <span class="text-secondary-900 font-medium">{{ $item->payroll->period_label }}</span>
                            <p class="text-xs text-secondary-400">{{ $item->payroll->payroll_number }}</p>
                        </td>
                        <td class="text-right text-secondary-700 font-mono text-xs">Rp {{ number_format($item->basic_salary, 0, ',', '.') }}</td>
                        <td class="text-right text-success-600 font-mono text-xs font-medium">+Rp {{ number_format($item->total_earnings, 0, ',', '.') }}</td>
                        <td class="text-right text-danger-600 font-mono text-xs font-medium">-Rp {{ number_format($item->total_deductions, 0, ',', '.') }}</td>
                        <td class="text-right font-bold text-secondary-900 font-mono text-xs">{{ $item->formatted_net_salary }}</td>
                        <td>
                            @switch($item->status)
                                @case('pending')
                                    <x-badge type="secondary">{{ $item->status_label }}</x-badge>
                                    @break
                                @case('calculated')
                                    <x-badge type="warning">{{ $item->status_label }}</x-badge>
                                    @break
                                @case('approved')
                                    <x-badge type="primary">{{ $item->status_label }}</x-badge>
                                    @break
                                @case('paid')
                                    <x-badge type="success">{{ $item->status_label }}</x-badge>
                                    @break
                                @default
                                    <x-badge type="secondary">{{ $item->status_label }}</x-badge>
                            @endswitch
                        </td>
                        <td>
                            <div class="flex items-center justify-end gap-1">
                                <a href="{{ route('payroll-items.show', $item) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Lihat Slip Gaji">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                </a>
                                <a href="{{ route('payroll-items.pdf', $item) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Download PDF" target="_blank">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                                </a>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="text-center py-12">
                            <div class="flex flex-col items-center">
                                <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                                <p class="text-secondary-500 mb-4">Belum ada riwayat payroll yang sesuai dengan pencarian</p>
                                <a href="{{ route('payrolls.index') }}" class="btn btn-primary">Lihat Payroll</a>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </x-table>

            @if($payrollItems->hasPages())
                <div class="card-footer">
                    {{ $payrollItems->links() }}
                </div>
            @endif
        </div>
    </div>

    <script>
        function payrollItemLiveFilter() {
            return {
                loading: false,
                debounceTimer: null,

                updateResetVisibility() {
                    const searchVal = document.getElementById('search')?.value || '';
                    const yearVal = document.getElementById('year')?.value || '';
                    const statusVal = document.getElementById('status')?.value || '';
                    const resetBtn = document.getElementById('reset-btn');
                    if (resetBtn) {
                        resetBtn.style.display = (searchVal || yearVal || statusVal) ? '' : 'none';
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
                    const yearInput = document.getElementById('year');
                    const statusInput = document.getElementById('status');

                    if (searchInput) searchInput.value = '';
                    if (yearInput) yearInput.value = '';
                    if (statusInput) statusInput.value = '';

                    this.updateResetVisibility();
                    this.fetchData(true);
                },

                fetchData(isReset = false) {
                    const form = document.getElementById('payroll-items-filter-form');
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
                        const newCard = doc.getElementById('payroll-items-card');
                        const currentCard = document.getElementById('payroll-items-card');
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
