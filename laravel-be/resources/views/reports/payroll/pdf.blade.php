<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Laporan Penggajian Karyawan</title>
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
        .summary-row {
            background-color: #f1f5f9 !important;
            font-weight: bold;
            color: #0f172a;
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
    @php
        $months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
        $monthName = !empty($month) && isset($months[$month - 1]) ? $months[$month - 1] : 'Semua Bulan';
    @endphp

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
                <td>Total Karyawan: <strong>{{ $payrollItems->count() }} orang</strong></td>
                <td>Gaji Kotor: <strong>Rp {{ number_format($sumGross, 0, ',', '.') }}</strong></td>
                <td>Potongan: <strong>Rp {{ number_format($sumDeductions, 0, ',', '.') }}</strong></td>
                <td>PPh 21: <strong>Rp {{ number_format($sumTax, 0, ',', '.') }}</strong></td>
                <td>Gaji Bersih: <strong>Rp {{ number_format($sumNet, 0, ',', '.') }}</strong></td>
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
                <th style="width: 100px;">Jabatan</th>
                <th class="text-right" style="width: 80px;">Gaji Pokok</th>
                <th class="text-right" style="width: 80px;">Gaji Kotor</th>
                <th class="text-right" style="width: 80px;">Potongan</th>
                <th class="text-right" style="width: 70px;">PPh 21</th>
                <th class="text-right" style="width: 85px;">Gaji Bersih</th>
            </tr>
        </thead>
        <tbody>
            @forelse($payrollItems as $index => $item)
                <tr>
                    <td class="text-center">{{ $index + 1 }}</td>
                    <td style="font-family: monospace; font-size: 8px;">{{ $item->employee?->employee_id ?? '-' }}</td>
                    <td><strong>{{ $item->employee?->full_name ?? '-' }}</strong></td>
                    <td>{{ $item->employee?->department?->name ?? '-' }}</td>
                    <td>{{ $item->employee?->position?->name ?? '-' }}</td>
                    <td class="text-right" style="font-size: 8px;">Rp {{ number_format($item->basic_salary, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 8px;">Rp {{ number_format($item->gross_salary, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 8px; color: #dc2626;">Rp {{ number_format($item->total_deductions, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 8px; color: #d97706;">Rp {{ number_format($item->tax_amount, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 8px; font-weight: bold; color: #166534;">Rp {{ number_format($item->net_salary, 0, ',', '.') }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding: 20px; color: #94a3b8;">
                        Tidak ada data penggajian untuk periode yang dipilih.
                    </td>
                </tr>
            @endforelse
        </tbody>
        @if($payrollItems->count() > 0)
            <tfoot>
                <tr class="summary-row">
                    <td colspan="5" class="text-right">TOTAL</td>
                    <td class="text-right" style="font-size: 8px;">Rp {{ number_format($payrollItems->sum('basic_salary'), 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 8px;">Rp {{ number_format($sumGross, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 8px; color: #dc2626;">Rp {{ number_format($sumDeductions, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 8px; color: #d97706;">Rp {{ number_format($sumTax, 0, ',', '.') }}</td>
                    <td class="text-right" style="font-size: 8px; font-weight: bold; color: #166534;">Rp {{ number_format($sumNet, 0, ',', '.') }}</td>
                </tr>
            </tfoot>
        @endif
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
