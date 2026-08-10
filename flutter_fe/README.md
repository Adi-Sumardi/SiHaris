# GajiPro Mobile App - HRIS & Payroll untuk Karyawan

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/BLoC-9.0-blueviolet?style=for-the-badge" alt="BLoC">
  <img src="https://img.shields.io/badge/ML_Kit-Face_Detection-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="ML Kit">
  <img src="https://img.shields.io/badge/Firebase-Messaging-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.jagoflutter.gajipro" target="_blank">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="60">
  </a>
</p>

GajiPro Mobile adalah aplikasi **Employee Self-Service** yang memungkinkan karyawan mengelola kehadiran, cuti, lembur, dan melihat slip gaji langsung dari smartphone. Terintegrasi dengan backend GajiPro Laravel.

---

## Statistik Project

| Metrik | Jumlah | Keterangan |
|--------|--------|------------|
| **Feature Modules** | 19 | Modul fitur terpisah (Clean Architecture) |
| **BLoC Classes** | 40+ | State management per fitur |
| **API Endpoints** | 50+ | Integrasi REST API |
| **UI Components** | 15+ | Reusable widgets (JagoButton, JagoCard, dll) |
| **Services** | 10+ | Core services (Camera, Location, Face Recognition) |
| **Models** | 30+ | Request/Response DTOs |

---

## Daftar Isi - Marketing Points

- [1. FITUR ABSENSI (Attendance)](#1-fitur-absensi-attendance)
- [2. FITUR FACE RECOGNITION](#2-fitur-face-recognition)
- [3. FITUR SLIP GAJI (Payslip)](#3-fitur-slip-gaji-payslip)
- [4. FITUR CUTI (Leave Management)](#4-fitur-cuti-leave-management)
- [5. FITUR LEMBUR (Overtime)](#5-fitur-lembur-overtime)
- [6. FITUR REIMBURSEMENT](#6-fitur-reimbursement)
- [7. FITUR APPROVAL (Manager)](#7-fitur-approval-manager)
- [8. FITUR PAJAK (Tax Forms)](#8-fitur-pajak-tax-forms)
- [9. FITUR PINJAMAN (Loan)](#9-fitur-pinjaman-loan)
- [10. FITUR PENGUMUMAN (Announcements)](#10-fitur-pengumuman-announcements)
- [11. FITUR LOKASI KANTOR](#11-fitur-lokasi-kantor)
- [12. FITUR NOTIFIKASI](#12-fitur-notifikasi)
- [13. FITUR PROFIL KARYAWAN](#13-fitur-profil-karyawan)
- [14. ARSITEKTUR & TECH STACK](#14-arsitektur--tech-stack)

---

## 1. FITUR ABSENSI (Attendance)

### 1.1 Clock In/Out dengan Selfie
**Marketing Point:** "Absensi mudah dengan satu tap dan foto selfie"

| Fitur | Detail | Benefit |
|-------|--------|---------|
| Foto selfie wajib | Capture wajah saat absen | Bukti visual kehadiran |
| Timestamp server | Waktu dari server, bukan HP | Anti manipulasi waktu |
| Status real-time | Tampilkan status sudah clock in/out | Karyawan tahu statusnya |

**Flow Absensi:**
```
Buka App → Dashboard → Tap Clock In → Ambil Selfie → GPS Validated → Success!
```

### 1.2 Validasi GPS Lokasi
**Marketing Point:** "Pastikan karyawan absen dari lokasi yang benar"

| Fitur | Detail | Benefit |
|-------|--------|---------|
| GPS accuracy | Akurasi sampai meter | Presisi tinggi |
| Multiple locations | Support banyak lokasi kantor | Fleksibel untuk field worker |
| Distance calculation | Haversine formula | Kalkulasi jarak akurat |
| Outside radius alert | Warning jika di luar area | Transparansi ke karyawan |

**Validasi Location:**
```
Get GPS → Check Against Assigned Offices → Calculate Distance → Allow/Deny
```

### 1.3 Riwayat Kehadiran
**Marketing Point:** "Lihat riwayat absensi lengkap dengan kalender"

| Fitur | Detail |
|-------|--------|
| Calendar view | Tampilan kalender bulanan |
| Status indicators | Warna berbeda per status (hadir, telat, alpha) |
| Detail per hari | Clock in/out time, durasi kerja |
| Filter by month | Pilih bulan untuk lihat histori |

### 1.4 Summary Kehadiran
**Marketing Point:** "Ringkasan kehadiran bulanan dalam satu layar"

| Data Summary | Contoh |
|--------------|--------|
| Total Hari Kerja | 22 hari |
| Hadir | 20 hari |
| Terlambat | 2 kali |
| Alpha | 0 hari |
| Cuti | 2 hari |
| Total Jam Kerja | 176 jam |

---

## 2. FITUR FACE RECOGNITION

### 2.1 Face Enrollment
**Marketing Point:** "Daftarkan wajah sekali, verifikasi setiap absen"

| Fitur | Detail | Benefit |
|-------|--------|---------|
| Multi-angle capture | Foto depan, kiri, kanan | Akurasi lebih tinggi |
| ML Kit detection | Google ML Kit face detection | Deteksi wajah real-time |
| TFLite embedding | Face embedding dengan TensorFlow Lite | Proses di device, cepat |
| Server sync | Embedding disimpan di server | Konsisten di semua device |

**Flow Enrollment:**
```
1. Capture foto depan (look straight)
2. Capture foto kiri (turn left)
3. Capture foto kanan (turn right)
4. Generate face embedding
5. Upload ke server
6. Enrollment complete!
```

### 2.2 Face Verification
**Marketing Point:** "Verifikasi wajah instan saat absen, anti titip absen"

| Fitur | Detail |
|-------|--------|
| Real-time detection | Deteksi wajah live dari kamera |
| Liveness check | Pastikan wajah real, bukan foto |
| Confidence score | Skor kecocokan 0-100% |
| Threshold configurable | Default 85% match |

**Verification Flow:**
```
Open Camera → Detect Face → Compare Embedding → Match Score → Allow/Deny
```

### 2.3 Face Status
**Marketing Point:** "Cek status pendaftaran wajah kapan saja"

| Status | Keterangan |
|--------|------------|
| `not_enrolled` | Belum daftar wajah |
| `enrolled` | Sudah terdaftar |
| `expired` | Perlu daftar ulang |

---

## 3. FITUR SLIP GAJI (Payslip)

### 3.1 Daftar Slip Gaji
**Marketing Point:** "Akses slip gaji bulanan langsung dari HP"

| Fitur | Detail |
|-------|--------|
| List by year | Pilih tahun untuk lihat slip |
| Monthly view | Semua bulan dalam satu tahun |
| Status badge | Paid/Pending status |
| Quick summary | Total THP per bulan |

### 3.2 Detail Slip Gaji
**Marketing Point:** "Detail lengkap pendapatan dan potongan"

**Tampilan Slip:**
```
┌─────────────────────────────────────────┐
│           SLIP GAJI                     │
│           Januari 2026                  │
├─────────────────────────────────────────┤
│ PENDAPATAN                              │
│ Gaji Pokok          : Rp 15.000.000     │
│ Tunj. Jabatan       : Rp  3.000.000     │
│ Tunj. Transport     : Rp    500.000     │
│ Lembur              : Rp  1.200.000     │
│ TOTAL               : Rp 19.700.000     │
├─────────────────────────────────────────┤
│ POTONGAN                                │
│ BPJS Kesehatan      : Rp    120.000     │
│ BPJS JHT            : Rp    400.000     │
│ PPh 21              : Rp    850.000     │
│ TOTAL               : Rp  1.370.000     │
├─────────────────────────────────────────┤
│ TAKE HOME PAY       : Rp 18.330.000     │
└─────────────────────────────────────────┘
```

### 3.3 Download PDF
**Marketing Point:** "Download slip gaji PDF untuk keperluan pribadi"

| Fitur | Detail |
|-------|--------|
| PDF generation | Generate dari server |
| Save to device | Simpan ke Downloads |
| Share option | Share via WhatsApp, Email |

---

## 4. FITUR CUTI (Leave Management)

### 4.1 Saldo Cuti
**Marketing Point:** "Cek sisa cuti real-time"

| Tipe Cuti | Allocated | Used | Remaining |
|-----------|-----------|------|-----------|
| Cuti Tahunan | 12 | 5 | 7 |
| Cuti Sakit | 14 | 2 | 12 |
| Cuti Melahirkan | 90 | 0 | 90 |

### 4.2 Ajukan Cuti
**Marketing Point:** "Ajukan cuti langsung dari HP, tidak perlu form kertas"

| Field | Keterangan |
|-------|------------|
| Tipe Cuti | Pilih dari list |
| Tanggal Mulai | Date picker |
| Tanggal Selesai | Date picker |
| Alasan | Textarea |
| Lampiran | Upload file (opsional) |

**Status Request:**
| Status | Warna | Keterangan |
|--------|-------|------------|
| `pending` | Kuning | Menunggu approval |
| `approved` | Hijau | Disetujui |
| `rejected` | Merah | Ditolak |
| `cancelled` | Abu-abu | Dibatalkan |

### 4.3 Batalkan Cuti
**Marketing Point:** "Batalkan pengajuan cuti yang masih pending"

- Hanya bisa batalkan jika status masih `pending`
- Kuota cuti akan dikembalikan setelah dibatalkan

### 4.4 Riwayat Cuti
**Marketing Point:** "Track semua pengajuan cuti"

| Data | Contoh |
|------|--------|
| Tipe | Cuti Tahunan |
| Periode | 15-17 Jan 2026 |
| Durasi | 3 hari |
| Status | Approved |
| Approved by | HR Manager |

---

## 5. FITUR LEMBUR (Overtime)

### 5.1 Ajukan Lembur
**Marketing Point:** "Ajukan lembur dengan approval workflow"

| Field | Keterangan |
|-------|------------|
| Tanggal | Kapan lembur |
| Jam Mulai | Waktu mulai |
| Jam Selesai | Waktu selesai |
| Alasan | Kenapa perlu lembur |

### 5.2 Summary Lembur
**Marketing Point:** "Ringkasan lembur bulanan"

| Data Summary | Contoh |
|--------------|--------|
| Total Jam Lembur | 15 jam |
| Estimasi Upah | Rp 1.500.000 |
| Approved | 12 jam |
| Pending | 3 jam |

### 5.3 Riwayat Lembur
**Marketing Point:** "Track semua request lembur"

| Data | Contoh |
|------|--------|
| Tanggal | 15 Jan 2026 |
| Durasi | 3 jam |
| Upah | Rp 300.000 |
| Status | Approved |

---

## 6. FITUR REIMBURSEMENT

### 6.1 Kategori Reimbursement
**Marketing Point:** "Berbagai kategori reimbursement sesuai kebijakan"

| Kategori | Budget/Bulan |
|----------|--------------|
| Transport | Rp 2.000.000 |
| Makan (Client) | Rp 1.000.000 |
| Kesehatan | Rp 5.000.000 |
| Training | Rp 10.000.000 |
| Perjalanan Dinas | Unlimited |

### 6.2 Ajukan Reimbursement
**Marketing Point:** "Ajukan reimbursement dengan upload struk"

| Field | Keterangan |
|-------|------------|
| Kategori | Pilih dari list |
| Tanggal | Tanggal transaksi |
| Jumlah | Nominal |
| Deskripsi | Detail pengeluaran |
| Lampiran | Upload struk/invoice |

### 6.3 Summary Reimbursement
**Marketing Point:** "Track penggunaan budget reimbursement"

| Data | Contoh |
|------|--------|
| Total Diajukan | Rp 3.500.000 |
| Approved | Rp 2.800.000 |
| Pending | Rp 700.000 |
| Sudah Dibayar | Rp 2.800.000 |

---

## 7. FITUR APPROVAL (Manager)

### 7.1 Pending Approvals
**Marketing Point:** "Manager approve request langsung dari HP"

| Tipe Request | Contoh |
|--------------|--------|
| Leave Requests | 5 pending |
| Overtime Requests | 3 pending |
| Reimbursements | 2 pending |

### 7.2 Approve/Reject
**Marketing Point:** "One-tap approve atau reject dengan catatan"

| Action | Keterangan |
|--------|------------|
| Approve | Setujui request |
| Reject | Tolak dengan alasan |
| View Detail | Lihat detail sebelum action |

### 7.3 Approval History
**Marketing Point:** "Track semua approval yang sudah diproses"

| Data | Contoh |
|------|--------|
| Karyawan | John Doe |
| Tipe | Leave Request |
| Action | Approved |
| Tanggal | 15 Jan 2026 |

---

## 8. FITUR PAJAK (Tax Forms)

### 8.1 Daftar Bukti Potong
**Marketing Point:** "Akses Bukti Potong 1721-A1 langsung dari HP"

| Data | Contoh |
|------|--------|
| Tahun | 2025 |
| No. Bukti Potong | 1.1-12.25-000001 |
| Total PPh 21 | Rp 12.500.000 |
| Status | Final |

### 8.2 Download Tax Form
**Marketing Point:** "Download Bukti Potong PDF untuk lapor SPT"

- Format PDF sesuai standar DJP
- Siap untuk lapor SPT Tahunan

---

## 9. FITUR PINJAMAN (Loan)

### 9.1 Pinjaman Aktif
**Marketing Point:** "Lihat status pinjaman dan jadwal cicilan"

| Data | Contoh |
|------|--------|
| Total Pinjaman | Rp 10.000.000 |
| Sisa Pinjaman | Rp 6.000.000 |
| Cicilan/Bulan | Rp 1.000.000 |
| Tenor | 10 bulan |

### 9.2 Jadwal Cicilan
**Marketing Point:** "Track jadwal pembayaran cicilan"

| Bulan | Nominal | Status |
|-------|---------|--------|
| Jan 2026 | Rp 1.000.000 | Lunas |
| Feb 2026 | Rp 1.000.000 | Lunas |
| Mar 2026 | Rp 1.000.000 | Pending |

---

## 10. FITUR PENGUMUMAN (Announcements)

### 10.1 Daftar Pengumuman
**Marketing Point:** "Pengumuman perusahaan langsung ke HP karyawan"

| Fitur | Detail |
|-------|--------|
| Unread badge | Jumlah belum dibaca |
| Priority indicator | Urgent/Normal |
| Date sorting | Terbaru di atas |

### 10.2 Detail Pengumuman
**Marketing Point:** "Baca pengumuman lengkap dengan attachment"

| Data | Contoh |
|------|--------|
| Judul | Libur Lebaran 2026 |
| Isi | Pengumuman lengkap... |
| Tanggal | 1 Mar 2026 |
| Lampiran | PDF, Image |

---

## 11. FITUR LOKASI KANTOR

### 11.1 Lokasi Kantor Assigned
**Marketing Point:** "Lihat lokasi kantor yang di-assign untuk absen"

| Data | Contoh |
|------|--------|
| Nama | Kantor Pusat Jakarta |
| Alamat | Jl. Sudirman No. 1 |
| Radius | 150 meter |
| Status | Aktif |

### 11.2 Map View
**Marketing Point:** "Visualisasi lokasi kantor di peta"

- Flutter Map dengan marker lokasi
- Radius circle visualization
- Current location indicator
- Distance to office

---

## 12. FITUR NOTIFIKASI

### 12.1 Push Notifications
**Marketing Point:** "Notifikasi real-time ke HP karyawan"

| Event | Notifikasi |
|-------|------------|
| Absen berhasil | "Clock in berhasil: 08:00" |
| Cuti disetujui | "Cuti Anda telah disetujui" |
| Cuti ditolak | "Cuti Anda ditolak" |
| Slip gaji | "Slip gaji Januari tersedia" |
| Pengumuman | "Pengumuman baru dari HR" |

### 12.2 Firebase Cloud Messaging
**Marketing Point:** "Teknologi push notification terpercaya"

- Firebase Cloud Messaging (FCM)
- Background & foreground handling
- Device token management

---

## 13. FITUR PROFIL KARYAWAN

### 13.1 Data Profil
**Marketing Point:** "Lihat dan update data pribadi"

**Data Pribadi:**
| Field | Contoh |
|-------|--------|
| Nama | John Doe |
| Email | john@company.com |
| No. HP | 081234567890 |
| Tanggal Lahir | 15 Jan 1990 |
| Alamat | Jl. Sudirman No. 1 |

**Data Pekerjaan:**
| Field | Contoh |
|-------|--------|
| NIK Karyawan | EMP20260001 |
| Department | Engineering |
| Position | Senior Developer |
| Tanggal Bergabung | 1 Jan 2020 |

### 13.2 Ubah Password
**Marketing Point:** "Ganti password dengan aman"

- Validasi password lama
- Requirement password baru
- Konfirmasi password

### 13.3 Hapus Akun
**Marketing Point:** "Compliance dengan Google Play Store policy"

- Fitur delete account tersedia
- Recovery period 30 hari
- Data dihapus permanent setelah 30 hari

---

## 14. ARSITEKTUR & TECH STACK

### 14.1 Clean Architecture
**Marketing Point:** "Codebase terstruktur, mudah maintain"

```
lib/
├── core/                    # Core utilities & services
│   ├── components/          # Reusable UI (JagoButton, JagoCard, dll)
│   ├── constants/           # Colors, spacing, text styles
│   ├── services/            # Camera, Location, Face Recognition
│   ├── utils/               # Formatters, validators
│   └── ml/                  # Face recognition ML
├── data/                    # Data layer
│   ├── datasources/         # Remote APIs & local storage
│   └── models/              # Request/Response DTOs
└── presentation/            # UI layer (19 modules)
    ├── auth/                # Login, Register
    ├── attendance/          # Absensi
    ├── face_recognition/    # Face enrollment & verify
    ├── home/                # Dashboard
    ├── payslip/             # Slip gaji
    ├── leave/               # Cuti
    ├── overtime/            # Lembur
    ├── reimbursement/       # Reimbursement
    ├── approval/            # Manager approvals
    ├── tax_form/            # Bukti potong
    ├── loan/                # Pinjaman
    ├── announcement/        # Pengumuman
    ├── office_location/     # Lokasi kantor
    ├── notification/        # Push notifications
    ├── profile/             # Profil karyawan
    └── settings/            # Pengaturan app
```

### 14.2 State Management (BLoC)
**Marketing Point:** "State management terprediksi dan testable"

| Pattern | Keterangan |
|---------|------------|
| BLoC | Business Logic Component |
| Events | User actions & API responses |
| States | Loading, Success, Error |
| Separation | UI terpisah dari business logic |

**Contoh BLoC per Fitur:**
```
attendance/
├── attendance_bloc.dart         # Main attendance logic
├── attendance_history_bloc.dart # History loading
├── attendance_summary_bloc.dart # Summary calculation
└── attendance_action_bloc.dart  # Clock in/out actions
```

### 14.3 Dependencies Utama

**State Management & Architecture:**
| Package | Version | Kegunaan |
|---------|---------|----------|
| flutter_bloc | 9.0.0 | State management |
| dartz | 0.10.1 | Functional programming |
| equatable | 2.0.5 | Object equality |

**Network & Storage:**
| Package | Version | Kegunaan |
|---------|---------|----------|
| http | 1.2.2 | HTTP client |
| shared_preferences | 2.5.1 | Local storage |
| path_provider | 2.1.2 | File management |

**AI & Camera:**
| Package | Version | Kegunaan |
|---------|---------|----------|
| google_mlkit_face_detection | 0.13.1 | Face detection |
| tflite_flutter | 0.12.1 | Face embedding model |
| camera | 0.11.2 | Camera access |
| image_picker | 1.1.2 | Image selection |

**Location & Maps:**
| Package | Version | Kegunaan |
|---------|---------|----------|
| geolocator | 13.0.2 | GPS location |
| flutter_map | 7.0.2 | Map display |
| latlong2 | 0.9.1 | Coordinate handling |

**Notifications:**
| Package | Version | Kegunaan |
|---------|---------|----------|
| firebase_core | 4.4.0 | Firebase initialization |
| firebase_messaging | 16.1.1 | Push notifications |

**UI & Graphics:**
| Package | Version | Kegunaan |
|---------|---------|----------|
| google_fonts | 6.2.1 | Typography |
| flutter_svg | 2.0.10+1 | SVG rendering |
| cached_network_image | 3.4.1 | Image caching |

### 14.4 Core Services

| Service | Fungsi |
|---------|--------|
| `ApiService` | HTTP client dengan logging |
| `SessionService` | Session management & auto-logout |
| `StorageService` | SharedPreferences wrapper |
| `CameraService` | Device camera operations |
| `FaceRecognitionService` | ML face detection & recognition |
| `LocationService` | GPS operations |
| `NotificationService` | Push notification handling |
| `ConnectivityService` | Network connectivity check |

### 14.5 UI Components (Design System)

| Component | Kegunaan |
|-----------|----------|
| `JagoButton` | Standardized button |
| `JagoCard` | Card container |
| `JagoAppBar` | App bar dengan back button |
| `JagoBadge` | Status badges |
| `JagoAvatar` | Profile avatar |
| `JagoEmptyState` | Empty state placeholder |
| `JagoTextField` | Input text field |
| `JagoDropdown` | Dropdown select |

### 14.6 Theme & Colors
**Marketing Point:** "UI konsisten dengan brand GajiPro"

| Color | Hex | Kegunaan |
|-------|-----|----------|
| Primary | `#0066CC` | Ocean Blue |
| Secondary | `#64748B` | Slate |
| Success | `#22C55E` | Green |
| Warning | `#F59E0B` | Amber |
| Danger | `#EF4444` | Red |
| Background | `#F8FAFC` | Light Gray |

---

## Setup Development

### Prerequisites
- Flutter 3.10 atau lebih baru
- Android Studio / VS Code
- Device fisik untuk testing face recognition
- Backend GajiPro Laravel berjalan

### Installation

```bash
# Clone repository
git clone <repo-url>
cd flutter_jagogajian_app

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Konfigurasi API

Edit file `lib/core/constants/variables.dart`:

```dart
// Production
static const String baseUrl = 'https://gajipro.jagoflutter.com';

// Development (ganti dengan IP local)
// static const String baseUrl = 'http://192.168.1.100:8000';
```

---

## Build Release

### Generate Keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
```

### Build App Bundle

```bash
# Build untuk Play Store
flutter build appbundle --release

# Build APK untuk testing
flutter build apk --release
```

Lihat dokumentasi lengkap di [docs/release-docs.md](docs/release-docs.md)

---

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/data/datasources/auth_remote_datasource_test.dart

# Run with coverage
flutter test --coverage
```

---

## Permissions

| Permission | Platform | Kegunaan |
|------------|----------|----------|
| INTERNET | Android/iOS | API calls |
| CAMERA | Android/iOS | Face recognition & selfie |
| ACCESS_FINE_LOCATION | Android/iOS | GPS validasi absensi |
| ACCESS_COARSE_LOCATION | Android | GPS fallback |
| READ_MEDIA_IMAGES | Android 13+ | Akses galeri |

---

## API Integration

### Base URL
```
Production: https://gajipro.jagoflutter.com/api/v1
```

### Authentication
- Method: Bearer Token (Laravel Sanctum)
- Token disimpan di SharedPreferences
- Auto-refresh & auto-logout

### Main Endpoints

| Module | Endpoints |
|--------|-----------|
| Auth | `/auth/login`, `/auth/profile`, `/auth/change-password`, `/auth/delete-account` |
| Attendance | `/attendance/clock-in`, `/attendance/clock-out`, `/attendance/history`, `/attendance/summary` |
| Face | `/face-recognition/enroll`, `/face-recognition/verify`, `/face-recognition/status` |
| Leave | `/leaves`, `/leaves/balance`, `/leaves/types` |
| Payslip | `/payslips`, `/payslips/{id}/download` |
| Tax | `/tax-forms`, `/tax-forms/{id}/download` |
| Reimbursement | `/reimbursements`, `/reimbursements/categories` |
| Overtime | `/overtimes`, `/overtimes/summary` |
| Approval | `/approvals/pending`, `/approvals/history` |
| Announcement | `/announcements`, `/announcements/unread-count` |
| Office | `/office-locations/assigned`, `/office-locations/validate-gps` |
| Notification | `/device-tokens/register` |

### API Documentation
- Swagger: `https://gajipro.jagoflutter.com/docs`
- OpenAPI JSON: `https://gajipro.jagoflutter.com/docs/api-docs.json`

---

## Play Store Compliance

Aplikasi ini sudah memenuhi requirement Google Play Store:

| Requirement | Status |
|-------------|--------|
| Delete account feature | ✅ Profil > Hapus Akun |
| Privacy policy | ✅ Settings > Privacy Policy |
| Permission rationale | ✅ Clear permission requests |
| Target SDK | ✅ Android 13+ (API 33) |
| 64-bit support | ✅ arm64-v8a, x86_64 |

---

## Download

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.jagoflutter.gajipro" target="_blank">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="80">
  </a>
</p>

---

## Support

- Website Demo: [gajipro.jagoflutter.com](https://gajipro.jagoflutter.com)
- Email: support@gajipro.com
- Source Code: [jagoflutter.com/academy/gajipro](https://jagoflutter.com/academy/gajipro)

---

<p align="center">
  <strong>GajiPro Mobile</strong> - Employee Self-Service di Genggaman Anda
</p>
