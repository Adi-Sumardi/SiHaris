<?php

namespace App\Jobs;

use App\Services\AdmsApiService;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class PushAttendanceToAdmsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public int $backoff = 30;

    public function __construct(
        public string $pin,
        public string|Carbon $timestamp,
        public string $type,
        public ?string $deviceId = null,
        public ?string $eventId = null
    ) {}

    public function handle(AdmsApiService $admsService): void
    {
        $timestampStr = $this->timestamp instanceof Carbon
            ? $this->timestamp->format('Y-m-d H:i:s')
            : $this->timestamp;

        Log::info("Pushing attendance to ADMS API: PIN={$this->pin}, Type={$this->type}, Timestamp={$timestampStr}");

        $result = $admsService->pushAttendance(
            pin: $this->pin,
            timestamp: $timestampStr,
            type: $this->type,
            deviceId: $this->deviceId,
            eventId: $this->eventId
        );

        if (! $result['success']) {
            Log::warning("PushAttendanceToAdmsJob failed for PIN={$this->pin}: {$result['message']}");
        } else {
            Log::info("PushAttendanceToAdmsJob succeeded for PIN={$this->pin}");
        }
    }
}
