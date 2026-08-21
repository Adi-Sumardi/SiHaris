<?php

namespace App\Http\Controllers;

use App\Http\Requests\AttendanceRequest;
use App\Models\Attendance;
use App\Models\Employee;
use App\Models\WorkSchedule;
use App\Services\AttendanceReconciliationService;
use App\Services\GpsValidationService;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class AttendanceController extends Controller
{
    public function __construct(
        protected GpsValidationService $gpsValidationService,
        protected AttendanceReconciliationService $reconciliationService
    ) {}

    public function index(Request $request): View
    {
        $tenant = app('tenant');

        $query = Attendance::with(['company', 'employee', 'workSchedule'])
            ->where('company_id', $tenant->id);

        if ($request->filled('date')) {
            $query->whereDate('date', $request->date);
        }

        if ($request->filled('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('month')) {
            $date = Carbon::parse($request->month);
            $query->forMonth($date->year, $date->month);
        }

        $attendances = $query->orderBy('date', 'desc')
            ->orderBy('clock_in', 'desc')
            ->paginate(20)
            ->withQueryString();

        $employees = Employee::where('company_id', $tenant->id)
            ->active()
            ->orderBy('first_name')
            ->get();

        return view('attendances.index', compact('attendances', 'employees'));
    }

    public function syncAdmsAttendance(Request $request): RedirectResponse
    {
        $tenant = app('tenant');
        $date = $request->input('date', date('Y-m-d'));

        try {
            $admsService = app(\App\Services\AdmsApiService::class);
            $reconciliationService = app(\App\Services\AttendanceReconciliationService::class);
            $job = new \App\Jobs\SyncAdmsAttendanceJob($tenant->id, $date);
            $result = $job->handle($admsService, $reconciliationService);

            return redirect()->route('attendances.index', ['date' => $date])
                ->with('success', "Sinkronisasi presensi ADMS berhasil. ({$result['applied']} log kehadiran diterapkan dari {$result['total']} data ADMS)");
        } catch (\Throwable $e) {
            return redirect()->route('attendances.index')
                ->with('error', 'Gagal menyinkronkan presensi ADMS: '.$e->getMessage());
        }
    }

    public function create(): View
    {
        $tenant = app('tenant');

        $employees = Employee::where('company_id', $tenant->id)
            ->active()
            ->orderBy('first_name')
            ->get();

        return view('attendances.create', compact('employees'));
    }

    public function store(AttendanceRequest $request): RedirectResponse
    {
        $tenant = app('tenant');
        $employee = Employee::findOrFail($request->employee_id);

        // Check for duplicate
        $existing = Attendance::where('company_id', $tenant->id)
            ->where('employee_id', $request->employee_id)
            ->whereDate('date', $request->date)
            ->first();

        if ($existing) {
            return redirect()->back()
                ->withInput()
                ->withErrors(['date' => 'Kehadiran untuk karyawan ini pada tanggal tersebut sudah ada.']);
        }

        $date = Carbon::parse($request->date);
        $resolvedSchedule = $employee->resolveScheduleForDate($date);

        $attendance = Attendance::create([
            'company_id' => $tenant->id,
            'employee_id' => $request->employee_id,
            'work_schedule_id' => $resolvedSchedule?->id,
            'date' => $date,
            'scheduled_start' => $resolvedSchedule?->start_time?->format('H:i'),
            'scheduled_end' => $resolvedSchedule?->end_time?->format('H:i'),
            'clock_in' => $request->clock_in ? $date->copy()->setTimeFromTimeString($request->clock_in) : null,
            'clock_out' => $request->clock_out ? $date->copy()->setTimeFromTimeString($request->clock_out) : null,
            'status' => $request->status ?? 'present',
            'clock_in_status' => $this->determineClockInStatus($request->clock_in, $resolvedSchedule),
            'clock_out_status' => $this->determineClockOutStatus($request->clock_out, $resolvedSchedule),
            'is_manual_entry' => true,
            'approved_by' => auth()->id(),
            'approved_at' => now(),
            'admin_notes' => $request->admin_notes,
            'late_minutes' => $this->calculateLateMinutes($request->clock_in, $resolvedSchedule),
            'working_minutes' => $this->calculateWorkingMinutes($request->clock_in, $request->clock_out),
        ]);

        return redirect()->route('attendances.index')
            ->with('success', 'Data kehadiran berhasil ditambahkan.');
    }

    public function show(Attendance $attendance): View
    {
        $tenant = app('tenant');

        if ($attendance->company_id !== $tenant->id) {
            abort(404);
        }

        $attendance->load(['company', 'employee', 'workSchedule', 'approvedBy']);

        return view('attendances.show', compact('attendance'));
    }

    public function edit(Attendance $attendance): View
    {
        $tenant = app('tenant');

        if ($attendance->company_id !== $tenant->id) {
            abort(404);
        }

        $employees = Employee::where('company_id', $tenant->id)
            ->active()
            ->orderBy('first_name')
            ->get();

        return view('attendances.edit', compact('attendance', 'employees'));
    }

    public function update(Request $request, Attendance $attendance): RedirectResponse
    {
        $tenant = app('tenant');

        if ($attendance->company_id !== $tenant->id) {
            abort(404);
        }

        $validated = $request->validate([
            'employee_id' => ['required', 'exists:employees,id'],
            'date' => ['required', 'date'],
            'clock_in' => ['nullable', 'date_format:H:i'],
            'clock_out' => ['nullable', 'date_format:H:i'],
            'status' => ['nullable', 'in:present,absent,late,half_day,leave,holiday,weekend'],
            'admin_notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $employee = Employee::findOrFail($validated['employee_id']);
        $date = Carbon::parse($validated['date']);
        $resolvedSchedule = $employee->resolveScheduleForDate($date);

        $attendance->update([
            'clock_in' => $validated['clock_in'] ? $date->copy()->setTimeFromTimeString($validated['clock_in']) : null,
            'clock_out' => $validated['clock_out'] ? $date->copy()->setTimeFromTimeString($validated['clock_out']) : null,
            'status' => $validated['status'] ?? 'present',
            'clock_in_status' => $this->determineClockInStatus($validated['clock_in'] ?? null, $resolvedSchedule),
            'clock_out_status' => $this->determineClockOutStatus($validated['clock_out'] ?? null, $resolvedSchedule),
            'admin_notes' => $validated['admin_notes'] ?? null,
            'late_minutes' => $this->calculateLateMinutes($validated['clock_in'] ?? null, $resolvedSchedule),
            'working_minutes' => $this->calculateWorkingMinutes($validated['clock_in'] ?? null, $validated['clock_out'] ?? null),
        ]);

        return redirect()->route('attendances.index')
            ->with('success', 'Data kehadiran berhasil diperbarui.');
    }

    public function destroy(Attendance $attendance): RedirectResponse
    {
        $tenant = app('tenant');

        if ($attendance->company_id !== $tenant->id) {
            abort(404);
        }

        $attendance->delete();

        return redirect()->route('attendances.index')
            ->with('success', 'Data kehadiran berhasil dihapus.');
    }

    public function clockIn(Request $request): RedirectResponse
    {
        $tenant = app('tenant');
        $user = auth()->user();

        $employee = Employee::where('company_id', $tenant->id)
            ->where('user_id', $user->id)
            ->first();

        if (! $employee) {
            return redirect()->back()
                ->with('error', 'Data karyawan tidak ditemukan.');
        }

        $rules = $tenant->enable_gps_validation
            ? ['latitude' => 'required|numeric', 'longitude' => 'required|numeric']
            : ['latitude' => 'nullable|numeric', 'longitude' => 'nullable|numeric'];
        $request->validate($rules);

        $officeLocationId = null;
        if ($tenant->enable_gps_validation) {
            $gpsResult = $this->gpsValidationService->validateEmployeeLocation(
                $employee,
                $request->latitude,
                $request->longitude
            );

            if (! $gpsResult['valid']) {
                $message = match ($gpsResult['reason']) {
                    'no_assigned_offices' => 'Tidak ada lokasi kantor yang ditugaskan.',
                    'no_active_offices' => 'Tidak ada lokasi kantor aktif yang ditugaskan.',
                    'outside_radius' => 'Lokasi Anda terlalu jauh dari kantor.',
                    default => 'Validasi lokasi gagal.',
                };

                return redirect()->back()->with('error', $message);
            }

            $officeLocationId = $gpsResult['office_location_id'];
        }

        $result = $this->reconciliationService->record($employee, 'clock_in', $tenant->now(), 'web', [
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'office_location_id' => $officeLocationId,
            'ip' => $request->ip(),
        ]);

        if (in_array($result['status'], ['duplicate_ignored', 'duplicate_event'], true)) {
            return redirect()->back()
                ->with('error', 'Anda sudah melakukan clock in hari ini.');
        }

        return redirect()->back()
            ->with('success', 'Clock in berhasil dicatat pada '.$result['attendance']->clock_in->setTimezone($tenant->timezone)->format('H:i').'.');
    }

    public function clockOut(Request $request): RedirectResponse
    {
        $tenant = app('tenant');
        $user = auth()->user();

        $employee = Employee::where('company_id', $tenant->id)
            ->where('user_id', $user->id)
            ->first();

        if (! $employee) {
            return redirect()->back()
                ->with('error', 'Data karyawan tidak ditemukan.');
        }

        $today = $tenant->today();
        $yesterday = $today->copy()->subDay();

        // Find attendance - check both today and yesterday (for overnight shifts)
        $attendance = Attendance::where('company_id', $tenant->id)
            ->where('employee_id', $employee->id)
            ->whereNotNull('clock_in')
            ->whereNull('clock_out')
            ->where(function ($query) use ($today, $yesterday) {
                $query->whereDate('date', $today)
                    ->orWhereDate('date', $yesterday);
            })
            ->orderBy('date', 'desc')
            ->first();

        if (! $attendance) {
            return redirect()->back()
                ->with('error', 'Anda belum melakukan clock in.');
        }

        $rules = $tenant->enable_gps_validation
            ? ['latitude' => 'required|numeric', 'longitude' => 'required|numeric']
            : ['latitude' => 'nullable|numeric', 'longitude' => 'nullable|numeric'];
        $request->validate($rules);

        $officeLocationId = null;
        if ($tenant->enable_gps_validation) {
            $gpsResult = $this->gpsValidationService->validateEmployeeLocation(
                $employee,
                $request->latitude,
                $request->longitude
            );

            if (! $gpsResult['valid']) {
                $message = match ($gpsResult['reason']) {
                    'no_assigned_offices' => 'Tidak ada lokasi kantor yang ditugaskan.',
                    'no_active_offices' => 'Tidak ada lokasi kantor aktif yang ditugaskan.',
                    'outside_radius' => 'Lokasi Anda terlalu jauh dari kantor.',
                    default => 'Validasi lokasi gagal.',
                };

                return redirect()->back()->with('error', $message);
            }

            $officeLocationId = $gpsResult['office_location_id'];
        }

        $result = $this->reconciliationService->record($employee, 'clock_out', $tenant->now(), 'web', [
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'office_location_id' => $officeLocationId,
            'ip' => $request->ip(),
        ]);

        if (in_array($result['status'], ['duplicate_ignored', 'duplicate_event'], true)) {
            return redirect()->back()
                ->with('error', 'Anda sudah melakukan clock out hari ini.');
        }

        return redirect()->back()
            ->with('success', 'Clock out berhasil dicatat pada '.$result['attendance']->clock_out->setTimezone($tenant->timezone)->format('H:i').'.');
    }

    public function report(Request $request): View
    {
        $tenant = app('tenant');

        // Determine date range
        if ($request->filled('month')) {
            $date = Carbon::parse($request->month);
            $year = $date->year;
            $month = $date->month;
        } else {
            $companyNow = $tenant->now();
            $year = $companyNow->year;
            $month = $companyNow->month;
        }

        // Base query conditions
        $baseConditions = function ($query) use ($tenant, $request, $year, $month) {
            $query->where('company_id', $tenant->id)
                ->forMonth($year, $month);

            if ($request->filled('employee_id')) {
                $query->where('employee_id', $request->employee_id);
            }

            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }
        };

        // Optimized: Get summary using database aggregate instead of loading all records
        $summary = Attendance::where(function ($query) use ($baseConditions) {
            $baseConditions($query);
        })
            ->selectRaw("
                COUNT(DISTINCT DATE(date)) as total_days,
                COUNT(DISTINCT employee_id) as total_employees,
                SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present,
                SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late,
                SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent,
                SUM(CASE WHEN status = 'leave' THEN 1 ELSE 0 END) as leave_count,
                SUM(CASE WHEN status = 'half_day' THEN 1 ELSE 0 END) as half_day,
                COALESCE(SUM(working_minutes), 0) as total_working_minutes,
                COALESCE(SUM(overtime_minutes), 0) as total_overtime_minutes,
                COALESCE(SUM(late_minutes), 0) as total_late_minutes
            ")
            ->first();

        $summaryData = [
            'total_days' => (int) ($summary->total_days ?? 0),
            'total_employees' => (int) ($summary->total_employees ?? 0),
            'present' => (int) ($summary->present ?? 0),
            'late' => (int) ($summary->late ?? 0),
            'absent' => (int) ($summary->absent ?? 0),
            'leave' => (int) ($summary->leave_count ?? 0),
            'half_day' => (int) ($summary->half_day ?? 0),
            'total_working_hours' => round(($summary->total_working_minutes ?? 0) / 60, 1),
            'total_overtime_hours' => round(($summary->total_overtime_minutes ?? 0) / 60, 1),
            'total_late_hours' => round(($summary->total_late_minutes ?? 0) / 60, 1),
        ];

        // Optimized: Get report data per employee using database aggregate
        $reportData = Attendance::with('employee')
            ->where(function ($query) use ($baseConditions) {
                $baseConditions($query);
            })
            ->selectRaw("
                employee_id,
                SUM(CASE WHEN status IN ('present', 'late') THEN 1 ELSE 0 END) as present,
                SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late,
                SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent,
                SUM(CASE WHEN status = 'leave' THEN 1 ELSE 0 END) as leave_count,
                COALESCE(SUM(working_minutes), 0) as total_working_minutes,
                COALESCE(SUM(overtime_minutes), 0) as total_overtime_minutes,
                COALESCE(SUM(late_minutes), 0) as total_late_minutes
            ")
            ->groupBy('employee_id')
            ->get()
            ->map(function ($row) {
                return [
                    'employee' => $row->employee,
                    'present' => (int) $row->present,
                    'late' => (int) $row->late,
                    'absent' => (int) $row->absent,
                    'leave' => (int) $row->leave_count,
                    'working_hours' => round($row->total_working_minutes / 60, 1),
                    'overtime_hours' => round($row->total_overtime_minutes / 60, 1),
                    'late_hours' => round($row->total_late_minutes / 60, 1),
                ];
            })
            ->keyBy(fn ($item) => $item['employee']->id);

        // Get attendances for detail view (still needed for the table)
        $attendances = Attendance::with(['employee', 'workSchedule'])
            ->where(function ($query) use ($baseConditions) {
                $baseConditions($query);
            })
            ->orderBy('date', 'asc')
            ->orderBy('employee_id')
            ->paginate(50)
            ->withQueryString();

        $employees = Employee::where('company_id', $tenant->id)
            ->active()
            ->orderBy('first_name')
            ->get();

        return view('attendances.report', [
            'attendances' => $attendances,
            'summary' => $summaryData,
            'employees' => $employees,
            'reportData' => $reportData,
        ]);
    }

    public function export(Request $request)
    {
        $tenant = app('tenant');

        $query = Attendance::with(['employee', 'workSchedule'])
            ->where('company_id', $tenant->id);

        if ($request->filled('month')) {
            $date = Carbon::parse($request->month);
            $query->forMonth($date->year, $date->month);
        } else {
            $companyNow = $tenant->now();
            $query->forMonth($companyNow->year, $companyNow->month);
        }

        if ($request->filled('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        $attendances = $query->orderBy('date', 'asc')
            ->orderBy('employee_id')
            ->get();

        // For now, return CSV format
        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="laporan-kehadiran-'.$tenant->today()->format('Y-m-d').'.csv"',
        ];

        $callback = function () use ($attendances) {
            $file = fopen('php://output', 'w');

            // Header
            fputcsv($file, [
                'Tanggal',
                'ID Karyawan',
                'Nama Karyawan',
                'Jam Masuk',
                'Jam Pulang',
                'Durasi Kerja (menit)',
                'Terlambat (menit)',
                'Lembur (menit)',
                'Status',
            ]);

            // Data
            foreach ($attendances as $attendance) {
                fputcsv($file, [
                    $attendance->date->format('Y-m-d'),
                    $attendance->employee->employee_id,
                    $attendance->employee->full_name,
                    $attendance->clock_in?->format('H:i'),
                    $attendance->clock_out?->format('H:i'),
                    $attendance->working_minutes,
                    $attendance->late_minutes,
                    $attendance->overtime_minutes,
                    $attendance->status_label,
                ]);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    private function determineClockInStatus(?string $clockIn, ?WorkSchedule $schedule): ?string
    {
        if (! $clockIn || ! $schedule) {
            return null;
        }

        $clockInTime = Carbon::parse($clockIn);
        $scheduledStart = Carbon::parse($schedule->start_time->format('H:i'));
        $tolerance = $schedule->late_tolerance ?? 15;

        if ($clockInTime->gt($scheduledStart->copy()->addMinutes($tolerance))) {
            $lateMinutes = $scheduledStart->diffInMinutes($clockInTime);

            return $lateMinutes > 30 ? 'very_late' : 'late';
        }

        return 'on_time';
    }

    private function determineClockOutStatus(?string $clockOut, ?WorkSchedule $schedule): ?string
    {
        if (! $clockOut || ! $schedule) {
            return null;
        }

        $clockOutTime = Carbon::parse($clockOut);
        $scheduledEnd = Carbon::parse($schedule->end_time->format('H:i'));
        $tolerance = $schedule->early_leave_tolerance ?? 15;

        if ($clockOutTime->lt($scheduledEnd->copy()->subMinutes($tolerance))) {
            return 'early';
        } elseif ($clockOutTime->gt($scheduledEnd)) {
            return 'overtime';
        }

        return 'on_time';
    }

    private function calculateLateMinutes(?string $clockIn, ?WorkSchedule $schedule): int
    {
        if (! $clockIn || ! $schedule) {
            return 0;
        }

        $clockInTime = Carbon::parse($clockIn);
        $scheduledStart = Carbon::parse($schedule->start_time->format('H:i'));

        if ($clockInTime->gt($scheduledStart)) {
            return $scheduledStart->diffInMinutes($clockInTime);
        }

        return 0;
    }

    private function calculateWorkingMinutes(?string $clockIn, ?string $clockOut): int
    {
        if (! $clockIn || ! $clockOut) {
            return 0;
        }

        $start = Carbon::parse($clockIn);
        $end = Carbon::parse($clockOut);

        return $start->diffInMinutes($end);
    }
}
