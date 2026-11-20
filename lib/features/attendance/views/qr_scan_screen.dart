import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../events/viewmodels/event_viewmodel.dart';
import '../viewmodels/attendance_viewmodel.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({
    super.key,
    this.eventId,
    this.eventTitle,
  });

  final int? eventId;
  final String? eventTitle;

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _manualController = TextEditingController();
  bool _hasScanned = false;
  int? _selectedEventId;
  String? _selectedEventTitle;

  Timer? _sessionCountdownTimer;
  int _sessionRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.eventId;
    _selectedEventTitle = widget.eventTitle;

    Future.microtask(() async {
      if (!mounted) return;
      final user = ref.read(authViewModelProvider).currentUser;

      if (user != null && (user.isOrganizer || user.isAdmin)) {
        // Load organizer's events if no event was pre-selected
        if (_selectedEventId == null) {
          await ref
              .read(eventViewModelProvider.notifier)
              .loadEvents(mine: true);
          final events = ref.read(eventViewModelProvider).events;
          if (events.isNotEmpty && mounted) {
            setState(() {
              _selectedEventId = events.first.id;
              _selectedEventTitle = events.first.title;
            });
          }
        }

        // Check if an attendance session is already active for this event
        if (_selectedEventId != null) {
          await ref
              .read(attendanceViewModelProvider.notifier)
              .checkSessionStatus(_selectedEventId!);
          final session =
              ref.read(attendanceViewModelProvider).activeSession;
          if (session != null && session.isActive) {
            _startLocalCountdown(session.remainingSeconds);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _manualController.dispose();
    _sessionCountdownTimer?.cancel();
    super.dispose();
  }

  void _startLocalCountdown(int initialSeconds) {
    _sessionCountdownTimer?.cancel();
    setState(() => _sessionRemainingSeconds = initialSeconds);

    _sessionCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_sessionRemainingSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _sessionRemainingSeconds--);
    });
  }

  String _formatSessionTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleStartSession() async {
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event first')),
      );
      return;
    }

    await ref
        .read(attendanceViewModelProvider.notifier)
        .startSession(_selectedEventId!, durationMinutes: 30);

    final session = ref.read(attendanceViewModelProvider).activeSession;
    if (session != null && session.isActive) {
      _startLocalCountdown(session.remainingSeconds > 0
          ? session.remainingSeconds
          : 1800);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '30-Minute Attendance Session Started! Scanner is now active.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleStopSession() async {
    if (_selectedEventId == null) return;

    await ref
        .read(attendanceViewModelProvider.notifier)
        .stopSession(_selectedEventId!);
    _sessionCountdownTimer?.cancel();
    setState(() => _sessionRemainingSeconds = 0);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance session ended. Scanning paused.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _processScan(String rawData) async {
    if (rawData.trim().isEmpty || _hasScanned) return;

    final user = ref.read(authViewModelProvider).currentUser;
    final isOrganizer = user != null && (user.isOrganizer || user.isAdmin);
    final isSessionActive =
        ref.read(attendanceViewModelProvider).isSessionActive;

    // Requirement: Organizer can only scan if attendance session is started!
    if (isOrganizer && !isSessionActive) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Session Not Started'),
            ],
          ),
          content: const Text(
            'Attendance scanning is blocked because the session is not started. Please tap "Start Attendance Session" to open the 30-minute check-in window.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _hasScanned = true);

    if (isOrganizer) {
      // Organizer scanning student's dynamic rotating pass
      final result = await ref
          .read(attendanceViewModelProvider.notifier)
          .scanStudentPass(_selectedEventId ?? 0, rawData.trim());

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                result.ok
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: result.ok ? AppTheme.accentTeal : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                result.ok ? 'Attendance Marked' : 'Scan Error',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.ok && result.studentName != null) ...[
                Text(
                  'Student: ${result.studentName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (result.studentId != null &&
                    result.studentId!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Student ID: ${result.studentId}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
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
                    'Status: Present ✓',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentTeal,
                    ),
                  ),
                ),
              ] else ...[
                Text(result.message),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryIndigo,
              ),
              child: const Text('Scan Next Student'),
            ),
          ],
        ),
      );
    } else {
      // Student scanning organizer QR token
      final result = await ref
          .read(attendanceViewModelProvider.notifier)
          .verifyQrToken(rawData.trim());

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(result.ok ? 'Attendance Marked' : 'Verification Failed'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    if (mounted) {
      // Re-arm scanner after 1.5 seconds delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _hasScanned = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).currentUser;
    final isOrganizer = user != null && (user.isOrganizer || user.isAdmin);
    final state = ref.watch(attendanceViewModelProvider);
    final events = ref.watch(eventViewModelProvider).events;
    final isSessionActive = state.isSessionActive;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: Text(
          isOrganizer ? 'Organizer Attendance Scanner' : 'Scan Attendance QR',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // If Organizer: Event Selector & Session Control Header
          if (isOrganizer) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Event Dropdown or Label
                  if (events.length > 1)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedEventId ?? events.first.id,
                      decoration: const InputDecoration(
                        labelText: 'Select Managed Event',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: events.map((e) {
                        return DropdownMenuItem<int>(
                          value: e.id,
                          child: Text(
                            e.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedEventId = val;
                            _selectedEventTitle = events
                                .firstWhere((e) => e.id == val)
                                .title;
                          });
                          ref
                              .read(attendanceViewModelProvider.notifier)
                              .checkSessionStatus(val);
                        }
                      },
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.event_note_rounded,
                            size: 18, color: AppTheme.primaryIndigo),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedEventTitle ?? 'Campus Event',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),

                  // Session Control Status Bar & Start/Stop Button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSessionActive
                          ? AppTheme.teal50
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSessionActive
                            ? AppTheme.teal200
                            : AppTheme.cardBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Status & 30-min Timer
                        Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: isSessionActive
                                    ? AppTheme.accentTealLight
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSessionActive
                                      ? 'Session Active (30 Min)'
                                      : 'Session Not Started',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSessionActive
                                        ? AppTheme.accentTeal
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                if (isSessionActive)
                                  Text(
                                    'Remaining: ${_formatSessionTime(_sessionRemainingSeconds)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryIndigo,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Scanning is locked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Right: Start / Stop Button
                        if (!isSessionActive)
                          FilledButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : _handleStartSession,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accentTeal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded,
                                size: 18),
                            label: const Text(
                              'Start Session',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : _handleStopSession,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(
                                  color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.stop_rounded, size: 18),
                            label: const Text(
                              'Stop Session',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Camera Viewfinder / MobileScanner
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null && code.isNotEmpty) {
                        _processScan(code);
                      }
                    }
                  },
                ),

                // If organizer has NOT started session: Show blurred overlay blocking scan
                if (isOrganizer && !isSessionActive)
                  Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              size: 32,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Attendance Session Not Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click the "Start Session" button above to activate the 30-minute attendance check-in window and scan student QR passes.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _handleStartSession,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accentTeal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.play_circle_fill_rounded),
                            label: const Text(
                              'Start Attendance Session',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Active Scanner Reticle / Viewfinder Frame
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.accentTealLight,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 90,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (state.isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Testing Input Section (For Emulator / Manual Paste)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Testing on emulator without camera? Paste QR token below:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          decoration: InputDecoration(
                            hintText: isOrganizer
                                ? 'Paste student live QR token'
                                : 'Paste CAMPUS_QR_... token',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                _processScan(_manualController.text.trim());
                                _manualController.clear();
                              },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(80, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          backgroundColor: AppTheme.primaryIndigo,
                        ),
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
