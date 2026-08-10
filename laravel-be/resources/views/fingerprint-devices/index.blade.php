@extends('layouts.admin')

@section('title', 'Mesin Fingerprint')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Mesin Fingerprint</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Mesin Fingerprint</h1>
            <p class="text-secondary-500 mt-1">Kelola mesin absensi fingerprint dan pemetaan PIN karyawan.</p>
        </div>
        <a href="{{ route('fingerprint-devices.create') }}" class="btn btn-primary">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
            Tambah Mesin
        </a>
    </div>
@endsection

@section('content')
    @if($unmatchedCount > 0)
        <x-alert type="warning" class="mb-4">
            Ada <strong>{{ $unmatchedCount }}</strong> log absensi dari mesin fingerprint yang PIN-nya belum dipetakan ke karyawan manapun. Buka detail mesin untuk meninjau.
        </x-alert>
    @endif

    <div class="card">
        <x-table>
            <x-slot name="header">
                <th>Nama Mesin</th>
                <th>Merek</th>
                <th>Serial Number</th>
                <th>Lokasi</th>
                <th>Karyawan Terpetakan</th>
                <th>Status</th>
                <th class="text-right">Aksi</th>
            </x-slot>

            @forelse($devices as $device)
                <tr>
                    <td>
                        <span class="font-medium text-secondary-900">{{ $device->name }}</span>
                        @if($device->last_sync_at)
                            <p class="text-xs text-secondary-500">Sync terakhir: {{ $device->last_sync_at->translatedFormat('d M Y H:i') }}</p>
                        @else
                            <p class="text-xs text-secondary-400">Belum pernah sync</p>
                        @endif
                    </td>
                    <td class="capitalize">{{ $device->brand }}</td>
                    <td><span class="font-mono text-sm">{{ $device->serial_number }}</span></td>
                    <td>{{ $device->officeLocation?->name ?? '-' }}</td>
                    <td>{{ $device->user_mappings_count }} orang</td>
                    <td>
                        @if($device->is_active)
                            <x-badge type="success">Aktif</x-badge>
                        @else
                            <x-badge type="secondary">Tidak Aktif</x-badge>
                        @endif
                    </td>
                    <td>
                        <div class="flex items-center justify-end gap-1">
                            <a href="{{ route('fingerprint-devices.show', $device) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Detail">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                            </a>
                            <a href="{{ route('fingerprint-devices.edit', $device) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Edit">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                            </a>
                            <button
                                type="button"
                                @click="$dispatch('confirm-dialog', {
                                    title: 'Hapus Mesin Fingerprint',
                                    message: 'Apakah Anda yakin ingin menghapus mesin {{ $device->name }}? Pemetaan PIN karyawan akan ikut terhapus.',
                                    confirmText: 'Ya, Hapus',
                                    type: 'danger',
                                    formAction: '{{ route('fingerprint-devices.destroy', $device) }}'
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
                        <p class="text-secondary-500">Belum ada mesin fingerprint terdaftar.</p>
                        <a href="{{ route('fingerprint-devices.create') }}" class="btn btn-primary mt-4">Tambah Mesin</a>
                    </td>
                </tr>
            @endforelse
        </x-table>

        @if($devices->hasPages())
            <div class="card-footer">
                {{ $devices->links() }}
            </div>
        @endif
    </div>
@endsection
