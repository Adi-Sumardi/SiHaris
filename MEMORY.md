# SiHaris (GajiPro) — Project Memory & Architecture Notes

## 1. Production Server Details
- **IP Address**: `172.16.5.204`
- **SSH User**: `yapiar1`
- **SSH Password**: `Adalah123`
- **Backend Directory**: `/var/www/siharis/laravel-be`
- **Web URL**: `https://siharis.yapinet.id`
- **Internal App Port**: `8888` (Nginx vhost on `127.0.0.1:8888` reverse-proxied)

---

## 2. Authentication System (OTP WhatsApp & Email + 30-Day Token)
- **Login Options**: Karyawan & Admin dapat login menggunakan **Nomor HP** atau **Email** tanpa password, dengan verifikasi **6-Digit Kode OTP** (berlaku selama **3 Menit / 180 detik**).
- **Sanctum Token Expiration**: Token autentikasi API di-generate dengan durasi aktif **30 Hari** (`now()->addDays(30)`).

### Messaging Gateways Configuration:
1. **WhatsApp Gateway (SendaGo WA API)**:
   - **Base URL**: `https://api-sendago.adilabs.id`
   - **Endpoint**: `POST /api/messages`
   - **Header**: `X-API-KEY: sg_7a377488dbfd3485632982210f44557e57b6b27fa089fbe3`
   - **Device ID**: Biarkan kosong/tanpa `SENDAGO_DEVICE_ID` agar SendaGo mengarahkan ke device aktif default (`PMB`).
   - **Payload**: `{"to": "0812...", "body": "..."}`
2. **Email Gateway (SendaGo Mail API)**:
   - **Base URL**: `https://sendagomail.adilabs.id`
   - **Member ID**: `mbr_5ad25ec95ebd6db4`
   - **Secret**: `8f81536d2623d1faae74ecf8f393b28746b70a27912ca897`

### API Endpoints:
- `POST /api/v1/auth/request-otp` (`{ "login": "0812..." }`)
- `POST /api/v1/auth/verify-otp` (`{ "login": "0812...", "otp": "123456" }`)

### Web Routes:
- `POST /login/otp`
- `GET /login/verify-otp`
- `POST /login/verify-otp`

---

## 3. ADMS Fingerprint & Face Attendance
- **Machine Registration**: Tidak perlu input mesin finger manual di Web karena data diambil otomatis via API ADMS Cloud (`ADMS-FACE-APP`).
- **Database Mapping**:
  - `employees.employee_id`: NIP / ID Karyawan internal kepegawaian.
  - `employees.pin`: PIN khusus biometrik mesin fingerprint / ADMS Cloud (mis. `1032`).
  - `fingerprint_user_mappings`: Pemetaan relasi per device (`fingerprint_device_id`, `employee_id`, `device_user_pin`).
- **Sync ADMS & Relay**:
  - `SyncAdmsEmployeesJob`: Sinkronisasi otomatis mencocokkan pegawai via `pin` -> `employee_id` -> `email` -> `name`, dan auto-populate `employees.pin` jika kosong.
  - `PushAttendanceToAdmsJob`: Saat karyawan absen Face Recognition di mobile app, sistem otomatis me-relay log transaksi dengan PIN biometrik (`employees.pin` / `1032`) ke API ADMS Cloud (`POST /attendance`).
- **Dashboard View**: Menampilkan status ADMS Cloud Server Machine di menu `/fingerprint-devices` dengan tombol **"Sync Data ADMS API"**.

---

## 4. Mobile App (Flutter)
- **OTP Screen**: `lib/presentation/auth/pages/otp_verification_screen.dart` (6-digit PIN input, 60s timer).
- **Login Screen**: `lib/presentation/auth/pages/login_screen.dart` (pilihan login OTP via WA / Email).
- **Environment Base URL**: `https://siharis.yapinet.id`
- **Release Keystore**: `flutter_fe/android/app/siharis.jks`
  - **Alias**: `siharis`
  - **Password**: `siharis2026.`
  - **Package ID**: `id.yapinet.siharis`
