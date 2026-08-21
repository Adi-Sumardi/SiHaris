<?php

namespace App\Http\Controllers;

use App\Models\Holiday;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class HolidayController extends Controller
{
    public function index(Request $request): View
    {
        $companyId = auth()->user()->company_id;
        $currentYear = now()->year;

        $query = Holiday::where('company_id', $companyId);

        // Filter by year
        if ($request->filled('year')) {
            $query->whereYear('date', $request->year);
        } else {
            $query->whereYear('date', $currentYear);
        }

        // Filter by type
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        // Filter by search
        if ($request->filled('search')) {
            $query->where('name', 'like', '%'.$request->search.'%');
        }

        $holidays = $query->orderBy('date')->paginate(15)->withQueryString();

        // Get available years for filter
        $years = Holiday::where('company_id', $companyId)
            ->get()
            ->map(fn ($h) => $h->date->year)
            ->unique()
            ->sortDesc()
            ->values()
            ->toArray();

        // Add current year if not in list
        if (! in_array($currentYear, $years)) {
            array_unshift($years, $currentYear);
        }

        return view('holidays.index', compact('holidays', 'years', 'currentYear'));
    }

    public function create(): View
    {
        return view('holidays.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $companyId = auth()->user()->company_id;

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'date' => [
                'required',
                'date',
                function ($attribute, $value, $fail) use ($companyId) {
                    $exists = Holiday::where('company_id', $companyId)
                        ->whereDate('date', $value)
                        ->exists();
                    if ($exists) {
                        $fail('Tanggal ini sudah terdaftar sebagai hari libur.');
                    }
                },
            ],
            'type' => ['required', 'in:national,company,religious,collective_leave'],
            'description' => ['nullable', 'string', 'max:1000'],
            'is_recurring' => ['nullable', 'boolean'],
        ]);

        Holiday::create([
            'company_id' => $companyId,
            'name' => $validated['name'],
            'date' => $validated['date'],
            'type' => $validated['type'],
            'description' => $validated['description'] ?? null,
            'is_recurring' => $validated['is_recurring'] ?? false,
            'is_active' => true,
            'created_by' => auth()->id(),
        ]);

        return redirect()->route('holidays.index')
            ->with('success', 'Hari libur berhasil ditambahkan.');
    }

    public function edit(Holiday $holiday): View|RedirectResponse
    {
        if ($holiday->company_id !== auth()->user()->company_id) {
            abort(404);
        }

        return view('holidays.edit', compact('holiday'));
    }

    public function update(Request $request, Holiday $holiday): RedirectResponse
    {
        if ($holiday->company_id !== auth()->user()->company_id) {
            abort(404);
        }

        $companyId = auth()->user()->company_id;

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'date' => [
                'required',
                'date',
                function ($attribute, $value, $fail) use ($companyId, $holiday) {
                    $exists = Holiday::where('company_id', $companyId)
                        ->whereDate('date', $value)
                        ->where('id', '!=', $holiday->id)
                        ->exists();
                    if ($exists) {
                        $fail('Tanggal ini sudah terdaftar sebagai hari libur.');
                    }
                },
            ],
            'type' => ['required', 'in:national,company,religious,collective_leave'],
            'description' => ['nullable', 'string', 'max:1000'],
            'is_recurring' => ['nullable', 'boolean'],
        ]);

        $holiday->update([
            'name' => $validated['name'],
            'date' => $validated['date'],
            'type' => $validated['type'],
            'description' => $validated['description'] ?? null,
            'is_recurring' => $validated['is_recurring'] ?? false,
        ]);

        return redirect()->route('holidays.index')
            ->with('success', 'Hari libur berhasil diperbarui.');
    }

    public function destroy(Holiday $holiday): RedirectResponse
    {
        if ($holiday->company_id !== auth()->user()->company_id) {
            abort(404);
        }

        $holiday->delete();

        return redirect()->route('holidays.index')
            ->with('success', 'Hari libur berhasil dihapus.');
    }

    public function calendar(): View
    {
        return view('holidays.calendar');
    }

    public function events(Request $request)
    {
        $companyId = auth()->user()->company_id;
        $year = $request->get('year', now()->year);

        $holidays = Holiday::where('company_id', $companyId)
            ->whereYear('date', $year)
            ->active()
            ->orderBy('date')
            ->get()
            ->map(function ($holiday) {
                return [
                    'id' => $holiday->id,
                    'name' => $holiday->name,
                    'date' => $holiday->date->format('Y-m-d'),
                    'type' => $holiday->type,
                    'type_label' => $holiday->type_label,
                    'type_color' => $holiday->type_color,
                    'description' => $holiday->description,
                ];
            });

        return response()->json($holidays);
    }

    public function generate(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'year' => ['nullable', 'integer', 'min:2020', 'max:2100'],
        ]);

        $companyId = auth()->user()->company_id;
        $year = (int) ($validated['year'] ?? $request->input('year') ?? now()->year);

        $holidays = $this->nationalHolidaysFor($year);

        $created = 0;
        $skipped = 0;

        foreach ($holidays as $holiday) {
            $exists = Holiday::where('company_id', $companyId)
                ->whereDate('date', $holiday['date'])
                ->exists();

            if (! $exists) {
                Holiday::create([
                    'company_id' => $companyId,
                    'name' => $holiday['name'],
                    'date' => $holiday['date'],
                    'type' => $holiday['type'],
                    'is_recurring' => $holiday['recurring'] ?? false,
                    'is_active' => true,
                    'created_by' => auth()->id(),
                ]);
                $created++;
            } else {
                $skipped++;
            }
        }

        $message = "Berhasil menambahkan {$created} hari libur nasional tahun {$year}.";
        if ($skipped > 0) {
            $message .= " {$skipped} tanggal dilewati karena sudah ada.";
        }
        if (! array_key_exists($year, self::LUNAR_HOLIDAYS)) {
            $message .= " Catatan: tanggal libur Islam/Imlek/Hindu/Buddha untuk tahun {$year} belum tersedia — silakan tambahkan manual sesuai SKB Pemerintah.";
        }

        return redirect()->route('holidays.index', ['year' => $year])
            ->with('success', $message);
    }

    /**
     * Tanggal libur lunar/keagamaan (Islam, Imlek, Hindu, Buddha) per tahun,
     * mengacu pada SKB 3 Menteri tentang Hari Libur Nasional & Cuti Bersama.
     * Tanggal ini bergerak tiap tahun sehingga harus dikurasi.
     *
     * @var array<int, array<int, array{name: string, md: string, type: string}>>
     */
    private const LUNAR_HOLIDAYS = [
        2025 => [
            ['name' => 'Isra Mikraj Nabi Muhammad SAW', 'md' => '01-27', 'type' => 'religious'],
            ['name' => 'Tahun Baru Imlek 2576', 'md' => '01-29', 'type' => 'religious'],
            ['name' => 'Hari Suci Nyepi (Tahun Baru Saka 1947)', 'md' => '03-29', 'type' => 'religious'],
            ['name' => 'Idul Fitri 1446 H', 'md' => '03-31', 'type' => 'religious'],
            ['name' => 'Idul Fitri 1446 H (Hari Kedua)', 'md' => '04-01', 'type' => 'religious'],
            ['name' => 'Hari Raya Waisak 2569', 'md' => '05-12', 'type' => 'religious'],
            ['name' => 'Idul Adha 1446 H', 'md' => '06-06', 'type' => 'religious'],
            ['name' => 'Tahun Baru Islam 1447 H', 'md' => '06-27', 'type' => 'religious'],
            ['name' => 'Maulid Nabi Muhammad SAW', 'md' => '09-05', 'type' => 'religious'],
        ],
        2026 => [
            ['name' => 'Isra Mikraj Nabi Muhammad SAW', 'md' => '01-16', 'type' => 'religious'],
            ['name' => 'Tahun Baru Imlek 2577', 'md' => '02-17', 'type' => 'religious'],
            ['name' => 'Hari Suci Nyepi (Tahun Baru Saka 1948)', 'md' => '03-19', 'type' => 'religious'],
            ['name' => 'Idul Fitri 1447 H', 'md' => '03-20', 'type' => 'religious'],
            ['name' => 'Idul Fitri 1447 H (Hari Kedua)', 'md' => '03-21', 'type' => 'religious'],
            ['name' => 'Idul Adha 1447 H', 'md' => '05-27', 'type' => 'religious'],
            ['name' => 'Hari Raya Waisak 2570', 'md' => '05-31', 'type' => 'religious'],
            ['name' => 'Tahun Baru Islam 1448 H', 'md' => '06-16', 'type' => 'religious'],
            ['name' => 'Maulid Nabi Muhammad SAW', 'md' => '08-25', 'type' => 'religious'],
        ],
    ];

    /**
     * Cuti Bersama per tahun sesuai SKB 3 Menteri.
     * 2025: tanggal resmi. 2026: tentatif (menyesuaikan posisi libur) — verifikasi
     * dengan SKB resmi saat sudah terbit, mudah diubah di array ini.
     *
     * @var array<int, array<int, string>>
     */
    private const COLLECTIVE_LEAVE = [
        2025 => [
            '01-28' => 'Cuti Bersama Tahun Baru Imlek',
            '03-28' => 'Cuti Bersama Hari Suci Nyepi',
            '04-02' => 'Cuti Bersama Idul Fitri 1446 H',
            '04-03' => 'Cuti Bersama Idul Fitri 1446 H',
            '04-04' => 'Cuti Bersama Idul Fitri 1446 H',
            '04-07' => 'Cuti Bersama Idul Fitri 1446 H',
            '05-13' => 'Cuti Bersama Hari Raya Waisak',
            '05-30' => 'Cuti Bersama Kenaikan Isa Almasih',
            '06-09' => 'Cuti Bersama Idul Adha 1446 H',
            '12-26' => 'Cuti Bersama Hari Raya Natal',
        ],
        2026 => [
            '03-18' => 'Cuti Bersama Idul Fitri 1447 H',
            '03-23' => 'Cuti Bersama Idul Fitri 1447 H',
            '03-24' => 'Cuti Bersama Idul Fitri 1447 H',
            '03-25' => 'Cuti Bersama Idul Fitri 1447 H',
            '12-24' => 'Cuti Bersama Hari Raya Natal',
        ],
    ];

    /**
     * Susun daftar lengkap hari libur nasional untuk satu tahun:
     * libur tetap (Gregorian) + libur Kristen (dihitung dari Paskah) + libur lunar (kurasi SKB).
     *
     * @return array<int, array{name: string, date: string, type: string, recurring: bool}>
     */
    private function nationalHolidaysFor(int $year): array
    {
        // Libur dengan tanggal tetap setiap tahun.
        $holidays = [
            ['name' => 'Tahun Baru Masehi', 'date' => "{$year}-01-01", 'type' => 'national', 'recurring' => true],
            ['name' => 'Hari Buruh Internasional', 'date' => "{$year}-05-01", 'type' => 'national', 'recurring' => true],
            ['name' => 'Hari Lahir Pancasila', 'date' => "{$year}-06-01", 'type' => 'national', 'recurring' => true],
            ['name' => 'Hari Kemerdekaan RI', 'date' => "{$year}-08-17", 'type' => 'national', 'recurring' => true],
            ['name' => 'Hari Raya Natal', 'date' => "{$year}-12-25", 'type' => 'religious', 'recurring' => true],
        ];

        // Libur Kristen dihitung otomatis dari tanggal Paskah (akurat untuk tahun manapun).
        $easter = $this->easterDate($year);
        $goodFriday = (clone $easter)->modify('-2 days');
        $ascension = (clone $easter)->modify('+39 days');
        $holidays[] = ['name' => 'Wafat Isa Almasih', 'date' => $goodFriday->format('Y-m-d'), 'type' => 'religious', 'recurring' => false];
        $holidays[] = ['name' => 'Kenaikan Isa Almasih', 'date' => $ascension->format('Y-m-d'), 'type' => 'religious', 'recurring' => false];

        // Cuti Bersama (kurasi per tahun sesuai SKB).
        foreach (self::COLLECTIVE_LEAVE[$year] ?? [] as $md => $name) {
            $holidays[] = [
                'name' => $name,
                'date' => "{$year}-{$md}",
                'type' => 'collective_leave',
                'recurring' => false,
            ];
        }

        // Libur lunar/keagamaan (kurasi per tahun sesuai SKB).
        foreach (self::LUNAR_HOLIDAYS[$year] ?? [] as $lunar) {
            $holidays[] = [
                'name' => $lunar['name'],
                'date' => "{$year}-{$lunar['md']}",
                'type' => $lunar['type'],
                'recurring' => false,
            ];
        }

        return $holidays;
    }

    /**
     * Hitung tanggal Minggu Paskah (Western/Gregorian) memakai algoritma Computus (Meeus/Jones/Butcher).
     */
    private function easterDate(int $year): \DateTimeImmutable
    {
        $a = $year % 19;
        $b = intdiv($year, 100);
        $c = $year % 100;
        $d = intdiv($b, 4);
        $e = $b % 4;
        $f = intdiv($b + 8, 25);
        $g = intdiv($b - $f + 1, 3);
        $h = (19 * $a + $b - $d - $g + 15) % 30;
        $i = intdiv($c, 4);
        $k = $c % 4;
        $l = (32 + 2 * $e + 2 * $i - $h - $k) % 7;
        $m = intdiv($a + 11 * $h + 22 * $l, 451);
        $month = intdiv($h + $l - 7 * $m + 114, 31);
        $day = (($h + $l - 7 * $m + 114) % 31) + 1;

        return new \DateTimeImmutable(sprintf('%04d-%02d-%02d', $year, $month, $day));
    }
}
