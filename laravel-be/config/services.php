<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // Attendance recap WhatsApp gateway.
    // Confirmed contract: POST /api/messages, X-API-KEY header, {to, body, deviceId}.
    'sendago' => [
        'base_url' => env('SENDAGO_BASE_URL', 'https://api-sendago.adilabs.id'),
        'api_key' => env('SENDAGO_API_KEY'),
        'device_id' => env('SENDAGO_DEVICE_ID'),
    ],

    // Attendance recap email gateway.
    // Confirmed contract: POST /emails/api-send, auth via {memberId, secret} in the body.
    'sendagomail' => [
        'base_url' => env('SENDAGOMAIL_BASE_URL', 'https://sendagomail.adilabs.id'),
        'member_id' => env('SENDAGOMAIL_MEMBER_ID'),
        'secret' => env('SENDAGOMAIL_SECRET'),
    ],

    // Mekari Qontak Omnichannel - WhatsApp Business Cloud API line used for
    // OTP login (QontakWhatsAppGateway::sendOtp()). An official WhatsApp
    // Business line can only message a number that hasn't messaged first via
    // an approved template, so this needs its own Qontak account, verified
    // WhatsApp Business number, and an approved "otp_login"-style
    // Authentication template - these values are NOT interchangeable with
    // another tenant's Qontak app (channel_integration_id and
    // otp_template_id are both scoped to one WhatsApp Business number).
    'qontak' => [
        'base_url' => env('QONTAK_BASE_URL', 'https://api.mekari.com/qontak/chat/v1'),
        // Signs every request (Mekari's own HMAC scheme, not a Bearer
        // token) - see QontakWhatsAppGateway::post(). No access/refresh
        // token to manage.
        'client_id' => env('QONTAK_CLIENT_ID'),
        'client_secret' => env('QONTAK_CLIENT_SECRET'),
        // GET {base_url}/../../open/v1/integrations?target_channel=wa - the
        // WhatsApp channel's own id inside this Qontak account, required on
        // every broadcast send alongside the template id.
        'channel_integration_id' => env('QONTAK_CHANNEL_INTEGRATION_ID'),
        // UUID of the approved OTP Authentication template. Body has exactly
        // one variable (the code itself); the template's own copy-code
        // button repeats it as a button value.
        'otp_template_id' => env('QONTAK_OTP_TEMPLATE_ID'),
    ],

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect' => env('GOOGLE_REDIRECT_URI', 'https://siharis.yapinet.id/auth/google/callback'),
    ],

    'adms' => [
        'base_url' => env('ADMS_BASE_URL', 'http://adms.alazhar-rm.com/api/v1/face'),
        'api_key' => env('ADMS_API_KEY', 'adms-face-token-2026'),
    ],

    // Firebase Cloud Messaging for Android/iOS push notifications.
    // 'credentials' must point to a Firebase service-account JSON file (not committed to git).
    'firebase' => [
        'project_id' => env('FIREBASE_PROJECT_ID', 'siharis-app'),
        'credentials' => env('FIREBASE_CREDENTIALS_PATH', storage_path('app/firebase/firebase-service-account.json')),
    ],
];
