import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        const SnackBar(content: Text('Registered for event!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
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
        const SnackBar(content: Text('Registration cancelled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
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
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (event != null &&
              user != null &&
              (user.isAdmin || user.id == event.organizerId))
            IconButton(
              tooltip: 'Edit Event',
              icon: const Icon(Icons.edit_outlined),
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

          final isOwnerOrAdmin = user != null &&
              (user.isAdmin || user.id == event.organizerId);

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
                        _InfoRow(
                          icon: Icons.schedule_outlined,
                          label: 'Starts',
                          value: DateFormatter.formatDateTime(event.startTime),
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.event_available_outlined,
                          label: 'Ends',
                          value: DateFormatter.formatDateTime(event.endTime),
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Venue',
                          value: event.venue,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.people_outline,
                          label: 'Capacity',
                          value:
                              '${event.registeredCount} / ${event.maxCapacity} registered',
                        ),
                        if (event.organizerName != null) ...[
                          const Divider(height: 20),
                          _InfoRow(
                            icon: Icons.person_outline,
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
                    onPressed: () =>
                        context.push('/attendance/qr/${event.id}', extra: event),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Generate Attendance QR'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                        '/attendance/report/${event.id}',
                        extra: event),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
