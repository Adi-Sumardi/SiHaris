<?php

namespace App\Mail;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Symfony\Component\Mailer\SentMessage;
use Symfony\Component\Mailer\Transport\AbstractTransport;
use Symfony\Component\Mime\MessageConverter;

class SendagoMailTransport extends AbstractTransport
{
    public function __construct(
        protected string $baseUrl,
        protected ?string $memberId,
        protected ?string $secret,
    ) {
        parent::__construct();
    }

    protected function doSend(SentMessage $message): void
    {
        $email = MessageConverter::toEmail($message->getOriginalMessage());

        $toAddresses = array_map(fn ($address) => $address->getAddress(), $email->getTo());
        $to = implode(',', $toAddresses);
        $subject = $email->getSubject() ?? 'Notifikasi SiHaris';
        $body = $email->getHtmlBody() ?? $email->getTextBody() ?? '';

        if (empty($this->memberId) || empty($this->secret)) {
            Log::info('SendagoMail test mode: Email not sent to API', [
                'to' => $to,
                'subject' => $subject,
            ]);

            return;
        }

        try {
            $response = Http::timeout(15)
                ->post(rtrim($this->baseUrl, '/').'/emails/api-send', [
                    'memberId' => $this->memberId,
                    'secret' => $this->secret,
                    'toAddr' => $to,
                    'subject' => $subject,
                    'body' => $body,
                ]);

            if (! $response->successful()) {
                Log::error('SendagoMail Transport API failed', [
                    'to' => $to,
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
            }
        } catch (\Throwable $e) {
            Log::error('SendagoMail Transport Exception', [
                'to' => $to,
                'error' => $e->getMessage(),
            ]);
        }
    }

    public function __toString(): string
    {
        return 'sendagomail';
    }
}
