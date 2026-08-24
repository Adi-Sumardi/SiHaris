<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreFingerprintDeviceRequest;
use App\Http\Requests\UpdateFingerprintDeviceRequest;
use App\Models\Employee;
use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Models\RawAttendanceLog;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\View\View;

class FingerprintDeviceController extends Controller
{
    public function index(): View
    {
        $tenant = app('tenant');

        // Auto-create ADMS Cloud machine device if missing
        $admsDevice = FingerprintDevice::firstOrCreate(
            [
                'company_id' => $tenant->id,
                'serial_number' => 'ADMS-FACE-APP',
            ],
            [
                'name' => 'ADMS Face & Fingerprint Server (Cloud)',
                'brand' => 'solution',
                'is_active' => true,
                'ip_address' => 'adms.alazhar-rm.com',
                'port' => 80,
                'last_sync_at' => now(),
            ]
        );

        // If no user mappings exist yet, run initial sync with ADMS API
        if ($admsDevice->userMappings()->count() === 0) {
            try {
                \App\Jobs\SyncAdmsEmployeesJob::dispatchSync($tenant->id);
            } catch (\Throwable $e) {
                // Keep page rendering gracefully even if remote API is transiently unreachable
            }
        }

        $devices = FingerprintDevice::where('company_id', $tenant->id)
            ->with('officeLocation')
            ->withCount('userMappings')
            ->orderBy('name')
            ->paginate(15);

        $unmatchedCount = RawAttendanceLog::where('company_id', $tenant->id)
            ->where('status', 'unmatched')
            ->count();

        $admsService = app(\App\Services\AdmsApiService::class);
        $admsHealthy = $admsService->checkHealth();

        return view('fingerprint-devices.index', compact('devices', 'unmatchedCount', 'admsHealthy'));
    }

    public function syncAdms(): RedirectResponse
    {
        $tenant = app('tenant');

        try {
            \App\Jobs\SyncAdmsEmployeesJob::dispatchSync($tenant->id);

            return redirect()->route('fingerprint-devices.index')
                ->with('success', 'Berhasil menyinkronkan data pegawai & PIN dari API ADMS Cloud.');
        } catch (\Throwable $e) {
            return redirect()->route('fingerprint-devices.index')
                ->with('error', 'Gagal menyinkronkan data ADMS: '.$e->getMessage());
        }
    }

    public function syncAttendance(Request $request): RedirectResponse
    {
        $tenant = app('tenant');
        $date = $request->input('date', date('Y-m-d'));

        try {
            $admsService = app(\App\Services\AdmsApiService::class);
            $reconciliationService = app(\App\Services\AttendanceReconciliationService::class);
            $job = new \App\Jobs\SyncAdmsAttendanceJob($tenant->id, $date);
            $result = $job->handle($admsService, $reconciliationService);

            return redirect()->back()
                ->with('success', "Sinkronisasi presensi ADMS berhasil. ({$result['applied']} log kehadiran diterapkan dari {$result['total']} data ADMS)");
        } catch (\Throwable $e) {
            return redirect()->back()
                ->with('error', 'Gagal menyinkronkan presensi ADMS: '.$e->getMessage());
        }
    }

    public function create(): View
    {
        $tenant = app('tenant');
        $officeLocations = \App\Models\OfficeLocation::where('company_id', $tenant->id)->orderBy('name')->get();

        return view('fingerprint-devices.create', compact('officeLocations'));
    }

    public function store(StoreFingerprintDeviceRequest $request): RedirectResponse
    {
        $tenant = app('tenant');

        $device = FingerprintDevice::create([
            'company_id' => $tenant->id,
            'webhook_secret' => Str::random(40),
            ...$request->validated(),
        ]);

        return redirect()->route('fingerprint-devices.show', $device)
            ->with('success', 'Mesin fingerprint berhasil ditambahkan.')
            ->with('reveal_secret', $device->webhook_secret);
    }

    public function show(FingerprintDevice $fingerprintDevice): View
    {
        $tenant = app('tenant');

        if ($fingerprintDevice->company_id !== $tenant->id) {
            abort(404);
        }

        $mappings = $fingerprintDevice->userMappings()->with('employee')->get();

        $mappedEmployeeIds = $mappings->pluck('employee_id');
        $availableEmployees = Employee::where('company_id', $tenant->id)
            ->whereNotIn('id', $mappedEmployeeIds)
            ->where('is_active', true)
            ->orderBy('first_name')
            ->get();

        $unmatchedLogs = RawAttendanceLog::where('fingerprint_device_id', $fingerprintDevice->id)
            ->where('status', 'unmatched')
            ->latest('event_time')
            ->limit(20)
            ->get();

        return view('fingerprint-devices.show', compact(
            'fingerprintDevice',
            'mappings',
            'availableEmployees',
            'unmatchedLogs'
        ));
    }

    public function edit(FingerprintDevice $fingerprintDevice): View
    {
        $tenant = app('tenant');

        if ($fingerprintDevice->company_id !== $tenant->id) {
            abort(404);
        }

        $officeLocations = \App\Models\OfficeLocation::where('company_id', $tenant->id)->orderBy('name')->get();

        return view('fingerprint-devices.edit', compact('fingerprintDevice', 'officeLocations'));
    }

    public function update(UpdateFingerprintDeviceRequest $request, FingerprintDevice $fingerprintDevice): RedirectResponse
    {
        $tenant = app('tenant');

        if ($fingerprintDevice->company_id !== $tenant->id) {
            abort(404);
        }

        $fingerprintDevice->update($request->validated());

        return redirect()->route('fingerprint-devices.index')
            ->with('success', 'Mesin fingerprint berhasil diperbarui.');
    }

    public function destroy(FingerprintDevice $fingerprintDevice): RedirectResponse
    {
        $tenant = app('tenant');

        if ($fingerprintDevice->company_id !== $tenant->id) {
            abort(404);
        }

        $fingerprintDevice->delete();

        return redirect()->route('fingerprint-devices.index')
            ->with('success', 'Mesin fingerprint berhasil dihapus.');
    }

    public function regenerateSecret(FingerprintDevice $fingerprintDevice): RedirectResponse
    {
        $tenant = app('tenant');

        if ($fingerprintDevice->company_id !== $tenant->id) {
            abort(404);
        }

        $fingerprintDevice->update(['webhook_secret' => Str::random(40)]);

        return redirect()->route('fingerprint-devices.show', $fingerprintDevice)
            ->with('success', 'Webhook secret berhasil diperbarui. Update konfigurasi agen di lokasi.')
            ->with('reveal_secret', $fingerprintDevice->webhook_secret);
    }

    public function addMapping(Request $request, FingerprintDevice $fingerprintDevice): RedirectResponse
    {
        $tenant = app('tenant');

        if ($fingerprintDevice->company_id !== $tenant->id) {
            abort(404);
        }

        $request->validate([
            'employee_id' => [
                'required',
                \Illuminate\Validation\Rule::exists('employees', 'id')->where('company_id', $tenant->id),
                \Illuminate\Validation\Rule::unique('fingerprint_user_mappings', 'employee_id')
                    ->where('fingerprint_device_id', $fingerprintDevice->id),
            ],
            'device_user_pin' => [
                'required',
                'string',
                'max:255',
                \Illuminate\Validation\Rule::unique('fingerprint_user_mappings', 'device_user_pin')
                    ->where('fingerprint_device_id', $fingerprintDevice->id),
            ],
        ], [
            'employee_id.unique' => 'Karyawan ini sudah memiliki pemetaan PIN di mesin ini.',
            'device_user_pin.unique' => 'PIN ini sudah dipetakan ke karyawan lain di mesin ini.',
        ]);

        FingerprintUserMapping::create([
            'fingerprint_device_id' => $fingerprintDevice->id,
            'employee_id' => $request->employee_id,
            'device_user_pin' => $request->device_user_pin,
        ]);

        return redirect()->route('fingerprint-devices.show', $fingerprintDevice)
            ->with('success', 'Pemetaan PIN karyawan berhasil ditambahkan.');
    }

    public function removeMapping(FingerprintDevice $fingerprintDevice, FingerprintUserMapping $mapping): RedirectResponse
    {
        $tenant = app('tenant');

        if ($fingerprintDevice->company_id !== $tenant->id || $mapping->fingerprint_device_id !== $fingerprintDevice->id) {
            abort(404);
        }

        $mapping->delete();

        return redirect()->route('fingerprint-devices.show', $fingerprintDevice)
            ->with('success', 'Pemetaan PIN karyawan berhasil dihapus.');
    }
}
