<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Company;
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
     *     weekday_present_days: int,
     *     saturday_present_days: int,
     *     total_present_days: int,
     *     absent_days: int,
     *     late_days: int,
     *     late_gt_5_days: int,
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

        $presentAttendances = $attendances->whereIn('status', ['present', 'late']);
        $presentDays = $presentAttendances->count();

        // Separate weekday (Senin-Jumat) vs Saturday (Sabtu)
        $weekdayPresentDays = $presentAttendances->filter(function ($att) {
            return Carbon::parse($att->date)->isWeekday();
        })->count();

        $saturdayPresentDays = $presentAttendances->filter(function ($att) {
            return Carbon::parse($att->date)->isSaturday();
        })->count();

        $totalPresentDays = $weekdayPresentDays + $saturdayPresentDays;

        $absentDays = $attendances->where('status', 'absent')->count();
        $lateDays = $attendances->where('status', 'late')->count();

        // Late > 5 minutes count
        $lateGt5Days = $attendances->filter(function ($att) {
            return ($att->late_minutes ?? 0) > 5;
        })->count();

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
            'weekday_present_days' => $weekdayPresentDays,
            'saturday_present_days' => $saturdayPresentDays,
            'total_present_days' => $totalPresentDays,
            'absent_days' => $absentDays,
            'late_days' => $lateDays,
            'late_gt_5_days' => $lateGt5Days,
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
    public function periodFor(string $frequency, Carbon $reference, ?Company $company = null): array
    {
        return match ($frequency) {
            'daily' => [
                $reference->copy()->subDay()->startOfDay(),
                $reference->copy()->subDay()->endOfDay(),
            ],
            'monthly' => $this->resolveMonthlyPeriod($reference, $company),
            default => [
                $reference->copy()->subWeek()->startOfWeek(Carbon::MONDAY)->startOfDay(),
                $reference->copy()->subWeek()->endOfWeek(Carbon::SUNDAY)->endOfDay(),
            ],
        };
    }

    /**
     * Calculate monthly cutoff period.
     * If cutoff day > 1 (e.g. 21): period runs from 21 of previous month to 20 of current month.
     * If cutoff day <= 1: period runs from 1st of previous month to last day of previous month.
     *
     * @return array{0: Carbon, 1: Carbon}
     */
    protected function resolveMonthlyPeriod(Carbon $reference, ?Company $company = null): array
    {
        $cutoffDay = (int) ($company?->attendance_recap_day_of_month ?? 1);

        if ($cutoffDay <= 1) {
            return [
                $reference->copy()->subMonthNoOverflow()->startOfMonth()->startOfDay(),
                $reference->copy()->subMonthNoOverflow()->endOfMonth()->endOfDay(),
            ];
        }

        // Custom cutoff > 1 (e.g. 21)
        $previousMonth = $reference->copy()->subMonthNoOverflow();
        $startDay = min($cutoffDay, $previousMonth->daysInMonth);
        $start = Carbon::create($previousMonth->year, $previousMonth->month, $startDay, 0, 0, 0, $reference->timezone);

        $endDay = min($cutoffDay - 1, $reference->daysInMonth);
        $end = Carbon::create($reference->year, $reference->month, $endDay, 23, 59, 59, $reference->timezone);

        return [$start, $end];
    }
}
