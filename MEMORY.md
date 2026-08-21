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
- **Sync ADMS & Hybrid Attendance**:
  - `SyncAdmsEmployeesJob`: Sinkronisasi otomatis mencocokkan pegawai via `pin` -> `employee_id` -> `email` -> `name`, dan auto-populate `employees.pin` jika kosong.
  - `SyncAdmsAttendanceJob`: Menarik log presensi harian dari `GET /api/v1/face/attendance-logs?date=YYYY-MM-DD`, memfilter `pin != 0`, hanya memproses PIN yang terpetakan ke Karyawan SiHaris (`fingerprint_user_mappings`), dan merekonsiliasi ke tabel `attendances`. Terjadwal setiap 5 menit via `routes/console.php`.
  - `PushAttendanceToAdmsJob`: Saat karyawan absen Face Recognition di mobile app, sistem otomatis me-relay log transaksi dengan PIN biometrik (`employees.pin` / `1032`) ke API ADMS Cloud (`POST /attendance`).
- **Dashboard View**: Menampilkan status ADMS Cloud Server Machine di menu `/fingerprint-devices` dengan tombol **"Sync Data Pegawai & PIN"** dan **"Sync Log Presensi"**, serta tombol **"Sync Presensi ADMS"** di menu `/attendances`.
- **OTP User Resolution**: `OtpService::findUser` memprioritaskan akun Karyawan Aktif (`Employee` dengan `is_active = true`) dengan normalisasi varian nomor HP (`08...`, `8...`, `628...`, `+628...`) agar tidak tertukar dengan akun admin murni.

---

## 4. Mobile App (Flutter)
- **OTP Screen**: `lib/presentation/auth/pages/otp_verification_screen.dart` (6-digit PIN input, 60s timer).
- **Login Screen**: `lib/presentation/auth/pages/login_screen.dart` (pilihan login OTP via WA / Email).
- **Environment Base URL**: `https://siharis.yapinet.id`
- **Release Keystore**: `flutter_fe/android/app/siharis.jks`
  - **Alias**: `siharis`
  - **Password**: `siharis2026.`
  - **Package ID**: `id.yapinet.siharis`

---

## 5. Employee Bulk Import & Master Data Sync
- **Template Download**: `EmployeeTemplateExport` (`GET /imports/employees/template`)
  - Kolom lengkap mencakup: `NIK`, `PIN`, `Nama Depan`, `Nama Belakang`, `Email`, `Telepon`, `Jenis Kelamin`, `Tanggal Lahir`, `Status Pernikahan`, `Agama`, `Golongan Darah`, `No KTP`, `Alamat KTP`, `Alamat`, `Kota`, `Provinsi`, `Kode Pos`, `Kode Departemen`, `Kode Jabatan`, `Kode Jadwal`, `NIK Manajer`, `Kode Lokasi Kantor`, `Tanggal Masuk`, `Status Karyawan`, `Tanggal Mulai Kontrak`, `Tanggal Selesai Kontrak`, `Gaji Pokok`, `Nama Bank`, `Nomor Rekening`, `Nama Rekening`, `NPWP`, `Status Pajak`, `BPJS Kesehatan`, `BPJS Ketenagakerjaan`, `Nama Kontak Darurat`, `Telepon Kontak Darurat`, `Hubungan Kontak Darurat`, `Aktif`.
- **Import Handler**: `EmployeeImport` & `EmployeeImportController`
  - Pencarian relasi **Departemen**, **Jabatan**, **Jadwal Kerja**, dan **Lokasi Kantor** bersifat *case-insensitive* dan mendukung pencarian berdasarkan **Kode** maupun **Nama**.
  - Mendukung resolusi Atasan Langsung (`manager_id`) via NIK dan penugasan lokasi kantor (`office_locations`).
  - Sanitasi tipe data otomatis untuk cell numerik dari Excel (NIK, KTP, Telepon) tanpa gagal validasi `string`.
  - Eksekusi berjalan dalam `DB::transaction` dengan cache tracking status real-time untuk Alpine.js.

