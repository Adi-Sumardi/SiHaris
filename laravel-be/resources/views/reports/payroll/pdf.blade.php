<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Penggajian Karyawan</title>
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
        .summary-row {
            background-color: #f1f5f9 !important;
            font-weight: bold;
            color: #0f172a;
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
    @php
        $months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
        $monthName = !empty($month) && isset($months[$month - 1]) ? $months[$month - 1] : 'Semua Bulan';
    @endphp

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
                    <div class="report-title">LAPORAN REKAP PENGGAJIAN</div>
                    <div class="report-meta">
                        Periode: {{ $monthName }} {{ $year }} | Dicetak: {{ now()->translatedFormat('d F Y, H:i') }} WIB
                    </div>
                </td>
            </tr>
        </table>
    </div>

    {{-- Summary Bar --}}
    @php
        $sumGross = $payrollItems->sum('gross_salary');
        $sumDeductions = $payrollItems->sum('total_deductions');
        $sumTax = $payrollItems->sum('tax_amount');
        $sumNet = $payrollItems->sum('net_salary');
    @endphp
    <div class="summary-bar">
        <table>
            <tr>
                <td style="width: 18%;">Total: <strong>{{ $payrollItems->count() }} orang</strong></td>
                <td style="width: 22%;">Gaji Kotor: <strong>Rp {{ number_format($sumGross, 0, ',', '.') }}</strong></td>
                <td style="width: 20%;">Potongan: <strong>Rp {{ number_format($sumDeductions, 0, ',', '.') }}</strong></td>
                <td style="width: 18%;">PPh 21: <strong>Rp {{ number_format($sumTax, 0, ',', '.') }}</strong></td>
                <td style="width: 22%;">Gaji Bersih: <strong>Rp {{ number_format($sumNet, 0, ',', '.') }}</strong></td>
            </tr>
        </table>
    </div>

    {{-- Table Data --}}
    <table class="data-table">
        <thead>
            <tr>
                <th class="text-center" style="width: 4%;">No</th>
                <th style="width: 9%;">ID</th>
                <th style="width: 17%;">Nama Karyawan</th>
                <th style="width: 12%;">Departemen</th>
                <th style="width: 11%;">Jabatan</th>
                <th class="text-right" style="width: 10%;">Gaji Pokok</th>
                <th class="text-right" style="width: 10%;">Gaji Kotor</th>
                <th class="text-right" style="width: 9%;">Potongan</th>
                <th class="text-right" style="width: 8%;">PPh 21</th>
                <th class="text-right" style="width: 10%;">Gaji Bersih</th>
            </tr>
        </thead>
        <tbody>
            @forelse($payrollItems as $index => $item)
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td style="font-family: monospace; font-size: 7pt;">{{ $item->employee?->employee_id ?? '-' }}</td>
                    <td><strong>{{ $item->employee?->full_name ?? '-' }}</strong></td>
                    <td>{{ $item->employee?->department?->name ?? '-' }}</td>
                    <td>{{ $item->employee?->position?->name ?? '-' }}</td>
                    <td class="text-right" style="font-size: 7pt;">Rp {{ number_format($item->basic_salary, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 7pt;">Rp {{ number_format($item->gross_salary, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 7pt; color: #dc2626;">Rp {{ number_format($item->total_deductions, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 7pt; color: #d97706;">Rp {{ number_format($item->tax_amount, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 7pt; font-weight: bold; color: #166534;">Rp {{ number_format($item->net_salary, 0, ',', '.') }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding: 15px; color: #94a3b8;">
                        Tidak ada data penggajian untuk periode yang dipilih.
                    </td>
                </tr>
            @endforelse
        </tbody>
        @if($payrollItems->count() > 0)
            <tfoot>
                <tr class="summary-row">
                    <td colspan="5" class="text-right">TOTAL</td>
                    <td class="text-right" style="font-size: 7pt;">Rp {{ number_format($payrollItems->sum('basic_salary'), 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 7pt;">Rp {{ number_format($sumGross, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 7pt; color: #dc2626;">Rp {{ number_format($sumDeductions, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 7pt; color: #d97706;">Rp {{ number_format($sumTax, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 7pt; font-weight: bold; color: #166534;">Rp {{ number_format($sumNet, 0, ',', '.') }}</td>
                </tr>
            </tfoot>
        @endif
    </table>

    {{-- Footer --}}
    <div class="footer">
        <table>
            <tr>
                <td style="width: 50%; text-align: left;">Dokumen resmi SiHaris HRMS - {{ $company->name ?? 'Perusahaan' }}</td>
                <td style="width: 50%; text-align: right;">Total Data: {{ $payrollItems->count() }} Karyawan</td>
            </tr>
        </table>
    </div>
</body>
</html>
