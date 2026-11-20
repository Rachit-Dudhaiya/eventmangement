import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Override with `--dart-define=API_BASE_URL=http://192.168.1.100:8000`
  /// when testing on a physical Android device.
  static String get baseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) {
      return defined;
    }
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:8000';
    }
    // 10.0.2.2 routes to host machine localhost from the Android Emulator
    return 'http://10.0.2.2:8000';
  }

  static const String health = '/api/health';
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';

  static const String categories = '/api/categories';
  static const String events = '/api/events';
  static String eventDetail(int id) => '/api/events/$id';
  static String eventRegister(int id) => '/api/events/$id/register';
  static String eventRegistrants(int id) => '/api/events/$id/registrants';
  static const String myRegistrations = '/api/my-registrations';

  static String generateAttendanceQr(int eventId) =>
      '/api/events/$eventId/attendance/qr';
  static String startAttendanceSession(int eventId) =>
      '/api/events/$eventId/attendance/session/start';
  static String stopAttendanceSession(int eventId) =>
      '/api/events/$eventId/attendance/session/stop';
  static String attendanceSessionStatus(int eventId) =>
      '/api/events/$eventId/attendance/session/status';
  static String studentPass(int eventId) =>
      '/api/events/$eventId/attendance/student-pass';
  static const String scanStudentPass = '/api/attendance/scan-student-pass';
  static const String verifyAttendance = '/api/attendance/verify';
  static String eventAttendanceReport(int eventId) =>
      '/api/events/$eventId/attendance';
  static const String myAttendance = '/api/my-attendance';

  static const String deviceToken = '/api/notifications/device-token';
  static const String notifications = '/api/notifications';
  static String markNotificationRead(int id) => '/api/notifications/$id/read';
  static const String sendNotification = '/api/notifications/send';

  static const String profile = '/api/profile';
  static const String adminStats = '/api/admin/stats';
  static const String adminUsers = '/api/admin/users';
  static String adminUserStatus(int id) => '/api/admin/users/$id/status';
  static String adminEventStatus(int id) => '/api/admin/events/$id/status';
}
