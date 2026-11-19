# Prototype & UI/UX Specification (PRT)
## Campus Event Management & Attendance System

> Text wireframes and navigation flows for the Flutter (Riverpod) client. These are low-fidelity layouts to guide implementation.

---

## 1. Design Principles
- **Role-first navigation:** users only see what their role permits.
- **Fast entry:** scanner screen optimized for one-handed, high-throughput scanning.
- **Clear status:** color-coded chips for event/registration/attendance status.
- **Zero-trust UI:** no security decision made in the app; every action re-validated server-side.

---

## 2. Global Navigation (by role)

| Role | Bottom / Side Nav Items |
|---|---|
| Student | Home · Discover · My Registrations · Profile |
| Organizer | Dashboard · My Events · Scan · Analytics |
| Coordinator | Dashboard · Events · Organizers · Analytics |
| Admin | Dashboard · Users & Roles · Events · Analytics · System/Backups |
| Scanner | Scan Only (kiosk mode, locked) |

---

## 3. Key Screen Wireframes

### 3.1 Login / Role-aware Dashboard
```
┌─────────────────────────────┐
│        CAMPUS EVENTS        │
│   [ email / campus ID ]     │
│   [ password          ]     │
│   [ Login ]                 │
│   Guest: Browse events →    │
└─────────────────────────────┘
After login → redirect to role dashboard (token stored securely).
```

### 3.2 Event Discovery (Search & Filter) — FR-01, FR-10
```
┌─────────────────────────────┐
│ [🔍 Search events...     ]   │
│ Filters: [Scope▾][Dept▾]    │
│          [Date▾][Status▾]   │
│ ─────────────────────────── │
│ 🖼️ Tech Talk 2026           │
│ Central · CS Dept · 12 Nov  │
│ 📍 Main Hall · ⏰ 10:00 AM   │
│ Status: ● PUBLISHED         │
│ [ View Details ]            │
│ ─────────────────────────── │
│ 🖼️ Annual Sports Day        │
│ Departmental · 18 Nov       │
│ ...                         │
└─────────────────────────────┘
```

### 3.3 Event Details — FR-01, FR-05, FR-13
```
┌─────────────────────────────┐
│ [Cover Image]               │
│ Tech Talk 2026              │
│ ● PUBLISHED   🏛️ CENTRAL     │
│ 📅 12 Nov 2026, 10:00–12:00 │
│ 📍 Main Hall (Capacity 300) │
│ 👤 Organizer: Dr. X          │
│ 📞 Contact: cs@campus.edu    │
│ About: ...description...    │
│ Utility: parking, map link  │
│ 🟢 240 / 300 registered      │
│ [ Register Now ]            │
│ Last updated: 2h ago by Dr.X│  ← FR-07
└─────────────────────────────┘
```

### 3.4 Registration Form (Single Entry) — FR-02, FR-03
```
┌─────────────────────────────┐
│ Register: Tech Talk 2026    │
│ Name (read-only): A. Student│
│ Campus ID (read-only): ...  │
│ Email: [ verified@example ] │
│ [ Submit Registration ]     │
│ ℹ️ One registration per event│
│ Status: PENDING_VERIFICATION│
└─────────────────────────────┘
After submit → "Check your email to verify" → verify link → VERIFIED → QR pass shown.
```

### 3.5 My QR Pass — FR-03, NFR-03
```
┌─────────────────────────────┐
│ ┌─────────────────────────┐ │
│ │   ▓▓ QR CODE ▓▓         │ │
│ │  (signed, expires 10m)  │ │
│ └─────────────────────────┘ │
│ Tech Talk 2026 · A. Student │
│ ⏳ Refreshes automatically  │
│ Status: ACTIVE / USED       │
└─────────────────────────────┘
```

### 3.6 QR Scanner (Kiosk) — FR-11, NFR-04
```
┌─────────────────────────────┐
│ 🔒 SCANNER MODE (locked)    │
│  ┌───────────────────────┐  │
│  │   CAMERA VIEW         │  │
│  │   [ scan frame ]      │  │
│  └───────────────────────┘  │
│ Last result: ✅ PASS        │
│ A. Student · ID 2024310     │
│ ⏱️ validated in 180 ms       │
│ [Recent scans: 42]          │
└─────────────────────────────┘
Feedback: green PASS / red DENY with reason (expired, duplicate, wrong event).
```

### 3.7 Organizer Dashboard — FR-06, FR-09, FR-12
```
┌─────────────────────────────┐
│ My Events  [+ New Event]    │
│ ─────────────────────────── │
│ Tech Talk · ● ONGOING       │
│ Registrations: 240/300 ████░│
│ ⚠️ Capacity alert (80%)      │
│ Present: 198 · No-show: 42  │
│ [View Audience][Scan Entry] │
│ [Edit][Change History]      │
└─────────────────────────────┘
```

### 3.8 AI Analytics — FR-14
```
┌─────────────────────────────┐
│ 📊 Analytics                │
│ Ask: "Best attended dept?"  │
│ [ Ask AI ]                  │
│ ─────────────────────────── │
│ 📈 Attendance trend (chart) │
│ 🏆 Top events this month    │
│ ⚠️ Anomaly: duplicate spike │
│ [ Export PDF / CSV ]        │
└─────────────────────────────┘
```

### 3.9 Admin — Users, Roles & Backups — FR-08, NFR-01
```
┌─────────────────────────────┐
│ Admin Console               │
│ [Users & Roles] [Events]    │
│ [Audit Log]   [Backups]     │
│ Backup status: Last 02:00 ✓ │
│ [ Run Backup ] [ Restore ]  │
└─────────────────────────────┘
```

---

## 4. Navigation Flow

```
Login → Role Dashboard
 ├─ Student → Discover → Details → Register → Verify Email → QR Pass → Scan Entry
 ├─ Organizer → Create Event → Publish → Monitor/Capacity Alert → Scan → Audience List
 ├─ Coordinator → Approve Events → Analytics → Export Report
 ├─ Admin → Manage Roles → Backups → Audit Log
 └─ Scanner → Kiosk (Scan → PASS/DENY)
Guest → Browse Events (read-only) → [Login to Register]
```

---

## 5. Component Library (suggested)
- `StatusChip` (event/registration/attendance variants)
- `EventCard`, `FilterBar`, `CapacityBar`, `QrDisplay`, `ScanResultBanner`
- `RoleGuard` widget: hides UI by role (UX only — backend still enforces)
- `ChangeHistoryList`, `AnalyticsChart`, `EmptyState`

---

## 6. Accessibility & UX Notes
- Minimum tap target 48dp; high-contrast status colors with text labels (not color-only).
- Scanner screen keeps screen awake and uses large feedback text.
- Offline: cache published events for read-only viewing; queue nothing security-sensitive.
