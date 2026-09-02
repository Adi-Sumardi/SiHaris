<?php

namespace App\Http\Controllers;

use App\Models\Department;
use App\Models\Employee;
use App\Models\EmployeeWeeklySchedule;
use App\Models\OfficeLocation;
use App\Models\Position;
use App\Models\User;
use App\Models\WorkSchedule;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class EmployeeController extends Controller
{
    public function index(Request $request): View
    {
        $tenant = app('tenant');

        $query = Employee::with(['department', 'position'])
            ->where('company_id', $tenant->id);

        // Filter by department
        if ($request->filled('department_id')) {
            $query->where('department_id', $request->department_id);
        }

        // Filter by employment status
        if ($request->filled('employment_status')) {
            $query->where('employment_status', $request->employment_status);
        }

        // Filter by employment type (YPI / YAPI)
        if ($request->filled('employment_type')) {
            $query->where('employment_type', $request->employment_type);
        }

        // Filter by active status
        if ($request->filled('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        // Search by name, employee_id, pin, nik, or email
        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                    ->orWhere('last_name', 'like', "%{$search}%")
                    ->orWhere('employee_id', 'like', "%{$search}%")
                    ->orWhere('pin', 'like', "%{$search}%")
                    ->orWhere('nik', 'like', "%{$search}%")
                    ->orWhere('identity_number', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhereRaw("CONCAT(first_name, ' ', COALESCE(last_name, '')) LIKE ?", ["%{$search}%"]);
            });
        }

        $employees = $query->orderBy('first_name')->paginate(15)->withQueryString();

        $departments = Department::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        return view('employees.index', compact('employees', 'departments'));
    }

    public function create(): View
    {
        $tenant = app('tenant');

        $departments = Department::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $positions = Position::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $officeLocations = OfficeLocation::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $workSchedules = WorkSchedule::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $managers = Employee::where('company_id', $tenant->id)
            ->active()
            ->orderBy('first_name')
            ->get();

        return view('employees.create', compact('departments', 'positions', 'officeLocations', 'workSchedules', 'managers'));
    }

    public function store(Request $request): RedirectResponse
    {
        $tenant = app('tenant');

        $validated = $request->validate([
            'employee_id' => [
                'nullable',
                'string',
                'max:50',
                Rule::unique('employees', 'employee_id')->where('company_id', $tenant->id),
            ],
            'pin' => ['nullable', 'string', 'max:50'],
            'nik' => ['nullable', 'string', 'max:50'],
            'identity_number' => ['nullable', 'string', 'max:50'],
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:20'],
            'department_id' => ['required', 'exists:departments,id'],
            'position_id' => ['required', 'exists:positions,id'],
            'manager_id' => ['nullable', Rule::exists('employees', 'id')->where('company_id', $tenant->id)],
            'hire_date' => ['required', 'date'],
            'employment_status' => ['required', 'in:permanent,contract,probation,intern'],
            'employment_type' => ['nullable', 'string', 'max:50', Rule::in(['YPI Al Azhar', 'YPI', 'YAPI'])],
            'work_schedule_id' => ['nullable', Rule::exists('work_schedules', 'id')->where('company_id', $tenant->id)],
            'schedule_mode' => ['nullable', 'in:default,weekly'],
            'weekly_schedules' => ['nullable', 'array'],
            'weekly_schedules.*' => ['nullable', Rule::exists('work_schedules', 'id')->where('company_id', $tenant->id)],
            'gender' => ['nullable', 'in:male,female'],
            'date_of_birth' => ['nullable', 'date'],
            'marital_status' => ['nullable', 'in:single,married,divorced,widowed'],
            'religion' => ['nullable', 'string', 'max:50'],
            'blood_type' => ['nullable', 'string', 'max:10'],
            'identity_address' => ['nullable', 'string'],
            'address' => ['nullable', 'string'],
            'city' => ['nullable', 'string', 'max:100'],
            'province' => ['nullable', 'string', 'max:100'],
            'postal_code' => ['nullable', 'string', 'max:10'],
            'emergency_contact_name' => ['nullable', 'string', 'max:255'],
            'emergency_contact_phone' => ['nullable', 'string', 'max:20'],
            'emergency_contact_relationship' => ['nullable', 'string', 'max:50'],
            'base_salary' => ['nullable', 'numeric', 'min:0'],
            'bank_name' => ['nullable', 'string', 'max:100'],
            'bank_account_number' => ['nullable', 'string', 'max:50'],
            'bank_account_name' => ['nullable', 'string', 'max:255'],
            'npwp' => ['nullable', 'string', 'max:30'],
            'tax_status' => ['nullable', 'string', 'max:10'],
            'bpjs_kesehatan' => ['nullable', 'string', 'max:20'],
            'bpjs_ketenagakerjaan' => ['nullable', 'string', 'max:20'],
            'contract_start_date' => ['nullable', 'date'],
            'contract_end_date' => ['nullable', 'date', 'after:contract_start_date'],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
            'photo' => ['nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:2048'],
            'office_location_ids' => ['nullable', 'array'],
            'office_location_ids.*' => ['exists:office_locations,id'],
            'primary_office_id' => ['nullable', 'exists:office_locations,id'],
        ], [
            'employee_id.unique' => 'NIP / ID Karyawan sudah terdaftar di sistem.',
            'first_name.required' => 'Nama depan wajib diisi.',
            'email.unique' => 'Email ini sudah terdaftar sebagai akun pengguna.',
            'department_id.required' => 'Departemen wajib dipilih.',
            'position_id.required' => 'Jabatan wajib dipilih.',
            'hire_date.required' => 'Tanggal bergabung wajib diisi.',
            'employment_status.required' => 'Status kerja wajib dipilih.',
            'password.min' => 'Password minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password tidak sesuai.',
            'photo.max' => 'Ukuran foto maksimal 2MB.',
        ]);

        $validated['company_id'] = $tenant->id;

        // Handle photo upload
        if ($request->hasFile('photo')) {
            $validated['photo'] = $request->file('photo')->store('employees/'.$tenant->id, 'public');
        }

        // If weekly mode, clear work_schedule_id
        $scheduleMode = $request->input('schedule_mode', 'default');
        $weeklySchedules = $request->input('weekly_schedules', []);

        if ($scheduleMode === 'weekly') {
            $validated['work_schedule_id'] = null;
        }

        try {
            DB::transaction(function () use ($validated, $tenant, $request, $scheduleMode, $weeklySchedules) {
                $user = null;

                // Create user account if password is provided and email exists
                if (! empty($validated['password']) && ! empty($validated['email'])) {
                    $fullName = trim($validated['first_name'].' '.($validated['last_name'] ?? ''));

                    setPermissionsTeamId($tenant->id);

                    $user = User::create([
                        'company_id' => $tenant->id,
                        'name' => $fullName,
                        'email' => $validated['email'],
                        'phone' => $validated['phone'] ?? null,
                        'password' => Hash::make($validated['password']),
                        'is_active' => true,
                    ]);

                    // Assign employee role
                    $user->assignRole('employee');
                }

                // Remove non-employee fields
                unset($validated['password'], $validated['office_location_ids'], $validated['primary_office_id'], $validated['schedule_mode'], $validated['weekly_schedules']);

                // Create employee with user_id if user was created
                $employeeData = $validated;
                if ($user) {
                    $employeeData['user_id'] = $user->id;
                }

                $employee = Employee::create($employeeData);

                // Sync weekly schedules
                if ($scheduleMode === 'weekly') {
                    $this->syncWeeklySchedules($employee, $weeklySchedules, $tenant->id);
                }

                // Attach office locations
                $officeIds = $request->input('office_location_ids', []);
                $primaryOfficeId = (int) $request->input('primary_office_id');

                if (! empty($officeIds)) {
                    $syncData = [];
                    foreach ($officeIds as $officeId) {
                        $syncData[(int) $officeId] = ['is_primary' => (int) $officeId === $primaryOfficeId];
                    }
                    $employee->officeLocations()->attach($syncData);
                }
            });

            return redirect()->route('employees.index')
                ->with('success', 'Karyawan berhasil ditambahkan.');
        } catch (\Exception $e) {
            \Log::error('Error creating employee: '.$e->getMessage(), [
                'company_id' => $tenant->id,
                'request' => $request->except(['password', 'password_confirmation', 'photo']),
                'trace' => $e->getTraceAsString(),
            ]);

            return redirect()->back()
                ->withInput()
                ->with('error', 'Gagal menambahkan karyawan: '.$e->getMessage());
        }
    }

    public function show(Employee $employee): View
    {
        $tenant = app('tenant');

        if ($employee->company_id !== $tenant->id) {
            abort(404);
        }

        $employee->load([
            'department',
            'position',
            'user',
            'faceEmbedding',
            'workSchedule',
            'weeklySchedules.workSchedule',
            'currentSalary.components.salaryComponent',
        ]);

        return view('employees.show', compact('employee'));
    }

    public function edit(Employee $employee): View
    {
        $tenant = app('tenant');

        if ($employee->company_id !== $tenant->id) {
            abort(404);
        }

        $employee->load(['officeLocations', 'weeklySchedules', 'user']);

        $departments = Department::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $positions = Position::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $officeLocations = OfficeLocation::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $workSchedules = WorkSchedule::where('company_id', $tenant->id)
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        $managers = Employee::where('company_id', $tenant->id)
            ->where('id', '!=', $employee->id)
            ->active()
            ->orderBy('first_name')
            ->get();

        $weeklyScheduleMap = $employee->weeklySchedules->pluck('work_schedule_id', 'day_of_week');

        return view('employees.edit', compact('employee', 'departments', 'positions', 'officeLocations', 'workSchedules', 'weeklyScheduleMap', 'managers'));
    }

    public function update(Request $request, Employee $employee): RedirectResponse
    {
        $tenant = app('tenant');

        if ($employee->company_id !== $tenant->id) {
            abort(404);
        }

        // Build email validation rule - ignore current user's email if exists
        $emailRule = ['nullable', 'email', 'max:255'];
        if ($employee->user_id) {
            $emailRule[] = 'unique:users,email,'.$employee->user_id;
        } else {
            $emailRule[] = 'unique:users,email';
        }

        $validated = $request->validate([
            'employee_id' => [
                'nullable',
                'string',
                'max:50',
                Rule::unique('employees', 'employee_id')->where('company_id', $tenant->id)->ignore($employee->id),
            ],
            'pin' => ['nullable', 'string', 'max:50'],
            'nik' => ['nullable', 'string', 'max:50'],
            'identity_number' => ['nullable', 'string', 'max:50'],
            'first_name' => ['required', 'string', 'max:255'],
            'last_name' => ['nullable', 'string', 'max:255'],
            'email' => $emailRule,
            'phone' => ['nullable', 'string', 'max:20'],
            'department_id' => ['required', 'exists:departments,id'],
            'position_id' => ['required', 'exists:positions,id'],
            'manager_id' => ['nullable', Rule::exists('employees', 'id')->where('company_id', $tenant->id)->whereNot('id', $employee->id)],
            'hire_date' => ['required', 'date'],
            'resignation_date' => ['nullable', 'date'],
            'employment_status' => ['required', 'in:permanent,contract,probation,intern'],
            'employment_type' => ['nullable', 'string', 'max:50', Rule::in(['YPI Al Azhar', 'YPI', 'YAPI'])],
            'work_schedule_id' => ['nullable', Rule::exists('work_schedules', 'id')->where('company_id', $tenant->id)],
            'schedule_mode' => ['nullable', 'in:default,weekly'],
            'weekly_schedules' => ['nullable', 'array'],
            'weekly_schedules.*' => ['nullable', Rule::exists('work_schedules', 'id')->where('company_id', $tenant->id)],
            'gender' => ['nullable', 'in:male,female'],
            'date_of_birth' => ['nullable', 'date'],
            'marital_status' => ['nullable', 'in:single,married,divorced,widowed'],
            'religion' => ['nullable', 'string', 'max:50'],
            'blood_type' => ['nullable', 'string', 'max:10'],
            'identity_address' => ['nullable', 'string'],
            'address' => ['nullable', 'string'],
            'city' => ['nullable', 'string', 'max:100'],
            'province' => ['nullable', 'string', 'max:100'],
            'postal_code' => ['nullable', 'string', 'max:10'],
            'emergency_contact_name' => ['nullable', 'string', 'max:255'],
            'emergency_contact_phone' => ['nullable', 'string', 'max:20'],
            'emergency_contact_relationship' => ['nullable', 'string', 'max:50'],
            'base_salary' => ['nullable', 'numeric', 'min:0'],
            'bank_name' => ['nullable', 'string', 'max:100'],
            'bank_account_number' => ['nullable', 'string', 'max:50'],
            'bank_account_name' => ['nullable', 'string', 'max:255'],
            'npwp' => ['nullable', 'string', 'max:30'],
            'tax_status' => ['nullable', 'string', 'max:10'],
            'bpjs_kesehatan' => ['nullable', 'string', 'max:20'],
            'bpjs_ketenagakerjaan' => ['nullable', 'string', 'max:20'],
            'contract_start_date' => ['nullable', 'date'],
            'contract_end_date' => ['nullable', 'date', 'after:contract_start_date'],
            'is_active' => ['nullable', 'boolean'],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
            'photo' => ['nullable', 'image', 'mimes:jpeg,png,jpg,webp', 'max:2048'],
            'office_location_ids' => ['nullable', 'array'],
            'office_location_ids.*' => ['exists:office_locations,id'],
            'primary_office_id' => ['nullable', 'exists:office_locations,id'],
        ], [
            'employee_id.unique' => 'NIP / ID Karyawan sudah terdaftar di sistem.',
            'first_name.required' => 'Nama depan wajib diisi.',
            'email.unique' => 'Email ini sudah terdaftar sebagai akun pengguna.',
            'department_id.required' => 'Departemen wajib dipilih.',
            'position_id.required' => 'Jabatan wajib dipilih.',
            'hire_date.required' => 'Tanggal bergabung wajib diisi.',
            'employment_status.required' => 'Status kerja wajib dipilih.',
            'password.min' => 'Password minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password tidak sesuai.',
            'photo.max' => 'Ukuran foto maksimal 2MB.',
        ]);

        // Handle photo upload
        if ($request->hasFile('photo')) {
            $validated['photo'] = $request->file('photo')->store('employees/'.$tenant->id, 'public');
        }

        $scheduleMode = $request->input('schedule_mode', 'default');
        $weeklySchedules = $request->input('weekly_schedules', []);

        if ($scheduleMode === 'weekly') {
            $validated['work_schedule_id'] = null;
        }

        try {
            DB::transaction(function () use ($validated, $employee, $tenant, $request, $scheduleMode, $weeklySchedules) {
                $fullName = trim($validated['first_name'].' '.($validated['last_name'] ?? ''));

                // Handle user account
                if ($employee->user) {
                    // Update existing user
                    $userData = ['name' => $fullName];

                    if (! empty($validated['email'])) {
                        $userData['email'] = $validated['email'];
                    }

                    if (isset($validated['phone'])) {
                        $userData['phone'] = $validated['phone'];
                    }

                    if (! empty($validated['password'])) {
                        $userData['password'] = Hash::make($validated['password']);
                    }

                    $employee->user->update($userData);
                } elseif (! empty($validated['password']) && ! empty($validated['email'])) {
                    // Create new user account
                    setPermissionsTeamId($tenant->id);

                    $user = User::create([
                        'company_id' => $tenant->id,
                        'name' => $fullName,
                        'email' => $validated['email'],
                        'phone' => $validated['phone'] ?? null,
                        'password' => Hash::make($validated['password']),
                        'is_active' => true,
                    ]);

                    $user->assignRole('employee');
                    $validated['user_id'] = $user->id;
                }

                // Remove non-employee fields
                unset($validated['password'], $validated['office_location_ids'], $validated['primary_office_id'], $validated['schedule_mode'], $validated['weekly_schedules']);

                $employee->update($validated);

                // Sync weekly schedules
                if ($scheduleMode === 'weekly') {
                    $this->syncWeeklySchedules($employee, $weeklySchedules, $tenant->id);
                } else {
                    // Clear weekly schedules when switching to default mode
                    $employee->weeklySchedules()->delete();
                }

                // Sync office locations
                $officeIds = $request->input('office_location_ids', []);
                $primaryOfficeId = (int) $request->input('primary_office_id');

                if (! empty($officeIds)) {
                    $syncData = [];
                    foreach ($officeIds as $officeId) {
                        $syncData[(int) $officeId] = ['is_primary' => (int) $officeId === $primaryOfficeId];
                    }
                    $employee->officeLocations()->sync($syncData);
                } else {
                    $employee->officeLocations()->detach();
                }
            });

            return redirect()->route('employees.show', $employee)
                ->with('success', 'Data karyawan berhasil diperbarui.');
        } catch (\Exception $e) {
            \Log::error('Error updating employee: '.$e->getMessage(), [
                'employee_id' => $employee->id,
                'company_id' => $tenant->id,
                'request' => $request->except(['password', 'password_confirmation', 'photo']),
                'trace' => $e->getTraceAsString(),
            ]);

            return redirect()->back()
                ->withInput()
                ->with('error', 'Gagal memperbarui data karyawan: '.$e->getMessage());
        }
    }

    public function destroy(Employee $employee): RedirectResponse
    {
        $tenant = app('tenant');

        if ($employee->company_id !== $tenant->id) {
            abort(404);
        }

        // Prevent deletion of demo employees
        if ($employee->isDemoEmployee()) {
            return redirect()->route('employees.index')
                ->with('error', 'Data karyawan demo tidak dapat dihapus. Ini adalah data contoh untuk demonstrasi sistem.');
        }

        $employee->delete();

        return redirect()->route('employees.index')
            ->with('success', 'Karyawan berhasil dihapus.');
    }

    public function showResetPasswordForm(Employee $employee): View
    {
        $tenant = app('tenant');

        if ($employee->company_id !== $tenant->id) {
            abort(404);
        }

        return view('employees.reset-password', compact('employee'));
    }

    public function resetPassword(Request $request, Employee $employee): RedirectResponse
    {
        $tenant = app('tenant');

        if ($employee->company_id !== $tenant->id) {
            abort(404);
        }

        if (! $employee->user) {
            return redirect()->route('employees.show', $employee)
                ->with('error', 'Karyawan ini tidak memiliki akun pengguna.');
        }

        if ($employee->user->isDemoAccount()) {
            return redirect()->route('employees.show', $employee)
                ->with('error', 'Password akun demo tidak dapat diubah.');
        }

        $request->validate([
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ], [
            'password.required' => 'Password wajib diisi.',
            'password.min' => 'Password minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password tidak sesuai.',
        ]);

        $employee->user->update([
            'password' => Hash::make($request->password),
        ]);

        return redirect()->route('employees.show', $employee)
            ->with('success', 'Password berhasil direset.');
    }

    public function generatePassword(Employee $employee): RedirectResponse
    {
        $tenant = app('tenant');

        if ($employee->company_id !== $tenant->id) {
            abort(404);
        }

        if (! $employee->user) {
            return redirect()->route('employees.show', $employee)
                ->with('error', 'Karyawan ini tidak memiliki akun pengguna.');
        }

        if ($employee->user->isDemoAccount()) {
            return redirect()->route('employees.show', $employee)
                ->with('error', 'Password akun demo tidak dapat diubah.');
        }

        $newPassword = \Illuminate\Support\Str::random(12);

        $employee->user->update([
            'password' => Hash::make($newPassword),
        ]);

        return redirect()->route('employees.show', $employee)
            ->with('success', 'Password berhasil di-generate.')
            ->with('generated_password', $newPassword);
    }

    private function syncWeeklySchedules(Employee $employee, array $weeklySchedules, int $companyId): void
    {
        $employee->weeklySchedules()->delete();

        foreach ($weeklySchedules as $dayOfWeek => $scheduleId) {
            if (! empty($scheduleId)) {
                EmployeeWeeklySchedule::create([
                    'company_id' => $companyId,
                    'employee_id' => $employee->id,
                    'day_of_week' => (int) $dayOfWeek,
                    'work_schedule_id' => (int) $scheduleId,
                ]);
            }
        }
    }

    public function updateEmploymentType(Request $request, Employee $employee): \Illuminate\Http\JsonResponse
    {
        $tenant = app('tenant');

        if ($employee->company_id !== $tenant->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'employment_type' => ['nullable', 'string', 'max:50', Rule::in(['YPI Al Azhar', 'YPI', 'YAPI', ''])],
        ]);

        $type = ! empty($validated['employment_type']) ? $validated['employment_type'] : null;
        if ($type === 'YPI') {
            $type = 'YPI Al Azhar';
        }

        $employee->update([
            'employment_type' => $type,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Status kepegawaian berhasil diperbarui.',
            'employment_type' => $employee->employment_type,
        ]);
    }

    public function bulkUpdateEmploymentType(Request $request): \Illuminate\Http\JsonResponse
    {
        $tenant = app('tenant');

        $validated = $request->validate([
            'employee_ids' => ['required', 'array', 'min:1'],
            'employee_ids.*' => ['required', Rule::exists('employees', 'id')->where('company_id', $tenant->id)],
            'employment_type' => ['nullable', 'string', 'max:50', Rule::in(['YPI Al Azhar', 'YPI', 'YAPI', ''])],
        ]);

        $type = ! empty($validated['employment_type']) ? $validated['employment_type'] : null;
        if ($type === 'YPI') {
            $type = 'YPI Al Azhar';
        }

        $updatedCount = Employee::where('company_id', $tenant->id)
            ->whereIn('id', $validated['employee_ids'])
            ->update([
                'employment_type' => $type,
            ]);

        $label = $type ?: 'Belum Diatur';

        return response()->json([
            'success' => true,
            'count' => $updatedCount,
            'employment_type' => $type,
            'message' => "Berhasil memperbarui status kepegawaian {$updatedCount} karyawan menjadi {$label}.",
        ]);
    }
}
