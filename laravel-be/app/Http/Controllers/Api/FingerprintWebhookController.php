<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FingerprintDevice;
use App\Models\FingerprintUserMapping;
use App\Services\AttendanceReconciliationService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FingerprintWebhookController extends Controller
{
    public function __construct(
        protected AttendanceReconciliationService $reconciliationService
    ) {}

    /**
     * Ingest attendance logs pushed by an on-premise fingerprint agent
     * (e.g. Solution X100C via a local pull agent).
     *
     * Body: { device_serial, logs: [ {pin, type, timestamp}, ... ] }
     * Header: X-Device-Signature = HMAC-SHA256(raw body, device.webhook_secret)
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'device_serial' => 'required|string',
            'logs' => 'required|array|min:1',
            'logs.*.pin' => 'required|string',
            'logs.*.type' => 'required|in:clock_in,clock_out',
            'logs.*.timestamp' => 'required|date',
        ]);

        $device = FingerprintDevice::where('serial_number', $request->device_serial)
            ->where('is_active', true)
            ->first();

        if (! $device) {
            return response()->json([
                'success' => false,
                'message' => 'Device tidak dikenal.',
            ], 404);
        }

        $signature = $request->header('X-Device-Signature');
        $expectedSignature = hash_hmac('sha256', $request->getContent(), $device->webhook_secret ?? '');

        if (! $device->webhook_secret || ! $signature || ! hash_equals($expectedSignature, $signature)) {
            return response()->json([
                'success' => false,
                'message' => 'Signature tidak valid.',
            ], 401);
        }

        $summary = ['applied' => 0, 'superseded' => 0, 'duplicate' => 0, 'unmatched' => 0];

        foreach ($request->input('logs') as $log) {
            $mapping = FingerprintUserMapping::where('fingerprint_device_id', $device->id)
                ->where('device_user_pin', $log['pin'])
                ->first();

            $result = $this->reconciliationService->record(
                $mapping?->employee,
                $log['type'],
                // Fingerprint machines log wall-clock time and rarely include a
                // UTC offset; interpret naive timestamps as the device's own
                // company's local time rather than letting Carbon silently fall
                // back to the app's default (UTC) timezone.
                Carbon::parse($log['timestamp'], $device->company->timezone),
                'fingerprint',
                [
                    'company_id' => $device->company_id,
                    'fingerprint_device_id' => $device->id,
                    'device_user_pin' => $log['pin'],
                ]
            );

            match ($result['status']) {
                'applied' => $summary['applied']++,
                'superseded' => $summary['superseded']++,
                'duplicate_ignored', 'duplicate_event' => $summary['duplicate']++,
                'unmatched' => $summary['unmatched']++,
                default => null,
            };
        }

        $device->update(['last_sync_at' => now()]);

        return response()->json([
            'success' => true,
            'summary' => $summary,
        ]);
    }
}
