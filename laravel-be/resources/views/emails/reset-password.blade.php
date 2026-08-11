<style>
    .siharis-email-wrapper {
        width: 100%;
        background-color: #f4f6f9;
        padding: 24px 0;
        font-family: 'Plus Jakarta Sans', 'Helvetica Neue', Helvetica, Arial, sans-serif;
        color: #334155;
    }
    .siharis-email-container {
        max-width: 580px;
        margin: 0 auto;
        background: #ffffff;
        border-radius: 16px;
        overflow: hidden;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.01);
        border: 1px solid #e2e8f0;
    }
    .siharis-email-header {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%);
        padding: 32px 24px;
        text-align: center;
    }
    .siharis-email-header-title {
        color: #ffffff;
        font-size: 22px;
        font-weight: 700;
        letter-spacing: -0.5px;
        margin: 0;
    }
    .siharis-email-content {
        padding: 32px 24px;
    }
    .siharis-email-greeting {
        font-size: 18px;
        font-weight: 600;
        color: #0f172a;
        margin-bottom: 16px;
    }
    .siharis-email-text {
        font-size: 15px;
        line-height: 1.6;
        color: #475569;
        margin-bottom: 24px;
    }
    .siharis-email-btn-container {
        text-align: center;
        margin: 32px 0;
    }
    .siharis-email-btn {
        display: inline-block;
        background: linear-gradient(135deg, #4f46e5 0%, #4338ca 100%);
        color: #ffffff !important;
        font-size: 16px;
        font-weight: 600;
        text-decoration: none;
        padding: 14px 32px;
        border-radius: 12px;
        box-shadow: 0 4px 14px 0 rgba(79, 70, 229, 0.39);
    }
    .siharis-email-info-box {
        background-color: #f8fafc;
        border: 1px solid #e2e8f0;
        border-left: 4px solid #6366f1;
        border-radius: 8px;
        padding: 16px;
        margin-bottom: 24px;
        font-size: 14px;
        color: #475569;
    }
    .siharis-email-info-box strong {
        color: #1e293b;
    }
    .siharis-email-link-fallback {
        font-size: 12px;
        color: #94a3b8;
        word-break: break-all;
        margin-top: 24px;
        padding-top: 20px;
        border-top: 1px solid #f1f5f9;
    }
    .siharis-email-link-fallback a {
        color: #6366f1;
        text-decoration: underline;
    }
    .siharis-email-footer {
        background-color: #f8fafc;
        padding: 20px 24px;
        text-align: center;
        font-size: 13px;
        color: #94a3b8;
        border-top: 1px solid #f1f5f9;
    }
</style>

<div class="siharis-email-wrapper">
    <div class="siharis-email-container">
        <!-- Header -->
        <div class="siharis-email-header">
            <h1 class="siharis-email-header-title">{{ $appName }}</h1>
        </div>

        <!-- Content -->
        <div class="siharis-email-content">
            <div class="siharis-email-greeting">Halo, {{ $name }}! 👋</div>
            
            <p class="siharis-email-text">
                Kami menerima permintaan untuk melakukan <strong>reset password</strong> pada akun <strong>{{ $appName }}</strong> Anda. Silakan klik tombol di bawah ini untuk membuat password baru:
            </p>

            <div class="siharis-email-btn-container">
                <a href="{{ $url }}" class="siharis-email-btn" target="_blank">Reset Password Saya</a>
            </div>

            <div class="siharis-email-info-box">
                <strong>⏰ Batas Waktu Tautan:</strong><br>
                Tautan reset password ini hanya berlaku selama <strong>{{ $count }} menit</strong> demi keamanan akun Anda.
            </div>

            <p class="siharis-email-text" style="font-size: 13px; color: #64748b;">
                🔒 <em>Jika Anda tidak merasa mengajukan permintaan reset password ini, Anda dapat mengabaikan email ini dengan aman. Password Anda tidak akan berubah.</em>
            </p>

            <div class="siharis-email-link-fallback">
                Jika tombol di atas tidak dapat diklik, salin dan tempel URL berikut ke browser Anda:<br>
                <a href="{{ $url }}" target="_blank">{{ $url }}</a>
            </div>
        </div>

        <!-- Footer -->
        <div class="siharis-email-footer">
            &copy; {{ date('Y') }} {{ $appName }}. Seluruh hak cipta dilindungi undang-undang.<br>
            Sistem Informasi Kehadiran & Penggajian Karyawan
        </div>
    </div>
</div>
