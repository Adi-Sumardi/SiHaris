@extends('layouts.admin')

@section('title', 'Daftar Jadwal Kerja')

@section('breadcrumb')
    <span class="text-slate-700 font-medium">Jadwal Kerja</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Daftar Jadwal Kerja</h1>
            <p class="text-secondary-500 mt-1">Kelola jadwal dan jam kerja karyawan.</p>
        </div>
        <div class="flex items-center gap-3">
            <a href="{{ route('imports.work-schedules.index') }}" class="btn btn-secondary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>
                Import
            </a>
            <button type="button" @click="$dispatch('open-modal', 'assign-schedule')" class="btn btn-secondary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4 4 4 0 004 4zm6 0a4 4 0 10-4-4"/></svg>
                Assign Jadwal
            </button>
            <a href="{{ route('work-schedules.create') }}" class="btn btn-primary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
                Tambah Jadwal
            </a>
        </div>
    </div>
@endsection

@section('content')
    {{-- Filters --}}
    <div class="card mb-4">
        <div class="card-body-sm">
            <form action="{{ route('work-schedules.index') }}" method="GET" class="flex flex-wrap items-end gap-3">
                {{-- Search --}}
                <div class="flex-1 min-w-[180px]">
                    <label for="search" class="block text-xs font-medium text-secondary-500 mb-1">Cari</label>
                    <input type="text" name="search" id="search" value="{{ request('search') }}" placeholder="Nama atau kode jadwal..." class="input w-full">
                </div>

                {{-- Status --}}
                <div class="w-28">
                    <label for="status" class="block text-xs font-medium text-secondary-500 mb-1">Status</label>
                    <select name="status" id="status" class="input w-full">
                        <option value="">Semua</option>
                        <option value="active" {{ request('status') === 'active' ? 'selected' : '' }}>Aktif</option>
                        <option value="inactive" {{ request('status') === 'inactive' ? 'selected' : '' }}>Nonaktif</option>
                    </select>
                </div>

                <div class="flex items-center gap-2">
                    @if(request()->hasAny(['search', 'status']))
                        <a href="{{ route('work-schedules.index') }}" class="btn btn-ghost btn-sm">Reset</a>
                    @endif
                    <button type="submit" class="btn btn-primary btn-sm">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                        Cari
                    </button>
                </div>
            </form>
        </div>
    </div>

    {{-- Work Schedule List --}}
    <div class="card">
        <x-table>
            <x-slot name="header">
                <th>Nama Jadwal</th>
                <th>Jam Kerja</th>
                <th>Hari Kerja</th>
                <th>Toleransi</th>
                <th>Karyawan</th>
                <th>Status</th>
                <th class="text-right">Aksi</th>
            </x-slot>

            @forelse($workSchedules as $schedule)
                <tr>
                    <td>
                        <div>
                            <span class="font-medium text-secondary-900">{{ $schedule->name }}</span>
                            @if($schedule->code)
                                <p class="text-sm text-secondary-500">{{ $schedule->code }}</p>
                            @endif
                            @if($schedule->is_default)
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-primary-100 text-primary-800">Default</span>
                            @endif
                            @if($schedule->is_flexible)
                                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">Fleksibel</span>
                            @endif
                        </div>
                    </td>
                    <td>
                        <div class="flex items-center gap-1">
                            <svg class="w-4 h-4 text-secondary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <span>{{ $schedule->start_time->format('H:i') }} - {{ $schedule->end_time->format('H:i') }}</span>
                        </div>
                        @if($schedule->break_start && $schedule->break_end)
                            <p class="text-sm text-secondary-500">Istirahat: {{ $schedule->break_start->format('H:i') }} - {{ $schedule->break_end->format('H:i') }}</p>
                        @endif
                    </td>
                    <td>
                        <span class="text-sm">{{ $schedule->working_days_text }}</span>
                    </td>
                    <td>
                        <div class="text-sm">
                            <p>Terlambat: {{ $schedule->late_tolerance }} menit</p>
                            <p>Pulang awal: {{ $schedule->early_leave_tolerance }} menit</p>
                        </div>
                    </td>
                    <td>
                        <span class="font-medium">{{ $schedule->employees_count }}</span>
                        <span class="text-secondary-500">orang</span>
                    </td>
                    <td>
                        @if($schedule->is_active)
                            <x-badge type="success">Aktif</x-badge>
                        @else
                            <x-badge type="danger">Tidak Aktif</x-badge>
                        @endif
                    </td>
                    <td>
                        <div class="flex items-center justify-end gap-1">
                            <a href="{{ route('work-schedules.show', $schedule) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Detail">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                            </a>
                            <a href="{{ route('work-schedules.edit', $schedule) }}" class="p-1.5 text-secondary-400 hover:text-primary-600 hover:bg-primary-50 rounded-md transition-colors" title="Edit">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                            </a>
                            @unless($schedule->is_default)
                            <button
                                type="button"
                                @click="$dispatch('confirm-dialog', {
                                    title: 'Hapus Jadwal Kerja',
                                    message: 'Apakah Anda yakin ingin menghapus jadwal {{ $schedule->name }}?',
                                    confirmText: 'Ya, Hapus',
                                    type: 'danger',
                                    formAction: '{{ route('work-schedules.destroy', $schedule) }}'
                                })"
                                class="p-1.5 text-secondary-400 hover:text-danger-600 hover:bg-danger-50 rounded-md transition-colors"
                                title="Hapus"
                            >
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                            </button>
                            @endunless
                        </div>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" class="text-center py-12">
                        <div class="flex flex-col items-center">
                            <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            <p class="text-secondary-500">Belum ada data jadwal kerja.</p>
                            <a href="{{ route('work-schedules.create') }}" class="btn btn-primary mt-4">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
                                Tambah Jadwal
                            </a>
                        </div>
                    </td>
                </tr>
            @endforelse
        </x-table>

        @if($workSchedules->hasPages())
            <div class="card-footer">
                {{ $workSchedules->links() }}
            </div>
        @endif
    </div>

    {{-- Assign Schedule Modal --}}
    <x-modal name="assign-schedule" title="Assign Jadwal Kerja">
        <form action="{{ route('work-schedules.bulk-assign') }}" method="POST" x-data="{ targetType: '{{ old('target_type', 'all') }}' }">
            @csrf

            <div class="space-y-4">
                <div>
                    <label for="assign_work_schedule_id" class="block text-sm font-medium text-secondary-700 mb-1">
                        Jadwal Kerja <span class="text-danger-500">*</span>
                    </label>
                    <select name="work_schedule_id" id="assign_work_schedule_id" class="input w-full @error('work_schedule_id') border-danger-500 @enderror" required>
                        <option value="">Pilih jadwal...</option>
                        @foreach($assignableSchedules as $schedule)
                            <option value="{{ $schedule->id }}" {{ old('work_schedule_id') == $schedule->id ? 'selected' : '' }}>
                                {{ $schedule->name }}{{ $schedule->code ? ' ('.$schedule->code.')' : '' }}
                            </option>
                        @endforeach
                    </select>
                    @error('work_schedule_id')
                        <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                    @enderror
                </div>

                <div>
                    <label class="block text-sm font-medium text-secondary-700 mb-2">Assign ke</label>
                    <div class="space-y-2">
                        <label class="flex items-center gap-2">
                            <input type="radio" name="target_type" value="all" x-model="targetType" class="text-primary-600">
                            <span class="text-sm">Semua Karyawan</span>
                        </label>
                        <label class="flex items-center gap-2">
                            <input type="radio" name="target_type" value="department" x-model="targetType" class="text-primary-600">
                            <span class="text-sm">Departemen Tertentu</span>
                        </label>
                        <label class="flex items-center gap-2">
                            <input type="radio" name="target_type" value="position" x-model="targetType" class="text-primary-600">
                            <span class="text-sm">Jabatan Tertentu</span>
                        </label>
                    </div>
                    @error('target_type')
                        <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                    @enderror
                </div>

                <div x-show="targetType === 'department'" x-cloak>
                    <label for="assign_department_id" class="block text-sm font-medium text-secondary-700 mb-1">Departemen</label>
                    <select name="department_id" id="assign_department_id" class="input w-full @error('department_id') border-danger-500 @enderror" :required="targetType === 'department'">
                        <option value="">Pilih departemen...</option>
                        @foreach($departments as $department)
                            <option value="{{ $department->id }}" {{ old('department_id') == $department->id ? 'selected' : '' }}>{{ $department->name }}</option>
                        @endforeach
                    </select>
                    @error('department_id')
                        <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                    @enderror
                </div>

                <div x-show="targetType === 'position'" x-cloak>
                    <label for="assign_position_id" class="block text-sm font-medium text-secondary-700 mb-1">Jabatan</label>
                    <select name="position_id" id="assign_position_id" class="input w-full @error('position_id') border-danger-500 @enderror" :required="targetType === 'position'">
                        <option value="">Pilih jabatan...</option>
                        @foreach($positions as $position)
                            <option value="{{ $position->id }}" {{ old('position_id') == $position->id ? 'selected' : '' }}>
                                {{ $position->name }}{{ $position->department ? ' ('.$position->department->name.')' : '' }}
                            </option>
                        @endforeach
                    </select>
                    @error('position_id')
                        <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                    @enderror
                </div>

                <div class="bg-warning-50 text-warning-700 text-xs p-3 rounded-lg">
                    Jadwal yang dipilih akan menimpa jadwal kerja karyawan pada target yang dipilih, termasuk pola jadwal mingguan per-hari yang sudah diatur sebelumnya untuk karyawan tersebut.
                </div>
            </div>

            <div class="flex items-center justify-end gap-3 mt-6">
                <button type="button" @click="open = false" class="btn btn-ghost">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan</button>
            </div>
        </form>
    </x-modal>

    @if($errors->hasAny(['work_schedule_id', 'target_type', 'department_id', 'position_id']))
        <script>
            document.addEventListener('DOMContentLoaded', () => {
                window.dispatchEvent(new CustomEvent('open-modal', { detail: 'assign-schedule' }));
            });
        </script>
    @endif
@endsection
