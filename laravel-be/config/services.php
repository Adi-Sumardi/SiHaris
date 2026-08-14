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

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect' => env('GOOGLE_REDIRECT_URI', 'https://siharis.yapinet.id/auth/google/callback'),
    ],

    'adms' => [
        'base_url' => env('ADMS_BASE_URL', 'http://adms.alazhar-rm.com/api/v1/face'),
        'api_key' => env('ADMS_API_KEY', 'adms-face-token-2026'),
    ],
];
