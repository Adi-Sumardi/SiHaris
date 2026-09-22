<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Sends OTP codes over WhatsApp via Mekari Qontak Omnichannel's WhatsApp
 * Business Cloud API line, replacing the SendaGo free-text send for this
 * purpose (see WhatsAppNotificationService, kept for reference/other uses).
 *
 * An official WhatsApp Business line cannot send free-form text to a number
 * that hasn't messaged the business first within 24h - every cold outbound
 * message must be an approved template. So this only exposes sendOtp(),
 * built on the approved 'otp_login'-style Authentication template
 * configured via QONTAK_OTP_TEMPLATE_ID.
 *
 * Request contract (confirmed against Qontak's own docs):
 *   POST {base_url}/broadcasts/whatsapp/direct
 *   Body: {to_number, to_name, message_template_id, channel_integration_id,
 *          language: {code}, parameters: {body: [{key,value,value_text}],
 *          buttons: [{index,type,value}]}}
 *
 * Auth is Mekari's own HMAC scheme, NOT a Bearer access_token: every request
 * is signed as
 *   signature = base64(HMAC-SHA256("date: {RFC7231 date}\n{METHOD} {PATH} HTTP/1.1", client_secret))
 * sent as `Authorization: hmac username="{client_id}", algorithm="hmac-sha256",
 * headers="date request-line", signature="{signature}"` alongside a `Date`
 * header carrying that same RFC 7231 timestamp. No access/refresh token to
 * manage at all.
 */
class QontakWhatsAppGateway
{
    /**
     * @return array{success: bool, error: ?string}
     */
    public function sendOtp(string $phone, string $code): array
    {
        $templateId = config('services.qontak.otp_template_id');

        if (empty($templateId)) {
            Log::warning('[QontakWhatsAppGateway] otp_template_id not configured, cannot send OTP.');

            return ['success' => false, 'error' => 'QONTAK_OTP_TEMPLATE_ID_NOT_CONFIGURED'];
        }

        return $this->sendTemplate($phone, $templateId, [$code], [$code]);
    }

    /**
     * @param  string[]  $bodyValues  Positional - index 0 fills {{1}}, index 1 fills {{2}}, etc.
     * @param  string[]  $buttonValues  Positional, one per interactive button component on the template (e.g. a copy-code button).
     * @return array{success: bool, error: ?string}
     */
    private function sendTemplate(string $phone, string $templateId, array $bodyValues, array $buttonValues = []): array
    {
        $baseUrl = config('services.qontak.base_url');
        $channelIntegrationId = config('services.qontak.channel_integration_id');
        $clientId = config('services.qontak.client_id');
        $clientSecret = config('services.qontak.client_secret');

        if (empty($baseUrl) || empty($channelIntegrationId) || empty($clientId) || empty($clientSecret)) {
            Log::warning('[QontakWhatsAppGateway] Credentials not configured, WhatsApp OTP was NOT sent.', ['phone' => $phone]);

            return ['success' => false, 'error' => 'QONTAK_CREDENTIALS_NOT_CONFIGURED'];
        }

        $body = [
            'to_number' => $this->normalizePhone($phone),
            'to_name' => 'Karyawan',
            'message_template_id' => $templateId,
            'channel_integration_id' => $channelIntegrationId,
            'language' => ['code' => 'id'],
            'parameters' => [
                'body' => collect($bodyValues)->values()->map(fn ($value, $i) => [
                    'key' => (string) ($i + 1),
                    'value' => 'var'.($i + 1),
                    'value_text' => (string) $value,
                ])->all(),
            ],
        ];

        if (! empty($buttonValues)) {
            $body['parameters']['buttons'] = collect($buttonValues)->values()->map(fn ($value, $i) => [
                'index' => (string) $i,
                'type' => 'url',
                'value' => (string) $value,
            ])->all();
        }

        $path = rtrim((string) parse_url($baseUrl, PHP_URL_PATH), '/').'/broadcasts/whatsapp/direct';
        $date = gmdate('D, d M Y H:i:s \G\M\T');
        $signature = base64_encode(hash_hmac('sha256', "date: {$date}\nPOST {$path} HTTP/1.1", $clientSecret, true));
        $authorization = 'hmac username="'.$clientId.'", algorithm="hmac-sha256", headers="date request-line", signature="'.$signature.'"';

        try {
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
                'Authorization' => $authorization,
                'Date' => $date,
            ])->timeout(15)->post(rtrim($baseUrl, '/').'/broadcasts/whatsapp/direct', $body);

            if ($response->successful()) {
                return ['success' => true, 'error' => null];
            }

            Log::warning('[QontakWhatsAppGateway] Send failed', [
                'phone' => $phone,
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return ['success' => false, 'error' => 'http_'.$response->status()];
        } catch (\Throwable $e) {
            Log::error('[QontakWhatsAppGateway] Send exception', [
                'phone' => $phone,
                'message' => $e->getMessage(),
            ]);

            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * WhatsApp Cloud API expects international format without a leading
     * "+" (e.g. "62812..."), unlike SendaGo's local "0812..." expectation -
     * SiHaris stores/accepts employee phone numbers in either 0-prefixed or
     * 62-prefixed form, so this always converts to the 62-prefixed one.
     */
    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D/', '', $phone) ?? '';

        if (str_starts_with($digits, '0')) {
            return '62'.substr($digits, 1);
        }

        if (! str_starts_with($digits, '62')) {
            return '62'.$digits;
        }

        return $digits;
    }
}
