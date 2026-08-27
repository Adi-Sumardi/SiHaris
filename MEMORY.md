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
  - `employees.employee_id`: NIP / ID Karyawan internal kepegawaian perusahaan (mis. `EMP001`, `KRY-202601`).
  - `employees.pin`: PIN khusus biometrik mesin fingerprint / face recognition / ADMS Cloud (mis. `101`, `1032`).
  - `employees.nik` & `employees.identity_number`: NIK (Nomor Induk Kependudukan) 16-digit KTP Indonesia.
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
- **Profile & Biometrics**: `lib/presentation/profile/pages/profile_screen.dart` (menampilkan PIN Mesin Fingerprint dengan tombol copy, NIK KTP, status biometrik, pull-to-refresh untuk sinkronisasi instan, modal pengajuan reset wajah, serta tombol pendaftaran wajah).
- **Live Face Enrollment**: `lib/presentation/face_recognition/pages/face_enroll_screen.dart` (live front camera feed dengan Google ML Kit Face Detection, real-time facial mesh/contour, MobileFaceNet TFLite 192-dimensional embedding extraction, dan auto-sync ke server).
- **Office Location Sync**: `lib/data/datasources/office_location_remote_datasource.dart` selalu mengambil penugasan kantor terbaru dari `GET /api/v1/office-locations/assigned` dan menyimpan cache di `AuthLocalDatasource.saveAssignedOffices()` agar pemindahan lokasi di web admin langsung terrefleksi di layar absensi tanpa harus login ulang.
- **Environment Base URL**: `https://siharis.yapinet.id`
- **Release Keystore**: `flutter_fe/android/app/siharis.jks`
  - **Alias**: `siharis`
  - **Password**: `siharis2026.`
  - **Package ID**: `id.yapinet.siharis`

---

## 5. Face Recognition & Face Reset Approval Workflow
- **Kebijakan Pendaftaran Wajah 1x**: Pendaftaran wajah karyawan dibatasi hanya dapat dilakukan 1 kali untuk integritas dan anti-fraud absensi biometrik.
- **Alur Permohonan Reset Wajah (Employee Request)**:
  - Karyawan yang sudah terdaftar wajahnya dapat mengajukan permohonan reset via aplikasi mobile (`POST /api/v1/face-recognition/reset-request`) dengan menyertakan alasan.
- **Halaman Persetujuan Administrator (Web Dashboard)**:
  - Halaman khusus `/face-recognition/requests` untuk meninjau status permohonan (`pending`, `approved`, `rejected`).
  - **Setujui (Approve)**: Menghapus data embedding biometrik lama karyawan di database & media storage (`EmployeeFaceEmbedding`), mengubah status `face_enrolled` menjadi `false`, sehingga karyawan dapat langsung mendaftarkan wajah baru di aplikasi HP.
  - **Tolak (Reject)**: Menolak pengajuan dengan catatan alasan penolakan dari Administrator.
- **Real-time Synchronization**: Layar profil aplikasi mobile dilengkapi *pull-to-refresh* (swipe refresh) agar status langsung ter-update setelah persetujuan admin tanpa perlu login ulang.

---

## 6. Employee Bulk Import & Database Rollback
- **Struktur Identitas Karyawan**:
  - **ID Karyawan** (`employee_id`): ID unik pegawai/karyawan di perusahaan.
  - **PIN** (`pin`): PIN absensi mesin fingerprint / face / ADMS.
  - **NIK (No KTP)** (`nik` / `identity_number`): 16 digit Nomor Induk Kependudukan.
- **Template Download**: `EmployeeTemplateExport` (`GET /imports/employees/template`)
  - Kolom lengkap mencakup: `ID Karyawan`, `PIN`, `Nama Depan`, `Nama Belakang`, `Email`, `Telepon`, `Jenis Kelamin`, `Tanggal Lahir`, `Status Pernikahan`, `Agama`, `Golongan Darah`, `NIK (No KTP)`, `Alamat KTP`, `Alamat`, `Kota`, `Provinsi`, `Kode Pos`, `Kode Departemen`, `Kode Jabatan`, `Kode Jadwal`, `NIK Manajer`, `Kode Lokasi Kantor`, `Tanggal Masuk`, `Status Karyawan`, `Tanggal Mulai Kontrak`, `Tanggal Selesai Kontrak`, `Gaji Pokok`, `Nama Bank`, `Nomor Rekening`, `Nama Rekening`, `NPWP`, `Status Pajak`, `BPJS Kesehatan`, `BPJS Ketenagakerjaan`, `Nama Kontak Darurat`, `Telepon Kontak Darurat`, `Hubungan Kontak Darurat`, `Aktif`.
- **Import Handler**: `EmployeeImport` & `EmployeeImportController`
  - Memisahkan resolusi field `ID Karyawan`, `PIN`, dan `NIK (No KTP)` secara mandiri.
  - Pencarian relasi **Departemen**, **Jabatan**, **Jadwal Kerja**, dan **Lokasi Kantor** bersifat *case-insensitive* dan mendukung pencarian berdasarkan **Kode** maupun **Nama**.
  - Mendukung resolusi Atasan Langsung (`manager_id`) via NIK dan penugasan lokasi kantor (`office_locations`).
  - Sanitasi tipe data otomatis untuk cell numerik dari Excel (NIK, KTP, Telepon) tanpa gagal validasi `string`.
  - Eksekusi berjalan dalam `DB::transaction` dengan cache tracking status real-time untuk Alpine.js.

---

## 7. National Holidays Generation ("Generate Nasional")
- **Konfirmasi Modal**: `resources/views/components/confirm-dialog.blade.php` mendukung injeksi parameter dinamis dari objek `formData` ke dalam form submit POST saat tombol konfirmasi ditekan.
- **Controller Backend**: `HolidayController::generate()` memvalidasi field `year` secara nullable dengan fallback otomatis ke tahun berjalan (`now()->year`).
- **Data Generator**: Menghasilkan hari libur nasional Indonesia, hari raya keagamaan (Islam, Kristen via algoritma Computus/Easter, Hindu, Buddha, Imlek), serta Cuti Bersama sesuai SKB 3 Menteri.

---

## 8. Position Code Uniqueness per Department (Keunikan Kode Jabatan per Departemen)
- **Aturan Unik Jabatan**: Kode jabatan (`code`) bersifat unik per **Departemen** dalam suatu perusahaan (`company_id + department_id + code`), bukan unik global seluruh perusahaan.
  - Memungkinkan perusahaan menggunakan kode jabatan yang sama (misal: `MGR`, `STF`, `SPV`) untuk beberapa departemen yang berbeda.
  - Database schema: Unique index `['company_id', 'department_id', 'code']` (`positions_company_dept_code_unique`).
- **Form Request (`PositionRequest`)**: Validasi `Rule::unique('positions', 'code')->where('company_id', $tenant->id)->where('department_id', $this->department_id)->whereNull('deleted_at')->ignore($positionId)`.
- **Import Data**:
  - `PositionImport`: Pengecekan kode existing difilter berdasarkan `company_id` dan `department_id`.
  - `EmployeeImport`: Resolusi `getPositionId` mendukung preferensi pencarian berbasis `department_id` karyawan untuk membedakan jabatan dengan kode/nama identik di departemen lain.

---

## 9. Employee Salary Bulk Import (Import Gaji Karyawan)
- **Halaman Import**: `/imports/employee-salaries` (`EmployeeSalaryImportController`)
- **Template Excel**: `GET /imports/employee-salaries/template` (`EmployeeSalaryTemplateExport`)
  - Kolom: `ID Karyawan`, `Gaji Pokok`, `Tanggal Berlaku`, `Tanggal Berakhir`, `Metode Pembayaran` (`Transfer`/`Tunai`), `Nama Bank`, `Nomor Rekening`, `Nama Rekening`, `Aktif` (`Ya`/`Tidak`), `Catatan`.
- **Fitur Import (`EmployeeSalaryImport`)**:
  - Resolusi Karyawan multi-identifier: `employee_id`, `nik`, `pin`, `email`, atau `nama`.
  - Otomatis menonaktifkan pengaturan gaji lama karyawan jika record baru berstatus Aktif.
  - Otomatis membuat komponen gaji `BASIC` sesuai nominal gaji pokok.
  - Mendukung komponen gaji tambahan dinamis jika nama kolom di Excel cocok dengan kode/nama komponen pada `salary_components`.
  - Memperbarui data rekening bank dan `base_salary` pada profil karyawan (`Employee`).

---

## 10. Attendance Live Search Filter (Pencarian Kehadiran Live Data)
- **Menu Kehadiran**: `/attendances` (`AttendanceController::index`)
- **Filter Live Search**: Dropdown static employee diganti dengan input live search (`search`) dengan debounce 300ms, clear button, dan live asynchronous data fetch.
- **Dukungan Pencarian**: Mencari karyawan berdasarkan `first_name`, `last_name`, `employee_id`, `nik`, `email`, atau nama lengkap secara real-time tanpa full page reload.

---

## 11. Employee Live Search Filter (Pencarian Karyawan Live Data)
- **Menu Karyawan**: `/employees` (`EmployeeController::index`)
- **Filter Live Search**: Input pencarian real-time (debounce 300ms) untuk nama depan/belakang/lengkap, NIK, ID Karyawan, PIN, dan email secara asinkron tanpa reload halaman.

---

## 12. Employee Employment Type (Status Kepegawaian YPI Al Azhar / YAPI)
- **Penggantian Kolom**: Kolom NIK Manajer digantikan dengan **Status Kepegawaian** (`employment_type`) dengan opsi `YPI Al Azhar` dan `YAPI`.
- **Database Schema**: Kolom `employment_type` (string 50, nullable) pada tabel `employees` dengan index `['company_id', 'employment_type']`.
- **Bulk Select pada Daftar Karyawan**:
  - Terdapat checkbox Select All di header tabel dan checkbox di setiap baris karyawan.
  - Floating action bar memungkinkan memilih banyak karyawan dan mengubah status kepegawaiannya sekaligus menjadi `YPI Al Azhar`, `YAPI`, atau dikosongkan.
- **Filter & Export/Import**:
  - Filter `Kepegawaian` tersedia di header filter `/employees`.
  - Form Tambah & Edit Karyawan (`employees/create.blade.php`, `employees/edit.blade.php`) dan halaman detail (`employees/show.blade.php`) telah disesuaikan.
  - Template Excel Karyawan (`EmployeeTemplateExport`) dan Import (`EmployeeImport`) serta panduan pada halaman `/imports/employees` telah diperbarui dengan kolom `Status Kepegawaian` (`YPI Al Azhar` / `YAPI`).

---

## 13. Reports System Live Search & Landscape PDF Export
- **Laporan Karyawan (`/reports/employees`)**:
  - Input Live Search (debounced 300ms) untuk nama, ID, NIK, PIN, dan email.
  - Filter `Kepegawaian` (`YPI Al Azhar` / `YAPI`).
  - Export PDF & Excel dinamis mengikuti kata kunci pencarian dan filter aktif.
  - Layout PDF didesain ulang dengan orientasi **A4 Landscape**, header perusahaan formal, styling tabel modern dan rapi.
- **Laporan Kehadiran (`/reports/attendance`)**:
  - Dropdown statis karyawan dihilangkan dan diganti dengan input Live Search karyawan.
  - Perbaikan bug export: filter pencarian, karyawan tertentu, departemen, dan rentang tanggal kini terfilter secara presisi pada hasil export Excel maupun PDF.
  - Layout PDF berorientasi **A4 Landscape**.
- **Laporan Cuti (`/reports/leave`)**:
  - Input Live Search karyawan (debounced 300ms).
  - Export Excel & PDF menerapkan semua filter aktif (`search`, `department_id`, `leave_type_id`, `status`, `start_date`, `end_date`).
  - Layout PDF berorientasi **A4 Landscape**.
- **Laporan Penggajian (`/reports/payroll`)**:
  - Input Live Search karyawan (debounced 300ms).
  - Export Excel & PDF memfilter karyawan sesuai query pencarian.
  - Layout PDF berorientasi **A4 Landscape**.

---

## 14. Dynamic Flextime Shift Calculation (Perhitungan Fleksi Time Berbasis Menit Dinamis)
- **Konsep & Aturan Bisnis**:
  - Pada jadwal kerja fleksibel (`is_flexible = true`), batas toleransi keterlambatan (`late_tolerance`, misal 60 menit) berlaku sebagai jendela kedatangan fleksibel.
  - Karyawan yang datang setelah jam masuk standar (misal datang 07:25 dengan patokan 07:00 dan toleransi 60 menit) **tidak dianggap terlambat** selama masih dalam batas toleransi fleksi (`late_minutes = 0`, status `on_time` / `present`).
  - **Jam Pulang Target Dinamis** (`target_clock_out`) otomatis bergeser sebesar menit kedatangannya (misal $16:00 + 25\text{ menit} = \mathbf{16:25}$).
  - Karyawan wajib pulang pada atau setelah target jam pulang dinamis ($\ge 16:25$) untuk memenuhi durasi kerja penuh shift.
  - **Evaluasi Pulang Awal**: Jika karyawan pulang sebelum target jam pulang dinamis (dikurangi `early_leave_tolerance`, misal pulang jam 16:00 dengan target 16:25 dan toleransi 5 menit), dihitung **Pulang Awal** (`early_leave_minutes = 25`, status `early`).
  - **Kedatangan Melebihi Toleransi Fleksi**: Jika datang melebihi toleransi fleksi (misal 08:15 dengan toleransi 60 menit), menit terlambat dihitung $75 - 60 = 15\text{ menit}$ (status `late`), dan pergeseran jam pulang maksimal mentok di batas toleransi ($16:00 + 60\text{ menit} = 17:00$).
- **Implementasi Core**:
  - `WorkSchedule`: Method `getFlexiMinutes()`, `getScheduledEnd($date, $clockIn)`, `isEarlyLeave()`, `getEarlyLeaveMinutes()`, dan `getOvertimeMinutes()` mendukung evaluasi jam masuk fleksibel (`$clockIn`).
  - `Attendance`: Method `getDynamicScheduledEndDatetime()` menghitung pergeseran target jam pulang dinamis dan digunakan pada `clockOut()` serta `recalculate()`.
  - `Api/V1/AttendanceController::today`: Mengembalikan field `target_clock_out`, `flexi_minutes`, dan `is_flexible` pada response JSON.
  - `AttendanceTodayModel` (Flutter): Model mobile diperbarui untuk menerima field target fleksi dinamis.
  - Web Views: Halaman `/work-schedules/{id}` dan `/attendances/{id}` menampilkan informasi dan target jam pulang dinamis flextime.

---

## 15. Push Notification System (Firebase Cloud Messaging / FCM HTTP v1)
- **Firebase Project**: `siharis-app` (Project Number: `18322324609`, Package: `id.yapinet.siharis`).
- **Sender (Laravel Backend)**:
  - Menggunakan **Firebase Cloud Messaging HTTP v1 API** (`POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send`) dengan autentikasi OAuth2 Bearer token dari Service Account Private Key.
  - File Service Account Key: `storage/app/firebase/firebase-service-account.json` (dikecualikan dari Git).
  - `.env` variables:
    ```env
    FIREBASE_PROJECT_ID=siharis-app
    FIREBASE_CREDENTIALS_PATH=storage/app/firebase/firebase-service-account.json
    ```
  - `FcmService` (`app/Services/FcmService.php`): Mengelola pengiriman notifikasi ke device token individual maupun bulk, mendeteksi token invalid (`UNREGISTERED`, `NOT_FOUND`, dll) dan otomatis menonaktifkannya di database `device_tokens`.
  - `PushNotificationService` (`app/Services/PushNotificationService.php`): Hook otomatis untuk event presensi (Clock In/Out), pengajuan cuti & persetujuan cuti, pengumuman perusahaan, ketersediaan slip gaji, dan rekap keterlambatan/pulang awal (`SendAttendanceRecapCommand`).
- **Receiver (Flutter Mobile App)**:
  - Konfigurasi Google Services: `flutter_fe/android/app/google-services.json` (dikecualikan dari Git).
  - Android Gradle: `com.google.gms.google-services` di `settings.gradle.kts` dan `app/build.gradle.kts`.
  - Android Manifest: Izin `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, serta metadata `high_importance_channel`.
  - Inisialisasi: `Firebase.initializeApp()` dan `FirebaseMessaging.onBackgroundMessage` di `main.dart`.
  - `NotificationService` (`lib/core/services/notification_service.dart`): Izin notifikasi, registrasi device token ke `POST /api/v1/device-tokens`, `flutter_local_notifications` untuk heads-up banner saat foreground, dan handling tap notifikasi.
  - Feature Flag: `FeatureConfig.enablePushNotification = true`.

---

## 16. Attendance Recap System & Notification Routing Policy
- **Channel Policy**:
  - **WhatsApp**: Digunakan **KHUSUS untuk pengiriman OTP** login/verifikasi via `OtpService` & `WhatsAppNotificationService`. **TIDAK** digunakan untuk rekap presensi.
  - **Mobile Push Notification (In-App)**: Rekap presensi dikirimkan secara langsung ke aplikasi mobile karyawan (`NotificationScreen` & FCM Push) via `SendAttendanceRecapCommand` dan `PushNotificationService`.
  - **Email**: Opsional jika diaktifkan pada pengaturan perusahaan (`enable_attendance_recap` & `attendance_recap_send_email`).
- **Template Standar Rekap Presensi**:
  ```text
  📊 REKAP ABSEN BULANAN [NAMA_PERUSAHAAN]
  Nama: [Nama Karyawan]
  Periode: [dd/mm/yyyy] - [dd/mm/yyyy]
  =============================
  Hari Kerja (Senin-Jumat): [X] hari
  Hari Sabtu: [Y] hari
  Total: [Z] hari

  ⏰ Datang Terlambat:
  • > 5 menit: [L]x
  ```
- **Kalkulasi Periode Cutoff Bulanan**:
  - Jika `attendance_recap_day_of_month` > 1 (contoh: 21 pada YAPI), periode dihitung dari tanggal 21 bulan sebelumnya hingga tanggal 20 bulan berjalan (contoh tanggal eksekusi 21 Agustus 2026 -> periode `21/07/2026 - 20/08/2026`).
  - `AttendanceRecapService` memisahkan presensi hari Senin-Jumat (`weekday_present_days`), hari Sabtu (`saturday_present_days`), serta akumulasi keterlambatan lebih dari 5 menit (`late_gt_5_days`).

---

## 17. Timezone Synchronization & Mobile Screen Fixes (v1.0.9+16)
- **Eliminasi Duplicate Push Notifications**:
  - Pada Laravel 11, Event Listener di `app/Listeners` terdaftar secara otomatis via Event Discovery. Panggilan manual `Event::listen` di `AppServiceProvider.php` dihapus agar listener `AttendanceClockIn`, `AttendanceClockOut`, `LeaveRequestApproved`, dan `LeaveRequestRejected` tidak terduplikasi (mengatasi notifikasi masuk 2x).
- **Sinkronisasi Waktu WIB pada Notifikasi & Pesan**:
  - `PushNotificationService` mengonversi waktu presensi ke timezone perusahaan (`$attendance->company?->timezone ?? 'Asia/Jakarta'`) sebelum memformat string pesan notifikasi ("pukul 16:32" bukan "09:32").
  - `NotificationScreen` pada aplikasi Flutter memanggil `.toLocal()` pada parsing `createdAt` (`DateTime.parse(notification.createdAt).toLocal()`) di list item, header grouping, dan modal detail bottom sheet.
- **Kalkulasi Jam Kerja Aktif & Keterlambatan Real-time (Screen Clock)**:
  - `AttendanceController::today()` dan Flutter `AttendanceScreen` menghitung durasi jam kerja berjalan secara dinamis saat karyawan sedang aktif bekerja (`clock_in` ada dan `clock_out` belum dilakukan), sehingga tidak lagi tampil `0m`.
  - Field `schedule.name` disertakan dalam response API `/attendance/today` agar badge shift kerja (mis. *Fleksi Time*) tampil pada kartu jadwal.
  - Tampilan *Jadwal Pulang* pada shift fleksibel menampilkan jam target dinamis (mis. `16:00 (Fleksi 16:30)`).
  - Sanitasi time string pada `Attendance::getScheduledStartDatetime()` dan `getScheduledEndDatetime()` untuk mencegah error parsing datetime ganda.
- **Redesain Kartu Riwayat Kehadiran (Attendance History Screen)**:
  - Layout `_buildHistoryItem` dirombak menjadi kartu modern 2-tier (Baris atas: Pill Tanggal, Hari, Badge Status, Chevron; Baris bawah: Waktu Masuk, Waktu Pulang, dan Badge Durasi Jam Kerja) untuk menghilangkan masalah tampilan yang berdempetan (*overlapping*).
- **Rilis Mobile App v1.0.9+16**:
  - Bump versi di `pubspec.yaml` ke `1.0.9+16`.
  - Update fallback version string di `splash_screen.dart` dan `profile_screen.dart` ke `v1.0.9`.
  - Downloadable artifacts di `/downloads`: `siharis-latest.apk`, `siharis-latest.aab`, `siharis-latest.ipa`, dan `VERSION` (`1.0.9+16`).











