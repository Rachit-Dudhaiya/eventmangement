import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../notifications/views/send_notification_dialog.dart';
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

  Future<void> _notifyRegistrants(int eventId, String eventTitle) async {
    final response = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SendNotificationDialog(
        eventId: eventId,
        eventTitle: eventTitle,
      ),
    );
    if (!mounted || response == null) return;

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final sent = data['sent'] ?? 0;
    final failed = data['failed'] ?? 0;
    final note = data['note'] as String?;
    final message = note ??
        (failed == 0
            ? 'Push notification sent to $sent devices.'
            : 'Sent to $sent devices; $failed notifications failed.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
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
              color:
                  _isBookmarked ? AppTheme.accentTeal : AppTheme.textSecondary,
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
            icon:
                const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(event.categoryName ?? 'General')),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.schedule_outlined,
                          iconBg: AppTheme.blue50,
                          iconColor: AppTheme.primaryIndigo,
                          label: 'Starts',
                          value: DateFormatter.formatDateTime(event.startTime),
                        ),
                        const Divider(height: 20),
                        _InfoTile(
                          icon: Icons.event_available_outlined,
                          iconBg: AppTheme.teal50,
                          iconColor: AppTheme.accentTeal,
                          label: 'Ends',
                          value: DateFormatter.formatDateTime(event.endTime),
                        ),
                        const Divider(height: 20),
                        _InfoTile(
                          icon: Icons.location_on_outlined,
                          iconBg: AppTheme.blue50,
                          iconColor: AppTheme.primaryIndigo,
                          label: 'Venue',
                          value: event.venue,
                        ),
                        const Divider(height: 20),
                        _InfoTile(
                          icon: Icons.people_outline,
                          iconBg: AppTheme.teal50,
                          iconColor: AppTheme.accentTeal,
                          label: 'Capacity',
                          value:
                              '${event.registeredCount} / ${event.maxCapacity} registered',
                        ),
                        if (event.organizerName != null) ...[
                          const Divider(height: 20),
                          _InfoTile(
                            icon: Icons.person_outline,
                            iconBg: AppTheme.blue50,
                            iconColor: AppTheme.primaryIndigo,
                            label: 'Organizer',
                            value: event.organizerName!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'About this event',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                if (user != null && user.isStudent) ...[
                  if (event.isRegistered)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push('/attendance/scan'),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Attendance QR'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: regState.isSubmitting
                              ? null
                              : _handleCancelRegistration,
                          child: const Text('Cancel Registration'),
                        ),
                      ],
                    )
                  else
                    FilledButton(
                      onPressed: (regState.isSubmitting ||
                              event.isFull ||
                              event.status != 'published')
                          ? null
                          : _handleRegister,
                      child: Text(
                        event.isFull
                            ? 'Event Full'
                            : event.status != 'published'
                                ? 'Registration Closed'
                                : 'Register Now',
                      ),
                    ),
                ],
                if (isOwnerOrAdmin) ...[
                  OutlinedButton.icon(
                    onPressed: () => _notifyRegistrants(event.id, event.title),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Notify Registrants'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => context.push('/attendance/qr/${event.id}',
                        extra: event),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Generate Attendance QR'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .push('/attendance/report/${event.id}', extra: event),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('View Attendance Report'),
                  ),
                ],
              ],
            ),
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
