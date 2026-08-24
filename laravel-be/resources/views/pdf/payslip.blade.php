<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Slip Gaji - {{ $employee->full_name }} - {{ $payroll->period_label }}</title>
    <style>
        @page {
            size: a4 portrait;
            margin: 12mm 15mm 12mm 15mm;
        }
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'DejaVu Sans', Arial, sans-serif;
            font-size: 8.5pt;
            line-height: 1.3;
            color: #1e293b;
            background: #fff;
        }
        table.layout-table {
            width: 100%;
            border-collapse: collapse;
        }
        table.layout-table td {
            border: none;
            padding: 0;
            vertical-align: top;
        }

        /* Header */
        table.header-table {
            width: 100%;
            border-collapse: collapse;
            border-bottom: 2px solid #0284c7;
            padding-bottom: 8px;
            margin-bottom: 12px;
        }
        table.header-table td {
            border: none;
            padding-bottom: 6px;
            vertical-align: middle;
        }
        .company-name {
            font-size: 14pt;
            font-weight: bold;
            color: #0369a1;
            text-transform: uppercase;
        }
        .company-address {
            font-size: 7pt;
            color: #64748b;
            margin-top: 2px;
            line-height: 1.3;
        }
        .slip-title {
            font-size: 13pt;
            font-weight: bold;
            color: #0284c7;
        }
        .slip-period {
            font-size: 9pt;
            font-weight: bold;
            color: #0f172a;
            margin-top: 1px;
        }
        .slip-date {
            font-size: 6.5pt;
            color: #64748b;
            margin-top: 2px;
        }

        /* Employee Info */
        table.employee-card {
            width: 100%;
            border-collapse: collapse;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            margin-bottom: 12px;
        }
        table.employee-card td {
            border: none;
            padding: 4px 8px;
            font-size: 7.5pt;
            vertical-align: middle;
        }
        .info-label {
            color: #64748b;
            font-size: 7pt;
            width: 15%;
        }
        .info-val {
            color: #0f172a;
            font-weight: 600;
            width: 35%;
        }

        /* Tables */
        .section-title {
            font-size: 8pt;
            font-weight: bold;
            color: #0369a1;
            padding: 3px 6px;
            background: #f0f9ff;
            border-left: 3px solid #0284c7;
            margin-bottom: 4px;
            text-transform: uppercase;
        }
        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 10px;
        }
        table.data-table th, table.data-table td {
            padding: 4px 6px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
            font-size: 7.5pt;
        }
        table.data-table th {
            background: #f8fafc;
            font-size: 7pt;
            font-weight: 600;
            color: #64748b;
            text-transform: uppercase;
        }
        .amount {
            text-align: right;
            font-family: 'DejaVu Sans Mono', monospace;
        }
        .earning { color: #166534; }
        .deduction { color: #dc2626; }
        .subtotal-row td {
            background: #f8fafc;
            font-weight: bold;
            border-top: 1.5px solid #cbd5e1;
        }

        /* Summary Banner */
        table.summary-card {
            width: 100%;
            border-collapse: collapse;
            background-color: #0369a1;
            color: #ffffff;
            margin-bottom: 14px;
        }
        table.summary-card td {
            border: none;
            padding: 8px 6px;
            text-align: center;
            vertical-align: middle;
        }
        table.summary-card td.divider {
            border-left: 1px solid rgba(255,255,255,0.25);
            border-right: 1px solid rgba(255,255,255,0.25);
        }
        .summary-label {
            font-size: 6.5pt;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #bae6fd;
            margin-bottom: 2px;
        }
        .summary-val {
            font-size: 10pt;
            font-weight: bold;
            color: #ffffff;
        }
        .summary-val.large {
            font-size: 13pt;
            color: #ffffff;
        }

        /* Signatures */
        table.signature-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 10px;
        }
        table.signature-table td {
            border: none;
            width: 50%;
            text-align: center;
            vertical-align: top;
            padding: 0 20px;
        }
        .signature-line {
            border-bottom: 1px solid #334155;
            width: 140px;
            margin: 35px auto 4px;
        }
        .signature-name {
            font-size: 7.5pt;
            font-weight: bold;
            color: #0f172a;
        }
        .signature-title {
            font-size: 6.5pt;
            color: #64748b;
        }

        /* Notes & Footer */
        .notes {
            padding: 5px 8px;
            background: #fffbeb;
            border: 1px solid #fde68a;
            font-size: 6.5pt;
            color: #92400e;
            margin-bottom: 8px;
        }
        .confidential {
            text-align: center;
            font-size: 6pt;
            color: #94a3b8;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
    </style>
</head>
<body>
    @php
        $totalGross = $payslip->gross_salary ?? $payslip->total_earnings ?? ($payslip->basic_salary + collect($earnings)->sum('amount'));
        $totalDeductions = $payslip->total_deductions ?? collect($deductions)->sum('amount');
        $netSalary = $payslip->net_salary ?? ($totalGross - $totalDeductions);
    @endphp

    <!-- Header -->
    <table class="header-table">
        <tr>
            <td style="width: 60%;">
                <div class="company-name">{{ $company->name ?? 'SiHaris HRMS' }}</div>
                <div class="company-address">
                    {{ $company->address ?? 'Sistem Informasi Manajemen SDM & Kepegawaian' }}<br>
                    @if($company->phone)Telp: {{ $company->phone }}@endif
                    @if($company->email) | Email: {{ $company->email }}@endif
                </div>
            </td>
            <td style="width: 40%; text-align: right;">
                <div class="slip-title">SLIP GAJI</div>
                <div class="slip-period">{{ $payroll->period_label }}</div>
                <div class="slip-date">Tgl Cetak: {{ now()->translatedFormat('d F Y, H:i') }} WIB</div>
            </td>
        </tr>
    </table>

    <!-- Employee Info Card -->
    <table class="employee-card">
        <tr>
            <td class="info-label">Nama Pegawai</td>
            <td class="info-val">: {{ $employee->full_name }}</td>
            <td class="info-label">Jabatan</td>
            <td class="info-val">: {{ $employee->position?->name ?? '-' }}</td>
        </tr>
        <tr>
            <td class="info-label">ID / NIK</td>
            <td class="info-val">: {{ $employee->employee_id }} @if($employee->nik) / {{ $employee->nik }} @endif</td>
            <td class="info-label">Status Kerja</td>
            <td class="info-val">: {{ ucfirst($employee->employment_status ?? 'Permanent') }} @if($employee->employment_type) ({{ $employee->employment_type }}) @endif</td>
        </tr>
        <tr>
            <td class="info-label">Departemen</td>
            <td class="info-val">: {{ $employee->department?->name ?? '-' }}</td>
            <td class="info-label">Tgl Bayar</td>
            <td class="info-val">: {{ $payroll->payment_date?->format('d/m/Y') ?? now()->format('d/m/Y') }}</td>
        </tr>
    </table>

    <!-- Two-column Earnings and Deductions Table -->
    <table class="layout-table" style="margin-bottom: 8px;">
        <tr>
            <!-- Earnings (Left Column) -->
            <td style="width: 49%; vertical-align: top; padding-right: 6px;">
                <div class="section-title">A. Penerimaan (Earnings)</div>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Komponen</th>
                            <th class="amount" style="width: 45%;">Jumlah</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Gaji Pokok</td>
                            <td class="amount earning">Rp {{ number_format($payslip->basic_salary, 0, ',', '.') }}</td>
                        </tr>
                        @foreach($earnings as $item)
                        <tr>
                            <td>{{ $item['name'] }}</td>
                            <td class="amount earning">Rp {{ number_format($item['amount'], 0, ',', '.') }}</td>
                        </tr>
                        @endforeach
                        <tr class="subtotal-row">
                            <td><strong>Total Penerimaan (A)</strong></td>
                            <td class="amount earning"><strong>Rp {{ number_format($totalGross, 0, ',', '.') }}</strong></td>
                        </tr>
                    </tbody>
                </table>
            </td>

            <!-- Deductions (Right Column) -->
            <td style="width: 49%; vertical-align: top; padding-left: 6px;">
                <div class="section-title">B. Potongan (Deductions)</div>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Komponen</th>
                            <th class="amount" style="width: 45%;">Jumlah</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($deductions as $item)
                        <tr>
                            <td>{{ $item['name'] }}</td>
                            <td class="amount deduction">Rp {{ number_format($item['amount'], 0, ',', '.') }}</td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="2" style="text-align: center; color: #94a3b8; font-style: italic;">Tidak ada potongan</td>
                        </tr>
                        @endforelse
                        <tr class="subtotal-row">
                            <td><strong>Total Potongan (B)</strong></td>
                            <td class="amount deduction"><strong>Rp {{ number_format($totalDeductions, 0, ',', '.') }}</strong></td>
                        </tr>
                    </tbody>
                </table>
            </td>
        </tr>
    </table>

    <!-- Summary Banner -->
    <table class="summary-card">
        <tr>
            <td style="width: 32%;">
                <div class="summary-label">Total Penerimaan (A)</div>
                <div class="summary-val">Rp {{ number_format($totalGross, 0, ',', '.') }}</div>
            </td>
            <td style="width: 36%;" class="divider">
                <div class="summary-label">Gaji Bersih (Take Home Pay = A - B)</div>
                <div class="summary-val large">Rp {{ number_format($netSalary, 0, ',', '.') }}</div>
            </td>
            <td style="width: 32%;">
                <div class="summary-label">Total Potongan (B)</div>
                <div class="summary-val">Rp {{ number_format($totalDeductions, 0, ',', '.') }}</div>
            </td>
        </tr>
    </table>

    <!-- Signatures -->
    <table class="signature-table">
        <tr>
            <td>
                <div class="signature-title">Mengetahui,</div>
                <div class="signature-line"></div>
                <div class="signature-name">HRD / Finance Manager</div>
                <div class="signature-title">{{ $company->name ?? 'Perusahaan' }}</div>
            </td>
            <td>
                <div class="signature-title">Penerima,</div>
                <div class="signature-line"></div>
                <div class="signature-name">{{ $employee->full_name }}</div>
                <div class="signature-title">Karyawan</div>
            </td>
        </tr>
    </table>

    <!-- Notes & Disclaimer -->
    <div class="notes">
        <strong>Catatan:</strong> Slip gaji ini diterbitkan secara elektronik oleh sistem SiHaris HRMS dan sah tanpa tanda tangan basah.
    </div>

    <!-- Confidential -->
    <div class="confidential">
        DOKUMEN INI BERSIFAT RAHASIA (CONFIDENTIAL) - {{ $company->name ?? 'SiHaris' }} - {{ now()->format('Y') }}
    </div>
</body>
</html>
