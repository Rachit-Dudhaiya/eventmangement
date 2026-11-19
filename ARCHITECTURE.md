# System Architecture
## Campus Event Management & Attendance System

| Field | Value |
|---|---|
| **Version** | 1.0 |
| **Last Updated** | 2026-11-19 |
| **Stack** | Flutter + Riverpod · PHP/Laravel · MySQL/PostgreSQL · Redis |

---

## 1. Architecture Overview

A layered, API-driven client–server architecture with a **zero-trust** client and an authoritative backend.

```
┌──────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                              │
│  Flutter App (iOS / Android / Web)                           │
│  ├─ Presentation (Widgets, Screens)                          │
│  ├─ State Management: Riverpod (providers, notifiers)        │
│  ├─ Domain (use cases, models)                               │
│  └─ Data (REST client, secure token storage, QR camera)      │
└───────────────────────────┬──────────────────────────────────┘
                            │ HTTPS / JSON (Bearer token)
┌───────────────────────────▼──────────────────────────────────┐
│                    API GATEWAY / EDGE                        │
│  TLS termination · Rate limiting · Request validation        │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│                 BACKEND (PHP / Laravel)                      │
│  ├─ Auth & RBAC (Sanctum tokens, policies)                   │
│  ├─ Controllers / Form Requests (validation)                 │
│  ├─ Services (Event, Registration, QR, Notification, Analytics)│
│  ├─ Models / Eloquent ORM (parameterized queries)            │
│  └─ Queue Workers (email, push, AI jobs, backups)            │
└───────┬───────────────┬───────────────┬───────────────┬──────┘
        │               │               │               │
┌───────▼─────┐ ┌───────▼─────┐ ┌───────▼─────┐ ┌───────▼─────────┐
│  MySQL /    │ │   Redis     │ │ Email/Push  │ │  AI Analytics    │
│  PostgreSQL │ │ (cache,     │ │  Service    │ │  Service (LLM /  │
│  (primary)  │ │  queue,     │ │ (SMTP/FCM)  │ │  ML pipeline)    │
│             │ │  rate limit)│ │             │ │                  │
└─────────────┘ └─────────────┘ └─────────────┘ └──────────────────┘
```

---

## 2. Technology Choices & Rationale

| Layer | Choice | Rationale |
|---|---|---|
| Mobile/Web client | Flutter | Single codebase for iOS, Android, Web |
| State mgmt | Riverpod | Compile-safe, testable, decoupled DI; good for role-driven state |
| Backend | PHP / Laravel | Mature ORM (SQLi-safe), Sanctum tokens, queues, policies for RBAC |
| Database | PostgreSQL/MySQL | Relational integrity, unique constraints, transactions |
| Cache/Queue | Redis | Fast token/QR caching, rate limiting, background jobs |
| QR | HMAC-signed payload + camera | Secure, short-lived, single-use passes |

---

## 3. Client Architecture (Flutter + Riverpod)

- **Presentation:** Screens consume providers via `ref.watch`; `RoleGuard` hides unauthorized UI (UX only).
- **Application:** `AsyncNotifier` providers orchestrate use cases (register, fetch events, etc.).
- **Domain:** Pure Dart entities and use-case classes; no Flutter/PHP knowledge.
- **Data:** ApiClient with Dio; token stored in FlutterSecureStorage; QR via camera plugin.
- **Zero trust:** No permission logic enforced client-side; server responses are authoritative. Client validates input only for UX.

### Key providers
`authProvider`, `eventsProvider(filters)`, `registrationProvider`, `qrPassProvider`, `qrScanProvider`, `analyticsProvider`.

---

## 4. Backend Architecture (PHP / Laravel)

- **Auth:** Laravel Sanctum; tokens scoped by role. Policies gate each resource per role.
- **Validation:** FormRequest classes validate every input server-side.
- **Services:** Business logic isolated from controllers (EventService, RegistrationService, QrService, AnalyticsService, BackupService).
- **ORM:** Eloquent → parameterized queries (SQLi prevention).
- **Queues:** Email verification, notifications, AI report generation, backup jobs run async.
- **Audit:** Middleware logs privileged actions (actor, IP, timestamp).

---

## 5. Role & Permission Matrix

There are **four user roles only: Student, Organizer, Coordinator, Admin.** There is no Scanner role. QR scanning is an Admin permission; trusted gate devices may use an admin-issued **QR scan key** (a scoped credential, not a user role).

| Capability | Student | Organizer | Coordinator | Admin |
|---|:---:|:---:|:---:|:---:|
| Browse/search events | ✅ | ✅ | ✅ | ✅ |
| Register for event | ✅ | ❌ | ❌ | ❌ |
| Create events | ❌ | ❌ | ❌ | ✅ |
| Edit events | ❌ | ✅ (assigned) | ✅ | ✅ |
| Approve events | ❌ | ❌ | ✅ (parcel) | ✅ (final) |
| View audience records | ❌ | ✅ (assigned) | ✅ | ✅ |
| Scan QR / record entry | ❌ | ❌ | ❌ | ✅ |
| Create & manage QR scan keys | ❌ | ❌ | ❌ | ✅ |
| View AI analytics | ❌ | ❌ | ✅ | ✅ |
| Manage users/roles | ❌ | ❌ | ❌ | ✅ |
| Backups & audit log | ❌ | ❌ | ❌ | ✅ |
| Export data | ❌ | ❌ | ✅ | ✅ |

**Notes on the revised permissions**
- **Registration** is student-only; organizers, coordinators, and admins cannot register for events.
- **Event creation** is admin-only. Organizers and coordinators may only **edit** events assigned to them; they cannot create new ones.
- **Approval** is split: coordinators give **partial/parcel approval** (department-level review), while the admin performs the **final approval**.
- **QR scanning** is an Admin capability only. No dedicated Scanner role exists.
- **QR scan keys** are scoped device credentials issued and managed only by Admin. A key grants access to the scan endpoint alone — it cannot edit events, view analytics, or export data. It is not a login role.
- **Data export** is limited to Coordinator and Admin; organizers cannot export.

---

## 6. Database Schema (Logical)

```
users(id, name, campus_id, email, password_hash, role_id, department_id, email_verified_at, created_at, updated_at)
roles(id, name, guard_name)
permissions(id, name)
role_permission(role_id, permission_id)

departments(id, name, code)

events(id, title, description, category, cover_url, venue, map_link,
       start_at, end_at, scope, department_id, organizer_id, capacity,
       registration_deadline, status, contact_name, contact_email, contact_phone,
       utility_details_json, created_at, updated_at, last_changed_by)

change_logs(id, event_id, changed_by, field, old_value, new_value, changed_at)

registrations(id, student_id, event_id, status, verified_at, created_at, updated_at)
  UNIQUE(student_id, event_id)

qr_passes(id, registration_id, token_hash, expires_at, used_at, status, created_at)
  UNIQUE(token_hash)

attendance(id, event_id, student_id, scanned_at, recorded_by_type, recorded_by_id, method, result)
  UNIQUE(event_id, student_id)

notifications(id, user_id, event_id, type, channel, payload_json, sent_at, status)

analytics_reports(id, requested_by, parameters_json, result_json, generated_at)

backups(id, type, path, size, status, created_at)
audit_logs(id, actor_id, action, target, ip, created_at)
```

---

## 7. Security Architecture

| Concern | Implementation |
|---|---|
| Password hashing | bcrypt (cost ≥12) or Argon2id; unique salt per user |
| SQL injection | Eloquent ORM / prepared statements only; no raw string SQL |
| Zero client trust | Server re-authenticates & authorizes every request; client role hidden UI only; all signatures/timestamps checked server-side |
| QR security | Payload `{reg_id, nonce, exp}` HMAC-signed with server secret; expires ≤10 min; stored hash marked used atomically; replay rejected. Token rotated on refresh. |
| QR single-use | DB transaction: insert attendance + mark pass USED atomically (unique constraints) |
| Duplicate prevention | UNIQUE constraints + server checks for registration & attendance |
| Token storage (client) | FlutterSecureStorage / Keychain-Keystore; never in plain SharedPreferences |
| Transport | Enforced HTTPS/TLS 1.2+; certificate pinning optional |
| Rate limiting | Redis-based per-IP/per-token limits on login & scan endpoints |
| Audit | All privileged actions logged |

---

## 8. QR Entry Flow (latency-critical, ≤500 ms p95)

1. Student opens app → requests QR pass → server issues short-lived HMAC token (cached in Redis).
2. Gate device camera reads QR (client-only decode; no security decision).
3. Client POSTs token to `/api/qr/validate` authenticated by Admin session or an admin-issued QR scan key.
4. Server verifies HMAC signature + expiry (in-memory/Redis, no DB read for signature).
5. Server checks duplicate via cached set + DB unique constraint; writes attendance in one transaction.
6. Response: `PASS` (with name/id) or `DENY` + reason. Payload kept < 1 KB.

**Performance tactics:** Redis-backed token cache, DB connection pooling, indexed unique keys, minimal response body, queue non-critical side effects (notifications) after response.

---

## 9. AI Analytics Architecture

- Data aggregated from `registrations`, `attendance`, `events` into reporting tables/materialized views.
- A queue job invokes an analytics service (LLM / ML pipeline) to produce insights and anomaly flags.
- Results cached in `analytics_reports`; dashboard queries cache, not raw event data.
- Natural-language queries translated to structured queries with guardrails; no direct DB access from LLM.

---

## 10. Backup & Recovery

- Automated daily full DB backup + hourly incremental (binlog/WAL); file storage backups for images.
- Backups encrypted at rest, stored offsite/object storage.
- RPO ≤ 24h, RTO ≤ 4h; quarterly restore drills; `backups` table tracks runs.
- Admin console: run backup, view status, initiate restore (with confirmation).

---

## 11. Deployment

- **Backend:** PHP-FPM + Nginx behind TLS, containerized (Docker), horizontally scalable workers.
- **Database:** Managed PostgreSQL/MySQL with replicas and automated backups.
- **Cache/Queue:** Redis managed instance.
- **Client:** Flutter builds distributed via App Store, Google Play, and web hosting.
- **Environments:** development → staging → production with CI/CD pipeline.

---

## 12. Non-Functional Mapping

| NFR | Architecture Support |
|---|---|
| Backup & recovery | BackupService + scheduled queue jobs + offsite storage |
| Non-reg. student access | Guest read endpoints scoped to PUBLIC events; registration gated |
| QR security | HMAC short-lived single-use tokens, server-side verification |
| QR latency | Redis cache, minimal payload, indexed writes |
| Password hashing | Laravel Hash (bcrypt/Argon2id) |
| SQLi prevention | Eloquent ORM / prepared statements |
| Duplicate prevention | DB unique constraints + service checks |
| Zero client trust | Server-authoritative auth, validation, and signatures |
