<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Config\Env;
use App\Helpers\Response;
use App\Helpers\Validator;
use App\Repositories\AttendanceRepository;
use App\Repositories\EventRepository;
use App\Repositories\RegistrationRepository;
use App\Repositories\UserRepository;

final class AttendanceController
{
    public function generateQr(array $context): void
    {
        $eventId = (int) ($context['params']['id'] ?? 0);
        $event = (new EventRepository())->findById($eventId);
        if ($event === null) {
            Response::error('Event not found', 404);
        }

        $user = $context['user'];
        if ($user['role'] !== 'admin' && (int) $event['organizer_id'] !== (int) $user['id']) {
            Response::error('Forbidden: only the event organizer can generate attendance QR codes', 403);
        }
        if ($event['status'] !== 'published') {
            Response::error('Attendance QR can only be generated for published events', 400);
        }

        $input = Response::readJsonBody();
        $defaultTtl = (int) Env::get('QR_TOKEN_DEFAULT_TTL_MINUTES', '30');
        $ttlMinutes = max(1, min(120, (int) ($input['ttl_minutes'] ?? $defaultTtl)));
        $expiresAt = date('Y-m-d H:i:s', time() + ($ttlMinutes * 60));

        $plainToken = 'CAMPUS_QR_' . $eventId . '_' . bin2hex(random_bytes(16));
        (new AttendanceRepository())->createQrToken($eventId, (int) $user['id'], $plainToken, $expiresAt);

        Response::ok('QR token generated', [
            'event_id' => $eventId,
            'qr_token' => $plainToken,
            'expires_at' => $expiresAt,
            'ttl_minutes' => $ttlMinutes,
        ], 201);
    }

    public function startSession(array $context): void
    {
        $eventId = (int) ($context['params']['id'] ?? 0);
        $event = (new EventRepository())->findById($eventId);
        if ($event === null) {
            Response::error('Event not found', 404);
        }

        $user = $context['user'];
        if ($user['role'] !== 'admin' && (int) $event['organizer_id'] !== (int) $user['id']) {
            Response::error('Forbidden: only organizer can start attendance session', 403);
        }
        if ($event['status'] !== 'published') {
            Response::error('Attendance session can only be started for published events', 400);
        }

        $input = Response::readJsonBody();
        $durationMinutes = max(5, min(120, (int) ($input['duration_minutes'] ?? 30)));

        $attRepo = new AttendanceRepository();
        $session = $attRepo->startAttendanceSession($eventId, (int) $user['id'], $durationMinutes);

        Response::ok('Attendance session started', [
            'event_id' => $eventId,
            'is_active' => true,
            'session_token' => $session['session_token'],
            'expires_at' => $session['expires_at'],
            'duration_minutes' => $durationMinutes,
            'remaining_seconds' => $durationMinutes * 60,
        ], 201);
    }

    public function stopSession(array $context): void
    {
        $eventId = (int) ($context['params']['id'] ?? 0);
        $event = (new EventRepository())->findById($eventId);
        if ($event === null) {
            Response::error('Event not found', 404);
        }

        $user = $context['user'];
        if ($user['role'] !== 'admin' && (int) $event['organizer_id'] !== (int) $user['id']) {
            Response::error('Forbidden', 403);
        }

        (new AttendanceRepository())->stopAttendanceSession($eventId);

        Response::ok('Attendance session stopped', [
            'event_id' => $eventId,
            'is_active' => false,
        ]);
    }

    public function sessionStatus(array $context): void
    {
        $eventId = (int) ($context['params']['id'] ?? 0);
        $event = (new EventRepository())->findById($eventId);
        if ($event === null) {
            Response::error('Event not found', 404);
        }

        $session = (new AttendanceRepository())->getActiveSession($eventId);
        $isActive = false;
        $expiresAt = null;
        $remainingSeconds = 0;

        if ($session !== null) {
            $expireTime = strtotime($session['expires_at']);
            $now = time();
            if ($expireTime > $now) {
                $isActive = true;
                $expiresAt = $session['expires_at'];
                $remainingSeconds = $expireTime - $now;
            }
        }

        Response::ok('Session status retrieved', [
            'event_id' => $eventId,
            'is_active' => $isActive,
            'expires_at' => $expiresAt,
            'remaining_seconds' => max(0, $remainingSeconds),
        ]);
    }

    public function studentPass(array $context): void
    {
        $eventId = (int) ($context['params']['id'] ?? 0);
        $user = $context['user'];
        $userId = (int) $user['id'];

        $event = (new EventRepository())->findById($eventId);
        if ($event === null) {
            Response::error('Event not found', 404);
        }

        $registration = (new RegistrationRepository())->findByEventAndUser($eventId, $userId);
        if ($registration === null || $registration['status'] !== 'registered') {
            Response::error('You are not registered for this event', 403);
        }

        $attRecord = (new AttendanceRepository())->findByRegistrationId((int) $registration['id']);
        $isAttended = ($attRecord !== null);

        $session = (new AttendanceRepository())->getActiveSession($eventId);
        $isSessionActive = ($session !== null && strtotime($session['expires_at']) > time());

        Response::ok('Student pass details retrieved', [
            'event_id' => $eventId,
            'event_title' => $event['title'],
            'registration_id' => (int) $registration['id'],
            'user_id' => $userId,
            'student_name' => $user['full_name'],
            'student_id_number' => $user['student_id_number'] ?? '',
            'is_attended' => $isAttended,
            'session_active' => $isSessionActive,
            'session_expires_at' => $session['expires_at'] ?? null,
        ]);
    }

    public function scanStudentPass(array $context): void
    {
        $input = Response::readJsonBody();
        $user = $context['user'];

        if (!in_array($user['role'], ['organizer', 'admin'], true)) {
            Response::error('Forbidden: only organizers can scan student passes', 403);
        }

        $eventId = (int) ($input['event_id'] ?? 0);
        $payload = $input['student_pass'] ?? null;

        // Decode payload if passed as JSON string
        if (is_string($payload)) {
            $decoded = json_decode($payload, true);
            if (is_array($decoded)) {
                $payload = $decoded;
            }
        }

        if (!is_array($payload)) {
            Response::error('Invalid QR code format', 422);
        }

        $passEventId = (int) ($payload['event_id'] ?? 0);
        $studentUserId = (int) ($payload['user_id'] ?? 0);
        $timestamp = (int) ($payload['timestamp'] ?? 0);

        if ($eventId === 0 && $passEventId > 0) {
            $eventId = $passEventId;
        }

        if ($eventId !== $passEventId) {
            Response::error('QR code does not match this event', 400);
        }

        $event = (new EventRepository())->findById($eventId);
        if ($event === null) {
            Response::error('Event not found', 404);
        }

        if ($user['role'] !== 'admin' && (int) $event['organizer_id'] !== (int) $user['id']) {
            Response::error('Forbidden: you are not the organizer for this event', 403);
        }

        // Verify active check-in session
        $attRepo = new AttendanceRepository();
        $session = $attRepo->getActiveSession($eventId);
        if ($session === null || strtotime($session['expires_at']) <= time()) {
            Response::error('Attendance session is NOT started for this event. Tap "Start Session" to begin scanning.', 400);
        }

        // Verify 10-second rotating window freshness (allow ±25 seconds for network / scanning latency)
        $now = time();
        $timeDiff = abs($now - $timestamp);
        if ($timestamp === 0 || $timeDiff > 25) {
            Response::error('QR code has expired. Student must show the live updating QR code.', 400);
        }

        // Verify student registration
        $registration = (new RegistrationRepository())->findByEventAndUser($eventId, $studentUserId);
        if ($registration === null || $registration['status'] !== 'registered') {
            Response::error('Student is not registered for this event', 403);
        }

        // Check if already attended
        if ($attRepo->findByRegistrationId((int) $registration['id']) !== null) {
            Response::error('Attendance already marked for this student', 409);
        }

        // Record attendance
        $attendanceId = $attRepo->recordAttendance(
            (int) $registration['id'],
            $eventId,
            $studentUserId,
            (int) $session['id'],
            'present'
        );

        $student = (new UserRepository())->findById($studentUserId);

        Response::ok('Attendance recorded successfully', [
            'attendance_id' => $attendanceId,
            'event_id' => $eventId,
            'event_title' => $event['title'],
            'student_name' => $student['full_name'] ?? 'Student',
            'student_id_number' => $student['student_id_number'] ?? '',
            'status' => 'present',
            'marked_at' => date('Y-m-d H:i:s'),
        ], 201);
    }

    public function verify(array $context): void
    {
        $input = Response::readJsonBody();
        $errors = Validator::requireFields($input, ['qr_token']);
        if ($errors !== []) {
            Response::error('Validation failed', 422, $errors);
        }

        $plainToken = trim((string) $input['qr_token']);
        $attRepo = new AttendanceRepository();
        $qrRecord = $attRepo->findValidQrToken($plainToken);

        if ($qrRecord === null || (int) $qrRecord['is_revoked'] === 1) {
            Response::error('Invalid attendance QR code', 400);
        }
        if (strtotime($qrRecord['expires_at']) < time()) {
            Response::error('Attendance QR code has expired', 400);
        }

        $eventId = (int) $qrRecord['event_id'];
        $userId = (int) $context['user']['id'];

        $event = (new EventRepository())->findById($eventId);
        if ($event === null || $event['status'] !== 'published') {
            Response::error('Event is not active for attendance', 400);
        }

        $registration = (new RegistrationRepository())->findByEventAndUser($eventId, $userId);
        if ($registration === null || $registration['status'] !== 'registered') {
            Response::error('You must be registered for this event to mark attendance', 403);
        }

        if ($attRepo->findByRegistrationId((int) $registration['id']) !== null) {
            Response::error('Attendance already recorded for this event', 409);
        }

        $attendanceId = $attRepo->recordAttendance(
            (int) $registration['id'],
            $eventId,
            $userId,
            (int) $qrRecord['id'],
            'present'
        );

        Response::ok('Attendance recorded successfully', [
            'attendance_id' => $attendanceId,
            'event_id' => $eventId,
            'event_title' => $event['title'],
            'status' => 'present',
        ], 201);
    }

    public function eventReport(array $context): void
    {
        $eventId = (int) ($context['params']['id'] ?? 0);
        $event = (new EventRepository())->findById($eventId);
        if ($event === null) {
            Response::error('Event not found', 404);
        }

        $user = $context['user'];
        if ($user['role'] !== 'admin' && (int) $event['organizer_id'] !== (int) $user['id']) {
            Response::error('Forbidden', 403);
        }

        $rows = (new AttendanceRepository())->getEventReport($eventId);
        $totalRegistered = count($rows);
        $totalPresent = 0;
        foreach ($rows as $row) {
            if ($row['attendance_status'] !== null) {
                $totalPresent++;
            }
        }

        Response::ok('Attendance report retrieved', [
            'summary' => [
                'event_id' => $eventId,
                'event_title' => $event['title'],
                'total_registered' => $totalRegistered,
                'total_present' => $totalPresent,
                'attendance_rate' => $totalRegistered > 0 ? round(($totalPresent / $totalRegistered) * 100, 1) : 0.0,
            ],
            'attendees' => $rows,
        ]);
    }

    public function myAttendance(array $context): void
    {
        $rows = (new AttendanceRepository())->listByUser((int) $context['user']['id']);
        Response::ok('My attendance retrieved', ['attendance' => $rows]);
    }
}
