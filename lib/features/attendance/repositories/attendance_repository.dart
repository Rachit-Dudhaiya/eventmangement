import '../models/attendance_model.dart';
import '../services/attendance_service.dart';

class AttendanceRepository {
  AttendanceRepository(this._service);

  final AttendanceService _service;

  Future<AttendanceQrModel> generateQr(int eventId,
      {int ttlMinutes = 30}) async {
    final resp = await _service.generateQr(eventId, ttlMinutes: ttlMinutes);
    return AttendanceQrModel.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<AttendanceSessionModel> startSession(int eventId,
      {int durationMinutes = 30}) async {
    final resp = await _service.startSession(eventId,
        durationMinutes: durationMinutes);
    return AttendanceSessionModel.fromJson(
        resp['data'] as Map<String, dynamic>);
  }

  Future<bool> stopSession(int eventId) async {
    final resp = await _service.stopSession(eventId);
    return resp['success'] == true;
  }

  Future<AttendanceSessionModel> getSessionStatus(int eventId) async {
    final resp = await _service.fetchSessionStatus(eventId);
    return AttendanceSessionModel.fromJson(
        resp['data'] as Map<String, dynamic>);
  }

  Future<StudentPassModel> getStudentPass(int eventId) async {
    final resp = await _service.fetchStudentPass(eventId);
    return StudentPassModel.fromJson(resp['data'] as Map<String, dynamic>);
  }

  Future<({bool ok, String message, String studentName, String studentId})>
      scanStudentPass(int eventId, dynamic studentPassPayload) async {
    final resp = await _service.scanStudentPass(eventId, studentPassPayload);
    final data = resp['data'] as Map<String, dynamic>? ?? {};
    final studentName = data['student_name']?.toString() ?? 'Student';
    final studentId = data['student_id_number']?.toString() ?? '';
    return (
      ok: true,
      message: resp['message']?.toString() ?? 'Attendance recorded',
      studentName: studentName,
      studentId: studentId,
    );
  }

  Future<String> verifyQr(String qrToken) async {
    final resp = await _service.verifyQr(qrToken);
    final eventTitle = resp['data']?['event_title']?.toString() ?? 'Event';
    return 'Attendance marked for $eventTitle';
  }

  Future<({AttendanceSummary summary, List<AttendeeReportItem> attendees})>
      getEventReport(int eventId) async {
    final resp = await _service.fetchEventReport(eventId);
    final data = resp['data'] as Map<String, dynamic>;
    final summary =
        AttendanceSummary.fromJson(data['summary'] as Map<String, dynamic>);
    final attendees = ((data['attendees'] as List?) ?? [])
        .map((e) => AttendeeReportItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (summary: summary, attendees: attendees);
  }
}
