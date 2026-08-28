<?php

namespace App\Exports\Templates;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class LeaveRequestTemplateExport implements FromArray, ShouldAutoSize, WithHeadings, WithStyles
{
    public function headings(): array
    {
        return [
            'ID Karyawan',
            'Jenis Cuti',
            'Tanggal Mulai',
            'Tanggal Selesai',
            'Jumlah Hari',
            'Setengah Hari',
            'Sesi Setengah Hari',
            'Status',
            'Alasan',
            'Catatan',
        ];
    }

    public function array(): array
    {
        return [
            ['EMP001', 'CT', '2026-01-06', '2026-01-08', '', 'Tidak', '', 'Disetujui', 'Liburan keluarga', ''],
            ['EMP002', 'Cuti Sakit', '2026-01-15', '2026-01-15', '', 'Tidak', '', 'Disetujui', 'Demam', 'Surat dokter terlampir'],
            ['EMP003', 'CT', '2026-02-10', '2026-02-10', '0.5', 'Ya', 'Siang', 'Disetujui', 'Keperluan keluarga', ''],
        ];
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => [
                'fill' => [
                    'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                    'startColor' => ['rgb' => '4F46E5'],
                ],
                'font' => [
                    'color' => ['rgb' => 'FFFFFF'],
                    'bold' => true,
                ],
            ],
        ];
    }
}
