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

        $devices = FingerprintDevice::where('company_id', $tenant->id)
            ->with('officeLocation')
            ->withCount('userMappings')
            ->orderBy('name')
            ->paginate(15);

        $unmatchedCount = RawAttendanceLog::where('company_id', $tenant->id)
            ->where('status', 'unmatched')
            ->count();

        return view('fingerprint-devices.index', compact('devices', 'unmatchedCount'));
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
            ],
            'device_user_pin' => [
                'required',
                'string',
                'max:255',
                \Illuminate\Validation\Rule::unique('fingerprint_user_mappings', 'device_user_pin')
                    ->where('fingerprint_device_id', $fingerprintDevice->id),
            ],
        ], [
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
