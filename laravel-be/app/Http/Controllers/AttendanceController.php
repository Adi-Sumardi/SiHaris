<?php

namespace App\Http\Controllers;

use App\Http\Requests\AttendanceRequest;
use App\Models\Attendance;
use App\Models\Employee;
use App\Models\Holiday;
use App\Models\LeaveRequest;
use App\Models\WorkSchedule;
use App\Services\AttendanceReconciliationService;
use App\Services\GpsValidationService;
use Carbon\Carbon;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
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

        // "Tidak Hadir" and "Cuti" have no Attendance row for employees who never clocked in,
        // so those two statuses are answered by a roster diff for a single date instead of a plain status filter.
        if ($request->filled('status') && in_array($request->status, ['absent', 'leave'], true)) {
            $date = $request->filled('date') ? $request->date : $tenant->today()->format('Y-m-d');
            $attendances = $this->buildRosterStatusList($tenant, $request, $request->status, $date);

            return view('attendances.index', compact('attendances'));
        }

        $query = Attendance::with(['company', 'employee', 'workSchedule'])
            ->where('company_id', $tenant->id);

        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->whereHas('employee', function ($q) use ($search) {
                $q->where(function ($eq) use ($search) {
                    $eq->where('first_name', 'like', "%{$search}%")
                        ->orWhere('last_name', 'like', "%{$search}%")
                        ->orWhere('employee_id', 'like', "%{$search}%")
                        ->orWhere('nik', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhereRaw("CONCAT(first_name, ' ', COALESCE(last_name, '')) LIKE ?", ["%{$search}%"]);
                });
            });
        }

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

        return view('attendances.index', compact('attendances'));
    }

    /**
     * Build a paginated list of employees matching 'absent' or 'leave' for a single date, combining
     * any explicit manual Attendance rows for that status with employees who simply have no
     * attendance record at all (the common case, since rows are only created on a clock event).
     */
    private function buildRosterStatusList($tenant, Request $request, string $status, string $date): LengthAwarePaginator
    {
        $recordedEmployeeIds = Attendance::where('company_id', $tenant->id)
            ->whereDate('date', $date)
            ->pluck('employee_id');

        $onLeaveEmployeeIds = LeaveRequest::where('company_id', $tenant->id)
            ->where('status', 'approved')
            ->whereDate('start_date', '<=', $date)
            ->whereDate('end_date', '>=', $date)
            ->pluck('employee_id');

        $employeesQuery = Employee::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->whereNotIn('id', $recordedEmployeeIds);

        $employeesQuery = $status === 'leave'
            ? $employeesQuery->whereIn('id', $onLeaveEmployeeIds)
            : $employeesQuery->whereNotIn('id', $onLeaveEmployeeIds);

        if ($request->filled('search')) {
            $search = trim($request->search);
            $employeesQuery->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('employee_id', 'like', "%{$search}%")
                    ->orWhere('nik', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhereRaw("CONCAT(first_name, ' ', COALESCE(last_name, '')) LIKE ?", ["%{$search}%"]);
            });
        }

        if ($request->filled('employee_id')) {
            $employeesQuery->where('id', $request->employee_id);
        }

        $missingEmployees = $employeesQuery->orderBy('first_name')->get();

        $syntheticAttendances = $missingEmployees->map(function (Employee $employee) use ($tenant, $status, $date) {
            $attendance = new Attendance([
                'company_id' => $tenant->id,
                'employee_id' => $employee->id,
                'date' => $date,
                'status' => $status,
                'working_minutes' => 0,
            ]);
            $attendance->setRelation('employee', $employee);

            return $attendance;
        });

        $explicitAttendances = Attendance::with(['employee', 'workSchedule'])
            ->where('company_id', $tenant->id)
            ->whereDate('date', $date)
            ->where('status', $status)
            ->when($request->filled('employee_id'), fn ($q) => $q->where('employee_id', $request->employee_id))
            ->get();

        $items = $explicitAttendances->concat($syntheticAttendances)
            ->sortBy(fn (Attendance $attendance) => $attendance->employee?->first_name)
            ->values();

        $perPage = 20;
        $page = (int) ($request->get('page', 1));

        return new LengthAwarePaginator(
            $items->forPage($page, $perPage)->values(),
            $items->count(),
            $perPage,
            $page,
            ['path' => $request->url(), 'query' => $request->query()]
        );
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
            'clock_out_status' => $this->determineClockOutStatus($request->clock_out, $resolvedSchedule, $request->clock_in),
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
            'clock_out_status' => $this->determineClockOutStatus($validated['clock_out'] ?? null, $resolvedSchedule, $validated['clock_in'] ?? null),
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

        // Determine the month being reported on
        if ($request->filled('month')) {
            $monthDate = Carbon::parse($request->month);
        } else {
            $monthDate = $tenant->now();
        }

        $periodStart = Carbon::create($monthDate->year, $monthDate->month, 1)->startOfDay();
        $periodEnd = $periodStart->copy()->endOfMonth()->endOfDay();

        // Don't count days that haven't happened yet as "should have attended" when the
        // selected month is still in progress.
        $today = $tenant->today()->endOfDay();
        if ($periodEnd->gt($today)) {
            $periodEnd = $today->copy();
        }

        // Roster this report covers: every active employee, not just those who happen to
        // already have an Attendance row — otherwise anyone absent the whole month simply
        // never appears.
        $employeesQuery = Employee::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->with(['weeklySchedules.workSchedule', 'workSchedule']);

        if ($request->filled('search')) {
            $search = trim($request->search);
            $employeesQuery->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('employee_id', 'like', "%{$search}%")
                    ->orWhere('nik', 'like', "%{$search}%")
                    ->orWhere('pin', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhereRaw("CONCAT(first_name, ' ', last_name) LIKE ?", ["%{$search}%"]);
            });
        }

        if ($request->filled('employee_id')) {
            $employeesQuery->where('id', $request->employee_id);
        }

        $employees = $employeesQuery->orderBy('first_name')->get();

        $attendancesByEmployee = Attendance::where('company_id', $tenant->id)
            ->whereBetween('date', [$periodStart->toDateString(), $periodEnd->toDateString()])
            ->get()
            ->groupBy('employee_id');

        $leaveRequestsByEmployee = LeaveRequest::where('company_id', $tenant->id)
            ->where('status', 'approved')
            ->where('start_date', '<=', $periodEnd)
            ->where('end_date', '>=', $periodStart)
            ->get()
            ->groupBy('employee_id');

        $holidayDates = Holiday::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->whereBetween('date', [$periodStart, $periodEnd])
            ->pluck('date')
            ->map(fn ($date) => Carbon::parse($date)->toDateString())
            ->flip();

        $reportData = collect();

        foreach ($employees as $employee) {
            $attendances = $attendancesByEmployee->get($employee->id, collect());

            $leaveDays = $leaveRequestsByEmployee->get($employee->id, collect())
                ->sum(function (LeaveRequest $leave) use ($periodStart, $periodEnd) {
                    $start = Carbon::parse($leave->start_date)->max($periodStart);
                    $end = Carbon::parse($leave->end_date)->min($periodEnd);

                    return $start->lte($end) ? $start->diffInDays($end) + 1 : 0;
                });

            $workingDays = $this->countWorkingDays($employee, $periodStart, $periodEnd, $holidayDates);
            $presentDays = $attendances->whereIn('status', ['present', 'late'])->count();

            $reportData->put($employee->id, [
                'employee' => $employee,
                'present' => $presentDays,
                'late' => $attendances->where('status', 'late')->count(),
                'absent' => max(0, $workingDays - $presentDays - (int) $leaveDays),
                'leave' => (int) $leaveDays,
                'working_hours' => round($attendances->sum('working_minutes') / 60, 1),
                'overtime_hours' => round($attendances->sum('overtime_minutes') / 60, 1),
                'late_hours' => round($attendances->sum('late_minutes') / 60, 1),
            ]);
        }

        if ($request->filled('status') && in_array($request->status, ['present', 'late', 'absent', 'leave'], true)) {
            $reportData = $reportData->filter(fn (array $row) => $row[$request->status] > 0);
        }

        $summaryData = [
            'total_employees' => $reportData->count(),
            'present' => $reportData->sum('present'),
            'late' => $reportData->sum('late'),
            'absent' => $reportData->sum('absent'),
            'leave' => $reportData->sum('leave'),
            'total_working_hours' => round($reportData->sum('working_hours'), 1),
            'total_overtime_hours' => round($reportData->sum('overtime_hours'), 1),
            'total_late_hours' => round($reportData->sum('late_hours'), 1),
        ];

        return view('attendances.report', [
            'summary' => $summaryData,
            'reportData' => $reportData,
        ]);
    }

    /**
     * Count the employee's scheduled working days in [start, end], skipping company holidays
     * and any day their weekly pattern / work schedule marks as a day off.
     */
    private function countWorkingDays(Employee $employee, Carbon $start, Carbon $end, \Illuminate\Support\Collection $holidayDates): int
    {
        $hasSchedule = (bool) $employee->workSchedule || $employee->hasWeeklySchedulePattern();

        $workingDays = 0;
        $cursor = $start->copy();
        while ($cursor->lte($end)) {
            if (! $holidayDates->has($cursor->toDateString())) {
                $isWorkingDay = $hasSchedule
                    ? (bool) $employee->resolveScheduleForDate($cursor)
                    : $cursor->isWeekday();

                if ($isWorkingDay) {
                    $workingDays++;
                }
            }
            $cursor->addDay();
        }

        return $workingDays;
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

        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->whereHas('employee', function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('employee_id', 'like', "%{$search}%")
                    ->orWhere('nik', 'like', "%{$search}%")
                    ->orWhere('pin', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhereRaw("CONCAT(first_name, ' ', last_name) LIKE ?", ["%{$search}%"]);
            });
        }

        if ($request->filled('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
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

    private function determineClockOutStatus(?string $clockOut, ?WorkSchedule $schedule, ?string $clockIn = null): ?string
    {
        if (! $clockOut || ! $schedule) {
            return null;
        }

        $clockOutTime = Carbon::parse($clockOut);
        $scheduledEnd = Carbon::parse($schedule->end_time->format('H:i'));

        if ($schedule->is_flexible && $clockIn) {
            $clockInTime = Carbon::parse($clockIn);
            $scheduledStart = Carbon::parse($schedule->start_time->format('H:i'));
            if ($clockInTime->gt($scheduledStart)) {
                $flexiMinutes = min($scheduledStart->diffInMinutes($clockInTime), (int) ($schedule->late_tolerance ?? 0));
                $scheduledEnd->addMinutes($flexiMinutes);
            }
        }

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
