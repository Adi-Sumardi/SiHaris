<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Sends WhatsApp messages via the SendaGo gateway (api-sendago.adilabs.id).
 *
 * Contract (confirmed):
 *   POST {base_url}/api/messages
 *   Headers: Content-Type: application/json, X-API-KEY: {api_key}
 *   Body: {"to": "081234567890", "body": "message text", "deviceId": "optional-device-uuid"}
 */
class WhatsAppNotificationService
{
    protected string $baseUrl;

    protected ?string $apiKey;

    protected ?string $deviceId;

    protected bool $isTestMode;

    public function __construct()
    {
        $this->baseUrl = config('services.sendago.base_url', '');
        $this->apiKey = config('services.sendago.api_key');
        $this->deviceId = config('services.sendago.device_id');
        $this->isTestMode = empty($this->apiKey);
    }

    /**
     * @return array{success: bool, error: ?string}
     */
    public function sendMessage(string $phone, string $message): array
    {
        if ($this->isTestMode) {
            Log::warning('WhatsAppNotificationService is in TEST MODE because SENDAGO_API_KEY is not set in .env! Message was NOT sent via WhatsApp gateway.', ['phone' => $phone]);

            return ['success' => true, 'error' => 'TEST_MODE_NO_API_KEY'];
        }

        try {
            $response = Http::withHeaders(['X-API-KEY' => $this->apiKey])
                ->timeout(10)
                ->post(rtrim($this->baseUrl, '/').'/api/messages', array_filter([
                    'to' => $this->normalizePhone($phone),
                    'body' => $message,
                    'deviceId' => $this->deviceId,
                ]));

            if ($response->successful()) {
                return ['success' => true, 'error' => null];
            }

            Log::warning('WhatsApp recap send failed', [
                'phone' => $phone,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return ['success' => false, 'error' => 'http_'.$response->status()];
        } catch (\Throwable $e) {
            Log::error('WhatsApp recap send exception', [
                'phone' => $phone,
                'message' => $e->getMessage(),
            ]);

            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * SendaGo expects the local Indonesian format (leading 0), matching how
     * employee phone numbers are already stored — strip formatting only.
     */
    private function normalizePhone(string $phone): string
    {
        return preg_replace('/\D/', '', $phone) ?? '';
    }
}
