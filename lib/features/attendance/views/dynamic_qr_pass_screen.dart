import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../events/models/event_model.dart';
import '../viewmodels/attendance_viewmodel.dart';

class DynamicQrPassScreen extends ConsumerStatefulWidget {
  const DynamicQrPassScreen({
    super.key,
    required this.eventId,
    this.event,
  });

  final int eventId;
  final EventModel? event;

  @override
  ConsumerState<DynamicQrPassScreen> createState() =>
      _DynamicQrPassScreenState();
}

class _DynamicQrPassScreenState extends ConsumerState<DynamicQrPassScreen> {
  Timer? _rotationTimer;
  Timer? _sessionTimer;

  // 10-second rotation window
  int _secondsUntilRotation = 10;
  // 30-minute total session period (1800 seconds)
  int _sessionRemainingSeconds = 1800;

  String _currentQrPayload = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(attendanceViewModelProvider.notifier)
          .loadStudentPass(widget.eventId);
      _generateDynamicToken();
      _startTimers();
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _rotationTimer?.cancel();
    _sessionTimer?.cancel();

    // 1-second tick timer
    _rotationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_sessionRemainingSeconds <= 0) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsUntilRotation--;
        _sessionRemainingSeconds--;

        if (_secondsUntilRotation <= 0) {
          _secondsUntilRotation = 10;
          _generateDynamicToken();
        }
      });
    });
  }

  void _generateDynamicToken() {
    final user = ref.read(authViewModelProvider).currentUser;
    final pass = ref.read(attendanceViewModelProvider).activePass;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final payloadMap = {
      'type': 'student_dynamic_pass',
      'event_id': widget.eventId,
      'user_id': user?.id ?? pass?.userId ?? 0,
      'registration_id': pass?.registrationId ?? 0,
      'student_name': user?.fullName ?? pass?.studentName ?? 'Student',
      'student_id': user?.studentIdNumber ?? pass?.studentIdNumber ?? '24CE001',
      'timestamp': now,
      'window': now ~/ 10,
    };

    _currentQrPayload = jsonEncode(payloadMap);
  }

  void _renew30MinSession() {
    setState(() {
      _sessionRemainingSeconds = 1800;
      _secondsUntilRotation = 10;
      _generateDynamicToken();
    });
    _startTimers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('30-Minute pass period renewed!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatSessionTime(int totalSeconds) {
    if (totalSeconds <= 0) return 'Expired';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).currentUser;
    final state = ref.watch(attendanceViewModelProvider);
    final eventTitle =
        widget.event?.title ?? state.activePass?.eventTitle ?? 'Campus Event';
    final venue = widget.event?.venue ?? 'Main Campus Auditorium';
    final isExpired = _sessionRemainingSeconds <= 0;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: const Text(
          'Dynamic Attendance Pass',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Renew Session',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentTeal),
            onPressed: _renew30MinSession,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Event Details Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.teal50,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppTheme.teal200, width: 1),
                        ),
                        child: const Text(
                          'Verified Registration Pass',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentTeal,
                          ),
                        ),
                      ),
                      Text(
                        'ID: ${user?.studentIdNumber ?? '24CE001'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    eventTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppTheme.accentTeal),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Rotating QR Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 10-Second Rotation Indicator Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.red
                                  : AppTheme.accentTealLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isExpired
                                ? 'Pass Expired'
                                : 'Rotating every 10 sec',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isExpired
                                  ? Colors.red
                                  : AppTheme.accentTeal,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.blue50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isExpired
                              ? 'Expired'
                              : 'Next in ${_secondsUntilRotation}s',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryIndigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Linear Progress Bar for 10-Second Window
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: isExpired ? 0.0 : (_secondsUntilRotation / 10.0),
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _secondsUntilRotation <= 3
                            ? Colors.orange
                            : AppTheme.accentTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // The Live QR Code
                  if (isExpired)
                    Container(
                      height: 220,
                      width: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.cardBorder, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_off_outlined,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          const Text(
                            '30-Min Session Ended',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: _renew30MinSession,
                            child: const Text('Renew 30-Min Pass'),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.cardBorder, width: 1.5),
                      ),
                      child: QrImageView(
                        data: _currentQrPayload.isNotEmpty
                            ? _currentQrPayload
                            : 'CAMPUS_PASS_${widget.eventId}',
                        size: 210,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 30-Minute Period Countdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 16, color: AppTheme.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              '30-Min Session Window:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatSessionTime(_sessionRemainingSeconds),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isExpired
                                ? Colors.red
                                : AppTheme.primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Anti-Screenshot & Security Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.blue50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.blue200, width: 1),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 20, color: AppTheme.primaryIndigo),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live Anti-Fraud Protection: This QR code changes every 10 seconds. Screenshots or forwarded photos are automatically rejected by the organizer scanner.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryIndigo,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Copy Raw Token Button for Emulator / Testing
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _currentQrPayload));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '10-second live pass token copied to clipboard! (Paste in Organizer scanner to test)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppTheme.cardBorder),
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text(
                'Copy Live 10s Token (For Testing)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
