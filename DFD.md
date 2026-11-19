# Data Flow Diagrams (DFD)
## Campus Event Management & Attendance System

Notation: Giangreco/Yourdon-style. External entities = squares, processes = circles, data stores = open-ended rectangles, data flows = arrows.

---

## Level 0 — Context Diagram

```
                    ┌──────────────────┐
   login cred ─────▶│                  │──── token ────▶  (all actors)
   event queries    │  CAMPUS EVENT    │
   registration  ──▶│  MANAGEMENT &    │──── notifications ──▶ [Email / Push Service]
   QR scan data  ──▶│  ATTENDANCE SYS  │
                    │   (system)       │──── reports ───────▶ [AI Analytics Service]
                    └────────┬─────────┘
                             │ event/attendance data
                             ▼
                    ┌──────────────────┐
                    │  Primary Data    │
                    │  Store (DB)      │
                    └──────────────────┘
```

**External Entities**
- **Student / Guest** — browses, registers, receives QR pass.
- **Organizer / Coordinator** — manages events, views analytics.
- **Admin** — manages roles, backups, security.
- **QR Scanner** — validates passes, records attendance.
- **Email/Push Service** — verification mail + notifications.
- **AI Analytics Service** — report generation.

---

## Level 1 — Major Processes

```
   ┌──────────┐
   │  Actors  │
   └────┬─────┘
        │ credentials / requests
        ▼
   ┌────────────────────┐        ┌──────────────┐
   │ 1.0 Authenticate & │───────▶│ D1 Users /   │
   │    Authorize (RBAC)│        │ Roles / Tokens│
   └────┬───────────────┘        └──────────────┘
        │ authorized request
        ▼
   ┌────────────────────┐        ┌──────────────┐
   │ 2.0 Manage Events  │◀──────▶│ D2 Events /  │
   │    (CRUD, scope,   │        │ ChangeLog    │
   │    utility info)   │        └──────────────┘
   └────┬───────────────┘
        │
        ▼
   ┌────────────────────┐        ┌──────────────┐
   │ 3.0 Registration & │◀──────▶│ D3 Registrations│
   │    Email Verify    │        │ QrPasses     │
   └────┬───────────────┘        └──────┬───────┘
        │ verification result            │ pass/token
        ▼                                ▼
   ┌────────────────────┐        ┌──────────────┐
   │ 4.0 Notify         │───────▶│ D4 Notifications│
   └────┬───────────────┘        └──────────────┘
        │
        ▼
   ┌────────────────────┐        ┌──────────────┐
   │ 5.0 QR Validate &  │◀──────▶│ D5 Attendance│
   │    Attendance Log  │        │ Records      │
   └────┬───────────────┘        └──────────────┘
        │
        ▼
   ┌────────────────────┐        ┌──────────────┐
   │ 6.0 AI Reports &   │◀──────▶│ D6 Analytics │
   │    Analytics       │        │ Reports      │
   └────┬───────────────┘        └──────────────┘
        │
        ▼
   ┌────────────────────┐
   │ 7.0 Backup & Audit │◀──────▶ D7 Backups / AuditLog
   └────────────────────┘
```

---

## Level 2 — Process 3.0 Registration & Verification (detail)

```
 Student ──▶[3.1 Validate form]──▶[3.2 Check duplicate (D3 unique)]──▶[3.3 Create PENDING reg]
                                                                          │
                                                                          ▼
                                                                 [3.4 Send verify email]
                                                                          │
                                              Email Service ◀─────────────┘
                                                                          │
 Student ──click link──▶[3.5 Verify token/OTP (expiry check)]──▶[3.6 Set VERIFIED/CONFIRMED or WAITLIST]
                                                                          │
                                                                          ▼
                                                                 [3.7 Issue signed QR pass (D3)]
                                                                          │
                                                                          ▼
                                                                 Student QR Pass
```

---

## Level 2 — Process 5.0 QR Validation (detail, latency-critical)

```
 Scanner ─▶[5.1 Scan QR (client)]─▶[5.2 POST /qr/validate token]─▶[5.3 Verify HMAC signature + expiry]
                                                                         │
                                          ┌──────────────────────────────┼──────────────────────────┐
                                          ▼                              ▼                          ▼
                                   [5.4 Token invalid/expired]    [5.5 Duplicate scan?]      [5.6 Valid]
                                          │                        (D5 unique check)               │
                                          ▼                              ▼                          ▼
                                     DENY: EXPIRED             DENY: DUPLICATE          [5.7 Write attendance (D5)]
                                                                                               │
                                                                                               ▼
                                                                                  PASS: record + mark QR USED
                                                                                               │
                                                                                               ▼
                                                                                    Feedback to Scanner (<500ms)
```

---

## Data Stores

| Store | Contents |
|---|---|
| D1 | Users, roles, permissions, auth tokens |
| D2 | Events, departments, change logs |
| D3 | Registrations, QR passes |
| D4 | Notifications, delivery log |
| D5 | Attendance records |
| D6 | Analytics reports, cached metrics |
| D7 | Backups, audit log |

---

## Data Dictionary (selected)

| Element | Type | Description |
|---|---|---|
| student_id | FK | Unique campus identifier |
| event_id | FK | Event primary key |
| scope | ENUM | CENTRAL / DEPARTMENTAL |
| reg_status | ENUM | PENDING_VERIFICATION, VERIFIED, CONFIRMED, WAITLISTED, CANCELLED |
| qr_token | STRING | HMAC-signed, expires ≤10 min, single-use |
| scan_method | ENUM | QR (only in v1) |
| last_changed_by | FK | User who last modified an event |
