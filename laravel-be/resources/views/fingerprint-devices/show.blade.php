@extends('layouts.admin')

@section('title', $fingerprintDevice->name)

@section('breadcrumb')
    <a href="{{ route('fingerprint-devices.index') }}" class="text-slate-500 hover:text-primary-600">Mesin Fingerprint</a>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">{{ $fingerprintDevice->name }}</span>
@endsection

@section('header')
    <div class="flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">{{ $fingerprintDevice->name }}</h1>
            <p class="text-secondary-500 mt-1 font-mono text-sm">{{ $fingerprintDevice->serial_number }}</p>
        </div>
        <a href="{{ route('fingerprint-devices.edit', $fingerprintDevice) }}" class="btn btn-secondary">Edit</a>
    </div>
@endsection

@section('content')
    @if(session('reveal_secret'))
        <x-alert type="warning" class="mb-4">
            <strong>Webhook secret (hanya ditampilkan sekali):</strong>
            <code class="block mt-1 font-mono text-sm bg-white/60 px-2 py-1 rounded">{{ session('reveal_secret') }}</code>
            Simpan nilai ini di konfigurasi agen. Nilai tidak akan ditampilkan lagi setelah halaman ini ditutup.
        </x-alert>
    @endif

    <div class="grid gap-6 lg:grid-cols-3">
        <div class="card lg:col-span-1">
            <div class="card-header"><h3 class="card-title">Konfigurasi Webhook</h3></div>
            <div class="card-body space-y-3 text-sm">
                <div>
                    <div class="text-secondary-500">Endpoint</div>
                    <code class="block break-all bg-secondary-50 px-2 py-1 rounded mt-1">{{ url('/api/v1/webhooks/fingerprint') }}</code>
                </div>
                <div>
                    <div class="text-secondary-500">Header</div>
                    <code class="block bg-secondary-50 px-2 py-1 rounded mt-1">X-Device-Signature: HMAC-SHA256(body, secret)</code>
                </div>
                <div>
                    <div class="text-secondary-500">Body</div>
                    <code class="block bg-secondary-50 px-2 py-1 rounded mt-1">{ device_serial, logs: [{ pin, type, timestamp }] }</code>
                </div>
                <form method="POST" action="{{ route('fingerprint-devices.regenerate-secret', $fingerprintDevice) }}"
                      @submit.prevent="$dispatch('confirm-dialog', {
                          title: 'Regenerate Secret',
                          message: 'Secret lama akan langsung tidak berlaku. Update konfigurasi agen setelahnya.',
                          confirmText: 'Ya, Regenerate',
                          type: 'warning',
                          formAction: '{{ route('fingerprint-devices.regenerate-secret', $fingerprintDevice) }}'
                      })">
                    @csrf
                    <button type="submit" class="btn btn-secondary btn-sm w-full mt-2">Regenerate Secret</button>
                </form>
            </div>
        </div>

        <div class="card lg:col-span-2">
            <div class="card-header"><h3 class="card-title">Pemetaan PIN Karyawan</h3></div>
            <div class="card-body-sm border-b">
                <form method="POST" action="{{ route('fingerprint-devices.mappings.store', $fingerprintDevice) }}" class="flex flex-wrap items-end gap-3">
                    @csrf
                    <div class="flex-1 min-w-[180px]">
                        <label class="block text-xs font-medium text-secondary-500 mb-1">Karyawan</label>
                        <select name="employee_id" class="input w-full" required>
                            <option value="">Pilih karyawan...</option>
                            @foreach($availableEmployees as $employee)
                                <option value="{{ $employee->id }}">{{ $employee->full_name }} ({{ $employee->employee_id }})</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="w-40">
                        <label class="block text-xs font-medium text-secondary-500 mb-1">PIN di Mesin</label>
                        <input type="text" name="device_user_pin" class="input w-full" required>
                    </div>
                    <button type="submit" class="btn btn-primary btn-sm">Tambah</button>
                </form>
                @error('device_user_pin')<p class="mt-2 text-sm text-danger-600">{{ $message }}</p>@enderror
                @error('employee_id')<p class="mt-2 text-sm text-danger-600">{{ $message }}</p>@enderror
            </div>

            <x-table>
                <x-slot name="header">
                    <th>PIN Mesin</th>
                    <th>Karyawan</th>
                    <th class="text-right">Aksi</th>
                </x-slot>
                @forelse($mappings as $mapping)
                    <tr>
                        <td><span class="font-mono">{{ $mapping->device_user_pin }}</span></td>
                        <td>{{ $mapping->employee->full_name }}</td>
                        <td class="text-right">
                            <button
                                type="button"
                                @click="$dispatch('confirm-dialog', {
                                    title: 'Hapus Pemetaan',
                                    message: 'Hapus pemetaan PIN {{ $mapping->device_user_pin }} untuk {{ $mapping->employee->full_name }}?',
                                    confirmText: 'Ya, Hapus',
                                    type: 'danger',
                                    formAction: '{{ route('fingerprint-devices.mappings.destroy', [$fingerprintDevice, $mapping]) }}'
                                })"
                                class="p-1.5 text-secondary-400 hover:text-danger-600 hover:bg-danger-50 rounded-md transition-colors"
                            >
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                            </button>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="3" class="text-center py-8 text-secondary-500">Belum ada karyawan yang dipetakan.</td></tr>
                @endforelse
            </x-table>
        </div>
    </div>

    @if($unmatchedLogs->isNotEmpty())
        <div class="card mt-6">
            <div class="card-header">
                <h3 class="card-title">Log Belum Terpetakan</h3>
                <p class="text-sm text-secondary-500">PIN berikut absen di mesin ini tapi belum dipetakan ke karyawan manapun.</p>
            </div>
            <x-table>
                <x-slot name="header">
                    <th>Waktu</th>
                    <th>PIN</th>
                    <th>Tipe</th>
                </x-slot>
                @foreach($unmatchedLogs as $log)
                    <tr>
                        <td>{{ $log->event_time->translatedFormat('d M Y H:i') }}</td>
                        <td><span class="font-mono">{{ $log->device_user_pin }}</span></td>
                        <td>{{ $log->type === 'clock_in' ? 'Masuk' : 'Pulang' }}</td>
                    </tr>
                @endforeach
            </x-table>
        </div>
    @endif
@endsection
