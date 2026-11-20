<?php

declare(strict_types=1);

use App\Controllers\AdminController;
use App\Controllers\AttendanceController;
use App\Controllers\AuthController;
use App\Controllers\EventController;
use App\Controllers\NotificationController;
use App\Controllers\ProfileController;
use App\Controllers\RegistrationController;
use App\Helpers\Response;
use App\Helpers\Router;
use App\Middleware\AuthMiddleware;

$router = new Router();

// Root welcome endpoint
$router->add('GET', '/', function (): void {
    Response::ok('Campus Event & Attendance API is live and healthy!', [
        'status' => 'online',
        'endpoints' => [
            'health' => '/api/health',
            'events' => '/api/events',
            'categories' => '/api/categories',
            'login' => '/api/auth/login',
        ],
    ]);
});

// Health check
$router->add('GET', '/api/health', function (): void {
    Response::ok('Campus Event API is running', ['timestamp' => date('c')]);
});

// Authentication
$router->add('POST', '/api/auth/register', [AuthController::class, 'register']);
$router->add('POST', '/api/auth/login', [AuthController::class, 'login']);
$router->add('POST', '/api/auth/logout', [AuthController::class, 'logout'], [AuthMiddleware::requireAuth()]);

// Categories & Events
$router->add('GET', '/api/categories', [EventController::class, 'categories']);
$router->add('GET', '/api/events', [EventController::class, 'index'], [AuthMiddleware::optional()]);
$router->add('GET', '/api/events/{id}', [EventController::class, 'show'], [AuthMiddleware::optional()]);
$router->add('POST', '/api/events', [EventController::class, 'store'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);
$router->add('PUT', '/api/events/{id}', [EventController::class, 'update'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);
$router->add('DELETE', '/api/events/{id}', [EventController::class, 'destroy'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);

// Registrations
$router->add('POST', '/api/events/{id}/register', [RegistrationController::class, 'register'], [AuthMiddleware::requireAuth()]);
$router->add('DELETE', '/api/events/{id}/register', [RegistrationController::class, 'cancel'], [AuthMiddleware::requireAuth()]);
$router->add('GET', '/api/my-registrations', [RegistrationController::class, 'myRegistrations'], [AuthMiddleware::requireAuth()]);
$router->add('GET', '/api/events/{id}/registrants', [RegistrationController::class, 'eventRegistrants'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);

// QR Attendance & Dynamic Sessions
$router->add('POST', '/api/events/{id}/attendance/session/start', [AttendanceController::class, 'startSession'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);
$router->add('POST', '/api/events/{id}/attendance/session/stop', [AttendanceController::class, 'stopSession'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);
$router->add('GET', '/api/events/{id}/attendance/session/status', [AttendanceController::class, 'sessionStatus'], [AuthMiddleware::requireAuth()]);
$router->add('GET', '/api/events/{id}/attendance/student-pass', [AttendanceController::class, 'studentPass'], [AuthMiddleware::requireAuth(['student'])]);
$router->add('POST', '/api/attendance/scan-student-pass', [AttendanceController::class, 'scanStudentPass'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);
$router->add('POST', '/api/events/{id}/attendance/qr', [AttendanceController::class, 'generateQr'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);
$router->add('POST', '/api/attendance/verify', [AttendanceController::class, 'verify'], [AuthMiddleware::requireAuth(['student'])]);
$router->add('GET', '/api/events/{id}/attendance', [AttendanceController::class, 'eventReport'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);
$router->add('GET', '/api/my-attendance', [AttendanceController::class, 'myAttendance'], [AuthMiddleware::requireAuth()]);

// Notifications
$router->add('POST', '/api/notifications/device-token', [NotificationController::class, 'saveDeviceToken'], [AuthMiddleware::requireAuth()]);
$router->add('POST', '/api/notifications/send', [NotificationController::class, 'send'], [AuthMiddleware::requireAuth(['organizer', 'admin'])]);

// Profile
$router->add('GET', '/api/profile', [ProfileController::class, 'show'], [AuthMiddleware::requireAuth()]);
$router->add('PUT', '/api/profile', [ProfileController::class, 'update'], [AuthMiddleware::requireAuth()]);

// Admin
$router->add('GET', '/api/admin/stats', [AdminController::class, 'stats'], [AuthMiddleware::requireAuth(['admin'])]);
$router->add('GET', '/api/admin/users', [AdminController::class, 'users'], [AuthMiddleware::requireAuth(['admin'])]);
$router->add('PATCH', '/api/admin/users/{id}/status', [AdminController::class, 'toggleUserStatus'], [AuthMiddleware::requireAuth(['admin'])]);
$router->add('POST', '/api/categories', [AdminController::class, 'createCategory'], [AuthMiddleware::requireAuth(['admin'])]);
$router->add('PATCH', '/api/admin/events/{id}/status', [AdminController::class, 'updateEventStatus'], [AuthMiddleware::requireAuth(['admin'])]);

return $router;
