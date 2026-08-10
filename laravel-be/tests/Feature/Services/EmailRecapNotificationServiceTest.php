<?php

use App\Services\EmailRecapNotificationService;
use Illuminate\Support\Facades\Http;

describe('EmailRecapNotificationService', function () {
    it('simulates success without any network call when credentials are missing', function () {
        config(['services.sendagomail.member_id' => null, 'services.sendagomail.secret' => null]);
        Http::fake();

        $result = app(EmailRecapNotificationService::class)->sendEmail('a@example.com', 'Subject', 'Body');

        expect($result)->toBe(['success' => true, 'error' => null]);
        Http::assertNothingSent();
    });

    it('sends the exact SendaGo Mail contract: POST /emails/api-send with memberId+secret in body', function () {
        config([
            'services.sendagomail.member_id' => 'mbr_d79d6cfbf53fd53b',
            'services.sendagomail.secret' => 'SECRET_ANDA',
            'services.sendagomail.base_url' => 'https://sendagomail.adilabs.id',
        ]);
        Http::fake(['sendagomail.adilabs.id/*' => Http::response(['success' => true], 200)]);

        $result = app(EmailRecapNotificationService::class)
            ->sendEmail('penerima@gmail.com', 'Rekap Kehadiran Anda', 'Halo, berikut rekap kehadiran Anda...');

        expect($result)->toBe(['success' => true, 'error' => null]);

        Http::assertSent(function ($request) {
            return $request->url() === 'https://sendagomail.adilabs.id/emails/api-send'
                && $request->method() === 'POST'
                && $request['memberId'] === 'mbr_d79d6cfbf53fd53b'
                && $request['secret'] === 'SECRET_ANDA'
                && $request['toAddr'] === 'penerima@gmail.com'
                && $request['subject'] === 'Rekap Kehadiran Anda'
                && $request['body'] === 'Halo, berikut rekap kehadiran Anda...';
        });
    });

    it('returns a failure result when the gateway responds with an error status', function () {
        config(['services.sendagomail.member_id' => 'mbr_x', 'services.sendagomail.secret' => 'sec']);
        Http::fake(['sendagomail.adilabs.id/*' => Http::response(['message' => 'invalid'], 422)]);

        $result = app(EmailRecapNotificationService::class)->sendEmail('a@example.com', 'Subject', 'Body');

        expect($result['success'])->toBeFalse();
        expect($result['error'])->toBe('http_422');
    });
});
