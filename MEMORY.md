# SiHaris (GajiPro) — Project Memory & Architecture Notes

## 1. Production Server Details
- **IP Address (Local LAN)**: `172.16.5.204`
- **Tailscale IP**: `100.96.106.57` (Host: `aplikasi2`)
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

---

## 18. Employee Document Management & Digital Archive (v1.1.0+17)
- **Konsep & Workflow**:
  - Berfungsi sebagai **Arsip Dokumen Digital Mandiri (Self-Service Digital Archive)** bagi setiap pegawai untuk mengunggah dan menyimpan berkas penting (SK, Sertifikat, KTP, KK, Ijazah, NPWP, BPJS Kesehatan, BPJS Ketenagakerjaan, Kontrak Kerja, dan Berkas Lainnya).
  - *Direct Management*: Tidak memerlukan alur verifikasi/approval bertingkat dari HR. Karyawan bebas mengunggah, melihat pratinjau, mengunduh, dan menghapus dokumen miliknya sendiri kapan saja.
- **Backend & REST API (Laravel)**:
  - Model: `app/Models/EmployeeDocument.php` dengan tipe dokumen terstandarisasi (`sk`, `ktp`, `kk`, `npwp`, `bpjs_kesehatan`, `bpjs_ketenagakerjaan`, `ijazah`, `sertifikat`, `kontrak_kerja`, `other`).
  - **Storage & Security**: Berkas fisik disimpan di disk `local` privat (`storage/app/documents/{company_id}/{employee_id}/`) demi keamanan data pribadi pegawai (NIK, KTP, KK, SK), bukan di public web root yang dapat ditebak.
  - **Signed Temporary URLs**: `preview_url` dan `download_url` dibuat secara dinamis menggunakan HMAC SHA-256 token bertanda tangan dengan masa berlaku sementara (`URL::temporarySignedRoute`), sehingga file aman dibuka di external browser / PDF viewer tanpa membocorkan Sanctum Bearer token.
  - Endpoint API (`/api/v1/documents`):
    - `GET /api/v1/documents`: Mengambil daftar berkas milik pegawai login (mendukung filter `type` dan query pencarian `search`).
    - `GET /api/v1/documents/types`: Metadata kategori berkas beserta label dan icon helper.
    - `POST /api/v1/documents`: Unggah berkas baru (multipart file: PDF/JPG/PNG max 10MB, nomor dokumen, tanggal terbit, masa berlaku, catatan).
    - `GET /api/v1/documents/{id}`: Detail metadata dokumen.
    - `GET /api/v1/documents/{id}/preview`: Stream binary file inline dengan validasi signature token.
    - `GET /api/v1/documents/{id}/download`: Mengunduh berkas fisik asli dengan validasi signature token.
    - `DELETE /api/v1/documents/{id}`: Soft delete berkas milik pegawai yang sedang login.
  - Web Admin Central Explorer (`/documents` via `DocumentController`):
    - **Header & Quick Action**: Tombol **"Upload Dokumen"** (membuka modal unggah langsung di halaman) dan tombol **"Daftar Karyawan"**.
    - **Statistik Ringkasan (`.stat-card`)**: 4 kartu statistik visual modern (*Total Berkas*, *Pegawai Terdata*, *Total SK*, *Total Sertifikat*) dengan hover elevation dan badge status.
    - **Form Filter & Pencarian Rapi**: Flex layout inline proporsional (Search bar, dropdown Departemen, dropdown Jenis Dokumen, tombol Filter & Reset) menggantikan grid yang sebelumnya pecah.
    - **Quick Category Pills**: Tab kategori cepat horizontal (*Semua*, *SK*, *Sertifikat*, *KTP*, *KK*, *Ijazah*) dengan counter badge jumlah berkas aktif.
    - **Tabel Standar (`<x-table>`)**: Avatar pegawai bergradien, NIP & departemen, badge jenis dokumen tematik, indikator tipe file (PDF/IMG) & ukuran file (*human-readable*), tanggal unggah, serta tombol aksi Pratinjau, Unduh, dan Hapus.
    - **Modal Upload Dokumen**: Rute `POST /documents` (`documents.store`) memvalidasi dan menyimpan berkas pegawai langsung dari modal admin.
    - **Modal Preview In-Browser**: Pratinjau dokumen PDF (iframe viewer) dan gambar langsung dengan header info dan shortcut tombol `Esc`.
    - **Empty State Informatif**: Ilustrasi dan tombol call-to-action saat belum ada berkas atau saat filter pencarian tidak menemukan hasil.
    - Menu `Dokumen Pegawai` terintegrasi pada navigasi sidebar Admin HR (`resources/views/layouts/admin.blade.php`).
- **Aplikasi Mobile (Flutter FE v1.1.0+17)**:
  - **Menu Cepat Home Screen**: Menu cepat `Slip Gaji` digantikan oleh `Berkas` (`/documents`) dengan icon `Icons.folder_shared_outlined` dan tema warna modern Indigo (`0xFF4F46E5`), karena Slip Gaji sudah tersedia secara permanen di Bottom Navigation Bar.
  - **Menu Profil**: Ditambahkan section dedicated **"Dokumen & Berkas Pegawai"** (`Berkas & Dokumen Saya`).
  - **Layar Berkas (`DocumentListScreen`)**:
    - Filter kategori berbasis horizontal scrollable chips (`Semua`, `SK`, `KTP`, `KK`, `Sertifikat`, dll).
    - Search bar real-time untuk mencari berkas berdasarkan nama/nomor.
    - Kartu berkas modern dengan badge kategori warna-warni, penanda tipe file (PDF / Gambar), badge tanggal berlaku / kadaluarsa, dan dropdown quick action (Pratinjau, Unduh, Hapus).
    - Floating Action Button (+ Tambah Berkas) dengan animasi modern.
  - **Layar Unggah (`DocumentUploadScreen`)**:
    - Pemilihan kategori via bottom sheet modal yang elegan.
    - Pilihan sumber berkas: Kamera langsung, Galeri foto, atau File Dokumen PDF (menggunakan `file_picker` & `image_picker`).
    - Form metadata lengkap: Nomor Dokumen, Tanggal Terbit, Masa Berlaku (dengan opsi *Berlaku Seumur Hidup*), dan Catatan Tambahan.
  - **Layar Detail (`DocumentDetailScreen`)**:
    - Pratinjau interaktif zoomable untuk gambar (`InteractiveViewer` + `CachedNetworkImage`) dan dokumen PDF.
    - Ringkasan metadata lengkap (Format, Ukuran File, Waktu Unggah, dll) dan tombol unduh/buka file asli.
- **Rilis Mobile App v1.1.0+17**:
  - `pubspec.yaml`: `version: 1.1.0+17`.
  - `splash_screen.dart` fallback version string: `v1.1.0`.
  - Downloadable artifacts di `/downloads`: `siharis-latest.apk`, `siharis-latest.aab`, `siharis-latest.ipa`, `SiHaris-v1.1.0.apk`, `SiHaris-v1.1.0.aab`, `SiHaris-v1.1.0.ipa`, dan `VERSION` (`1.1.0`).
  - Web & Direct APK download URL: `https://siharis.yapinet.id/download/android` (mengembalikan file `SiHaris-v1.1.0.apk`).

---

## 19. FCM Token Startup Auto-Registration (Push Notification Hotfix)
- **Problem**:
  - Push notification di Laravel backend (`PushNotificationService`) sudah aktif dan terintegrasi ke event Clock In/Out, Approval Cuti, Slip Gaji, dan Pengumuman.
  - Namun di database production, tabel `device_tokens` kosong (`DeviceToken::count() == 0`), sehingga FCM tidak memiliki target device token untuk dikirimi push.
  - **Root Cause**: `NotificationWrapper` sebelumnya hanya memicu registrasi token saat event `LoginSuccess` (fresh login). User yang sudah login sebelumnya (sesi tersimpan via `AuthLocalDatasource`) langsung melewati `SplashScreen` ke `MainScreen` tanpa memicu event `LoginSuccess`, sehingga token perangkat tidak pernah terdaftar.
- **Fix**:
  - `NotificationWrapper` kini mengecek `AuthLocalDatasource.isLoggedIn()` saat inisialisasi awal (*cold start* / startup).
  - Jika user sudah dalam kondisi login, sistem otomatis mengambil dan mendaftarkan FCM device token ke endpoint `POST /api/v1/device-tokens`.
  - `NotificationService` dan `AuthLocalDatasourceBase` dibuat *injectable* dengan unit/widget tests komprehensif di `test/presentation/notification/widgets/notification_wrapper_test.dart` (956 test lolos).
- **Download Endpoint**:
  - Rute resmi download APK: `https://siharis.yapinet.id/download/android` (alias: `/download/apk`) via `AppDownloadController@downloadAndroid` yang menyajikan file dengan Content-Disposition `SiHaris-v1.1.0.apk`.

---

## 20. Session-Scoped Login (Per-Device Token) & Attendance 500 Fix

- **Bug 1 — Auto-logout saat clock-in**:
  - **Root Cause**: `AuthController::login()` memanggil `$user->tokens()->delete()` (revoke SEMUA token milik user) setiap kali login, tanpa memandang device. Jika akun yang sama login dari device lain (atau double-tap tombol Masuk memicu dua request login), token yang sedang aktif di HP langsung ter-revoke di server. Request API berikutnya (mis. clock-in) balas `401` dan `SessionService.handleSessionExpired()` langsung memaksa logout tanpa pesan error — terlihat seperti "app tiba-tiba nge-log out sendiri".
  - **Fix**: Token kini diberi nama `mobile-app:{app_device_id}` (device id yang sama dipakai untuk anti-fraud device-binding absensi) dan hanya token dengan nama itu yang di-revoke saat login ulang — device lain tidak lagi ikut ter-logout. `AuthRemoteDatasource.login()` sekarang mengirim `app_device_id` di body request login.
- **Bug 2 — "Server Error" saat clock-in pakai face recognition**:
  - **Root Cause**: `Attendance::clockIn()` menulis lokasi kantor ke kolom `clock_in_office_location_id`, padahal kolom itu **tidak pernah ada** di migration manapun (kolom asli cukup `office_location_id`; hanya sisi clock-out yang punya kolom terpisah `clock_out_office_location_id`). Setiap clock-in yang berhasil menentukan office location (kasus normal saat GPS validation aktif — selalu terjadi di alur face recognition) memicu SQL error mentah → tampil sebagai "Server Error" generik di app.
  - **Fix**: satu baris — `$this->office_location_id = $data['office_location_id']` (bukan `clock_in_office_location_id`).
  - Ditemukan lewat reproduksi test Pest lokal yang meniru persis payload multipart yang dikirim app (GPS + face_verified + liveness + descriptors + foto), bukan lewat debugging live di server produksi — lihat pola kerja di README dev notes bila ada kasus serupa.
  - Ikut memperbaiki 9 test lawas yang gagal sejak commit timezone-sync sebelumnya (WIB→UTC untuk `getScheduledStartDatetime()`/`getScheduledEndDatetime()` sekarang benar, test lama tinggal disesuaikan ekspektasinya).

---

## 21. Lampiran Pengumuman (JPG/PNG/PDF) & Perbaikan UX Target Penerima

- **Lampiran Pengumuman**:
  - Kolom baru pada `announcements`: `attachment_path`, `attachment_name`, `attachment_size`, `attachment_mime_type` (nullable, disk `local` privat, pola signed-URL yang sama dengan `EmployeeDocumentController`/`PayslipController` — tidak pernah diserve langsung).
  - Web Admin (`/announcements/create` & `/edit`): field upload "Lampiran" (JPG/PNG/PDF, maks 10MB), preview + tombol hapus di form edit, tampilan inline (gambar) atau kartu buka/unduh (PDF) di halaman detail.
  - Mobile API (`/api/v1/announcements`): response `index`/`show` menyertakan `has_attachment` dan (di `show`) metadata lengkap + `attachment_preview_url`/`attachment_download_url` bertanda tangan (15 menit). Endpoint publik baru `GET /announcements/{id}/preview` & `/download`, di luar `auth:sanctum`.
  - Mobile App: `AnnouncementDetailScreen` menampilkan gambar inline atau kartu file (PDF) yang dibuka via `url_launcher`; `AnnouncementScreen` (list) menampilkan ikon klip kecil bila ada lampiran.
- **Perbaikan UX Target Penerima** (create & edit form):
  - **Jabatan Tertentu**: sebelumnya menampilkan nama jabatan saja sehingga jabatan dengan nama sama di departemen berbeda (mis. beberapa baris "Guru") tidak bisa dibedakan. Sekarang menampilkan `Guru (SD)`, `Guru (SMP)`, dst. (`Position::with('department')`).
  - **Karyawan Tertentu**: ditambahkan input pencarian (Alpine.js, filter nama + ID karyawan) di atas daftar checkbox karyawan.

---

## 22. Rilis Mobile App v1.2.0+18
- `pubspec.yaml`: `version: 1.2.0+18`.
- `splash_screen.dart` & `profile_screen.dart` fallback version string: `v1.2.0`.
- Mencakup: fix auto-logout per-device token (§20), fix Server Error clock-in wajah (§20), FCM auto-registration (§19, baru pertama kali dirilis di versi ini), fitur lampiran pengumuman (§21), perbaikan UX target penerima (§21, backend/web-only — tidak mempengaruhi versi mobile secara fungsional tapi dibundel dalam rilis yang sama).
- APK release dibuild & ditandatangani (`android/app/siharis.jks`, alias `siharis`) di `build/app/outputs/flutter-apk/app-release.apk`; package `id.yapinet.siharis`, versionCode 18, versionName 1.2.0.
- Sudah dipublish ke server produksi (`/downloads`) sebagai build resmi terbaru di sesi ini.

---

## 23. Rilis Mobile App v1.2.1+19 — Home Greeting Info Pegawai & Rounded Menu Cepat

- **Home Screen — info pegawai di greeting card**: `AuthLocalDatasource` kini menyimpan `position`/`department` dari `EmployeeModel` saat login (`_userPositionKey`/`_userDepartmentKey`, dibersihkan saat `removeAuthData()`), diakses lewat `getEmployeeInfo()` (Dart record `({String? position, String? department})`) — method konkret di luar `AuthLocalDatasourceBase` (mengikuti pola `getPrimaryOffice()`, agar tidak mengubah kontrak `getUserData()`). `HomeScreen` menampilkan baris posisi/departemen (ikon briefcase) di bawah nama pengguna pada greeting card.
- **Home Screen — rounded top edge Menu Cepat**: Section abu-abu (mulai dari "Menu Cepat") sekarang punya sudut atas membulat (radius 24) yang menyingkap warna biru header di baliknya, plus garis "grabber" kecil di tengah.
  - **Catatan penting**: pendekatan awal pakai `Container(margin: EdgeInsets.only(top: -20))` lalu `Padding(padding: EdgeInsets.only(top: -20))` untuk meniru overlap ala CSS (`margin-top: negatif`) — KEDUANYA gagal di runtime (`margin.isNonNegative`/`padding.isNonNegative` assertion), karena Flutter (tidak seperti CSS) tidak mengizinkan `EdgeInsets` negatif di `Container.margin` maupun `Padding.padding`. Solusi yang benar: `Stack` + dua `Positioned.fill` di dalam `SizedBox(height: 24)` sebagai band transisi tetap (layer bawah = gradient biru header, layer atas = `Container` abu dengan `borderRadius` atas + grabber) — diletakkan di antara `_buildHeader()` dan `_buildQuickActions()`, tanpa nilai negatif sama sekali. Kalau ada kebutuhan overlap/reveal serupa di masa depan, pakai pola `Stack`/`Positioned` ini, bukan margin/padding negatif.
  - Mockup desainnya dieksplorasi dulu via Claude Design skill (`.dc.html` di scratchpad) sebelum diterapkan ke kode asli, sesuai alur "match existing app pixel-perfectly" — file mockup TIDAK bagian dari repo/tidak disimpan permanen.
- **Login Screen — ganti logo**: Logo "Powered by" di halaman login diganti dari `assets/images/adilabs.png` ke `assets/images/yapi.png` (didownsample ke 200×200 dari source di root repo), ditampilkan kecil (`height: 28`, sebelumnya `36`).
- `pubspec.yaml`: `version: 1.2.1+19`. Fallback version string di `splash_screen.dart` & `profile_screen.dart` ikut dibump ke `v1.2.1`.
- Semua 961 test lolos (`flutter test`), `flutter analyze` bersih di file yang diubah.
- APK release dibuild & ditandatangani (`android/app/siharis.jks`) di `build/app/outputs/flutter-apk/app-release.apk`; versionCode 19, versionName 1.2.1.
- Sudah dipublish ke `/var/www/siharis/laravel-be/public/downloads/` di server produksi: `siharis-latest.apk`, `siharis-release.apk`, `SiHaris-v1.2.1.apk` (baru), `VERSION` di-update ke `1.2.1`. Dikonfirmasi lewat `https://siharis.yapinet.id/download/apk` (Content-Disposition `SiHaris-v1.2.1.apk`, content-length cocok). Build v1.2.0 sebelumnya (`SiHaris-v1.2.0.apk`) tetap disimpan sebagai arsip.

---

## 24. Rilis Mobile App v1.2.2+20 — Unifikasi Transisi Header Biru ke Body Abu-abu

- **Masalah**: setiap screen mobile (Absensi, Riwayat Kehadiran, Slip Gaji, Jadwal Shift, Berkas & Dokumen, Cuti & Izin, Lembur, Profil, Notifikasi, Login) punya treatment berbeda-beda di batas antara header biru dan body — sebagian gradient dengan arah/warna berbeda, sebagian warna flat dengan radius rounded di BAWAH header sendiri, dan dua screen (Jadwal Shift, Lembur) malah tidak punya header gradient sama sekali (pakai `AppBar` polos `AppColors.primary`); Notifikasi malah pakai `AppBar` putih tanpa warna biru sama sekali.
- **Solusi**: dieksplorasi dulu lewat 10-artboard mockup di Claude Design skill (bukan bagian repo) sebelum diterapkan ke kode asli. Diekstrak jadi 2 komponen shared, dipakai ulang oleh Home Screen (§23) dan seluruh screen lain:
  - `AppColors.headerGradient` (`core/constants/colors.dart`) — gradient standar (`primary700` → `primary600`, topLeft → bottomRight) untuk header biru semua screen.
  - `JagoHeaderBand` (`core/components/jago_header_band.dart`) — widget `SizedBox(height: 24)` berisi `Stack` + 2 `Positioned.fill` (layer bawah gradient biru, layer atas `Container` abu `scaffoldBackground` dengan `borderRadius` atas 24 + garis "grabber" abu di tengah). Ini REUSE dari pola yang sama persis dipakai `HomeScreen` (§23) — jangan duplikasi manual lagi di screen baru, import & pakai widget ini.
- **Per-screen**:
  - Absensi, Riwayat Kehadiran, Profil: gradient arah/warna diseragamkan (sebelumnya `topCenter→bottomCenter, primary600→primary700`) + `JagoHeaderBand` ditambahkan.
  - Slip Gaji, Cuti & Izin: header sebelumnya warna flat `AppColors.primary` + `BorderRadius.vertical(bottom: 24)` sendiri — diganti gradient + `JagoHeaderBand`, radius bawah pada header dihapus (rounding sekarang di band, bukan di header).
  - Jadwal Shift, Lembur: `Scaffold.appBar: AppBar(...)` dihapus total, diganti custom `_buildHeader()` gradient + `JagoHeaderBand`, body dibungkus `Column([header, band, Expanded(...)])`.
  - Notifikasi: `AppBar` putih (`AppColors.surface`) diganti custom gradient header (ikon mark-all-read + refresh jadi putih) + `JagoHeaderBand`.
  - Berkas & Dokumen (`document_list_screen.dart`, pakai `NestedScrollView`/`SliverAppBar`): gradient `[primary700, primary500]` diseragamkan ke `AppColors.headerGradient`, `Scaffold.backgroundColor` (sebelumnya custom `0xFFF8FAFC`) diseragamkan ke `AppColors.scaffoldBackground`, `JagoHeaderBand` ditambahkan sebagai child pertama `NestedScrollView.body`.
  - Login: TETAP pakai bentuk rounded-BOTTOM sendiri (bodinya putih, bukan grey scaffold, jadi trik reveal-band tidak relevan di sini) — hanya arah/warna gradient yang diseragamkan ke `AppColors.headerGradient`. Logo "Powered by" (§23) juga dibesarkan dari `height: 28` ke `44` di rilis ini (masukan user: "kekecilan").
- `pubspec.yaml`: `version: 1.2.2+20`. Fallback version string di `splash_screen.dart` & `profile_screen.dart` ikut dibump ke `v1.2.2`.
- Semua 961 test lolos (`flutter test`), `flutter analyze` bersih (tidak ada issue baru, semua warning yang tersisa pre-existing & tidak terkait perubahan ini).
- APK release dibuild & ditandatangani (`android/app/siharis.jks`) di `build/app/outputs/flutter-apk/app-release.apk`; versionCode 20, versionName 1.2.2.
- Sudah dipublish ke `/var/www/siharis/laravel-be/public/downloads/`: `siharis-latest.apk`, `siharis-release.apk`, `SiHaris-v1.2.2.apk` (baru), `VERSION` di-update ke `1.2.2`. Dikonfirmasi lewat `https://siharis.yapinet.id/download/android` (Content-Disposition `SiHaris-v1.2.2.apk`, content-length cocok). Build v1.2.1/v1.2.0 sebelumnya tetap disimpan sebagai arsip.

---

## 25. Fitur Import Data Cuti (Web Admin, `/imports/leave-requests`)

- **Masalah**: modul Cuti & Izin di web admin punya import untuk *Jenis Cuti* (`imports.leave-types`), tapi tidak ada cara mengimpor *riwayat/histori pengajuan cuti* karyawan dari sistem lama secara massal — HR harus input satu-satu.
- **Solusi**: dibuat mengikuti pola import yang sudah ada persis (Leave Type Import & Employee Salary Import sebagai referensi):
  - `App\Imports\LeaveRequestImport` (`ToModel, WithHeadingRow, WithValidation, SkipsEmptyRows`) — resolve karyawan secara fleksibel (ID Karyawan/PIN/NIK/Email/Nama, termasuk yang sudah `withTrashed()`), resolve jenis cuti via kode atau nama, hitung `total_days` otomatis dari rentang tanggal kalau kolom "Jumlah Hari" kosong, dukung setengah hari & 4 status (Disetujui/Menunggu/Ditolak/Dibatalkan, default Disetujui karena tujuannya migrasi data historis).
  - **Penting**: karena baris diimpor langsung (bukan lewat `LeaveRequest::approve()/reject()`), tidak ada `pending_days` yang bisa "dikonversi" — importer nge-adjust `LeaveBalance` (`used_days` untuk status approved, `pending_days` untuk status pending via `firstOrCreate` + `deductDays()`/`addPendingDays()`) secara langsung, bukan lewat method approve/reject bawaan model.
  - `App\Exports\Templates\LeaveRequestTemplateExport` — file `template_data_cuti.xlsx` dengan 3 baris contoh (termasuk contoh setengah hari).
  - `App\Http\Controllers\Import\LeaveRequestImportController` (`index/template/store`) + view `resources/views/imports/leave-requests/index.blade.php` — identik strukturnya dengan `imports/leave-types/index.blade.php` (dropzone upload, tombol Download Template, panel "Panduan Import").
  - Rute terdaftar di grup `imports.` (`routes/web.php`) sebagai `imports.leave-requests.{index,template,store}`.
  - Tombol "Import" ditambahkan di toolbar `leave-requests/index.blade.php` (sebelah "Ajukan Cuti"), style sama dengan tombol Import di halaman Jenis Cuti.
- **Test**: `tests/Feature/Import/LeaveRequestImportTest.php`, 16 test (resolve karyawan/jenis cuti, hitung hari otomatis vs eksplisit, setengah hari, efek ke saldo per status, baris di-skip untuk data tidak valid) — semua lolos. Full suite backend: 2254 passed, 3 failed pre-existing & tidak terkait (`PortalLeaveControllerTest`, gagal juga di `main` sebelum perubahan ini — kemungkinan sensitif terhadap tanggal `now()`, bukan regresi).
- **Deploy**: `git pull` di server produksi (`/var/www/siharis`), cache Laravel di-clear & di-cache ulang **sebagai `www-data`** (`sudo -u www-data php artisan config:clear/cache:clear/route:clear/view:clear` lalu `config:cache/route:cache` — **jangan lupa `-u www-data`**, sempat kelupaan sekali di sesi ini dan bikin `bootstrap/cache/{config,routes-v7}.php` ke-generate ulang milik `root:root` alih-alih `www-data:www-data`; langsung diperbaiki dengan re-run pakai `-u www-data`), `php8.3-fpm` & `siharis-worker` di-restart. Rute baru dikonfirmasi ada di `route:list --name=imports.leave-requests` di server.

---

## 26. Simplifikasi Kolom Status di Halaman Absensi (`/attendances`)

- **Masalah**: kolom STATUS di tabel `attendances/index.blade.php` menampilkan badge "Terlambat" terpisah dari detail jam masuk yang sudah ada sebagai sub-teks di bawah kolom Jam Masuk (`clock_in_status === 'late'/'very_late'` → "Terlambat Xm" / "Sangat Terlambat") — informasi terlambat jadi dobel/tersebar. Sub-teks "pulang cepat" di kolom Jam Pulang (`clock_out_status === 'early'`) juga belum menampilkan jumlah menitnya (cuma teks "Pulang Awal" polos), padahal versi "Terlambat" sudah pakai format `Xm`.
- **Fix** (murni view, `resources/views/attendances/index.blade.php`):
  - Kolom STATUS: kalau `$attendance->status === 'late'`, tampilkan badge "Hadir" (hijau/success) — bukan `status_label`/`status_color` bawaan (yang akan menampilkan "Terlambat"/warning). Status lain (`present`/`absent`/`half_day`/`leave`/`holiday`/`weekend`) tetap pakai accessor asli, tidak diubah — kolom status sekarang efektif hanya menampilkan Hadir/Tidak Hadir untuk kasus harian biasa, sementara detail keterlambatan tetap terlihat di kolom Jam Masuk.
  - Kolom Jam Pulang: teks "Pulang Awal" diganti "Pulang Cepat {{ early_leave_minutes }}m", konsisten dengan format "Terlambat Xm" di kolom Jam Masuk.
  - **Aman secara data**: `status` dan `clock_in_status`/`late_minutes` SELALU di-set bersamaan dalam blok kondisi yang sama di `Attendance::clockIn()`/`recalculate()` (`app/Models/Attendance.php`) — jadi tidak ada risiko baris `status='late'` kehilangan info keterlambatannya di kolom Jam Masuk setelah perubahan ini.
  - Filter dropdown "Terlambat" (`status=late`) di toolbar TIDAK diubah — tetap berguna untuk admin yang mau filter data.
- Tidak ada perubahan model/migration/route, jadi deploy cukup `git pull` + `php artisan view:clear` (sebagai `www-data`), tanpa restart `php8.3-fpm`/`siharis-worker`.









