# Software Requirements Specification (SRS)
## Campus Event Management & Attendance System

| Field | Value |
|---|---|
| **Version** | 1.0 |
| **Status** | Draft |
| **Last Updated** | 2026-11-19 |
| **Stack** | Flutter + Riverpod (client) · PHP/Laravel (server) · MySQL/PostgreSQL |

---

## 1. Introduction

### 1.1 Purpose
This SRS defines the functional and non-functional requirements, external interfaces, and data requirements for the Campus Event Management & Attendance System. It is the contractual basis for design, development, testing, and acceptance.

### 1.2 Scope
A web/mobile platform for managing campus events end-to-end: creation, publication, registration, verification, notification, attendance capture via QR, and AI analytics, governed by role-based access control.

### 1.3 Definitions & Acronyms
| Term | Meaning |
|---|---|
| **Central Event** | Event open to the entire campus |
| **Departmental Event** | Event restricted to a specific department |
| **QR Pass** | Signed, short-lived token issued after verified registration |
| **Scanner** | Restricted credential for QR entry validation only |
| **Riverpod** | Flutter state-management & dependency-injection framework |
| **RBAC** | Role-Based Access Control |

---

## 2. Overall Description

### 2.1 Product Perspective
A client–server system. The Flutter app (with Riverpod) is a **zero-trust client**: it holds no authoritative logic and validates nothing security-critical locally. The PHP backend is the single source of truth.

### 2.2 User Classes & Roles
| Role | Capabilities |
|---|---|
| Student | Browse, search, register, view own QR pass & status |
| Organizer | Create/edit own events, set capacity, view registrations, scan entry |
| Coordinator | Approve events, oversee department/central events, view analytics |
| Admin | Full system control, role management, backups, security config |
| Scanner | Scan QR and mark attendance only (no other data access) |

### 2.3 Operating Constraints
- All clients communicate over HTTPS with bearer tokens (Sanctum/JWT-style).
- Email & push services must be available for verification/notifications.
- QR validation must work under low bandwidth with minimal payload.

---

## 3. Functional Requirements

### FR-01 — Proper Event Information
- **Description:** Each event record stores: title, description, category, cover image, venue/location (with map link), start/end datetime, organizer, department, scope (central/departmental), capacity, registration deadline, tags, and status.
- **Acceptance:** All required fields are validated server-side; event detail screen shows complete, accurate info.

### FR-02 — Single-Entry Registration Form
- One registration record per `(student_id, event_id)` pair, enforced by a database unique constraint.
- Form collects minimal required data; repeated attempts return a "already registered" response.
- On success, a QR pass is generated (after email verification, see FR-03).

### FR-03 — Registration Verifying Mail
- After registration, system sends a verification email with a signed, expiring link/OTP.
- Registration status transitions: `PENDING_VERIFICATION → VERIFIED → (CONFIRMED / WAITLISTED)`.
- Unverified registrations do not receive an active QR pass.

### FR-04 — Event Notifications
- Notify registered users on: registration confirmed, event updated, event starting soon, event cancelled, QR pass ready.
- Channels: in-app push + email. User notification preferences respected.

### FR-05 — Centralized vs Departmental
- Every event has a `scope` field: `CENTRAL` or `DEPARTMENTAL` (with department id).
- Visibility and registration eligibility computed server-side from scope + user profile.

### FR-06 — Audience / Attendance Record
- Each scan creates an attendance record: `(event_id, student_id, scanned_at, scanner_id, method)`.
- Organizers/Coordinators can view per-event audience lists and export summaries.

### FR-07 — Last Time Changes (Audit/History)
- Every create/update stores `created_at`, `updated_at`, and `last_changed_by`.
- A change-log table records field-level diffs for event edits (who, when, what changed).

### FR-08 — Role-Based Login
- Login issues a token bound to the user's role.
- Each endpoint enforces role + permission checks server-side (never trust client role claims).
- Distinct dashboards/menus per role (see PRT).

### FR-09 — Capacity Alert & Status
- When registrations reach configurable thresholds (e.g., 80%, 100%), organizers/coordinators receive alerts.
- Event statuses: `DRAFT, PUBLISHED, ONGOING, COMPLETED, CANCELLED`.
- Registration statuses: `PENDING_VERIFICATION, VERIFIED, CONFIRMED, WAITLISTED, CANCELLED`.
- Attendance statuses: `NOT_SCANNED, PRESENT, DUPLICATE_DENIED`.

### FR-10 — Search & Filter
- Search by title/tag/organizer; filter by scope, department, date range, status, venue.
- Results paginated; filters combinable; server-side query with indexes.

### FR-11 — Special QR Scanning Credential
- A dedicated `SCANNER` role with a separate, narrowly scoped token.
- Scanner endpoints: validate QR + create attendance record only.
- Scanner cannot view PII beyond name/id needed for entry confirmation, cannot export data, cannot edit events.

### FR-12 — Status Tracking
- Unified status display across event lifecycle, registration, and attendance (see FR-09 state sets).

### FR-13 — Utility Details
- Store and display helper info: contact person, contact email/phone, venue capacity, required materials, parking/access notes, link to map, FAQ.

### FR-14 — AI-Based Report & Analytics
- Generate reports: attendance trends, popular events, no-show rate, department participation, capacity utilization, time-of-day analysis.
- Natural-language query interface ("Which department had the highest attendance this month?").
- Anomaly flags (e.g., unusual duplicate-scan spikes).
- Outputs: dashboard charts + downloadable summary (PDF/CSV).

---

## 4. External Interface Requirements

### 4.1 User Interfaces
- Flutter mobile app (iOS/Android) + optional Flutter Web admin console.
- Riverpod for state management; all UI state derived from server responses.

### 4.2 API Interface (REST, JSON)
| Method | Endpoint | Purpose | Roles |
|---|---|---|---|
| POST | `/api/auth/login` | Authenticate & issue token | All |
| GET | `/api/events` | List/search/filter events | All (guest read) |
| POST | `/api/events` | Create event | Organizer, Coordinator, Admin |
| PUT | `/api/events/{id}` | Update event | Owner, Coordinator, Admin |
| POST | `/api/registrations` | Register for event | Student |
| POST | `/api/registrations/verify` | Verify email/OTP | Student |
| POST | `/api/qr/validate` | Validate & record attendance | Scanner, Organizer, Admin |
| GET | `/api/analytics/report` | AI reports | Coordinator, Admin |

### 4.3 Hardware Interfaces
- Device camera for QR scanning (Flutter `mobile_scanner`/`barcode_scan2`).
- Network: HTTPS connectivity required for live validation.

---

## 5. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-01 | Backup & Recovery | Automated daily DB + file backups; RPO ≤ 24h, RTO ≤ 4h; periodic restore tests |
| NFR-02 | Guest Access | Non-registered students may browse public events read-only; registration requires verified account |
| NFR-03 | QR Security | Tokens HMAC-signed, expire ≤ 10 min, single-use, bound to student+event; replay rejected |
| NFR-04 | QR Latency | Scan→validation response p95 ≤ 500 ms; payload < 1 KB |
| NFR-05 | Password Hashing | bcrypt (cost ≥ 12) or Argon2id; salts unique; no plaintext, no reversible encryption |
| NFR-06 | SQLi Prevention | Parameterized queries / Eloquent ORM only; no string-concatenated SQL |
| NFR-07 | Duplicate Prevention | DB unique constraints + server-side checks for registration and attendance |
| NFR-08 | Zero Client Trust | Every request re-authenticated & authorized server-side; signatures/timestamps validated server-side |
| NFR-09 | Availability | 99.9% uptime during event hours |
| NFR-10 | Scalability | Support 10k concurrent users and 5k scans/minute |
| NFR-11 | Usability | Core task (register + entry) achievable in < 3 minutes |
| NFR-12 | Auditability | All privileged actions logged with actor, timestamp, IP |

---

## 6. Data Requirements (Logical Model)

Entities: `User`, `Role`, `Permission`, `Department`, `Event`, `Registration`, `QrPass`, `Attendance`, `ChangeLog`, `Notification`, `AnalyticsReport`, `BackupRecord`.

Key constraints:
- `registrations(student_id, event_id)` UNIQUE → duplicate prevention.
- `attendance(event_id, student_id)` UNIQUE → one entry per student.
- `qr_passes.token` UNIQUE, indexed; `expires_at` enforced.
- Foreign keys with cascading where appropriate.

---

## 7. State Diagrams (Textual)

### Event Lifecycle
`DRAFT → PUBLISHED → ONGOING → COMPLETED` (or `→ CANCELLED` at any pre-ongoing stage)

### Registration Lifecycle
`PENDING_VERIFICATION → VERIFIED → CONFIRMED | WAITLISTED → CANCELLED`

### QR Pass Lifecycle
`ISSUED → ACTIVE (≤10 min) → USED | EXPIRED | REVOKED`

---

## 8. Use Cases (Summary)

- **UC-01** Student registers for event → verify email → receive QR pass.
- **UC-02** Organizer creates event → sets capacity → publishes → monitors alerts.
- **UC-03** Scanner scans QR → validates → records attendance → shows PASS/DENY.
- **UC-04** Coordinator views AI analytics → exports report.
- **UC-05** Admin configures roles → triggers backup → reviews audit log.

---

## 9. Acceptance Criteria Summary
- All FRs demonstrable end-to-end.
- All NFRs verified (load test for QR latency, pentest for SQLi/hashing, restore drill for backup).
- Role isolation tested: a Scanner token cannot call organizer/admin endpoints.


## folder structure 


campus_drive_backend/
│
├── app/
│   │
│   ├── Models/
│   │   ├── User.php
│   │   ├── Role.php
│   │   ├── Department.php
│   │   ├── Event.php
│   │   ├── EventCategory.php
│   │   ├── Venue.php
│   │   ├── Registration.php
│   │   ├── Attendance.php
│   │   ├── QrToken.php
│   │   ├── Notification.php
│   │   ├── DeviceToken.php
│   │   ├── Feedback.php
│   │   ├── EventOrganizer.php
│   │   ├── AuditLog.php
│   │   └── EventAnnouncement.php
│   │
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── AuthController.php
│   │   │   ├── UserController.php
│   │   │   ├── RoleController.php
│   │   │   ├── DepartmentController.php
│   │   │   ├── EventController.php
│   │   │   ├── RegistrationController.php
│   │   │   ├── AttendanceController.php
│   │   │   ├── QrController.php
│   │   │   ├── NotificationController.php
│   │   │   ├── AudienceController.php
│   │   │   ├── FeedbackController.php
│   │   │   ├── AnalyticsController.php
│   │   │   ├── ReportController.php
│   │   │   └── FileUploadController.php
│   │   │
│   │   ├── Middleware/
│   │   │   ├── RoleMiddleware.php
│   │   │   ├── PermissionMiddleware.php
│   │   │   └── VerifyEmailMiddleware.php
│   │   │
│   │   ├── Requests/
│   │   │   ├── LoginRequest.php
│   │   │   ├── EventRequest.php
│   │   │   └── RegistrationRequest.php
│   │   │
│   │   └── Resources/
│   │       ├── UserResource.php
│   │       ├── EventResource.php
│   │       └── RegistrationResource.php
│   │
│   ├── Services/
│   │   ├── AuthService.php
│   │   ├── EmailVerificationService.php
│   │   ├── EventService.php
│   │   ├── RegistrationService.php
│   │   ├── CapacityService.php
│   │   ├── QRCodeService.php
│   │   ├── AttendanceService.php
│   │   ├── NotificationService.php
│   │   ├── FileUploadService.php
│   │   ├── AnalyticsService.php
│   │   ├── AIReportService.php
│   │   └── BackupService.php
│   │
│   ├── Jobs/
│   │   ├── SendVerificationEmail.php
│   │   ├── SendEventNotification.php
│   │   ├── SendEventReminder.php
│   │   └── GenerateAnalyticsReport.php
│   │
│   ├── Events/
│   │   ├── EventCreated.php
│   │   ├── EventUpdated.php
│   │   ├── EventCancelled.php
│   │   └── RegistrationCompleted.php
│   │
│   ├── Listeners/
│   │   ├── NotifyRegisteredStudents.php
│   │   └── UpdateEventCapacity.php
│   │
│   ├── Policies/
│   │   ├── EventPolicy.php
│   │   ├── RegistrationPolicy.php
│   │   └── AttendancePolicy.php
│   │
│   └── Providers/
│
├── bootstrap/
│
├── config/
│
├── database/
│   ├── migrations/
│   │   ├── create_users_table.php
│   │   ├── create_roles_table.php
│   │   ├── create_departments_table.php
│   │   ├── create_events_table.php
│   │   ├── create_event_categories_table.php
│   │   ├── create_venues_table.php
│   │   ├── create_registrations_table.php
│   │   ├── create_attendance_table.php
│   │   ├── create_qr_tokens_table.php
│   │   ├── create_notifications_table.php
│   │   ├── create_device_tokens_table.php
│   │   ├── create_feedback_table.php
│   │   ├── create_event_organizers_table.php
│   │   ├── create_audit_logs_table.php
│   │   └── create_event_announcements_table.php
│   │
│   ├── seeders/
│   │   ├── RoleSeeder.php
│   │   ├── DepartmentSeeder.php
│   │   └── AdminSeeder.php
│   │
│   └── factories/
│
├── routes/
│   ├── api.php
│   ├── web.php
│   └── console.php
│
├── storage/
│   ├── app/
│   │   ├── public/
│   │   │   └── event_posters/
│   │   ├── private/
│   │   │   ├── reports/
│   │   │   └── backups/
│   │   └── temporary/
│   ├── logs/
│   └── framework/
│
├── tests/
│   ├── Feature/
│   │   ├── AuthenticationTest.php
│   │   ├── EventTest.php
│   │   ├── RegistrationTest.php
│   │   ├── CapacityTest.php
│   │   ├── QrAttendanceTest.php
│   │   ├── RolePermissionTest.php
│   │   └── NotificationTest.php
│   │
│   └── Unit/
│       ├── RegistrationServiceTest.php
│       ├── QrCodeServiceTest.php
│       └── CapacityServiceTest.php
│
├── .env
├── composer.json
├── artisan
└── README.md

