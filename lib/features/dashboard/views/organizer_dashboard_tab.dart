import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../events/models/event_model.dart';
import '../../events/viewmodels/event_viewmodel.dart';

class OrganizerDashboardTab extends ConsumerStatefulWidget {
  const OrganizerDashboardTab({super.key});

  @override
  ConsumerState<OrganizerDashboardTab> createState() =>
      _OrganizerDashboardTabState();
}

class _OrganizerDashboardTabState extends ConsumerState<OrganizerDashboardTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => mounted
        ? ref.read(eventViewModelProvider.notifier).loadEvents(mine: true)
        : null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventViewModelProvider);
    final totalReg =
        state.events.fold<int>(0, (sum, e) => sum + e.registeredCount);
    final liveCount =
        state.events.where((e) => e.status == 'published').length;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/create'),
        backgroundColor: AppTheme.accentTeal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add_rounded, size: 21),
        label: const Text(
          'Create Event',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top AppBar Header: "Organizer Console" + Notification bell
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organizer Console',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dept. of Computer Engineering',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Notification bell with unread teal dot
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All attendance logs synced'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              size: 21,
                              color: AppTheme.textPrimary,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentTeal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(eventViewModelProvider.notifier)
                    .loadEvents(mine: true),
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    // 2-Column Metric Cards
                    Row(
                      children: [
                        // Metric 1: My Events
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.event_note_rounded,
                            iconColor: AppTheme.primaryIndigo,
                            iconBg: AppTheme.blue50,
                            badgeText: '$liveCount Live',
                            badgeBg: AppTheme.blue50,
                            badgeColor: AppTheme.primaryIndigo,
                            value: state.events.length.toString(),
                            label: 'My Events',
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Metric 2: Registrations
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.how_to_reg_rounded,
                            iconColor: AppTheme.accentTeal,
                            iconBg: AppTheme.teal50,
                            badgeText: '+18% ↑',
                            badgeBg: AppTheme.teal50,
                            badgeColor: AppTheme.accentTeal,
                            value: totalReg.toString(),
                            label: 'Registrations',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section Header: "Managed Events"
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Managed Events',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Active Cycle',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (state.isLoading && state.events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryIndigo,
                          ),
                        ),
                      )
                    else if (state.events.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: const Center(
                          child: Text(
                            'You have not created any events yet.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...state.events.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OrganizerEventCard(
                            event: event,
                            onTap: () => context.push('/events/${event.id}'),
                            onScanAttendance: () => context.push(
                              '/attendance/qr/${event.id}',
                              extra: event,
                            ),
                            onViewRoster: () => context.push(
                              '/attendance/report/${event.id}',
                              extra: event,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 80), // spacing for extended FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String badgeText;
  final Color badgeBg;
  final Color badgeColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizerEventCard extends StatelessWidget {
  const _OrganizerEventCard({
    required this.event,
    required this.onTap,
    required this.onScanAttendance,
    required this.onViewRoster,
  });

  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onScanAttendance;
  final VoidCallback onViewRoster;

  @override
  Widget build(BuildContext context) {
    final capacityRatio = event.maxCapacity > 0
        ? (event.registeredCount / event.maxCapacity).clamp(0.0, 1.0)
        : 0.0;

    final isCheckInOpen = event.status == 'published';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status & Ratio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCheckInOpen ? AppTheme.teal50 : AppTheme.blue50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCheckInOpen
                              ? AppTheme.teal200
                              : AppTheme.blue200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isCheckInOpen
                                  ? AppTheme.accentTeal
                                  : AppTheme.primaryIndigo,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCheckInOpen ? 'Check-in Open' : 'Upcoming',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCheckInOpen
                                  ? AppTheme.accentTeal
                                  : AppTheme.primaryIndigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${event.registeredCount} / ${event.maxCapacity}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Venue & Date Subtitle
                Text(
                  '${DateFormatter.formatShortDate(event.startTime)} • ${event.venue}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: capacityRatio,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCheckInOpen
                            ? AppTheme.primaryIndigo
                            : AppTheme.accentTeal,
                      ),
                    ),
                  ),
                ),

                // Quick Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onScanAttendance,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryIndigo,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Scan Attendance',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onViewRoster,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 16,
                              color: Color(0xFF334155),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Roster',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
