<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Cuti Karyawan</title>
    <style>
        @page {
            size: a4 landscape;
            margin: 10mm 12mm 12mm 12mm;
        }
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'DejaVu Sans', Helvetica, Arial, sans-serif;
            font-size: 8pt;
            line-height: 1.25;
            color: #1e293b;
            width: 100%;
        }
        .header-box {
            border-bottom: 2px solid #0284c7;
            padding-bottom: 8px;
            margin-bottom: 10px;
            width: 100%;
        }
        table.layout-table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
        }
        table.layout-table td {
            border: none;
            padding: 0;
            vertical-align: middle;
        }
        .company-title {
            font-size: 14pt;
            font-weight: bold;
            color: #0369a1;
            text-transform: uppercase;
            letter-spacing: 0.3px;
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
            font-size: 12pt;
            font-weight: bold;
            color: #0f172a;
            letter-spacing: 0.2px;
        }
        .report-meta {
            font-size: 7pt;
            color: #64748b;
            margin-top: 2px;
        }
        .summary-bar {
            background-color: #f0f9ff;
            border: 1px solid #bae6fd;
            padding: 5px 8px;
            margin-bottom: 10px;
            width: 100%;
        }
        .summary-bar table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
        }
        .summary-bar td {
            border: none;
            padding: 0 4px;
            font-size: 7.5pt;
            color: #0369a1;
        }
        .summary-bar td strong {
            color: #0c4a6e;
        }
        table.data-table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            margin-bottom: 12px;
        }
        table.data-table th, table.data-table td {
            border: 1px solid #cbd5e1;
            padding: 4px 4px;
            text-align: left;
            vertical-align: middle;
            word-wrap: break-word;
            overflow: hidden;
        }
        table.data-table th {
            background-color: #f1f5f9;
            color: #1e293b;
            font-size: 7pt;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.2px;
        }
        table.data-table tr:nth-child(even) {
            background-color: #f8fafc;
        }
        .text-center {
            text-align: center !important;
        }
        .text-right {
            text-align: right !important;
        }
        .badge {
            display: inline-block;
            padding: 1px 4px;
            border-radius: 2px;
            font-size: 6.5pt;
            font-weight: bold;
            text-transform: uppercase;
            text-align: center;
        }
        .badge-success {
            background-color: #dcfce7;
            color: #166534;
            border: 1px solid #bbf7d0;
        }
        .badge-warning {
            background-color: #fef3c7;
            color: #92400e;
            border: 1px solid #fde68a;
        }
        .badge-danger {
            background-color: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }
        .badge-secondary {
            background-color: #f1f5f9;
            color: #475569;
            border: 1px solid #cbd5e1;
        }
        .footer {
            margin-top: 10px;
            border-top: 1px solid #e2e8f0;
            padding-top: 4px;
            font-size: 7pt;
            color: #94a3b8;
            width: 100%;
        }
        .footer table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
        }
        .footer td {
            border: none;
            padding: 0;
        }
    </style>
</head>
<body>
    {{-- Header --}}
    <div class="header-box">
        <table class="layout-table">
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
    </div>

    {{-- Summary Bar --}}
    <div class="summary-bar">
        <table>
            <tr>
                <td style="width: 20%;">Total Pengajuan: <strong>{{ $leaveRequests->count() }}</strong></td>
                <td style="width: 18%;">Disetujui: <strong>{{ $leaveRequests->where('status', 'approved')->count() }}</strong></td>
                <td style="width: 18%;">Menunggu: <strong>{{ $leaveRequests->where('status', 'pending')->count() }}</strong></td>
                <td style="width: 18%;">Ditolak: <strong>{{ $leaveRequests->where('status', 'rejected')->count() }}</strong></td>
                <td style="width: 26%;">Total Hari Cuti: <strong>{{ $leaveRequests->where('status', 'approved')->sum('total_days') }} Hari</strong></td>
            </tr>
        </table>
    </div>

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
    <div class="footer">
        <table>
            <tr>
                <td style="width: 50%; text-align: left;">Dokumen resmi SiHaris HRMS - {{ $company->name ?? 'Perusahaan' }}</td>
                <td style="width: 50%; text-align: right;">Total Data: {{ $leaveRequests->count() }} Pengajuan</td>
            </tr>
        </table>
    </div>
</body>
</html>
