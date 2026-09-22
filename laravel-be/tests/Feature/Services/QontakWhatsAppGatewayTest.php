<?php

use App\Services\QontakWhatsAppGateway;
use Illuminate\Support\Facades\Http;

describe('QontakWhatsAppGateway', function () {
    beforeEach(function () {
        config([
            'services.qontak.base_url' => 'https://api.mekari.com/qontak/chat/v1',
            'services.qontak.client_id' => 'test-client-id',
            'services.qontak.client_secret' => 'test-client-secret',
            'services.qontak.channel_integration_id' => 'test-channel-id',
            'services.qontak.otp_template_id' => 'test-template-id',
        ]);
    });

    it('fails without sending when the OTP template id is not configured', function () {
        config(['services.qontak.otp_template_id' => null]);
        Http::fake();

        $result = app(QontakWhatsAppGateway::class)->sendOtp('081234567890', '654321');

        expect($result)->toBe(['success' => false, 'error' => 'QONTAK_OTP_TEMPLATE_ID_NOT_CONFIGURED']);
        Http::assertNothingSent();
    });

    it('fails without sending when Qontak credentials are not configured', function () {
        config(['services.qontak.client_secret' => null]);
        Http::fake();

        $result = app(QontakWhatsAppGateway::class)->sendOtp('081234567890', '654321');

        expect($result)->toBe(['success' => false, 'error' => 'QONTAK_CREDENTIALS_NOT_CONFIGURED']);
        Http::assertNothingSent();
    });

    it('sends the exact Qontak contract: POST /broadcasts/whatsapp/direct, HMAC-signed, template body with the OTP code', function () {
        Http::fake(['api.mekari.com/*' => Http::response(['id' => 'abc123'], 200)]);

        $result = app(QontakWhatsAppGateway::class)->sendOtp('081234567890', '654321');

        expect($result)->toBe(['success' => true, 'error' => null]);

        Http::assertSent(function ($request) {
            $authHeader = $request->header('Authorization')[0] ?? '';
            $dateHeader = $request->header('Date')[0] ?? '';

            return $request->url() === 'https://api.mekari.com/qontak/chat/v1/broadcasts/whatsapp/direct'
                && $request->method() === 'POST'
                && str_starts_with($authHeader, 'hmac username="test-client-id", algorithm="hmac-sha256"')
                && $dateHeader !== ''
                && $request['message_template_id'] === 'test-template-id'
                && $request['channel_integration_id'] === 'test-channel-id'
                && $request['language']['code'] === 'id'
                && $request['parameters']['body'][0]['value_text'] === '654321'
                && $request['parameters']['buttons'][0]['value'] === '654321';
        });
    });

    it('normalizes a local 0-prefixed phone number to 62-prefixed international format', function () {
        Http::fake(['api.mekari.com/*' => Http::response(['id' => 'abc123'], 200)]);

        app(QontakWhatsAppGateway::class)->sendOtp('081234567890', '654321');

        Http::assertSent(fn ($request) => $request['to_number'] === '6281234567890');
    });

    it('keeps a 62-prefixed phone number unchanged', function () {
        Http::fake(['api.mekari.com/*' => Http::response(['id' => 'abc123'], 200)]);

        app(QontakWhatsAppGateway::class)->sendOtp('6281234567890', '654321');

        Http::assertSent(fn ($request) => $request['to_number'] === '6281234567890');
    });

    it('returns a failure result when the gateway responds with an error status', function () {
        Http::fake(['api.mekari.com/*' => Http::response(['message' => 'invalid'], 422)]);

        $result = app(QontakWhatsAppGateway::class)->sendOtp('081234567890', '654321');

        expect($result['success'])->toBeFalse();
        expect($result['error'])->toBe('http_422');
    });
});
