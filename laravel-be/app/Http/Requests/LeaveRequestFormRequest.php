<?php

namespace App\Http\Requests;

use App\Models\Employee;
use App\Models\LeaveBalance;
use App\Models\LeaveType;
use App\Services\LeaveDayCalculatorService;
use Carbon\Carbon;
use Illuminate\Foundation\Http\FormRequest;

class LeaveRequestFormRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'employee_id' => ['required', 'exists:employees,id'],
            'leave_type_id' => ['required', 'exists:leave_types,id'],
            'start_date' => ['required', 'date'],
            'end_date' => ['required', 'date', 'after_or_equal:start_date'],
            'is_half_day' => ['nullable', 'boolean'],
            'half_day_type' => ['required_if:is_half_day,true', 'nullable', 'in:morning,afternoon'],
            'reason' => ['required', 'string', 'max:1000'],
            'attachment' => ['nullable', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:10240'],
            'emergency_contact' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'employee_id.required' => 'Karyawan wajib dipilih.',
            'leave_type_id.required' => 'Jenis cuti wajib dipilih.',
            'start_date.required' => 'Tanggal mulai wajib diisi.',
            'end_date.required' => 'Tanggal selesai wajib diisi.',
            'end_date.after_or_equal' => 'Tanggal selesai harus sama atau setelah tanggal mulai.',
            'half_day_type.required_if' => 'Tipe setengah hari wajib dipilih.',
            'reason.required' => 'Alasan cuti wajib diisi.',
        ];
    }

    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            if ($validator->errors()->any()) {
                return;
            }

            $this->validateLeaveBalance($validator);
        });
    }

    protected function validateLeaveBalance($validator)
    {
        $startDate = $this->input('start_date');
        $endDate = $this->input('end_date');
        $isHalfDay = $this->boolean('is_half_day');

        $employee = Employee::where('company_id', auth()->user()->company_id)
            ->find($this->input('employee_id'));

        if (! $employee) {
            // employee_id already failed the 'exists' rule above and
            // short-circuited before this runs; this is just a safety net.
            return;
        }

        $leaveType = LeaveType::find($this->input('leave_type_id'));

        // Use the same day-count LeaveRequestController::store()/update()
        // actually deduct from the balance (excludes weekends and active
        // company holidays, unless the leave type is entitled by calendar
        // days — e.g. statutory maternity leave) — previously this used a
        // naive calendar-day diff, so a long date range could be wrongly
        // rejected as "insufficient balance" even though the real
        // deduction would have easily fit.
        $totalDays = app(LeaveDayCalculatorService::class)->calculate(
            $employee,
            Carbon::parse($startDate),
            Carbon::parse($endDate),
            $isHalfDay,
            (bool) $leaveType?->count_calendar_days
        );

        $year = (new \DateTime($startDate))->format('Y');

        $balance = LeaveBalance::where('employee_id', $this->input('employee_id'))
            ->where('leave_type_id', $this->input('leave_type_id'))
            ->where('year', $year)
            ->first();

        if (! $balance) {
            $validator->errors()->add('leave_type_id', 'Tidak ada saldo cuti untuk jenis cuti ini di tahun '.$year);

            return;
        }

        if (! $balance->hasEnoughBalance($totalDays)) {
            $validator->errors()->add('leave_type_id', 'Saldo cuti tidak mencukupi. Tersedia: '.$balance->remaining_days.' hari');
        }
    }
}
