<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Data Karyawan</title>
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
        .badge-info {
            background-color: #e0f2fe;
            color: #0369a1;
            border: 1px solid #bae6fd;
        }
        .badge-danger {
            background-color: #fee2e2;
            color: #991b1b;
            border: 1px solid #fecaca;
        }
        .badge-primary {
            background-color: #dbeafe;
            color: #1e40af;
            border: 1px solid #bfdbfe;
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
                    <div class="report-title">LAPORAN DATA KARYAWAN</div>
                    <div class="report-meta">Dicetak: {{ now()->translatedFormat('d F Y, H:i') }} WIB</div>
                </td>
            </tr>
        </table>
    </div>

    {{-- Summary Bar --}}
    <div class="summary-bar">
        <table>
            <tr>
                <td style="width: 18%;">Total: <strong>{{ $employees->count() }} orang</strong></td>
                <td style="width: 12%;">Aktif: <strong>{{ $employees->where('is_active', true)->count() }}</strong></td>
                <td style="width: 14%;">Nonaktif: <strong>{{ $employees->where('is_active', false)->count() }}</strong></td>
                <td style="width: 14%;">Tetap: <strong>{{ $employees->where('employment_status', 'permanent')->count() }}</strong></td>
                <td style="width: 14%;">Kontrak: <strong>{{ $employees->where('employment_status', 'contract')->count() }}</strong></td>
                <td style="width: 16%;">YPI Al Azhar: <strong>{{ $employees->where('employment_type', 'YPI Al Azhar')->count() }}</strong></td>
                <td style="width: 12%;">YAPI: <strong>{{ $employees->where('employment_type', 'YAPI')->count() }}</strong></td>
            </tr>
        </table>
    </div>

    {{-- Table Data --}}
    <table class="data-table">
        <thead>
            <tr>
                <th class="text-center" style="width: 4%;">No</th>
                <th style="width: 9%;">ID</th>
                <th style="width: 18%;">Nama Lengkap</th>
                <th style="width: 17%;">Email</th>
                <th style="width: 12%;">Departemen</th>
                <th style="width: 12%;">Jabatan</th>
                <th class="text-center" style="width: 10%;">Kepegawaian</th>
                <th class="text-center" style="width: 7%;">Status Kerja</th>
                <th class="text-center" style="width: 6%;">Bergabung</th>
                <th class="text-center" style="width: 5%;">Status</th>
            </tr>
        </thead>
        <tbody>
            @forelse($employees as $index => $employee)
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td style="font-family: monospace; font-size: 7pt;">{{ $employee->employee_id }}</td>
                    <td><strong>{{ $employee->full_name }}</strong></td>
                    <td style="color: #475569; font-size: 7pt;">{{ $employee->email ?? '-' }}</td>
                    <td>{{ $employee->department?->name ?? '-' }}</td>
                    <td>{{ $employee->position?->name ?? '-' }}</td>
                    <td class="text-center">
                        @if($employee->employment_type === 'YPI Al Azhar' || $employee->employment_type === 'YPI')
                            <span class="badge badge-primary">YPI Al Azhar</span>
                        @elseif($employee->employment_type === 'YAPI')
                            <span class="badge badge-info">YAPI</span>
                        @elseif($employee->employment_type)
                            <span class="badge badge-secondary">{{ $employee->employment_type }}</span>
                        @else
                            <span style="color: #94a3b8;">-</span>
                        @endif
                    </td>
                    <td class="text-center">
                        @switch($employee->employment_status)
                            @case('permanent')
                                <span class="badge badge-success">Tetap</span>
                                @break
                            @case('contract')
                                <span class="badge badge-warning">Kontrak</span>
                                @break
                            @case('probation')
                                <span class="badge badge-info">Probation</span>
                                @break
                            @case('intern')
                                <span class="badge badge-secondary">Magang</span>
                                @break
                            @default
                                <span class="badge badge-secondary">{{ ucfirst($employee->employment_status ?? '-') }}</span>
                        @endswitch
                    </td>
                    <td class="text-center" style="font-size: 6.5pt;">{{ $employee->hire_date?->format('d/m/Y') ?? '-' }}</td>
                    <td class="text-center">
                        @if($employee->is_active)
                            <span class="badge badge-success">Aktif</span>
                        @else
                            <span class="badge badge-danger">Nonaktif</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding: 15px; color: #94a3b8;">
                        Tidak ada data karyawan yang sesuai dengan filter.
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
                <td style="width: 50%; text-align: right;">Total Data: {{ $employees->count() }} Karyawan</td>
            </tr>
        </table>
    </div>
</body>
</html>
