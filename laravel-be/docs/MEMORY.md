# SiHaris Project Memory & Knowledge Log

## Hybrid Attendance System (Mesin Fingerprint ADMS + Face Mobile App)

### Overview
Integrasi absensi dua arah antara SiHaris Backend/Mobile App dengan **Mesin Fingerprint / ADMS Cloud API** (`http://adms.alazhar-rm.com/api/v1/face`).

---

### Key Architectural Concepts
1. **Single Source of Truth**:
   - `attendances` table stores one row per employee per date (`unique(['employee_id', 'date'])`).
   - Fields: `clock_in_source`, `clock_out_source`, `clock_in_device_id`, `clock_out_device_id`, `needs_review`.
2. **Reconciliation Engine (`AttendanceReconciliationService`)**:
   - Handles deduplication (`dedup_hash`), overnight shifts, and earliest clock-in / latest clock-out rules.
3. **Async Relay (`PushAttendanceToAdmsJob`)**:
   - Mobile app clock in/out is saved to SiHaris instantly and relayed asynchronously to ADMS Cloud `POST /attendance`.
4. **Master Employee Sync (`SyncAdmsEmployeesJob`)**:
   - Synchronizes employee PIN mappings between ADMS and SiHaris (`fingerprint_user_mappings` & `employees.pin`).

---

### ADMS API Contracts
- **Base URL**: `http://adms.alazhar-rm.com/api/v1/face`
- **Authentication**: Header `X-API-KEY: adms-face-token-2026`
- **Endpoints Verified**:
  - `GET /health` -> Connection health check.
  - `GET /config` -> Face recognition settings (`Asia/Jakarta`, modes `["in", "out"]`).
  - `GET /employees` -> List of master employees & PINs.
  - `GET /employees/{employeeId}` -> Single employee detail.
  - `POST /attendance` -> Submit transaction (`pin`, `timestamp`, `type`, `device_id`, `event_id`). Returns `200 OK` with `attendance_id`.

---

### Key File Map
- **Laravel Service**: [`laravel-be/app/Services/AdmsApiService.php`](file:///Users/yapi/Adi/appdev/SiHaris/laravel-be/app/Services/AdmsApiService.php)
- **Laravel Jobs**:
  - [`laravel-be/app/Jobs/PushAttendanceToAdmsJob.php`](file:///Users/yapi/Adi/appdev/SiHaris/laravel-be/app/Jobs/PushAttendanceToAdmsJob.php)
  - [`laravel-be/app/Jobs/SyncAdmsEmployeesJob.php`](file:///Users/yapi/Adi/appdev/SiHaris/laravel-be/app/Jobs/SyncAdmsEmployeesJob.php)
- **Laravel Controller**: [`laravel-be/app/Http/Controllers/Api/V1/AttendanceController.php`](file:///Users/yapi/Adi/appdev/SiHaris/laravel-be/app/Http/Controllers/Api/V1/AttendanceController.php)
- **Flutter Model**: [`flutter_fe/lib/data/models/responses/attendance_today_model.dart`](file:///Users/yapi/Adi/appdev/SiHaris/flutter_fe/lib/data/models/responses/attendance_today_model.dart)
- **Flutter Screen**: [`flutter_fe/lib/presentation/attendance/pages/attendance_screen.dart`](file:///Users/yapi/Adi/appdev/SiHaris/flutter_fe/lib/presentation/attendance/pages/attendance_screen.dart)
- **Feature Tests**: [`laravel-be/tests/Feature/Services/AdmsApiServiceTest.php`](file:///Users/yapi/Adi/appdev/SiHaris/laravel-be/tests/Feature/Services/AdmsApiServiceTest.php)
