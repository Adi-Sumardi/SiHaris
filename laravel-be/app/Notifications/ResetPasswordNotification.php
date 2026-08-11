<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ResetPasswordNotification extends Notification
{
    use Queueable;

    public string $token;

    public function __construct(string $token)
    {
        $this->token = $token;
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $url = route('password.reset', [
            'token' => $this->token,
            'email' => $notifiable->getEmailForPasswordReset(),
        ]);

        $appName = brand_name();

        return (new MailMessage)
            ->subject("[$appName] Instruksi Reset Password Akun Anda")
            ->greeting("Halo, {$notifiable->name}!")
            ->line("Kami menerima permintaan untuk mengosongkan / meng-reset password akun $appName Anda.")
            ->action('Reset Password Sekarang', $url)
            ->line('Link reset password ini berlaku selama 60 menit.')
            ->line('Jika Anda tidak pernah meminta reset password, abaikan email ini dan password Anda akan tetap aman.')
            ->salutation("Salam hangat,\nTim $appName");
    }
}
