<?php

namespace App\Exports\Templates;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class EmployeeSalaryTemplateExport implements FromArray, ShouldAutoSize, WithHeadings, WithStyles
{
    public function headings(): array
    {
        return [
            'ID Karyawan',
            'Gaji Pokok',
            'Tanggal Berlaku',
            'Tanggal Berakhir',
            'Metode Pembayaran',
            'Nama Bank',
            'Nomor Rekening',
            'Nama Rekening',
            'Aktif',
            'Catatan',
        ];
    }

    public function array(): array
    {
        return [
            [
                'EMP001',
                10000000,
                '2026-01-01',
                '',
                'Transfer',
                'BCA',
                '1234567890',
                'John Doe',
                'Ya',
                'Gaji pokok standar',
            ],
            [
                'EMP002',
                8500000,
                '2026-01-01',
                '',
                'Transfer',
                'Mandiri',
                '0987654321',
                'Jane Smith',
                'Ya',
                'Penyesuaian gaji baru',
            ],
            [
                'EMP003',
                5000000,
                '2026-01-01',
                '',
                'Tunai',
                '',
                '',
                '',
                'Ya',
                'Pembayaran tunai',
            ],
        ];
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => [
                'font' => [
                    'color' => ['rgb' => 'FFFFFF'],
                    'bold' => true,
                ],
                'fill' => [
                    'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                    'startColor' => ['rgb' => '4F46E5'],
                ],
            ],
        ];
    }
}
