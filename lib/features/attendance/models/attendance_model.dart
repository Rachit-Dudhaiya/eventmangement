class AttendanceQrModel {
  const AttendanceQrModel({
    required this.eventId,
    required this.qrToken,
    required this.expiresAt,
    required this.ttlMinutes,
  });

  final int eventId;
  final String qrToken;
  final String expiresAt;
  final int ttlMinutes;

  factory AttendanceQrModel.fromJson(Map<String, dynamic> json) {
    return AttendanceQrModel(
      eventId: int.parse(json['event_id'].toString()),
      qrToken: (json['qr_token'] ?? '').toString(),
      expiresAt: (json['expires_at'] ?? '').toString(),
      ttlMinutes: int.tryParse(json['ttl_minutes']?.toString() ?? '30') ?? 30,
    );
  }
}

class AttendanceSessionModel {
  const AttendanceSessionModel({
    required this.eventId,
    required this.isActive,
    this.expiresAt,
    this.remainingSeconds = 0,
    this.durationMinutes = 30,
    this.sessionToken,
  });

  final int eventId;
  final bool isActive;
  final String? expiresAt;
  final int remainingSeconds;
  final int durationMinutes;
  final String? sessionToken;

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      eventId: int.tryParse(json['event_id']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      expiresAt: json['expires_at']?.toString(),
      remainingSeconds:
          int.tryParse(json['remaining_seconds']?.toString() ?? '0') ?? 0,
      durationMinutes:
          int.tryParse(json['duration_minutes']?.toString() ?? '30') ?? 30,
      sessionToken: json['session_token']?.toString(),
    );
  }
}

class StudentPassModel {
  const StudentPassModel({
    required this.eventId,
    required this.eventTitle,
    required this.registrationId,
    required this.userId,
    required this.studentName,
    required this.studentIdNumber,
    required this.isAttended,
    required this.sessionActive,
    this.sessionExpiresAt,
  });

  final int eventId;
  final String eventTitle;
  final int registrationId;
  final int userId;
  final String studentName;
  final String studentIdNumber;
  final bool isAttended;
  final bool sessionActive;
  final String? sessionExpiresAt;

  factory StudentPassModel.fromJson(Map<String, dynamic> json) {
    return StudentPassModel(
      eventId: int.tryParse(json['event_id']?.toString() ?? '0') ?? 0,
      eventTitle: (json['event_title'] ?? '').toString(),
      registrationId:
          int.tryParse(json['registration_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      studentName: (json['student_name'] ?? '').toString(),
      studentIdNumber: (json['student_id_number'] ?? '').toString(),
      isAttended: json['is_attended'] == true || json['is_attended'] == 1,
      sessionActive:
          json['session_active'] == true || json['session_active'] == 1,
      sessionExpiresAt: json['session_expires_at']?.toString(),
    );
  }
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.eventId,
    required this.eventTitle,
    required this.totalRegistered,
    required this.totalPresent,
    required this.attendanceRate,
  });

  final int eventId;
  final String eventTitle;
  final int totalRegistered;
  final int totalPresent;
  final double attendanceRate;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      eventId: int.parse(json['event_id'].toString()),
      eventTitle: (json['event_title'] ?? '').toString(),
      totalRegistered:
          int.tryParse(json['total_registered']?.toString() ?? '0') ?? 0,
      totalPresent: int.tryParse(json['total_present']?.toString() ?? '0') ?? 0,
      attendanceRate:
          double.tryParse(json['attendance_rate']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AttendeeReportItem {
  const AttendeeReportItem({
    required this.userId,
    required this.fullName,
    required this.email,
    this.studentIdNumber,
    this.attendanceStatus,
    this.markedAt,
  });

  final int userId;
  final String fullName;
  final String email;
  final String? studentIdNumber;
  final String? attendanceStatus;
  final String? markedAt;

  bool get isPresent => attendanceStatus != null;

  factory AttendeeReportItem.fromJson(Map<String, dynamic> json) {
    return AttendeeReportItem(
      userId: int.parse(json['user_id'].toString()),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      studentIdNumber: json['student_id_number']?.toString(),
      attendanceStatus: json['attendance_status']?.toString(),
      markedAt: json['marked_at']?.toString(),
    );
  }
}
