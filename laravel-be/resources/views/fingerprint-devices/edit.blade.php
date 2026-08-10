@extends('layouts.admin')

@section('title', 'Edit Mesin Fingerprint')

@section('breadcrumb')
    <a href="{{ route('fingerprint-devices.index') }}" class="text-slate-500 hover:text-primary-600">Mesin Fingerprint</a>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Edit</span>
@endsection

@section('header')
    <h1 class="text-2xl font-bold text-secondary-900">Edit Mesin Fingerprint</h1>
@endsection

@section('content')
    <div class="card max-w-2xl">
        <form method="POST" action="{{ route('fingerprint-devices.update', $fingerprintDevice) }}">
            @csrf
            @method('PUT')
            <div class="card-body space-y-4">
                <div>
                    <label for="name" class="block text-sm font-medium text-secondary-700 mb-1">Nama Mesin <span class="text-danger-500">*</span></label>
                    <input type="text" name="name" id="name" value="{{ old('name', $fingerprintDevice->name) }}" class="input w-full @error('name') border-danger-500 @enderror" required>
                    @error('name')<p class="mt-1 text-sm text-danger-600">{{ $message }}</p>@enderror
                </div>

                <div>
                    <label for="brand" class="block text-sm font-medium text-secondary-700 mb-1">Merek <span class="text-danger-500">*</span></label>
                    <select name="brand" id="brand" class="input w-full @error('brand') border-danger-500 @enderror" required>
                        @foreach(['zkteco' => 'ZKTeco', 'fingerspot' => 'Fingerspot', 'solution' => 'Solution (X100C, dll)', 'other' => 'Lainnya'] as $value => $label)
                            <option value="{{ $value }}" {{ old('brand', $fingerprintDevice->brand) === $value ? 'selected' : '' }}>{{ $label }}</option>
                        @endforeach
                    </select>
                    @error('brand')<p class="mt-1 text-sm text-danger-600">{{ $message }}</p>@enderror
                </div>

                <div>
                    <label for="serial_number" class="block text-sm font-medium text-secondary-700 mb-1">Serial Number <span class="text-danger-500">*</span></label>
                    <input type="text" name="serial_number" id="serial_number" value="{{ old('serial_number', $fingerprintDevice->serial_number) }}" class="input w-full font-mono @error('serial_number') border-danger-500 @enderror" required>
                    @error('serial_number')<p class="mt-1 text-sm text-danger-600">{{ $message }}</p>@enderror
                </div>

                <div>
                    <label for="office_location_id" class="block text-sm font-medium text-secondary-700 mb-1">Lokasi Kantor</label>
                    <select name="office_location_id" id="office_location_id" class="input w-full @error('office_location_id') border-danger-500 @enderror">
                        <option value="">Belum ditentukan</option>
                        @foreach($officeLocations as $location)
                            <option value="{{ $location->id }}" {{ old('office_location_id', $fingerprintDevice->office_location_id) == $location->id ? 'selected' : '' }}>{{ $location->name }}</option>
                        @endforeach
                    </select>
                    @error('office_location_id')<p class="mt-1 text-sm text-danger-600">{{ $message }}</p>@enderror
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label for="ip_address" class="block text-sm font-medium text-secondary-700 mb-1">IP Address</label>
                        <input type="text" name="ip_address" id="ip_address" value="{{ old('ip_address', $fingerprintDevice->ip_address) }}" class="input w-full @error('ip_address') border-danger-500 @enderror">
                        @error('ip_address')<p class="mt-1 text-sm text-danger-600">{{ $message }}</p>@enderror
                    </div>
                    <div>
                        <label for="port" class="block text-sm font-medium text-secondary-700 mb-1">Port</label>
                        <input type="number" name="port" id="port" value="{{ old('port', $fingerprintDevice->port) }}" class="input w-full @error('port') border-danger-500 @enderror">
                        @error('port')<p class="mt-1 text-sm text-danger-600">{{ $message }}</p>@enderror
                    </div>
                </div>

                <label class="flex items-center gap-2">
                    <input type="checkbox" name="is_active" value="1" {{ old('is_active', $fingerprintDevice->is_active) ? 'checked' : '' }} class="rounded border-secondary-300">
                    <span class="text-sm text-secondary-700">Aktif</span>
                </label>
            </div>
            <div class="card-footer flex justify-end gap-3">
                <a href="{{ route('fingerprint-devices.index') }}" class="btn btn-secondary">Batal</a>
                <button type="submit" class="btn btn-primary">Simpan</button>
            </div>
        </form>
    </div>
@endsection
