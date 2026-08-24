<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Kehadiran Karyawan</title>
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
                    <div class="report-title">LAPORAN KEHADIRAN KARYAWAN</div>
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
                <td>Total Record: <strong>{{ $attendances->count() }}</strong></td>
                <td>Tepat Waktu: <strong>{{ $attendances->where('clock_in_status', 'on_time')->count() }}</strong></td>
                <td>Terlambat: <strong>{{ $attendances->whereIn('clock_in_status', ['late', 'very_late'])->count() }}</strong></td>
                <td>Total Terlambat: <strong>{{ floor($attendances->sum('late_minutes') / 60) }}j {{ $attendances->sum('late_minutes') % 60 }}m</strong></td>
                <td>Total Lembur: <strong>{{ floor($attendances->sum('overtime_minutes') / 60) }}j {{ $attendances->sum('overtime_minutes') % 60 }}m</strong></td>
            </tr>
        </table>
    </div>

    {{-- Table Data --}}
    <table class="data-table">
        <thead>
            <tr>
                <th class="text-center" style="width: 25px;">No</th>
                <th class="text-center" style="width: 65px;">Tanggal</th>
                <th style="width: 70px;">ID Karyawan</th>
                <th style="width: 140px;">Nama Karyawan</th>
                <th style="width: 110px;">Departemen</th>
                <th class="text-center" style="width: 55px;">Masuk</th>
                <th class="text-center" style="width: 55px;">Pulang</th>
                <th class="text-center" style="width: 80px;">Status</th>
                <th class="text-right" style="width: 65px;">Terlambat</th>
                <th class="text-right" style="width: 60px;">Lembur</th>
            </tr>
        </thead>
        <tbody>
            @forelse($attendances as $index => $attendance)
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td class="text-center" style="font-size: 8px;">{{ $attendance->date->format('d/m/Y') }}</td>
                    <td style="font-family: monospace; font-size: 8px;">{{ $attendance->employee?->employee_id ?? '-' }}</td>
                    <td><strong>{{ $attendance->employee?->full_name ?? '-' }}</strong></td>
                    <td>{{ $attendance->employee?->department?->name ?? '-' }}</td>
                    <td class="text-center" style="font-family: monospace; font-size: 8px;">{{ $attendance->formatted_clock_in ?? '-' }}</td>
                    <td class="text-center" style="font-family: monospace; font-size: 8px;">{{ $attendance->formatted_clock_out ?? '-' }}</td>
                    <td class="text-center">
                        @switch($attendance->clock_in_status)
                            @case('on_time')
                                <span class="badge badge-success">Tepat Waktu</span>
                                @break
                            @case('late')
                                <span class="badge badge-warning">Terlambat</span>
                                @break
                            @case('very_late')
                                <span class="badge badge-danger">Sgt Terlambat</span>
                                @break
                            @default
                                <span class="badge badge-secondary">{{ ucfirst($attendance->status ?? '-') }}</span>
                        @endswitch
                    </td>
                    <td class="text-right" style="font-size: 8px;">
                        @if($attendance->late_minutes > 0)
                            <strong style="color: #d97706;">{{ $attendance->late_minutes }} m</strong>
                        @else
                            <span style="color: #94a3b8;">-</span>
                        @endif
                    </td>
                    <td class="text-right" style="font-size: 8px;">
                        @if($attendance->overtime_minutes > 0)
                            <strong style="color: #0284c7;">{{ $attendance->overtime_minutes }} m</strong>
                        @else
                            <span style="color: #94a3b8;">-</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding: 20px; color: #94a3b8;">
                        Tidak ada data kehadiran yang sesuai dengan filter.
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
