# Product Requirements Document (PRD)
## Campus Event Management & Attendance System

| Field | Value |
|---|---|
| **Document Version** | 1.0 |
| **Status** | Draft |
| **Last Updated** | 2026-11-19 |
| **Product Owner** | Campus Administration |
| **Tech Stack** | Flutter (Riverpod) · PHP (Laravel) · MySQL/PostgreSQL |

---

## 1. Executive Summary

The Campus Event Management & Attendance System is a multi-role platform that centralizes the creation, publication, registration, and attendance tracking of campus events. It replaces scattered spreadsheets, manual entry logs, and email threads with a single source of truth that supports both **central (university-wide)** and **department-level** events.

The system serves four primary roles — **Admin, Event Organizer, Event Coordinator, and Student** — plus a restricted **QR Gate Scanner** credential. Attendance is captured through secure, short-lived QR codes with guaranteed low-latency validation. An AI-based analytics module turns raw registration and attendance data into actionable reports.

---

## 2. Product Vision

> "One trusted platform where every campus event is discoverable, every registration is verifiable, and every attendance record is instant and auditable."

### Goals
1. Provide accurate, complete event information to the whole campus.
2. Enforce a single, duplicate-free registration per student per event.
3. Make entry fast and secure via role-restricted QR scanning.
4. Give organizers real-time visibility into capacity, audience, and status.
5. Deliver AI-driven insights for data-informed campus decisions.

### Non-Goals
- Payment processing for events (out of scope for v1).
- External social-media integrations.
- Offline-first editing of events (read-only offline caching is acceptable).

---

## 3. Target Users / Personas

| Persona | Description | Primary Needs |
|---|---|---|
| **Student** | Enrolled campus student | Browse events, register once, receive QR pass, view status |
| **Event Organizer** | Staff/student leader who creates events | Create/manage events, set capacity, monitor registrations, scan entry |
| **Event Coordinator** | Oversees multiple events/department | Approve events, view analytics, manage organizers, resolve conflicts |
| **Admin** | System administrator | Full access, user roles, backups, security, global settings |
| **QR Gate Scanner** | Trusted entry staff with special credential | Scan QR codes only; no editing or data export |

---

## 4. Scope

### In Scope (v1)
- Role-based authentication (Admin / Organizer / Coordinator / Student / Scanner)
- Event CRUD with centralized vs departmental classification
- Single-entry registration form with email verification
- Event notifications (push + email)
- Capacity alerts and waitlist/status handling
- Secure QR code issuance, scanning, and attendance logging
- Search and filter across events
- Change history ("last time changes") on events
- Audience/attendance records per event
- AI-based reports & analytics dashboard
- Backup & recovery, security hardening (hashing, SQLi prevention, zero client trust)

### Out of Scope (v1)
- Payments, ticketing revenue, external calendar sync, public API for third parties.

---

## 5. Functional Requirements (Summary)

| ID | Requirement | Priority |
|---|---|---|
| FR-01 | Display complete, accurate event information | Must |
| FR-02 | Single-entry registration form per student per event | Must |
| FR-03 | Email verification of registration | Must |
| FR-04 | Event notifications (email + in-app push) | Must |
| FR-05 | Label each event as Centralized or Departmental | Must |
| FR-06 | Record audience/attendance per event | Must |
| FR-07 | Maintain "last changed" history and audit log | Must |
| FR-08 | Role-based login with distinct permissions | Must |
| FR-09 | Capacity alerts and registration status | Must |
| FR-10 | Search & filter events | Should |
| FR-11 | Special QR scanning credential | Must |
| FR-12 | Status tracking (event, registration, attendance) | Must |
| FR-13 | Utility details (venue, time, contact, resources) | Should |
| FR-14 | AI-based report & analytics | Should |

Full detailed specifications are in the **SRS**.

---

## 6. Non-Functional Requirements (Summary)

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Backup and recovery | Daily automated backup, RPO ≤ 24h, RTO ≤ 4h |
| NFR-02 | Non-registered student access | Guest browse (read-only), gated registration |
| NFR-03 | QR code security | Signed, short-lived, single-use tokens |
| NFR-04 | QR performance latency | Scan-to-validation ≤ 500 ms (p95) |
| NFR-05 | Password hashing | bcrypt/Argon2id, never plain text |
| NFR-06 | SQL Injection prevention | Parameterized queries / ORM only |
| NFR-07 | Duplicate prevention | DB unique constraints + backend checks |
| NFR-08 | Zero client trust | All auth/validation server-side, token-based |

---

## 7. Key User Stories

- **As a Student**, I want to search events by department/date so I can find relevant ones.
- **As a Student**, I want to register once and get a QR pass so I can enter quickly.
- **As an Organizer**, I want a capacity alert when an event is almost full so I can open a waitlist.
- **As a Scanner**, I want instant visual feedback on a QR scan so I don't hold up the queue.
- **As a Coordinator**, I want AI analytics on attendance trends so I can plan future events.
- **As an Admin**, I want automated backups and an audit trail so the system stays compliant.

---

## 8. Success Metrics

| Metric | Target |
|---|---|
| Registration error/duplicate rate | < 0.5% |
| QR scan validation latency (p95) | ≤ 500 ms |
| Email verification delivery | ≥ 98% within 2 min |
| Attendance record accuracy | ≥ 99.5% |
| System uptime during events | ≥ 99.9% |

---

## 9. Assumptions & Dependencies
- Campus provides SMTP/email service and push notification credentials.
- PHP backend deployed with HTTPS (TLS) enforced.
- QR scanners are Flutter devices with camera access and stable connectivity.
- AI module may use an external LLM/analytics service or an on-premise model.

---

## 10. Release Roadmap

| Phase | Features |
|---|---|
| **Phase 1 (MVP)** | Auth, roles, event CRUD, registration + email verify, QR entry, search/filter |
| **Phase 2** | Notifications, capacity alerts, change history, audience records, utility details |
| **Phase 3** | AI reports & analytics, advanced filters, backup automation hardening |
| **Phase 4** | Guest access polish, multi-campus scaling, external integrations |
