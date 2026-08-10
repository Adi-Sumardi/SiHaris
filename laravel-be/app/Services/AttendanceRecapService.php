<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\Holiday;
use App\Models\LeaveRequest;
use Carbon\Carbon;

/**
 * Computes an employee's attendance recap for a given period, always
 * excluding weekends and company holidays from the working-day count —
 * the same rule payroll's attendance summary follows.
 */
class AttendanceRecapService
{
    /**
     * @return array{
     *     working_days: int,
     *     present_days: int,
     *     absent_days: int,
     *     late_days: int,
     *     leave_days: int,
     *     attendance_percentage: float,
     * }
     */
    public function compute(Employee $employee, Carbon $periodStart, Carbon $periodEnd): array
    {
        $holidayDates = Holiday::where('company_id', $employee->company_id)
            ->where('is_active', true)
            ->whereBetween('date', [$periodStart, $periodEnd])
            ->pluck('date')
            ->map(fn ($date) => Carbon::parse($date)->toDateString())
            ->flip();

        $hasSchedule = (bool) $employee->workSchedule || $employee->hasWeeklySchedulePattern();

        $workingDays = 0;
        $current = $periodStart->copy();
        while ($current->lte($periodEnd)) {
            if (! $holidayDates->has($current->toDateString())) {
                $isWorkingDay = $hasSchedule
                    ? (bool) $employee->resolveScheduleForDate($current)
                    : $current->isWeekday();

                if ($isWorkingDay) {
                    $workingDays++;
                }
            }
            $current->addDay();
        }

        $attendances = Attendance::where('employee_id', $employee->id)
            ->whereBetween('date', [$periodStart, $periodEnd])
            ->get();

        $presentDays = $attendances->whereIn('status', ['present', 'late'])->count();
        $absentDays = $attendances->where('status', 'absent')->count();
        $lateDays = $attendances->where('status', 'late')->count();

        $leaveDays = LeaveRequest::where('employee_id', $employee->id)
            ->where('status', 'approved')
            ->where('start_date', '<=', $periodEnd)
            ->where('end_date', '>=', $periodStart)
            ->get()
            ->sum(function (LeaveRequest $leave) use ($periodStart, $periodEnd) {
                $start = Carbon::parse($leave->start_date)->max($periodStart);
                $end = Carbon::parse($leave->end_date)->min($periodEnd);

                return $start->diffInDays($end) + 1;
            });

        return [
            'working_days' => $workingDays,
            'present_days' => $presentDays,
            'absent_days' => $absentDays,
            'late_days' => $lateDays,
            'leave_days' => (int) $leaveDays,
            'attendance_percentage' => $workingDays > 0 ? round(($presentDays / $workingDays) * 100, 2) : 0.0,
        ];
    }

    /**
     * Resolve the [start, end] period a recap should cover for the given
     * frequency, relative to a reference "now" — always the most recently
     * completed day/week/month, never a partial one still in progress.
     *
     * @return array{0: Carbon, 1: Carbon}
     */
    public function periodFor(string $frequency, Carbon $reference): array
    {
        return match ($frequency) {
            'daily' => [
                $reference->copy()->subDay()->startOfDay(),
                $reference->copy()->subDay()->startOfDay(),
            ],
            'monthly' => [
                $reference->copy()->subMonthNoOverflow()->startOfMonth(),
                $reference->copy()->subMonthNoOverflow()->endOfMonth(),
            ],
            default => [
                $reference->copy()->subWeek()->startOfWeek(Carbon::MONDAY),
                $reference->copy()->subWeek()->endOfWeek(Carbon::SUNDAY),
            ],
        };
    }
}
