<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password Akun {{ $appName }}</title>
    <style>
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            background-color: #f4f6f9;
            margin: 0;
            padding: 0;
            -webkit-font-smoothing: antialiased;
            color: #334155;
        }
        .wrapper {
            width: 100%;
            background-color: #f4f6f9;
            padding: 40px 0;
        }
        .container {
            max-width: 580px;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.01);
        }
        .header {
            background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4338ca 100%);
            padding: 36px 32px;
            text-align: center;
        }
        .header img {
            max-height: 48px;
            margin-bottom: 12px;
        }
        .header-title {
            color: #ffffff;
            font-size: 22px;
            font-weight: 700;
            letter-spacing: -0.5px;
            margin: 0;
        }
        .content {
            padding: 40px 32px;
        }
        .greeting {
            font-size: 18px;
            font-weight: 600;
            color: #0f172a;
            margin-bottom: 16px;
        }
        .text {
            font-size: 15px;
            line-height: 1.6;
            color: #475569;
            margin-bottom: 24px;
        }
        .btn-container {
            text-align: center;
            margin: 32px 0;
        }
        .btn {
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
        .info-box {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-left: 4px solid #6366f1;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 24px;
            font-size: 14px;
            color: #475569;
        }
        .info-box strong {
            color: #1e293b;
        }
        .link-fallback {
            font-size: 12px;
            color: #94a3b8;
            word-break: break-all;
            margin-top: 24px;
            padding-top: 20px;
            border-top: 1px solid #f1f5f9;
        }
        .link-fallback a {
            color: #6366f1;
            text-decoration: underline;
        }
        .footer {
            background-color: #f8fafc;
            padding: 24px 32px;
            text-align: center;
            font-size: 13px;
            color: #94a3b8;
            border-top: 1px solid #f1f5f9;
        }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="container">
            <!-- Header -->
            <div class="header">
                <h1 class="header-title">{{ $appName }}</h1>
            </div>

            <!-- Content -->
            <div class="content">
                <div class="greeting">Halo, {{ $name }}! 👋</div>
                
                <p class="text">
                    Kami menerima permintaan untuk melakukan <strong>reset password</strong> pada akun <strong>{{ $appName }}</strong> Anda. Silakan klik tombol di bawah ini untuk membuat password baru:
                </p>

                <div class="btn-container">
                    <a href="{{ $url }}" class="btn" target="_blank">Reset Password Saya</a>
                </div>

                <div class="info-box">
                    <strong>⏰ Batas Waktu Tautan:</strong><br>
                    Tautan reset password ini hanya berlaku selama <strong>{{ $count }} menit</strong> demi keamanan akun Anda.
                </div>

                <p class="text" style="font-size: 13px; color: #64748b;">
                    🔒 <em>Jika Anda tidak pernah meminta permintaan reset password ini, abaikan email ini secara aman. Password Anda tidak akan berubah.</em>
                </p>

                <div class="link-fallback">
                    Jika tombol di atas tidak berfungsi, salin dan tempel URL berikut ke browser Anda:<br>
                    <a href="{{ $url }}" target="_blank">{{ $url }}</a>
                </div>
            </div>

            <!-- Footer -->
            <div class="footer">
                &copy; {{ date('Y') }} {{ $appName }}. Seluruh hak cipta dilindungi undang-undang.<br>
                Sistem Informasi Kehadiran & Penggajian Karyawan
            </div>
        </div>
    </div>
</body>
</html>
