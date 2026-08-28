<?php

namespace App\Http\Controllers;

use App\Http\Requests\WorkScheduleRequest;
use App\Models\Department;
use App\Models\Employee;
use App\Models\EmployeeWeeklySchedule;
use App\Models\Position;
use App\Models\WorkSchedule;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class WorkScheduleController extends Controller
{
    public function index(Request $request): View
    {
        $tenant = app('tenant');

        $query = WorkSchedule::withCount('employees')
            ->where('company_id', $tenant->id);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('code', 'like', "%{$search}%");
            });
        }

        if ($request->filled('status')) {
            $query->where('is_active', $request->status === 'active');
        }

        $workSchedules = $query->orderBy('name')->paginate(15)->withQueryString();

        $assignableSchedules = WorkSchedule::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $departments = Department::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $positions = Position::with('department')
            ->where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        return view('work-schedules.index', compact('workSchedules', 'assignableSchedules', 'departments', 'positions'));
    }

    /**
     * Bulk-assign one work schedule to all employees, or to employees
     * scoped to a department or position.
     */
    public function bulkAssign(Request $request): RedirectResponse
    {
        $tenant = app('tenant');

        $validated = $request->validate([
            'work_schedule_id' => ['required', Rule::exists('work_schedules', 'id')->where('company_id', $tenant->id)],
            'target_type' => ['required', 'in:all,department,position'],
            'department_id' => ['required_if:target_type,department', 'nullable', Rule::exists('departments', 'id')->where('company_id', $tenant->id)],
            'position_id' => ['required_if:target_type,position', 'nullable', Rule::exists('positions', 'id')->where('company_id', $tenant->id)],
        ]);

        $employeeQuery = Employee::where('company_id', $tenant->id);

        if ($validated['target_type'] === 'department') {
            $employeeQuery->where('department_id', $validated['department_id']);
        } elseif ($validated['target_type'] === 'position') {
            $employeeQuery->where('position_id', $validated['position_id']);
        }

        $employeeIds = $employeeQuery->pluck('id');

        if ($employeeIds->isEmpty()) {
            return redirect()->route('work-schedules.index')
                ->with('error', 'Tidak ada karyawan yang sesuai dengan target yang dipilih.');
        }

        $updatedCount = DB::transaction(function () use ($employeeIds, $validated) {
            $count = Employee::whereIn('id', $employeeIds)
                ->update(['work_schedule_id' => $validated['work_schedule_id']]);

            // A per-day weekly override takes priority over work_schedule_id
            // in Employee::resolveScheduleForDate() — clear it so the newly
            // assigned flat schedule actually takes effect for everyone.
            EmployeeWeeklySchedule::whereIn('employee_id', $employeeIds)->delete();

            return $count;
        });

        $schedule = WorkSchedule::findOrFail($validated['work_schedule_id']);

        return redirect()->route('work-schedules.index')
            ->with('success', "Jadwal '{$schedule->name}' berhasil ditetapkan ke {$updatedCount} karyawan.");
    }

    public function create(): View
    {
        return view('work-schedules.create');
    }

    public function store(WorkScheduleRequest $request): RedirectResponse
    {
        $tenant = app('tenant');

        // If this schedule is set as default, remove default from others
        if ($request->boolean('is_default')) {
            WorkSchedule::where('company_id', $tenant->id)
                ->where('is_default', true)
                ->update(['is_default' => false]);
        }

        WorkSchedule::create([
            ...$request->validated(),
            'company_id' => $tenant->id,
        ]);

        return redirect()->route('work-schedules.index')
            ->with('success', 'Jadwal kerja berhasil ditambahkan.');
    }

    public function show(WorkSchedule $workSchedule): View
    {
        $tenant = app('tenant');

        if ($workSchedule->company_id !== $tenant->id) {
            abort(404);
        }

        $workSchedule->loadCount('employees');

        return view('work-schedules.show', compact('workSchedule'));
    }

    public function edit(WorkSchedule $workSchedule): View
    {
        $tenant = app('tenant');

        if ($workSchedule->company_id !== $tenant->id) {
            abort(404);
        }

        return view('work-schedules.edit', compact('workSchedule'));
    }

    public function update(WorkScheduleRequest $request, WorkSchedule $workSchedule): RedirectResponse
    {
        $tenant = app('tenant');

        if ($workSchedule->company_id !== $tenant->id) {
            abort(404);
        }

        // If this schedule is set as default, remove default from others
        if ($request->boolean('is_default') && ! $workSchedule->is_default) {
            WorkSchedule::where('company_id', $tenant->id)
                ->where('is_default', true)
                ->update(['is_default' => false]);
        }

        $workSchedule->update($request->validated());

        return redirect()->route('work-schedules.index')
            ->with('success', 'Jadwal kerja berhasil diperbarui.');
    }

    public function destroy(WorkSchedule $workSchedule): RedirectResponse
    {
        $tenant = app('tenant');

        if ($workSchedule->company_id !== $tenant->id) {
            abort(404);
        }

        if ($workSchedule->is_default) {
            return redirect()->route('work-schedules.index')
                ->with('error', 'Jadwal kerja default tidak dapat dihapus.');
        }

        if ($workSchedule->employees()->count() > 0) {
            return redirect()->route('work-schedules.index')
                ->with('error', 'Jadwal kerja tidak dapat dihapus karena masih digunakan oleh karyawan.');
        }

        $workSchedule->delete();

        return redirect()->route('work-schedules.index')
            ->with('success', 'Jadwal kerja berhasil dihapus.');
    }
}
