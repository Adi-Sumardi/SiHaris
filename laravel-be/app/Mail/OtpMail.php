<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $otpCode,
        public string $name = 'Karyawan'
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Kode Verifikasi OTP SiHaris: '.$this->otpCode,
        );
    }

    public function content(): Content
    {
        return new Content(
            htmlString: "
                <div style='font-family: Arial, sans-serif; padding: 20px; color: #333;'>
                    <h2 style='color: #0284C7;'>Kode Verifikasi OTP SiHaris</h2>
                    <p>Halo <strong>{$this->name}</strong>,</p>
                    <p>Gunakan kode OTP di bawah ini untuk memverifikasi login Anda ke aplikasi SiHaris:</p>
                    <div style='background-color: #F0F9FF; border: 2px dashed #0284C7; padding: 15px; text-align: center; margin: 20px 0; border-radius: 8px;'>
                        <span style='font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #0369A1;'>{$this->otpCode}</span>
                    </div>
                    <p>Kode ini berlaku selama <strong>3 menit</strong>. Jangan berikan kode ini kepada siapapun demi keamanan akun Anda.</p>
                    <br>
                    <p style='font-size: 12px; color: #777;'>Jika Anda tidak merasa melakukan tindakan ini, silakan abaikan email ini.</p>
                </div>
            "
        );
    }
}
