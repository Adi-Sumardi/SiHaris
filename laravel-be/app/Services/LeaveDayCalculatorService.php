<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\Holiday;
use Carbon\Carbon;

/**
 * Counts the number of leave days between two dates, excluding weekends
 * and company holidays according to the employee's own work schedule.
 *
 * Some leave types (e.g. statutory maternity leave, which Indonesian
 * labor law grants as a fixed 90 CALENDAR-day period) are entitled and
 * deducted by calendar days instead — pass $countCalendarDays for those,
 * driven by LeaveType::count_calendar_days.
 */
class LeaveDayCalculatorService
{
    public function calculate(Employee $employee, Carbon $startDate, Carbon $endDate, bool $isHalfDay = false, bool $countCalendarDays = false): float
    {
        if ($isHalfDay) {
            return 0.5;
        }

        if ($countCalendarDays) {
            return (float) $startDate->copy()->startOfDay()->diffInDays($endDate->copy()->startOfDay()) + 1;
        }

        $holidayDates = Holiday::where('company_id', $employee->company_id)
            ->where('is_active', true)
            ->whereBetween('date', [$startDate->copy()->startOfDay(), $endDate->copy()->endOfDay()])
            ->pluck('date')
            ->map(fn ($date) => Carbon::parse($date)->toDateString())
            ->flip();

        $hasSchedule = (bool) $employee->workSchedule || $employee->hasWeeklySchedulePattern();

        $days = 0;
        $current = $startDate->copy();

        while ($current->lte($endDate)) {
            if (! $holidayDates->has($current->toDateString())) {
                $isWorkingDay = $hasSchedule
                    ? (bool) $employee->resolveScheduleForDate($current)
                    : $current->isWeekday();

                if ($isWorkingDay) {
                    $days++;
                }
            }

            $current->addDay();
        }

        return (float) $days;
    }
}
