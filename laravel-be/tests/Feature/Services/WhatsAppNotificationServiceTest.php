<?php

use App\Services\WhatsAppNotificationService;
use Illuminate\Support\Facades\Http;

describe('WhatsAppNotificationService', function () {
    it('simulates success without any network call when no api key is configured', function () {
        config(['services.sendago.api_key' => null]);
        Http::fake();

        $service = app(WhatsAppNotificationService::class);
        $result = $service->sendMessage('081234567890', 'Halo');

        expect($result)->toBe(['success' => true, 'error' => null]);
        Http::assertNothingSent();
    });

    it('sends the exact SendaGo contract: POST /api/messages with X-API-KEY header', function () {
        config([
            'services.sendago.api_key' => 'test-api-key',
            'services.sendago.base_url' => 'https://api-sendago.adilabs.id',
            'services.sendago.device_id' => null,
        ]);
        Http::fake([
            'api-sendago.adilabs.id/*' => Http::response(['success' => true], 200),
        ]);

        $service = app(WhatsAppNotificationService::class);
        $result = $service->sendMessage('081234567890', 'Halo dari GajiPro');

        expect($result)->toBe(['success' => true, 'error' => null]);

        Http::assertSent(function ($request) {
            return $request->url() === 'https://api-sendago.adilabs.id/api/messages'
                && $request->method() === 'POST'
                && $request->hasHeader('X-API-KEY', 'test-api-key')
                && $request['to'] === '081234567890'
                && $request['body'] === 'Halo dari GajiPro';
        });
    });

    it('includes deviceId in the payload when configured', function () {
        config([
            'services.sendago.api_key' => 'test-api-key',
            'services.sendago.base_url' => 'https://api-sendago.adilabs.id',
            'services.sendago.device_id' => 'device-uuid-123',
        ]);
        Http::fake(['api-sendago.adilabs.id/*' => Http::response(['success' => true], 200)]);

        app(WhatsAppNotificationService::class)->sendMessage('081234567890', 'Halo');

        Http::assertSent(fn ($request) => $request['deviceId'] === 'device-uuid-123');
    });

    it('returns a failure result when the gateway responds with an error status', function () {
        config(['services.sendago.api_key' => 'test-api-key']);
        Http::fake(['api-sendago.adilabs.id/*' => Http::response(['message' => 'invalid'], 422)]);

        $result = app(WhatsAppNotificationService::class)->sendMessage('081234567890', 'Halo');

        expect($result['success'])->toBeFalse();
        expect($result['error'])->toBe('http_422');
    });
});
