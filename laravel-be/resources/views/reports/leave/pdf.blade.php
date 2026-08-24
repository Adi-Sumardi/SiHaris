<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Cuti Karyawan</title>
    <style>
        @page {
            size: a4 landscape;
            margin: 10mm 12mm 10mm 12mm;
        }
        body {
            font-family: 'DejaVu Sans', Helvetica, Arial, sans-serif;
            font-size: 8pt;
            line-height: 1.3;
            color: #1e293b;
            margin: 0;
            padding: 0;
        }
        table.header-table {
            width: 100%;
            border-collapse: collapse;
            border-bottom: 2px solid #0284c7;
            margin-bottom: 8px;
        }
        table.header-table td {
            border: none;
            padding-bottom: 6px;
            vertical-align: middle;
        }
        .company-title {
            font-size: 13pt;
            font-weight: bold;
            color: #0369a1;
            text-transform: uppercase;
        }
        .company-sub {
            font-size: 7pt;
            color: #64748b;
            margin-top: 2px;
        }
        .report-title-box {
            text-align: right;
        }
        .report-title {
            font-size: 11pt;
            font-weight: bold;
            color: #0f172a;
        }
        .report-meta {
            font-size: 7pt;
            color: #64748b;
            margin-top: 2px;
        }
        table.summary-table {
            width: 100%;
            border-collapse: collapse;
            background-color: #f0f9ff;
            border: 1px solid #bae6fd;
            margin-bottom: 8px;
        }
        table.summary-table td {
            border: none;
            padding: 4px 6px;
            font-size: 7.5pt;
            color: #0369a1;
        }
        table.summary-table td strong {
            color: #0c4a6e;
        }
        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 10px;
        }
        table.data-table th, table.data-table td {
            border: 1px solid #cbd5e1;
            padding: 4px 4px;
            text-align: left;
            vertical-align: middle;
            font-size: 7.5pt;
        }
        table.data-table th {
            background-color: #f1f5f9;
            color: #1e293b;
            font-size: 7pt;
            font-weight: bold;
            text-transform: uppercase;
        }
        table.data-table tr:nth-child(even) {
            background-color: #f8fafc;
        }
        .text-center { text-align: center !important; }
        .text-right { text-align: right !important; }
        .badge {
            display: inline-block;
            padding: 1px 4px;
            border-radius: 2px;
            font-size: 6.5pt;
            font-weight: bold;
            text-transform: uppercase;
            text-align: center;
        }
        .badge-success { background-color: #dcfce7; color: #166534; border: 1px solid #bbf7d0; }
        .badge-warning { background-color: #fef3c7; color: #92400e; border: 1px solid #fde68a; }
        .badge-danger { background-color: #fee2e2; color: #991b1b; border: 1px solid #fecaca; }
        .badge-secondary { background-color: #f1f5f9; color: #475569; border: 1px solid #cbd5e1; }
        table.footer-table {
            width: 100%;
            border-collapse: collapse;
            border-top: 1px solid #e2e8f0;
            margin-top: 8px;
        }
        table.footer-table td {
            border: none;
            padding-top: 4px;
            font-size: 7pt;
            color: #94a3b8;
        }
    </style>
</head>
<body>
    {{-- Header --}}
    <table class="header-table">
        <tr>
            <td style="width: 55%;">
                <div class="company-title">{{ $company->name ?? 'SiHaris HRMS' }}</div>
                <div class="company-sub">
                    {{ $company->address ?? 'Sistem Informasi Manajemen SDM & Kepegawaian' }}
                    @if(!empty($company->email)) | {{ $company->email }} @endif
                </div>
            </td>
            <td style="width: 45%;" class="report-title-box">
                <div class="report-title">LAPORAN PENGAJUAN & PENGGUNAAN CUTI</div>
                <div class="report-meta">
                    Periode: {{ \Carbon\Carbon::parse($startDate)->format('d/m/Y') }} - {{ \Carbon\Carbon::parse($endDate)->format('d/m/Y') }} | Dicetak: {{ now()->translatedFormat('d F Y, H:i') }} WIB
                </div>
            </td>
        </tr>
    </table>

    {{-- Summary Bar --}}
    <table class="summary-table">
        <tr>
            <td style="width: 20%;">Total Pengajuan: <strong>{{ $leaveRequests->count() }}</strong></td>
            <td style="width: 18%;">Disetujui: <strong>{{ $leaveRequests->where('status', 'approved')->count() }}</strong></td>
            <td style="width: 18%;">Menunggu: <strong>{{ $leaveRequests->where('status', 'pending')->count() }}</strong></td>
            <td style="width: 18%;">Ditolak: <strong>{{ $leaveRequests->where('status', 'rejected')->count() }}</strong></td>
            <td style="width: 26%;">Total Hari Cuti: <strong>{{ $leaveRequests->where('status', 'approved')->sum('total_days') }} Hari</strong></td>
        </tr>
    </table>

    {{-- Table Data --}}
    <table class="data-table">
        <thead>
            <tr>
                <th class="text-center" style="width: 4%;">No</th>
                <th style="width: 9%;">ID</th>
                <th style="width: 18%;">Nama Karyawan</th>
                <th style="width: 14%;">Departemen</th>
                <th style="width: 12%;">Jenis Cuti</th>
                <th class="text-center" style="width: 8%;">Mulai</th>
                <th class="text-center" style="width: 8%;">Selesai</th>
                <th class="text-center" style="width: 5%;">Hari</th>
                <th class="text-center" style="width: 8%;">Status</th>
                <th style="width: 14%;">Keterangan / Alasan</th>
            </tr>
        </thead>
        <tbody>
            @forelse($leaveRequests as $index => $leave)
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td style="font-family: monospace; font-size: 7pt;">{{ $leave->employee?->employee_id ?? '-' }}</td>
                    <td><strong>{{ $leave->employee?->full_name ?? '-' }}</strong></td>
                    <td>{{ $leave->employee?->department?->name ?? '-' }}</td>
                    <td>{{ $leave->leaveType?->name ?? '-' }}</td>
                    <td class="text-center" style="font-size: 7pt;">{{ $leave->start_date->format('d/m/Y') }}</td>
                    <td class="text-center" style="font-size: 7pt;">{{ $leave->end_date->format('d/m/Y') }}</td>
                    <td class="text-center font-bold">{{ $leave->total_days }}</td>
                    <td class="text-center">
                        @switch($leave->status)
                            @case('approved')
                                <span class="badge badge-success">Disetujui</span>
                                @break
                            @case('pending')
                                <span class="badge badge-warning">Menunggu</span>
                                @break
                            @case('rejected')
                                <span class="badge badge-danger">Ditolak</span>
                                @break
                            @case('cancelled')
                                <span class="badge badge-secondary">Dibatalkan</span>
                                @break
                            @default
                                <span class="badge badge-secondary">{{ ucfirst($leave->status) }}</span>
                        @endswitch
                    </td>
                    <td style="color: #475569; font-size: 7pt;">{{ Str::limit($leave->reason ?? '-', 50) }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding: 15px; color: #94a3b8;">
                        Tidak ada data pengajuan cuti yang sesuai dengan filter.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    {{-- Footer --}}
    <table class="footer-table">
        <tr>
            <td style="width: 50%; text-align: left;">Dokumen resmi SiHaris HRMS - {{ $company->name ?? 'Perusahaan' }}</td>
            <td style="width: 50%; text-align: right;">Total Data: {{ $leaveRequests->count() }} Pengajuan</td>
        </tr>
    </table>
</body>
</html>
