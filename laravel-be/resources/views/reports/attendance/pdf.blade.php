<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Kehadiran Karyawan</title>
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
            <td style="width: 52%;">
                <div class="company-title">{{ $company->name ?? 'SiHaris HRMS' }}</div>
                <div class="company-sub">
                    {{ $company->address ?? 'Sistem Informasi Manajemen SDM & Kepegawaian' }}
                    @if(!empty($company->email)) | {{ $company->email }} @endif
                </div>
            </td>
            <td style="width: 48%;" class="report-title-box">
                <div class="report-title">LAPORAN KEHADIRAN KARYAWAN</div>
                <div class="report-meta">
                    Periode: {{ \Carbon\Carbon::parse($startDate)->format('d/m/Y') }} - {{ \Carbon\Carbon::parse($endDate)->format('d/m/Y') }} | Dicetak: {{ now()->translatedFormat('d F Y, H:i') }} WIB
                </div>
            </td>
        </tr>
    </table>

    {{-- Summary Bar --}}
    <table class="summary-table">
        <tr>
            <td style="width: 18%;">Total Record: <strong>{{ $attendances->count() }}</strong></td>
            <td style="width: 18%;">Tepat Waktu: <strong>{{ $attendances->where('clock_in_status', 'on_time')->count() }}</strong></td>
            <td style="width: 18%;">Terlambat: <strong>{{ $attendances->whereIn('clock_in_status', ['late', 'very_late'])->count() }}</strong></td>
            <td style="width: 23%;">Total Terlambat: <strong>{{ floor($attendances->sum('late_minutes') / 60) }}j {{ $attendances->sum('late_minutes') % 60 }}m</strong></td>
            <td style="width: 23%;">Total Lembur: <strong>{{ floor($attendances->sum('overtime_minutes') / 60) }}j {{ $attendances->sum('overtime_minutes') % 60 }}m</strong></td>
        </tr>
    </table>

    {{-- Table Data --}}
    <table class="data-table">
        <thead>
            <tr>
                <th class="text-center" style="width: 4%;">No</th>
                <th class="text-center" style="width: 9%;">Tanggal</th>
                <th style="width: 10%;">ID Karyawan</th>
                <th style="width: 20%;">Nama Karyawan</th>
                <th style="width: 15%;">Departemen</th>
                <th class="text-center" style="width: 8%;">Masuk</th>
                <th class="text-center" style="width: 8%;">Pulang</th>
                <th class="text-center" style="width: 12%;">Status</th>
                <th class="text-right" style="width: 7%;">Terlambat</th>
                <th class="text-right" style="width: 7%;">Lembur</th>
            </tr>
        </thead>
        <tbody>
            @forelse($attendances as $index => $attendance)
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td class="text-center" style="font-size: 7pt;">{{ $attendance->date->format('d/m/Y') }}</td>
                    <td style="font-family: monospace; font-size: 7pt;">{{ $attendance->employee?->employee_id ?? '-' }}</td>
                    <td><strong>{{ $attendance->employee?->full_name ?? '-' }}</strong></td>
                    <td>{{ $attendance->employee?->department?->name ?? '-' }}</td>
                    <td class="text-center" style="font-family: monospace; font-size: 7pt;">{{ $attendance->formatted_clock_in ?? '-' }}</td>
                    <td class="text-center" style="font-family: monospace; font-size: 7pt;">{{ $attendance->formatted_clock_out ?? '-' }}</td>
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
                    <td class="text-right" style="font-size: 7pt;">
                        @if($attendance->late_minutes > 0)
                            <strong style="color: #d97706;">{{ $attendance->late_minutes }} m</strong>
                        @else
                            <span style="color: #94a3b8;">-</span>
                        @endif
                    </td>
                    <td class="text-right" style="font-size: 7pt;">
                        @if($attendance->overtime_minutes > 0)
                            <strong style="color: #0284c7;">{{ $attendance->overtime_minutes }} m</strong>
                        @else
                            <span style="color: #94a3b8;">-</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding: 15px; color: #94a3b8;">
                        Tidak ada data kehadiran yang sesuai dengan filter.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    {{-- Footer --}}
    <table class="footer-table">
        <tr>
            <td style="width: 50%; text-align: left;">Dokumen resmi SiHaris HRMS - {{ $company->name ?? 'Perusahaan' }}</td>
            <td style="width: 50%; text-align: right;">Total Data: {{ $attendances->count() }} Record</td>
        </tr>
    </table>
</body>
</html>
