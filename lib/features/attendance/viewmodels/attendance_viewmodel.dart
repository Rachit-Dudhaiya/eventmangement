import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';
import '../services/attendance_service.dart';

class AttendanceState {
  const AttendanceState({
    this.activeQr,
    this.activeSession,
    this.activePass,
    this.summary,
    this.attendees = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final AttendanceQrModel? activeQr;
  final AttendanceSessionModel? activeSession;
  final StudentPassModel? activePass;
  final AttendanceSummary? summary;
  final List<AttendeeReportItem> attendees;
  final bool isLoading;
  final String? errorMessage;

  bool get isSessionActive => activeSession?.isActive ?? false;

  AttendanceState copyWith({
    AttendanceQrModel? activeQr,
    AttendanceSessionModel? activeSession,
    StudentPassModel? activePass,
    AttendanceSummary? summary,
    List<AttendeeReportItem>? attendees,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AttendanceState(
      activeQr: activeQr ?? this.activeQr,
      activeSession:
          clearSession ? null : (activeSession ?? this.activeSession),
      activePass: activePass ?? this.activePass,
      summary: summary ?? this.summary,
      attendees: attendees ?? this.attendees,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(AttendanceService(ref.watch(apiClientProvider)));
});

final attendanceViewModelProvider =
    NotifierProvider<AttendanceViewModel, AttendanceState>(
  AttendanceViewModel.new,
);

class AttendanceViewModel extends Notifier<AttendanceState> {
  @override
  AttendanceState build() => const AttendanceState();

  AttendanceRepository get _repository =>
      ref.read(attendanceRepositoryProvider);

  Future<void> startSession(int eventId, {int durationMinutes = 30}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repository.startSession(eventId,
          durationMinutes: durationMinutes);
      state = state.copyWith(activeSession: session, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start attendance session.',
      );
    }
  }

  Future<void> stopSession(int eventId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.stopSession(eventId);
      state = state.copyWith(
        activeSession: AttendanceSessionModel(
          eventId: eventId,
          isActive: false,
          remainingSeconds: 0,
        ),
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to stop attendance session.',
      );
    }
  }

  Future<void> checkSessionStatus(int eventId) async {
    try {
      final session = await _repository.getSessionStatus(eventId);
      state = state.copyWith(activeSession: session);
    } catch (_) {
      // Quietly ignore or keep local state
    }
  }

  Future<void> loadStudentPass(int eventId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pass = await _repository.getStudentPass(eventId);
      state = state.copyWith(activePass: pass, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load student pass.',
      );
    }
  }

  Future<({bool ok, String message, String? studentName, String? studentId})>
      scanStudentPass(int eventId, dynamic studentPassPayload) async {
    state = state.copyWith(isLoading: true);
    try {
      final result =
          await _repository.scanStudentPass(eventId, studentPassPayload);
      return (
        ok: true,
        message: result.message,
        studentName: result.studentName,
        studentId: result.studentId,
      );
    } on ApiException catch (e) {
      return (
        ok: false,
        message: e.message,
        studentName: null,
        studentId: null,
      );
    } catch (_) {
      return (
        ok: false,
        message: 'Failed to verify student pass.',
        studentName: null,
        studentId: null,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> generateQr(int eventId, {int ttlMinutes = 30}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final qr =
          await _repository.generateQr(eventId, ttlMinutes: ttlMinutes);
      state = state.copyWith(activeQr: qr, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to generate QR code.',
      );
    }
  }

  Future<({bool ok, String message})> verifyQrToken(String qrToken) async {
    state = state.copyWith(isLoading: true);
    try {
      final msg = await _repository.verifyQr(qrToken);
      return (ok: true, message: msg);
    } on ApiException catch (e) {
      return (ok: false, message: e.message);
    } catch (_) {
      return (ok: false, message: 'Failed to verify QR code.');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadEventReport(int eventId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.getEventReport(eventId);
      state = state.copyWith(
        summary: result.summary,
        attendees: result.attendees,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load attendance report.',
      );
    }
  }
}
