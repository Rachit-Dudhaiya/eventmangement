import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../registrations/viewmodels/registration_viewmodel.dart';
import '../viewmodels/event_viewmodel.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => mounted
        ? ref
            .read(eventViewModelProvider.notifier)
            .loadEventDetail(widget.eventId)
        : null);
  }

  Future<void> _handleRegister() async {
    final err = await ref
        .read(registrationViewModelProvider.notifier)
        .registerForEvent(widget.eventId);

    if (!mounted) return;
    if (err == null) {
      await ref
          .read(eventViewModelProvider.notifier)
          .loadEventDetail(widget.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registered for event! Pass is ready.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCancelRegistration() async {
    final err = await ref
        .read(registrationViewModelProvider.notifier)
        .cancelRegistration(widget.eventId);

    if (!mounted) return;
    if (err == null) {
      await ref
          .read(eventViewModelProvider.notifier)
          .loadEventDetail(widget.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration cancelled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventViewModelProvider);
    final regState = ref.watch(registrationViewModelProvider);
    final user = ref.watch(authViewModelProvider).currentUser;
    final event = eventState.selectedEvent;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Event Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark event',
            icon: Icon(
              _isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _isBookmarked
                  ? AppTheme.accentTeal
                  : AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBookmarked
                      ? 'Event saved to bookmarks'
                      : 'Bookmark removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Share event',
            icon: const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event link copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          if (event != null &&
              user != null &&
              (user.isAdmin || user.id == event.organizerId))
            IconButton(
              tooltip: 'Edit Event',
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.primaryIndigo),
              onPressed: () =>
                  context.push('/events/${event.id}/edit', extra: event),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (eventState.isLoading && event == null) {
            return const LoadingStateView(message: 'Loading event...');
          }
          if (eventState.errorMessage != null && event == null) {
            return ErrorStateView(
              message: eventState.errorMessage!,
              onRetry: () => ref
                  .read(eventViewModelProvider.notifier)
                  .loadEventDetail(widget.eventId),
            );
          }
          if (event == null) {
            return const EmptyStateView(
              icon: Icons.event_busy,
              title: 'Event Not Found',
              subtitle: 'This event may have been removed.',
            );
          }

          final isOwnerOrAdmin =
              user != null && (user.isAdmin || user.id == event.organizerId);
          final capacityRatio = event.maxCapacity > 0
              ? (event.registeredCount / event.maxCapacity).clamp(0.0, 1.0)
              : 0.0;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Chip + Activity Points Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.teal50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.teal200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentTeal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event.categoryName ?? 'Workshop',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.blue50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '+2 Activity Points',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryIndigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bold Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rounded Info Card (Starts, Ends, Venue, Capacity, Organizer)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.cardBorder, width: 1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Starts
                            _InfoTile(
                              icon: Icons.event_available_rounded,
                              iconBg: AppTheme.blue50,
                              iconColor: AppTheme.primaryIndigo,
                              label: 'STARTS',
                              value: DateFormatter.formatDateTime(
                                  event.startTime),
                            ),
                            const Divider(
                                color: AppTheme.cardBorder, height: 20),

                            // Ends
                            _InfoTile(
                              icon: Icons.event_busy_rounded,
                              iconBg: AppTheme.blue50,
                              iconColor: AppTheme.primaryIndigo,
                              label: 'ENDS',
                              value:
                                  DateFormatter.formatDateTime(event.endTime),
                            ),
                            const Divider(
                                color: AppTheme.cardBorder, height: 20),

                            // Venue
                            _InfoTile(
                              icon: Icons.location_on_rounded,
                              iconBg: AppTheme.teal50,
                              iconColor: AppTheme.accentTeal,
                              label: 'VENUE',
                              value: event.venue,
                            ),
                            const Divider(
                                color: AppTheme.cardBorder, height: 20),

                            // Capacity with Progress Bar
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.teal50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.groups_rounded,
                                    color: AppTheme.accentTeal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'CAPACITY',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.4,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            '${event.registeredCount} / ${event.maxCapacity} Seats',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.accentTeal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: capacityRatio,
                                          minHeight: 6,
                                          backgroundColor:
                                              const Color(0xFFF1F5F9),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(AppTheme.accentTeal),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            if (event.organizerName != null) ...[
                              const Divider(
                                  color: AppTheme.cardBorder, height: 20),
                              // Organizer
                              _InfoTile(
                                icon: Icons.corporate_fare_rounded,
                                iconBg: const Color(0xFFF1F5F9),
                                iconColor: const Color(0xFF475569),
                                label: 'ORGANIZER',
                                value: event.organizerName!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // "About this event"
                      const Text(
                        'About this event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description.isNotEmpty
                            ? event.description
                            : 'Build and deploy a production-ready application from scratch with real-time sync, attendance verification via QR check-in, and peer collaboration.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: AppTheme.cardBorder, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user != null && user.isStudent) ...[
                        if (event.isRegistered) ...[
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: () =>
                                      context.push('/attendance/scan'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.accentTeal,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          size: 19, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Registered • Pass Ready',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: regState.isSubmitting
                                    ? null
                                    : _handleCancelRegistration,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                      color: AppTheme.cardBorder),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          FilledButton(
                            onPressed: (regState.isSubmitting ||
                                    event.isFull ||
                                    event.status != 'published')
                                ? null
                                : _handleRegister,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryIndigo,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: regState.isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.how_to_reg_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        event.isFull
                                            ? 'Event Full'
                                            : event.status != 'published'
                                                ? 'Registration Closed'
                                                : 'Register Now',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ] else if (isOwnerOrAdmin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => context.push(
                                  '/attendance/qr/${event.id}',
                                  extra: event,
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryIndigo,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_2_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Generate QR',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push(
                                  '/attendance/report/${event.id}',
                                  extra: event,
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: AppTheme.primaryIndigo,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Text(
                                  'View Report',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryIndigo,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
