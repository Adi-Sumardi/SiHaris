<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Cuti Karyawan</title>
    <style>
        @page {
            size: a4 landscape;
            margin: 12mm 15mm 15mm 15mm;
        }
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'DejaVu Sans', Helvetica, Arial, sans-serif;
            font-size: 9px;
            line-height: 1.3;
            color: #1e293b;
        }
        .header {
            border-bottom: 2px solid #0284c7;
            padding-bottom: 10px;
            margin-bottom: 12px;
        }
        .header-table {
            width: 100%;
            border-collapse: collapse;
        }
        .header-table td {
            border: none;
            padding: 0;
            vertical-align: middle;
        }
        .company-title {
            font-size: 16px;
            font-weight: bold;
            color: #0369a1;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .company-sub {
            font-size: 8.5px;
            color: #64748b;
            margin-top: 2px;
        }
        .report-title-box {
            text-align: right;
        }
        .report-title {
            font-size: 14px;
            font-weight: bold;
            color: #0f172a;
            letter-spacing: 0.3px;
        }
        .report-meta {
            font-size: 8px;
            color: #64748b;
            margin-top: 2px;
        }
        .summary-bar {
            background-color: #f0f9ff;
            border: 1px solid #bae6fd;
            border-radius: 4px;
            padding: 6px 10px;
            margin-bottom: 12px;
        }
        .summary-bar table {
            width: 100%;
            border-collapse: collapse;
        }
        .summary-bar td {
            border: none;
            padding: 0 8px;
            font-size: 8.5px;
            color: #0369a1;
        }
        .summary-bar td strong {
            color: #0c4a6e;
        }
        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
        }
        table.data-table th, table.data-table td {
            border: 1px solid #cbd5e1;
            padding: 5px 6px;
            text-align: left;
            vertical-align: middle;
        }
        table.data-table th {
            background-color: #f1f5f9;
            color: #1e293b;
            font-size: 8px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.3px;
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
            padding: 1.5px 5px;
            border-radius: 3px;
            font-size: 7.5px;
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
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            border-top: 1px solid #e2e8f0;
            padding-top: 5px;
            font-size: 7.5px;
            color: #94a3b8;
        }
        .footer table {
            width: 100%;
            border-collapse: collapse;
        }
        .footer td {
            border: none;
            padding: 0;
        }
    </style>
</head>
<body>
    {{-- Header --}}
    <div class="header">
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
    </div>

    {{-- Summary Bar --}}
    <div class="summary-bar">
        <table>
            <tr>
                <td>Total Pengajuan: <strong>{{ $leaveRequests->count() }}</strong></td>
                <td>Disetujui: <strong>{{ $leaveRequests->where('status', 'approved')->count() }}</strong></td>
                <td>Menunggu: <strong>{{ $leaveRequests->where('status', 'pending')->count() }}</strong></td>
                <td>Ditolak: <strong>{{ $leaveRequests->where('status', 'rejected')->count() }}</strong></td>
                <td>Total Hari Cuti: <strong>{{ $leaveRequests->where('status', 'approved')->sum('total_days') }} Hari</strong></td>
            </tr>
        </table>
    </div>

    {{-- Table Data --}}
    <table class="data-table">
        <thead>
            <tr>
                <th class="text-center" style="width: 25px;">No</th>
                <th style="width: 70px;">ID Karyawan</th>
                <th style="width: 140px;">Nama Karyawan</th>
                <th style="width: 110px;">Departemen</th>
                <th style="width: 100px;">Jenis Cuti</th>
                <th class="text-center" style="width: 65px;">Mulai</th>
                <th class="text-center" style="width: 65px;">Selesai</th>
                <th class="text-center" style="width: 45px;">Hari</th>
                <th class="text-center" style="width: 65px;">Status</th>
                <th>Keterangan / Alasan</th>
            </tr>
        </thead>
        <tbody>
            @forelse($leaveRequests as $index => $leave)
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td style="font-family: monospace; font-size: 8px;">{{ $leave->employee?->employee_id ?? '-' }}</td>
                    <td><strong>{{ $leave->employee?->full_name ?? '-' }}</strong></td>
                    <td>{{ $leave->employee?->department?->name ?? '-' }}</td>
                    <td>{{ $leave->leaveType?->name ?? '-' }}</td>
                    <td class="text-center" style="font-size: 8px;">{{ $leave->start_date->format('d/m/Y') }}</td>
                    <td class="text-center" style="font-size: 8px;">{{ $leave->end_date->format('d/m/Y') }}</td>
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
                    <td style="color: #475569; font-size: 8px;">{{ Str::limit($leave->reason ?? '-', 60) }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding: 20px; color: #94a3b8;">
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
                <td style="text-align: left;">Dokumen resmi SiHaris HRMS - {{ $company->name ?? 'Perusahaan' }}</td>
                <td style="text-align: right;">Halaman <script type="text/php">echo $pdf->get_page_number() . ' dari ' . $pdf->get_page_count();</script></td>
            </tr>
        </table>
    </div>
</body>
</html>
