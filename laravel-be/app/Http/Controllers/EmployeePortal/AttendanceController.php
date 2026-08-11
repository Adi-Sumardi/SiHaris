<?php

namespace App\Http\Controllers\EmployeePortal;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Employee;
use App\Services\AttendanceReconciliationService;
use App\Services\FaceRecognitionService;
use App\Services\GpsValidationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

class AttendanceController extends Controller
{
    public function __construct(
        protected GpsValidationService $gpsValidationService,
        protected AttendanceReconciliationService $reconciliationService,
        protected FaceRecognitionService $faceRecognitionService
    ) {}

    public function index(): View
    {
        $user = auth()->user();
        $company = $user->company;
        $employee = Employee::with(['faceEmbedding', 'company'])
            ->where('user_id', $user->id)
            ->firstOrFail();

        $today = $company->today();
        $todayAttendance = Attendance::where('employee_id', $employee->id)
            ->where('date', $today)
            ->first();

        // Check for active overnight shift from yesterday
        if (! $todayAttendance) {
            $todayAttendance = Attendance::where('employee_id', $employee->id)
                ->whereDate('date', $today->copy()->subDay())
                ->whereNotNull('clock_in')
                ->whereNull('clock_out')
                ->whereHas('workSchedule', fn ($q) => $q->where('is_overnight', true))
                ->first();
        }

        $attendanceHistory = Attendance::where('employee_id', $employee->id)
            ->orderBy('date', 'desc')
            ->paginate(15);

        // Face recognition data
        $faceRecognitionEnabled = $employee->company->enable_face_recognition ?? false;
        $hasFaceEnrolled = $employee->faceEmbedding && $employee->faceEmbedding->is_active;

        return view('portal.attendance', compact(
            'employee',
            'todayAttendance',
            'attendanceHistory',
            'faceRecognitionEnabled',
            'hasFaceEnrolled'
        ));
    }

    public function clockIn(Request $request): RedirectResponse
    {
        $user = auth()->user();
        $company = $user->company;
        $employee = Employee::with(['workSchedule', 'weeklySchedules.workSchedule'])->where('user_id', $user->id)->firstOrFail();

        $rules = $company->enable_gps_validation
            ? ['latitude' => 'required|numeric', 'longitude' => 'required|numeric']
            : ['latitude' => 'nullable|numeric', 'longitude' => 'nullable|numeric'];
        $request->validate($rules);

        $officeLocationId = null;
        if ($company->enable_gps_validation) {
            $gpsResult = $this->gpsValidationService->validateEmployeeLocation(
                $employee,
                $request->latitude,
                $request->longitude
            );

            if (! $gpsResult['valid']) {
                $message = match ($gpsResult['reason']) {
                    'no_assigned_offices' => 'Tidak ada lokasi kantor yang ditugaskan.',
                    'no_active_offices' => 'Tidak ada lokasi kantor aktif yang ditugaskan.',
                    'outside_radius' => 'Lokasi Anda terlalu jauh dari kantor. Absensi harus dilakukan di area kantor.',
                    default => 'Validasi lokasi gagal.',
                };

                return redirect()->route('portal.attendance.index')->with('error', $message);
            }

            $officeLocationId = $gpsResult['office_location_id'];
        }

        $result = $this->reconciliationService->record($employee, 'clock_in', $company->now(), 'web', [
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'office_location_id' => $officeLocationId,
            'ip' => $request->ip(),
        ]);

        if (in_array($result['status'], ['duplicate_ignored', 'duplicate_event'], true)) {
            return redirect()->route('portal.attendance.index')
                ->with('error', 'Anda sudah melakukan clock in hari ini.');
        }

        return redirect()->route('portal.attendance.index')
            ->with('success', 'Clock in berhasil dicatat.');
    }

    public function clockOut(Request $request): RedirectResponse
    {
        $user = auth()->user();
        $company = $user->company;
        $employee = Employee::where('user_id', $user->id)->firstOrFail();

        $today = $company->today();

        // Check today first, then yesterday for overnight shifts
        $attendance = Attendance::where('employee_id', $employee->id)
            ->whereNotNull('clock_in')
            ->whereNull('clock_out')
            ->where(function ($query) use ($today) {
                $query->whereDate('date', $today)
                    ->orWhereDate('date', $today->copy()->subDay());
            })
            ->orderBy('date', 'desc')
            ->first();

        if (! $attendance || ! $attendance->hasClockedIn()) {
            return redirect()->route('portal.attendance.index')
                ->with('error', 'Anda belum melakukan clock in.');
        }

        if ($attendance->hasClockedOut()) {
            return redirect()->route('portal.attendance.index')
                ->with('error', 'Anda sudah melakukan clock out hari ini.');
        }

        $rules = $company->enable_gps_validation
            ? ['latitude' => 'required|numeric', 'longitude' => 'required|numeric']
            : ['latitude' => 'nullable|numeric', 'longitude' => 'nullable|numeric'];
        $request->validate($rules);

        $officeLocationId = null;
        if ($company->enable_gps_validation) {
            $gpsResult = $this->gpsValidationService->validateEmployeeLocation(
                $employee,
                $request->latitude,
                $request->longitude
            );

            if (! $gpsResult['valid']) {
                $message = match ($gpsResult['reason']) {
                    'no_assigned_offices' => 'Tidak ada lokasi kantor yang ditugaskan.',
                    'no_active_offices' => 'Tidak ada lokasi kantor aktif yang ditugaskan.',
                    'outside_radius' => 'Lokasi Anda terlalu jauh dari kantor. Absensi harus dilakukan di area kantor.',
                    default => 'Validasi lokasi gagal.',
                };

                return redirect()->route('portal.attendance.index')->with('error', $message);
            }

            $officeLocationId = $gpsResult['office_location_id'];
        }

        $result = $this->reconciliationService->record($employee, 'clock_out', $company->now(), 'web', [
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'office_location_id' => $officeLocationId,
            'ip' => $request->ip(),
        ]);

        if (in_array($result['status'], ['duplicate_ignored', 'duplicate_event'], true)) {
            return redirect()->route('portal.attendance.index')
                ->with('error', 'Anda sudah melakukan clock out hari ini.');
        }

        return redirect()->route('portal.attendance.index')
            ->with('success', 'Clock out berhasil dicatat.');
    }

    public function faceRecognitionStatus(): JsonResponse
    {
        $user = auth()->user();
        $employee = Employee::with('faceEmbedding')
            ->where('user_id', $user->id)
            ->firstOrFail();

        $embedding = $employee->faceEmbedding;
        $isEnrolled = $embedding && $embedding->is_active;

        return response()->json([
            'enrolled' => $isEnrolled,
            'enrolled_at' => $isEnrolled ? $embedding->enrolled_at?->toIso8601String() : null,
        ]);
    }

    public function enrollFace(Request $request): RedirectResponse
    {
        $user = auth()->user();
        $employee = Employee::with('faceEmbedding')
            ->where('user_id', $user->id)
            ->firstOrFail();

        // 1-time rule: If already enrolled, lock self-registration
        if ($employee->faceEmbedding && $employee->faceEmbedding->is_active) {
            return redirect()->route('portal.attendance.index')
                ->with('error', 'Wajah Anda sudah terdaftar dan dikunci. Untuk mengganti foto wajah, silakan hubungi Admin / HR.');
        }

        $request->validate([
            'photo' => ['required_without:photo_base64', 'nullable', 'image', 'max:5120'],
            'photo_base64' => ['required_without:photo', 'nullable', 'string'],
        ]);

        $tenant = $user->company;

        if ($request->filled('photo_base64')) {
            $base64Data = $request->input('photo_base64');
            if (preg_match('/^data:image\/(\w+);base64,/', $base64Data, $type)) {
                $data = substr($base64Data, strpos($base64Data, ',') + 1);
                $ext = strtolower($type[1]);
                if ($ext === 'jpeg') $ext = 'jpg';
                $data = base64_decode($data);

                if ($data === false) {
                    return redirect()->route('portal.attendance.index')->with('error', 'Foto webcam tidak dapat diproses.');
                }

                $filename = 'face-enrollments/' . $tenant->id . '/' . uniqid('face_') . '.' . $ext;
                Storage::disk('public')->put($filename, $data);
                $photoPath = $filename;
            } else {
                return redirect()->route('portal.attendance.index')->with('error', 'Format foto webcam tidak valid.');
            }
        } else {
            $photoPath = $request->file('photo')->store(
                "face-enrollments/{$tenant->id}",
                'public'
            );
        }

        $this->faceRecognitionService->enrollFace(
            $employee,
            [],
            $photoPath,
            $user
        );

        return redirect()->route('portal.attendance.index')
            ->with('success', 'Wajah Anda berhasil didaftarkan! Pendaftaran mandiri telah dikunci.');
    }
}
