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
- **Pembersihan Cache**: Menghapus `holiday_calendar_*` dan `national_holidays_*` setelah generate sukses.

---

## 8. Multi-Tenant Company Scope Filter
- Penambahan filter `WHERE company_id = ?` pada query builder yang belum terscope untuk mencegah kebocoran data antar tenant (terutama pada modul Leave, Holiday, dan Attendance).

---

## 9. Employee Bulk Status Kepegawaian (Bulk Update)
- **Halaman**: `resources/views/employees/index.blade.php`
- **Fitur**: Checkbox pemilihan massal karyawan dengan floating solid blue action bar untuk mengubah status kepegawaian (`employment_type`) menjadi:
  - `YPI Al Azhar`
  - `YAPI`
  - `Kosongkan (-)`
- **Endpoint**: `POST /employees/bulk-employment-type`
- **Controller**: `EmployeeController::bulkUpdateEmploymentType()`

---

## 10. Multi-Location Attendance Assignment
- **Relasi Database**:
  - Tabel pivot `employee_office_locations` (`employee_id`, `office_location_id`, `is_primary`).
  - Relasi `Employee::officeLocations()` (Many-to-Many) dan `Employee::primaryOfficeLocation()`.
  - Relasi `OfficeLocation::employees()` (Many-to-Many).
- **Web Admin CRUD**:
  - `resources/views/employees/create.blade.php` & `edit.blade.php`: Checkbox multi-lokasi penugasan kantor dengan radio button untuk memilih lokasi utama (*Primary Location*).
  - `EmployeeController`: Menyimpan sinkronisasi pivot table `employee_office_locations`.
- **API Mobile**:
  - `GET /api/v1/office-locations/assigned`: Mengembalikan daftar semua lokasi kantor yang ditugaskan ke karyawan yang sedang login.
  - `AttendanceController::clockIn()`: Memvalidasi radius geofence GPS karyawan terhadap **SEMUA** lokasi kantor yang ditugaskan (bukan hanya 1 lokasi). Jika berada dalam radius salah satu kantor yang ditugaskan, clock-in diizinkan dan dicatat `office_location_id` yang sesuai.

---

## 11. Custom Flexible Working Hours (Shift Fleksibel Jam Masuk & Pulang)
- **Model & Database**:
  - `work_schedules.is_flexible_hours`: Flag boolean penanda shift fleksibel.
  - `work_schedules.flexible_arrival_start`: Batas awal jam masuk (contoh: `07:30`).
  - `work_schedules.flexible_arrival_end`: Batas akhir jam masuk (contoh: `08:30`).
  - `work_schedules.required_work_minutes`: Total durasi kerja wajib dalam menit (contoh: `480` menit = 8 jam).
- **Web Admin UI**:
  - `resources/views/work-schedules/create.blade.php` & `edit.blade.php`: Form input shift fleksibel dengan kalkulator durasi jam kerja otomatis.
- **Logika Perhitungan & Rekonsiliasi**:
  - Jika masuk di antara `07:30` dan `08:30` (misal `08:15`), jam pulang yang diharapkan dihitung: `08:15 + required_work_minutes` (misal `16:15`).
  - Jika clock out dilakukan sebelum jam pulang yang diharapkan, selisih waktu dicatat sebagai `early_leave_minutes`.
  - Jika masuk lewat dari `flexible_arrival_end` (misal `08:45`), dicatat `late_minutes = 15` menit dan jam pulang target dihitung dari `flexible_arrival_end + required_work_minutes`.

---

## 12. Overtime Management (Pengajuan & Perhitungan Lembur)
- **Alur Pengajuan (Mobile App & Web)**:
  - Karyawan mengajukan lembur via Mobile (`POST /api/v1/overtime-requests`) atau Web Admin (`/overtime-requests`).
  - Mendukung jenis hari: **Hari Kerja (Workday)** atau **Hari Libur/Istirahat (Day Off / Holiday)**.
  - Perhitungan jam lembur riil: `real_hours = end_time - start_time - break_minutes`.
- **Formula Pengali Upah Lembur (Depnaker)**:
  - `OvertimeSetting`: Mengatur rate upah lembur per jam dasar (`base_salary / 173`).
  - Hari Kerja: Jam ke-1 = 1.5x upah per jam, Jam ke-2 dst = 2.0x upah per jam.
  - Hari Libur: Jam 1-7 = 2.0x, Jam ke-8 = 3.0x, Jam ke-9 dst = 4.0x.
- **Integrasi Payroll**:
  - Nilai lembur yang disetujui (`status = approved`) otomatis masuk ke kalkulasi komponen slip gaji bulanan karyawan (`Overtime` payroll component).

---

## 13. Exit Management (Offboarding & Handover)
- **Alur Resign / Pemutusan Hubungan Kerja**:
  - Pengajuan exit (`EmployeeExit`): `resignation`, `termination`, `end_of_contract`, `retirement`, `other`.
  - Status alur: `pending` -> `approved` / `rejected` -> `in_progress` -> `completed`.
- **Checklist Serah Terima (Handover Tasks)**:
  - Pengembalian aset (laptop, ID card, kendaraan, kunci), clearance finance, serah terima berkas/tugas.
  - Saat status diubah menjadi `completed`, sistem otomatis mengupdate `employees.is_active = false` dan mengisi `employees.resignation_date`.

---

## 14. Organization Structure Chart (Interactive Org Chart)
- **Halaman**: `/organization-chart` (`resources/views/organization-chart/index.blade.php`)
- **Fitur**: Bagan hierarki organisasi interaktif berbasis relasi `manager_id` pada model `Employee`.
- **Komponen**: Menampilkan avatar, nama lengkap, jabatan, departemen, jumlah bawahan langsung, dan expandable node tree.

---

## 15. Push Notification Infrastructure (Firebase Cloud Messaging - FCM HTTP v1 API)
- **Sender (Laravel Backend)**:
  - Protokol: **FCM HTTP v1 API** (OAuth2 JWT Service Account) menggunakan endpoint:
    `https://fcm.googleapis.com/v1/projects/{project_id}/messages:send`
  - Konfigurasi `.env`:
    ```dotenv
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
  - `splash_screen.dart` fallback version string di-update ke `v1.1.0`.
  - Downloadable artifacts di `/downloads`: `siharis-latest.apk`, `siharis-latest.aab`, `siharis-latest.ipa`, `SiHaris-v1.1.0.apk`, `SiHaris-v1.1.0.aab`, `SiHaris-v1.1.0.ipa`, dan `VERSION` (`v1.1.0`).
