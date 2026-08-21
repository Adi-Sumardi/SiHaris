@extends('layouts.admin')

@section('title', 'Permintaan Reset / Daftar Ulang Wajah')

@section('breadcrumb')
    <a href="{{ route('face-recognition.index') }}" class="text-secondary-500 hover:text-secondary-700">Pendaftaran Wajah</a>
    <span class="text-secondary-400 mx-2">/</span>
    <span class="text-slate-700 font-medium">Permintaan Reset Wajah</span>
@endsection

@section('header')
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
            <h1 class="text-2xl font-bold text-secondary-900">Permintaan Reset Wajah</h1>
            <p class="text-secondary-500 mt-1">Konfirmasi permohonan pendaftaran ulang wajah dari karyawan.</p>
        </div>
        <div class="flex items-center gap-2">
            <a href="{{ route('face-recognition.index') }}" class="btn btn-outline">
                <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
                </svg>
                Kembali ke Data Wajah
            </a>
        </div>
    </div>
@endsection

@section('content')
    {{-- Filter & Stats --}}
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <a href="{{ route('face-recognition.requests', ['status' => 'pending']) }}" class="card hover:border-warning-500 transition-colors {{ request('status') === 'pending' || !request('status') ? 'ring-2 ring-warning-500' : '' }}">
            <div class="card-body-sm flex items-center gap-3">
                <div class="w-10 h-10 bg-warning-100 rounded-lg flex items-center justify-center">
                    <svg class="w-5 h-5 text-warning-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <div>
                    <p class="text-sm text-secondary-500">Menunggu Konfirmasi</p>
                    <p class="text-xl font-bold text-warning-600">{{ $pendingCount }}</p>
                </div>
            </div>
        </a>
        <a href="{{ route('face-recognition.requests', ['status' => 'approved']) }}" class="card hover:border-success-500 transition-colors {{ request('status') === 'approved' ? 'ring-2 ring-success-500' : '' }}">
            <div class="card-body-sm flex items-center gap-3">
                <div class="w-10 h-10 bg-success-100 rounded-lg flex items-center justify-center">
                    <svg class="w-5 h-5 text-success-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <div>
                    <p class="text-sm text-secondary-500">Disetujui</p>
                    <p class="text-xl font-bold text-success-600">{{ $approvedCount }}</p>
                </div>
            </div>
        </a>
        <a href="{{ route('face-recognition.requests', ['status' => 'rejected']) }}" class="card hover:border-danger-500 transition-colors {{ request('status') === 'rejected' ? 'ring-2 ring-danger-500' : '' }}">
            <div class="card-body-sm flex items-center gap-3">
                <div class="w-10 h-10 bg-danger-100 rounded-lg flex items-center justify-center">
                    <svg class="w-5 h-5 text-danger-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <div>
                    <p class="text-sm text-secondary-500">Ditolak</p>
                    <p class="text-xl font-bold text-danger-600">{{ $rejectedCount }}</p>
                </div>
            </div>
        </a>
    </div>

    {{-- Requests Table --}}
    <div class="card">
        <x-table>
            <x-slot name="header">
                <th>Karyawan</th>
                <th>ID Karyawan</th>
                <th>Departemen</th>
                <th>Alasan Permohonan</th>
                <th>Tanggal Pengajuan</th>
                <th>Status</th>
                <th class="text-right">Aksi</th>
            </x-slot>

            @forelse($requests as $req)
                <tr>
                    <td>
                        <div class="flex items-center gap-2.5">
                            <div class="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-medium text-xs flex-shrink-0">
                                {{ strtoupper(substr($req->employee->first_name ?? 'E', 0, 1)) }}
                            </div>
                            <div class="min-w-0">
                                <span class="font-medium text-secondary-900 block truncate">
                                    {{ $req->employee->full_name }}
                                </span>
                                @if($req->employee->email)
                                    <p class="text-xs text-secondary-400 truncate">{{ $req->employee->email }}</p>
                                @endif
                            </div>
                        </div>
                    </td>
                    <td>
                        <span class="font-mono text-xs text-secondary-600">{{ $req->employee->employee_id }}</span>
                    </td>
                    <td class="text-secondary-600">{{ $req->employee->department?->name ?? '-' }}</td>
                    <td>
                        <p class="text-sm text-secondary-800 max-w-xs break-words">
                            {{ $req->reason ?: 'Tidak ada keterangan tambahan.' }}
                        </p>
                    </td>
                    <td class="text-secondary-600 text-xs">
                        {{ $req->created_at->format('d M Y H:i') }}
                    </td>
                    <td>
                        @if($req->status === 'pending')
                            <x-badge type="warning">
                                <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                                Menunggu Konfirmasi
                            </x-badge>
                        @elseif($req->status === 'approved')
                            <x-badge type="success">
                                <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                Disetujui
                            </x-badge>
                            @if($req->reviewer)
                                <p class="text-xs text-secondary-400 mt-1">oleh {{ $req->reviewer->name }}</p>
                            @endif
                        @else
                            <x-badge type="danger">
                                <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                                </svg>
                                Ditolak
                            </x-badge>
                            @if($req->admin_notes)
                                <p class="text-xs text-danger-600 mt-1 italic">"{{ $req->admin_notes }}"</p>
                            @endif
                        @endif
                    </td>
                    <td>
                        <div class="flex items-center justify-end gap-1.5">
                            @if($req->status === 'pending')
                                {{-- Form Approve --}}
                                <form action="{{ route('face-recognition.requests.approve', $req) }}" method="POST" onsubmit="return confirm('Setujui permintaan reset wajah untuk {{ $req->employee->full_name }}? Data biometrik lama akan dihapus dan karyawan dapat mendaftarkan ulang wajahnya.');">
                                    @csrf
                                    <button type="submit" class="btn btn-success btn-sm">
                                        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                        </svg>
                                        Setujui
                                    </button>
                                </form>

                                {{-- Button Reject Modal Trigger --}}
                                <button type="button" onclick="openRejectModal({{ $req->id }}, '{{ addslashes($req->employee->full_name) }}')" class="btn btn-danger btn-sm">
                                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                                    </svg>
                                    Tolak
                                </button>
                            @else
                                <span class="text-xs text-secondary-400">Selesai</span>
                            @endif
                        </div>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" class="text-center py-12">
                        <div class="flex flex-col items-center">
                            <svg class="w-12 h-12 text-secondary-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                            </svg>
                            <p class="text-secondary-500 font-medium">Belum ada permintaan pendaftaran ulang wajah.</p>
                        </div>
                    </td>
                </tr>
            @endforelse
        </x-table>

        @if($requests->hasPages())
            <div class="p-4 border-t border-secondary-200">
                {{ $requests->links() }}
            </div>
        @endif
    </div>

    {{-- Reject Modal --}}
    <div id="rejectModal" class="fixed inset-0 z-50 hidden overflow-y-auto bg-black bg-opacity-50 flex items-center justify-center p-4">
        <div class="bg-white rounded-xl max-w-md w-full p-6 shadow-xl">
            <h3 class="text-lg font-bold text-secondary-900 mb-2">Tolak Permintaan Reset Wajah</h3>
            <p id="rejectModalText" class="text-sm text-secondary-600 mb-4"></p>
            <form id="rejectForm" method="POST">
                @csrf
                <div class="mb-4">
                    <label class="block text-sm font-medium text-secondary-700 mb-1">Catatan / Alasan Penolakan</label>
                    <textarea name="admin_notes" rows="3" class="input w-full" placeholder="Masukkan alasan penolakan..."></textarea>
                </div>
                <div class="flex justify-end gap-2">
                    <button type="button" onclick="closeRejectModal()" class="btn btn-outline">Batal</button>
                    <button type="submit" class="btn btn-danger">Tolak Permintaan</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function openRejectModal(id, employeeName) {
            document.getElementById('rejectModalText').innerText = 'Apakah Anda yakin ingin menolak permohonan reset wajah untuk ' + employeeName + '?';
            document.getElementById('rejectForm').action = '/face-recognition/requests/' + id + '/reject';
            document.getElementById('rejectModal').classList.remove('hidden');
        }
        function closeRejectModal() {
            document.getElementById('rejectModal').classList.add('hidden');
        }
    </script>
@endsection
