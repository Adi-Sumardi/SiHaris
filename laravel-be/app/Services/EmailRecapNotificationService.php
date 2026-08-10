<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Sends attendance recap emails via the SendaGo Mail gateway.
 *
 * Contract (confirmed):
 *   POST {base_url}/emails/api-send
 *   Body: {"memberId": "...", "secret": "...", "toAddr": "...", "subject": "...", "body": "..."}
 *   Auth is carried in the body (memberId + secret), not a header.
 */
class EmailRecapNotificationService
{
    protected string $baseUrl;

    protected ?string $memberId;

    protected ?string $secret;

    protected bool $isTestMode;

    public function __construct()
    {
        $this->baseUrl = config('services.sendagomail.base_url', '');
        $this->memberId = config('services.sendagomail.member_id');
        $this->secret = config('services.sendagomail.secret');
        $this->isTestMode = empty($this->memberId) || empty($this->secret);
    }

    /**
     * @return array{success: bool, error: ?string}
     */
    public function sendEmail(string $to, string $subject, string $body): array
    {
        if ($this->isTestMode) {
            return ['success' => true, 'error' => null];
        }

        try {
            $response = Http::timeout(10)
                ->post(rtrim($this->baseUrl, '/').'/emails/api-send', [
                    'memberId' => $this->memberId,
                    'secret' => $this->secret,
                    'toAddr' => $to,
                    'subject' => $subject,
                    'body' => $body,
                ]);

            if ($response->successful()) {
                return ['success' => true, 'error' => null];
            }

            Log::warning('Email recap send failed', [
                'to' => $to,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return ['success' => false, 'error' => 'http_'.$response->status()];
        } catch (\Throwable $e) {
            Log::error('Email recap send exception', [
                'to' => $to,
                'message' => $e->getMessage(),
            ]);

            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
}
