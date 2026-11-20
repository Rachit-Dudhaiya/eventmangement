import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AttendanceService {
  AttendanceService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> generateQr(int eventId, {int ttlMinutes = 30}) {
    return _apiClient.post(
      ApiConstants.generateAttendanceQr(eventId),
      body: {'ttl_minutes': ttlMinutes},
    );
  }

  Future<Map<String, dynamic>> startSession(int eventId,
      {int durationMinutes = 30}) {
    return _apiClient.post(
      ApiConstants.startAttendanceSession(eventId),
      body: {'duration_minutes': durationMinutes},
    );
  }

  Future<Map<String, dynamic>> stopSession(int eventId) {
    return _apiClient.post(
      ApiConstants.stopAttendanceSession(eventId),
    );
  }

  Future<Map<String, dynamic>> fetchSessionStatus(int eventId) {
    return _apiClient.get(ApiConstants.attendanceSessionStatus(eventId));
  }

  Future<Map<String, dynamic>> fetchStudentPass(int eventId) {
    return _apiClient.get(ApiConstants.studentPass(eventId));
  }

  Future<Map<String, dynamic>> scanStudentPass(
      int eventId, dynamic studentPassPayload) {
    return _apiClient.post(
      ApiConstants.scanStudentPass,
      body: {
        'event_id': eventId,
        'student_pass': studentPassPayload,
      },
    );
  }

  Future<Map<String, dynamic>> verifyQr(String qrToken) {
    return _apiClient.post(
      ApiConstants.verifyAttendance,
      body: {'qr_token': qrToken},
    );
  }

  Future<Map<String, dynamic>> fetchEventReport(int eventId) {
    return _apiClient.get(ApiConstants.eventAttendanceReport(eventId));
  }
}
