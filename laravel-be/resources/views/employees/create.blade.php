@extends('layouts.admin')

@section('title', 'Tambah Karyawan')

@section('breadcrumb')
    <a href="{{ route('employees.index') }}" class="text-slate-500 hover:text-primary-600">Karyawan</a>
    <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
    <span class="text-slate-700 font-medium">Tambah Karyawan</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Tambah Karyawan</h1>
            <p class="text-secondary-500 mt-1">Tambahkan karyawan baru ke sistem.</p>
        </div>
        <a href="{{ route('employees.index') }}" class="btn btn-ghost">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
            Kembali
        </a>
    </div>
@endsection

@section('content')
    <form action="{{ route('employees.store') }}" method="POST" enctype="multipart/form-data" class="space-y-6">
        @csrf

        {{-- Personal Information --}}
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Informasi Pribadi</h3>
            </div>
            <div class="card-body">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {{-- First Name --}}
                    <div>
                        <label for="first_name" class="block text-sm font-medium text-secondary-700 mb-1">Nama Depan <span class="text-danger-500">*</span></label>
                        <input type="text" name="first_name" id="first_name" value="{{ old('first_name') }}" class="input w-full @error('first_name') border-danger-500 @enderror" required>
                        @error('first_name')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Last Name --}}
                    <div>
                        <label for="last_name" class="block text-sm font-medium text-secondary-700 mb-1">Nama Belakang</label>
                        <input type="text" name="last_name" id="last_name" value="{{ old('last_name') }}" class="input w-full @error('last_name') border-danger-500 @enderror">
                        @error('last_name')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Email --}}
                    <div>
                        <label for="email" class="block text-sm font-medium text-secondary-700 mb-1">Email</label>
                        <input type="email" name="email" id="email" value="{{ old('email') }}" class="input w-full @error('email') border-danger-500 @enderror">
                        @error('email')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Phone --}}
                    <div>
                        <label for="phone" class="block text-sm font-medium text-secondary-700 mb-1">No. Telepon</label>
                        <input type="text" name="phone" id="phone" value="{{ old('phone') }}" class="input w-full @error('phone') border-danger-500 @enderror">
                        @error('phone')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- NIK / No. KTP --}}
                    <div>
                        <label for="nik" class="block text-sm font-medium text-secondary-700 mb-1">NIK (No. KTP)</label>
                        <input type="text" name="nik" id="nik" value="{{ old('nik') }}" class="input w-full @error('nik') border-danger-500 @enderror" placeholder="16 digit nomor induk kependudukan" maxlength="20">
                        @error('nik')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Gender --}}
                    <div>
                        <label for="gender" class="block text-sm font-medium text-secondary-700 mb-1">Jenis Kelamin</label>
                        <select name="gender" id="gender" class="input w-full @error('gender') border-danger-500 @enderror">
                            <option value="">Pilih Jenis Kelamin</option>
                            <option value="male" {{ old('gender') == 'male' ? 'selected' : '' }}>Laki-laki</option>
                            <option value="female" {{ old('gender') == 'female' ? 'selected' : '' }}>Perempuan</option>
                        </select>
                        @error('gender')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Date of Birth --}}
                    <div>
                        <label for="date_of_birth" class="block text-sm font-medium text-secondary-700 mb-1">Tanggal Lahir</label>
                        <input type="date" name="date_of_birth" id="date_of_birth" value="{{ old('date_of_birth') }}" class="input w-full @error('date_of_birth') border-danger-500 @enderror">
                        @error('date_of_birth')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Marital Status --}}
                    <div>
                        <label for="marital_status" class="block text-sm font-medium text-secondary-700 mb-1">Status Pernikahan</label>
                        <select name="marital_status" id="marital_status" class="input w-full @error('marital_status') border-danger-500 @enderror">
                            <option value="">Pilih Status</option>
                            <option value="single" {{ old('marital_status') == 'single' ? 'selected' : '' }}>Belum Menikah</option>
                            <option value="married" {{ old('marital_status') == 'married' ? 'selected' : '' }}>Menikah</option>
                            <option value="divorced" {{ old('marital_status') == 'divorced' ? 'selected' : '' }}>Cerai</option>
                            <option value="widowed" {{ old('marital_status') == 'widowed' ? 'selected' : '' }}>Duda/Janda</option>
                        </select>
                        @error('marital_status')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Religion --}}
                    <div>
                        <label for="religion" class="block text-sm font-medium text-secondary-700 mb-1">Agama</label>
                        <select name="religion" id="religion" class="input w-full @error('religion') border-danger-500 @enderror">
                            <option value="">Pilih Agama</option>
                            @foreach(['Islam', 'Kristen Protestan', 'Katolik', 'Hindu', 'Buddha', 'Konghucu', 'Lainnya'] as $rel)
                                <option value="{{ $rel }}" {{ old('religion') == $rel ? 'selected' : '' }}>{{ $rel }}</option>
                            @endforeach
                        </select>
                        @error('religion')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Blood Type --}}
                    <div>
                        <label for="blood_type" class="block text-sm font-medium text-secondary-700 mb-1">Golongan Darah</label>
                        <select name="blood_type" id="blood_type" class="input w-full @error('blood_type') border-danger-500 @enderror">
                            <option value="">Pilih Golongan Darah</option>
                            @foreach(['A', 'B', 'AB', 'O'] as $bt)
                                <option value="{{ $bt }}" {{ old('blood_type') == $bt ? 'selected' : '' }}>{{ $bt }}</option>
                            @endforeach
                        </select>
                        @error('blood_type')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Photo Upload --}}
                    <div class="md:col-span-2">
                        <label for="photo" class="block text-sm font-medium text-secondary-700 mb-1">Foto Profil Karyawan</label>
                        <input type="file" name="photo" id="photo" accept="image/*" class="block w-full text-sm text-secondary-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-medium file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100 @error('photo') border-danger-500 @enderror">
                        <p class="mt-1 text-xs text-secondary-500">Format: JPG, PNG, WEBP (Maksimal 2MB).</p>
                        @error('photo')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Identity Address (KTP) --}}
                    <div class="md:col-span-2">
                        <label for="identity_address" class="block text-sm font-medium text-secondary-700 mb-1">Alamat Sesuai KTP</label>
                        <textarea name="identity_address" id="identity_address" rows="2" class="input w-full @error('identity_address') border-danger-500 @enderror" placeholder="Alamat lengkap sesuai identitas KTP">{{ old('identity_address') }}</textarea>
                        @error('identity_address')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Address (Domisili) --}}
                    <div class="md:col-span-2">
                        <label for="address" class="block text-sm font-medium text-secondary-700 mb-1">Alamat Domisili / Tempat Tinggal</label>
                        <textarea name="address" id="address" rows="2" class="input w-full @error('address') border-danger-500 @enderror" placeholder="Alamat tempat tinggal saat ini">{{ old('address') }}</textarea>
                        @error('address')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- City --}}
                    <div>
                        <label for="city" class="block text-sm font-medium text-secondary-700 mb-1">Kota / Kabupaten</label>
                        <input type="text" name="city" id="city" value="{{ old('city') }}" class="input w-full @error('city') border-danger-500 @enderror" placeholder="Contoh: Jakarta Timur">
                        @error('city')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Province --}}
                    <div>
                        <label for="province" class="block text-sm font-medium text-secondary-700 mb-1">Provinsi</label>
                        <input type="text" name="province" id="province" value="{{ old('province') }}" class="input w-full @error('province') border-danger-500 @enderror" placeholder="Contoh: DKI Jakarta">
                        @error('province')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Postal Code --}}
                    <div>
                        <label for="postal_code" class="block text-sm font-medium text-secondary-700 mb-1">Kode Pos</label>
                        <input type="text" name="postal_code" id="postal_code" value="{{ old('postal_code') }}" class="input w-full @error('postal_code') border-danger-500 @enderror" placeholder="Contoh: 13450" maxlength="10">
                        @error('postal_code')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>
                </div>
            </div>
        </div>

        {{-- Emergency Contact Information --}}
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Kontak Darurat</h3>
            </div>
            <div class="card-body">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    {{-- Emergency Contact Name --}}
                    <div>
                        <label for="emergency_contact_name" class="block text-sm font-medium text-secondary-700 mb-1">Nama Kontak</label>
                        <input type="text" name="emergency_contact_name" id="emergency_contact_name" value="{{ old('emergency_contact_name') }}" class="input w-full @error('emergency_contact_name') border-danger-500 @enderror" placeholder="Contoh: Jane Doe">
                        @error('emergency_contact_name')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Emergency Contact Phone --}}
                    <div>
                        <label for="emergency_contact_phone" class="block text-sm font-medium text-secondary-700 mb-1">No. Telepon Darurat</label>
                        <input type="text" name="emergency_contact_phone" id="emergency_contact_phone" value="{{ old('emergency_contact_phone') }}" class="input w-full @error('emergency_contact_phone') border-danger-500 @enderror" placeholder="Contoh: 08123456789">
                        @error('emergency_contact_phone')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Emergency Contact Relationship --}}
                    <div>
                        <label for="emergency_contact_relationship" class="block text-sm font-medium text-secondary-700 mb-1">Hubungan</label>
                        <input type="text" name="emergency_contact_relationship" id="emergency_contact_relationship" value="{{ old('emergency_contact_relationship') }}" class="input w-full @error('emergency_contact_relationship') border-danger-500 @enderror" placeholder="Contoh: Pasangan / Orang Tua / Saudara">
                        @error('emergency_contact_relationship')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>
                </div>
            </div>
        </div>

        {{-- Account Information --}}
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Informasi Akun</h3>
            </div>
            <div class="card-body">
                <div class="p-4 bg-info-50 border border-info-200 rounded-lg mb-6">
                    <div class="flex items-start gap-3">
                        <svg class="w-5 h-5 text-info-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                        <div>
                            <p class="text-sm text-info-800 font-medium">Akun Login Karyawan</p>
                            <p class="text-sm text-info-600 mt-1">Jika password diisi, sistem akan membuat akun login untuk karyawan ini. Karyawan dapat login menggunakan email dan password yang ditentukan.</p>
                        </div>
                    </div>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {{-- Password --}}
                    <div x-data="{ show: false }">
                        <label for="password" class="block text-sm font-medium text-secondary-700 mb-1">Password</label>
                        <div class="relative">
                            <input :type="show ? 'text' : 'password'" name="password" id="password" class="input w-full @error('password') border-danger-500 @enderror" placeholder="Kosongkan jika tidak ingin membuat akun">
                            <button type="button" @click="show = !show" class="absolute right-3 top-1/2 -translate-y-1/2 text-secondary-400 hover:text-secondary-600">
                                <svg x-show="!show" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                <svg x-show="show" x-cloak class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"/></svg>
                            </button>
                        </div>
                        @error('password')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                        <p class="mt-1 text-xs text-secondary-500">Minimal 8 karakter</p>
                    </div>

                    {{-- Password Confirmation --}}
                    <div x-data="{ show: false }">
                        <label for="password_confirmation" class="block text-sm font-medium text-secondary-700 mb-1">Konfirmasi Password</label>
                        <div class="relative">
                            <input :type="show ? 'text' : 'password'" name="password_confirmation" id="password_confirmation" class="input w-full" placeholder="Ulangi password">
                            <button type="button" @click="show = !show" class="absolute right-3 top-1/2 -translate-y-1/2 text-secondary-400 hover:text-secondary-600">
                                <svg x-show="!show" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                <svg x-show="show" x-cloak class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"/></svg>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Employment Information --}}
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Informasi Pekerjaan</h3>
            </div>
            <div class="card-body">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {{-- NIP / Employee ID --}}
                    <div>
                        <label for="employee_id" class="block text-sm font-medium text-secondary-700 mb-1">NIP / ID Karyawan</label>
                        <input type="text" name="employee_id" id="employee_id" value="{{ old('employee_id') }}" class="input w-full @error('employee_id') border-danger-500 @enderror" placeholder="Otomatis digenerate jika kosong">
                        <p class="mt-1 text-xs text-secondary-500">Kosongkan jika ingin digenerate otomatis oleh sistem.</p>
                        @error('employee_id')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- PIN Mesin Fingerprint --}}
                    <div>
                        <label for="pin" class="block text-sm font-medium text-secondary-700 mb-1">PIN Mesin Fingerprint</label>
                        <input type="text" name="pin" id="pin" value="{{ old('pin') }}" class="input w-full @error('pin') border-danger-500 @enderror" placeholder="Contoh: 1032">
                        <p class="mt-1 text-xs text-secondary-500">Nomor PIN biometrik yang terdaftar pada mesin fingerprint / ADMS.</p>
                        @error('pin')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Department --}}
                    <div>
                        <label for="department_id" class="block text-sm font-medium text-secondary-700 mb-1">Departemen <span class="text-danger-500">*</span></label>
                        <select name="department_id" id="department_id" class="input w-full @error('department_id') border-danger-500 @enderror" required>
                            <option value="">Pilih Departemen</option>
                            @foreach($departments as $department)
                                <option value="{{ $department->id }}" {{ old('department_id') == $department->id ? 'selected' : '' }}>
                                    {{ $department->name }}
                                </option>
                            @endforeach
                        </select>
                        @error('department_id')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Position --}}
                    <div>
                        <label for="position_id" class="block text-sm font-medium text-secondary-700 mb-1">Jabatan <span class="text-danger-500">*</span></label>
                        <select name="position_id" id="position_id" class="input w-full @error('position_id') border-danger-500 @enderror" required>
                            <option value="">Pilih Jabatan</option>
                            @foreach($positions as $position)
                                <option value="{{ $position->id }}" {{ old('position_id') == $position->id ? 'selected' : '' }}>
                                    {{ $position->name }}
                                </option>
                            @endforeach
                        </select>
                        @error('position_id')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>
                    
                    {{-- Manager --}}
                    <div>
                        <label for="manager_id" class="block text-sm font-medium text-secondary-700 mb-1">Atasan / Manager</label>
                        <select name="manager_id" id="manager_id" class="input w-full @error('manager_id') border-danger-500 @enderror">
                            <option value="">Pilih Atasan</option>
                            @foreach($managers as $manager)
                                <option value="{{ $manager->id }}" {{ old('manager_id') == $manager->id ? 'selected' : '' }}>
                                    {{ $manager->full_name }} ({{ $manager->employee_id }})
                                </option>
                            @endforeach
                        </select>
                        @error('manager_id')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Hire Date --}}
                    <div>
                        <label for="hire_date" class="block text-sm font-medium text-secondary-700 mb-1">Tanggal Bergabung <span class="text-danger-500">*</span></label>
                        <input type="date" name="hire_date" id="hire_date" value="{{ old('hire_date') }}" class="input w-full @error('hire_date') border-danger-500 @enderror" required>
                        @error('hire_date')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Employment Status --}}
                    <div>
                        <label for="employment_status" class="block text-sm font-medium text-secondary-700 mb-1">Status Kerja <span class="text-danger-500">*</span></label>
                        <select name="employment_status" id="employment_status" class="input w-full @error('employment_status') border-danger-500 @enderror" required>
                            <option value="">Pilih Status</option>
                            <option value="permanent" {{ old('employment_status') == 'permanent' ? 'selected' : '' }}>Tetap</option>
                            <option value="contract" {{ old('employment_status') == 'contract' ? 'selected' : '' }}>Kontrak</option>
                            <option value="probation" {{ old('employment_status') == 'probation' ? 'selected' : '' }}>Probation</option>
                            <option value="intern" {{ old('employment_status') == 'intern' ? 'selected' : '' }}>Magang</option>
                        </select>
                        @error('employment_status')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Work Schedule --}}
                    <div class="md:col-span-2" x-data="{ scheduleMode: '{{ old('schedule_mode', 'default') }}' }">
                        <label class="block text-sm font-medium text-secondary-700 mb-2">Jadwal Kerja</label>

                        {{-- Schedule Mode Toggle --}}
                        <div class="flex gap-4 mb-4">
                            <label class="flex items-center gap-2 cursor-pointer">
                                <input type="radio" name="schedule_mode" value="default" x-model="scheduleMode" class="text-primary-600 focus:ring-primary-500">
                                <span class="text-sm text-secondary-700">Jadwal Tetap</span>
                            </label>
                            <label class="flex items-center gap-2 cursor-pointer">
                                <input type="radio" name="schedule_mode" value="weekly" x-model="scheduleMode" class="text-primary-600 focus:ring-primary-500">
                                <span class="text-sm text-secondary-700">Jadwal Mingguan</span>
                            </label>
                        </div>

                        {{-- Default: Single Schedule --}}
                        <div x-show="scheduleMode === 'default'" x-cloak>
                            <select name="work_schedule_id" id="work_schedule_id" class="input w-full @error('work_schedule_id') border-danger-500 @enderror">
                                <option value="">Pilih Jadwal Kerja</option>
                                @foreach($workSchedules as $schedule)
                                    <option value="{{ $schedule->id }}" {{ old('work_schedule_id') == $schedule->id ? 'selected' : '' }}>
                                        {{ $schedule->name }} ({{ \Carbon\Carbon::parse($schedule->start_time)->format('H:i') }} - {{ \Carbon\Carbon::parse($schedule->end_time)->format('H:i') }})
                                    </option>
                                @endforeach
                            </select>
                            @error('work_schedule_id')
                                <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                            @enderror
                        </div>

                        {{-- Weekly: Per-day Schedule --}}
                        <div x-show="scheduleMode === 'weekly'" x-cloak>
                            <div class="border border-secondary-200 rounded-lg overflow-hidden">
                                @php
                                    $days = [1 => 'Senin', 2 => 'Selasa', 3 => 'Rabu', 4 => 'Kamis', 5 => 'Jumat', 6 => 'Sabtu', 7 => 'Minggu'];
                                @endphp
                                @foreach($days as $dayNum => $dayName)
                                    <div class="flex items-center gap-4 px-4 py-3 {{ !$loop->last ? 'border-b border-secondary-200' : '' }}">
                                        <span class="text-sm font-medium text-secondary-700 w-20">{{ $dayName }}</span>
                                        <select name="weekly_schedules[{{ $dayNum }}]" class="input flex-1 @error('weekly_schedules.'.$dayNum) border-danger-500 @enderror">
                                            <option value="">Libur (Off)</option>
                                            @foreach($workSchedules as $schedule)
                                                <option value="{{ $schedule->id }}" {{ old('weekly_schedules.'.$dayNum) == $schedule->id ? 'selected' : '' }}>
                                                    {{ $schedule->name }} ({{ \Carbon\Carbon::parse($schedule->start_time)->format('H:i') }} - {{ \Carbon\Carbon::parse($schedule->end_time)->format('H:i') }})
                                                </option>
                                            @endforeach
                                        </select>
                                        @error('weekly_schedules.'.$dayNum)
                                            <p class="text-sm text-danger-600">{{ $message }}</p>
                                        @enderror
                                    </div>
                                @endforeach
                            </div>
                            <p class="mt-2 text-xs text-secondary-500">Pilih jadwal per hari. Hari tanpa jadwal dianggap libur.</p>
                        </div>
                    </div>

                    {{-- Contract Start Date --}}
                    <div>
                        <label for="contract_start_date" class="block text-sm font-medium text-secondary-700 mb-1">Tanggal Mulai Kontrak</label>
                        <input type="date" name="contract_start_date" id="contract_start_date" value="{{ old('contract_start_date') }}" class="input w-full @error('contract_start_date') border-danger-500 @enderror">
                        @error('contract_start_date')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Contract End Date --}}
                    <div>
                        <label for="contract_end_date" class="block text-sm font-medium text-secondary-700 mb-1">Tanggal Akhir Kontrak</label>
                        <input type="date" name="contract_end_date" id="contract_end_date" value="{{ old('contract_end_date') }}" class="input w-full @error('contract_end_date') border-danger-500 @enderror">
                        @error('contract_end_date')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Base Salary --}}
                    <div x-data="currencyInput({{ old('base_salary', 0) }})">
                        <label for="base_salary_display" class="block text-sm font-medium text-secondary-700 mb-1">Gaji Pokok</label>
                        <div class="input-group">
                            <span class="input-group-text">Rp</span>
                            <input type="text" id="base_salary_display" x-model="display" @input="updateValue($event)"
                                   class="input @error('base_salary') border-danger-500 @enderror"
                                   placeholder="0" inputmode="numeric">
                            <input type="hidden" name="base_salary" :value="value">
                        </div>
                        @error('base_salary')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>
                </div>
            </div>
        </div>

        {{-- Office Locations --}}
        @if($officeLocations->count() > 0)
        <div class="card" x-data="{
            selectedOffices: {{ json_encode(array_map('strval', old('office_location_ids', []))) }},
            primaryOffice: '{{ old('primary_office_id') ?? '' }}',
            toggleOffice(id) {
                const strId = String(id);
                const index = this.selectedOffices.indexOf(strId);
                if (index > -1) {
                    this.selectedOffices.splice(index, 1);
                    if (this.primaryOffice === strId) {
                        this.primaryOffice = this.selectedOffices[0] || '';
                    }
                } else {
                    this.selectedOffices.push(strId);
                    if (!this.primaryOffice) {
                        this.primaryOffice = strId;
                    }
                }
            },
            isSelected(id) {
                return this.selectedOffices.includes(String(id));
            }
        }">
            <div class="card-header">
                <h3 class="card-title">Lokasi Kantor</h3>
            </div>
            <div class="card-body">
                <p class="text-sm text-secondary-500 mb-4">Pilih lokasi kantor yang di-assign ke karyawan ini. Karyawan hanya dapat melakukan absensi di lokasi yang dipilih.</p>

                <div class="space-y-3">
                    @foreach($officeLocations as $office)
                        <label class="flex items-start gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                               :class="isSelected({{ $office->id }}) ? 'border-primary-300 bg-primary-50' : 'border-secondary-200 hover:border-secondary-300'">
                            <input type="checkbox"
                                   name="office_location_ids[]"
                                   value="{{ $office->id }}"
                                   :checked="isSelected({{ $office->id }})"
                                   @click="toggleOffice({{ $office->id }})"
                                   class="mt-1 rounded border-secondary-300 text-primary-600 focus:ring-primary-500">
                            <div class="flex-1">
                                <div class="flex items-center gap-2">
                                    <span class="font-medium text-secondary-900">{{ $office->name }}</span>
                                    <span class="text-xs bg-secondary-100 text-secondary-600 px-2 py-0.5 rounded">{{ $office->code }}</span>
                                </div>
                                <p class="text-sm text-secondary-500 mt-0.5">{{ $office->address }}</p>
                                <p class="text-xs text-secondary-400 mt-1">Radius: {{ $office->radius }}m</p>
                            </div>
                            <div x-show="isSelected({{ $office->id }})" x-cloak class="flex items-center gap-2">
                                <input type="radio"
                                       name="primary_office_id"
                                       value="{{ $office->id }}"
                                       :checked="primaryOffice === '{{ $office->id }}'"
                                       @click="primaryOffice = '{{ $office->id }}'"
                                       class="text-primary-600 focus:ring-primary-500">
                                <span class="text-xs text-secondary-600">Utama</span>
                            </div>
                        </label>
                    @endforeach
                </div>

                @error('office_location_ids')
                    <p class="mt-2 text-sm text-danger-600">{{ $message }}</p>
                @enderror
            </div>
        </div>
        @endif

        {{-- Bank Information --}}
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Informasi Bank</h3>
            </div>
            <div class="card-body">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    {{-- Bank Name --}}
                    <div>
                        <label for="bank_name" class="block text-sm font-medium text-secondary-700 mb-1">Nama Bank</label>
                        <input type="text" name="bank_name" id="bank_name" value="{{ old('bank_name') }}" class="input w-full @error('bank_name') border-danger-500 @enderror">
                        @error('bank_name')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Bank Account Number --}}
                    <div>
                        <label for="bank_account_number" class="block text-sm font-medium text-secondary-700 mb-1">Nomor Rekening</label>
                        <input type="text" name="bank_account_number" id="bank_account_number" value="{{ old('bank_account_number') }}" class="input w-full @error('bank_account_number') border-danger-500 @enderror">
                        @error('bank_account_number')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Bank Account Name --}}
                    <div>
                        <label for="bank_account_name" class="block text-sm font-medium text-secondary-700 mb-1">Nama Pemilik Rekening</label>
                        <input type="text" name="bank_account_name" id="bank_account_name" value="{{ old('bank_account_name') }}" class="input w-full @error('bank_account_name') border-danger-500 @enderror">
                        @error('bank_account_name')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>
                </div>
            </div>
        </div>

        {{-- Tax & BPJS Information --}}
        <div class="card">
            <div class="card-header">
                <h3 class="card-title">Informasi Pajak & BPJS</h3>
            </div>
            <div class="card-body">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {{-- NPWP --}}
                    <div>
                        <label for="npwp" class="block text-sm font-medium text-secondary-700 mb-1">NPWP</label>
                        <input type="text" name="npwp" id="npwp" value="{{ old('npwp') }}" class="input w-full @error('npwp') border-danger-500 @enderror">
                        @error('npwp')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- Tax Status --}}
                    <div>
                        <label for="tax_status" class="block text-sm font-medium text-secondary-700 mb-1">Status Pajak</label>
                        <select name="tax_status" id="tax_status" class="input w-full @error('tax_status') border-danger-500 @enderror">
                            <option value="">Pilih Status Pajak</option>
                            <option value="TK/0" {{ old('tax_status') == 'TK/0' ? 'selected' : '' }}>TK/0</option>
                            <option value="TK/1" {{ old('tax_status') == 'TK/1' ? 'selected' : '' }}>TK/1</option>
                            <option value="TK/2" {{ old('tax_status') == 'TK/2' ? 'selected' : '' }}>TK/2</option>
                            <option value="TK/3" {{ old('tax_status') == 'TK/3' ? 'selected' : '' }}>TK/3</option>
                            <option value="K/0" {{ old('tax_status') == 'K/0' ? 'selected' : '' }}>K/0</option>
                            <option value="K/1" {{ old('tax_status') == 'K/1' ? 'selected' : '' }}>K/1</option>
                            <option value="K/2" {{ old('tax_status') == 'K/2' ? 'selected' : '' }}>K/2</option>
                            <option value="K/3" {{ old('tax_status') == 'K/3' ? 'selected' : '' }}>K/3</option>
                        </select>
                        @error('tax_status')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- BPJS Kesehatan --}}
                    <div>
                        <label for="bpjs_kesehatan" class="block text-sm font-medium text-secondary-700 mb-1">No. BPJS Kesehatan</label>
                        <input type="text" name="bpjs_kesehatan" id="bpjs_kesehatan" value="{{ old('bpjs_kesehatan') }}" class="input w-full @error('bpjs_kesehatan') border-danger-500 @enderror">
                        @error('bpjs_kesehatan')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>

                    {{-- BPJS Ketenagakerjaan --}}
                    <div>
                        <label for="bpjs_ketenagakerjaan" class="block text-sm font-medium text-secondary-700 mb-1">No. BPJS Ketenagakerjaan</label>
                        <input type="text" name="bpjs_ketenagakerjaan" id="bpjs_ketenagakerjaan" value="{{ old('bpjs_ketenagakerjaan') }}" class="input w-full @error('bpjs_ketenagakerjaan') border-danger-500 @enderror">
                        @error('bpjs_ketenagakerjaan')
                            <p class="mt-1 text-sm text-danger-600">{{ $message }}</p>
                        @enderror
                    </div>
                </div>
            </div>
        </div>

        {{-- Form Actions --}}
        <div class="flex items-center justify-end gap-3">
            <a href="{{ route('employees.index') }}" class="btn btn-ghost">Batal</a>
            <button type="submit" class="btn btn-primary">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                Simpan Karyawan
            </button>
        </div>
    </form>
@endsection
