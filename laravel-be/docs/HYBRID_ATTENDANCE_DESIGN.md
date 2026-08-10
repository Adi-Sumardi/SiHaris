# Desain Absensi Hybrid: Mesin Fingerprint + Aplikasi (Face Detection)

**Status:** Draft desain (belum diimplementasi)
**Tujuan:** Karyawan dapat absen melalui **dua kanal** yang saling menjadi cadangan:
1. **Aplikasi mobile** (face detection + GPS + selfie) — sudah ada.
2. **Mesin fingerprint** (ZKTeco / Fingerspot / Solution / dsb).

Jika aplikasi bermasalah → pakai mesin. Jika mesin rusak → pakai aplikasi.
Sistem **wajib mencegah double-absen**: bila karyawan sudah absen masuk lewat
salah satu kanal, kanal lain tidak boleh membuat absen masuk kedua.

---

## 1. Prinsip Inti

### 1.1 Satu sumber kebenaran (Single Source of Truth)
Kedua kanal menulis ke **tabel `attendances` yang sama**. Tabel ini sudah memiliki:

```
unique(['employee_id', 'date'])     // 1 baris per karyawan per hari
clock_in  datetime nullable          // jam masuk
clock_out datetime nullable          // jam pulang
```

Artinya **anti-double-absen sudah terjamin secara struktural**: tidak mungkin ada
dua baris untuk hari yang sama. "Double clock-in" = mencoba mengisi `clock_in`
yang sudah terisi. Reconciliation cukup memberlakukan aturan:

> `clock_in` hanya diisi jika masih `null`, **atau** jika timestamp yang masuk
> lebih awal dari nilai yang tersimpan (untuk menangani log mesin yang datang terlambat).

### 1.2 Kanal sebagai metadata, bukan tabel terpisah
Tambahkan kolom **sumber** pada setiap event masuk/pulang agar HR tahu absen dari mana.

### 1.3 Reconciliation berbasis waktu
Karena log mesin ditarik dengan jeda (polling) dan absensi app bisa datang dari
**antrean offline** (lihat fitur offline attendance), keduanya adalah "event tertunda
yang direkonsiliasi berdasarkan timestamp". Satu mesin reconciliation menangani keduanya.

---

## 2. Perubahan Skema Database

### 2.1 `attendances` (alter)
```php
$table->enum('clock_in_source', ['app_face','fingerprint','web','manual'])->nullable()->after('clock_in');
$table->enum('clock_out_source', ['app_face','fingerprint','web','manual'])->nullable()->after('clock_out');
$table->foreignId('clock_in_device_id')->nullable()->constrained('fingerprint_devices')->nullOnDelete();
$table->foreignId('clock_out_device_id')->nullable()->constrained('fingerprint_devices')->nullOnDelete();
```

### 2.2 `fingerprint_devices` (baru)
| kolom | tipe | keterangan |
|-------|------|-----------|
| id | bigint | |
| company_id | fk | multi-tenant |
| name | string | "Mesin Lobby Lt.1" |
| brand | enum | zkteco / fingerspot / solution / other |
| ip_address, port | string/int | untuk mode pull (LAN) |
| serial_number | string | identifikasi device |
| office_location_id | fk nullable | lokasi fisik mesin |
| last_sync_at | datetime | |
| is_active | bool | |

### 2.3 `fingerprint_user_mappings` (baru)
Memetakan PIN/ID user di mesin → karyawan di sistem.
| device_id | fk |
| device_user_pin | string (PIN di mesin) |
| employee_id | fk |
| unique(device_id, device_user_pin) |

### 2.4 `raw_attendance_logs` (baru — audit & idempotensi)
Menyimpan **setiap** event mentah dari semua kanal (termasuk yang ditolak/duplikat),
sehingga reconciliation idempoten dan HR bisa mengaudit.
| kolom | keterangan |
|-------|-----------|
| company_id, employee_id (nullable) | |
| channel | app_face / fingerprint |
| device_id (nullable), device_user_pin (nullable) | |
| type | clock_in / clock_out |
| event_time | timestamp dari sumber |
| received_at | waktu server menerima |
| status | applied / duplicate_ignored / superseded / unmatched |
| dedup_hash | unique → mencegah proses ganda event yang sama |
| payload (json) | data mentah |

`dedup_hash = sha256(device_id|pin|type|event_time)` untuk log mesin,
atau `sha256(employee_id|type|event_time|channel)` untuk app. Insert dengan
`firstOrCreate` → event yang sama tidak akan diproses dua kali (idempoten).

---

## 3. Integrasi Mesin Fingerprint

Mesin fingerprint umumnya **tidak bisa memanggil HTTPS** langsung. Tiga pola:

### Pola A — Pull / Polling (disarankan untuk LAN)
Scheduled job Laravel (`SyncFingerprintDevices`, tiap 1–5 menit) connect ke device
via SDK TCP (ZKTeco/Fingerspot pakai port 4370, protokol ZK). Karena ekosistem PHP
untuk ZK terbatas, opsi:
- **Agen on-premise** kecil (Python `pyzk` / Node `zklib`) di jaringan lokal yang
  menarik log dari device lalu mem-POST ke webhook (Pola B). **Paling andal.**
- Atau library PHP ZK langsung dari server yang punya akses LAN ke device.

### Pola B — Push / Webhook
Device atau agen mem-POST log ke endpoint baru:
```
POST /api/v1/webhooks/fingerprint
Header: X-Device-Signature: HMAC(secret, body)   // verifikasi keaslian
Body: { device_serial, logs: [ {pin, type, timestamp}, ... ] }
```
Memanfaatkan grup `webhooks` yang sudah ada di `routes/api.php`.

### Pola C — Cloud Bridge
Jika mesin push ke cloud vendor (mis. Fingerspot.iO), poll API vendor secara berkala.

> **Rekomendasi:** Agen on-prem (Python pyzk) → POST ke `webhooks/fingerprint`.
> Decoupled, aman, tidak bergantung library PHP-ZK yang rapuh.

---

## 4. Mesin Reconciliation (inti anti-double)

`AttendanceReconciliationService::record(employee, type, eventTime, channel, deviceMeta)`

```text
function record(employee, type, eventTime, channel, deviceMeta):
    raw = RawAttendanceLog.firstOrCreate(dedup_hash, {...})   # idempoten
    if raw.alreadyExisted: return                              # event ganda → stop

    date = workDateFor(employee, eventTime)   # tangani shift malam lewat tengah malam
    att  = Attendance.firstOrCreate([employee_id, date])

    if type == clock_in:
        if att.clock_in is null:
            att.clock_in = eventTime; att.clock_in_source = channel; raw.status='applied'
        else if eventTime < att.clock_in - SKEW:
            att.clock_in = eventTime; att.clock_in_source = channel; raw.status='superseded'
        else:
            raw.status = 'duplicate_ignored'   # SUDAH absen masuk → diabaikan
    else: # clock_out  → umumnya ambil yang TERAKHIR
        if att.clock_out is null or eventTime > att.clock_out:
            att.clock_out = eventTime; att.clock_out_source = channel; raw.status='applied'
        else:
            raw.status = 'duplicate_ignored'

    recalcLateEarlyOvertime(att)   # hitung ulang telat/lembur
    att.save()
```

Aturan:
- **Clock-in** → ambil event **paling awal** (anti maju-mundurkan jam).
- **Clock-out** → ambil event **paling akhir**.
- **SKEW** (mis. 2 menit) menyerap selisih jam mesin vs server.

---

## 5. Perubahan Sisi Aplikasi (anti-double untuk user)

1. Sebelum face clock-in, app memanggil `GET /attendance/today` (sudah ada). Respons
   kini menyertakan `clock_in_source`. Jika `clock_in` sudah terisi (mis. dari mesin),
   tombol "Absen Masuk" dinonaktifkan + tampilkan: *"Anda sudah absen masuk via Mesin
   Fingerprint pukul 08:01."*
2. Saat submit, **server tetap memvalidasi ulang** (pertahanan terhadap client basi):
   bila `clock_in` sudah terisi kanal lain, kembalikan `409 Conflict` dengan pesan jelas,
   app menampilkan info dan refresh status.
3. Absensi dari **antrean offline** yang tersinkron belakangan otomatis lewat
   reconciliation yang sama — timestamp aslinya yang dipakai, bukan waktu sinkron.

---

## 6. Endpoint & Job Baru

| Komponen | Keterangan |
|----------|-----------|
| `POST /api/v1/webhooks/fingerprint` | terima log push dari agen/mesin (HMAC-verified) |
| `SyncFingerprintDevices` (job, scheduled) | mode pull per device |
| `AttendanceReconciliationService` | otak dedup/upsert (dipakai app, webhook, job) |
| Superadmin/Admin CRUD `fingerprint_devices` & `fingerprint_user_mappings` | kelola mesin & pemetaan PIN→karyawan |
| Laporan "Sumber Absensi" | rekap berapa % absen via app vs mesin, deteksi anomali |

---

## 7. Edge Cases

- **Clock-out tanpa clock-in** (hanya tap pulang di mesin): buat baris, isi `clock_out`,
  tandai `needs_review` untuk HR.
- **PIN mesin belum dipetakan** → simpan raw log `status=unmatched`, tampilkan di panel
  admin untuk dipetakan manual.
- **Drift jam mesin** → simpan `event_time` (device) + `received_at` (server); flag bila
  drift > ambang.
- **Karyawan absen masuk via app, pulang via mesin** → valid; `clock_in_source=app_face`,
  `clock_out_source=fingerprint`.
- **Multi-shift** (jika diaktifkan): kunci reconciliation per (employee, shift, type),
  bukan per tanggal saja.

---

## 8. Matriks Fallback

| Kondisi | Kanal dipakai | Hasil |
|---------|--------------|-------|
| Normal | app / mesin (bebas) | 1 record, dedup mencegah ganda |
| App error | mesin fingerprint | tetap tercatat, sync via job |
| Mesin rusak | app face | tetap tercatat langsung |
| Keduanya | event pertama menang | duplikat diabaikan + diaudit |

---

## 9. Rencana Implementasi Bertahap

1. **Fase 1 — Skema & Reconciliation**: migrasi (kolom source + 3 tabel baru) +
   `AttendanceReconciliationService`; refactor clock-in/out app agar lewat service ini.
2. **Fase 2 — Webhook**: `POST /webhooks/fingerprint` + HMAC + mapping PIN.
3. **Fase 3 — Agen on-prem / Job pull** untuk brand mesin yang dipakai.
4. **Fase 4 — UI Admin**: CRUD device & mapping, panel `unmatched`, laporan sumber.
5. **Fase 5 — UI App**: status "sudah absen via mesin", handling `409`.

---

## 10. Yang Perlu Dikonfirmasi Sebelum Implementasi
- **Merek & tipe mesin** fingerprint (ZKTeco? Fingerspot? Solution?) → menentukan SDK/protokol.
- **Mode integrasi**: pull (LAN) vs push (webhook/agen) vs cloud vendor.
- **Apakah mesin & server satu jaringan**, atau mesin tersebar di banyak cabang.
- **Multi-shift** dipakai atau tidak (mempengaruhi kunci dedup).
