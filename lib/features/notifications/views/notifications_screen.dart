import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../repositories/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<Map<String, dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _loadNotifications();
  }

  Future<Map<String, dynamic>> _loadNotifications() {
    return ref.read(notificationRepositoryProvider).getNotifications();
  }

  Future<void> _refresh() async {
    final request = _loadNotifications();
    setState(() => _notifications = request);
    await request;
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(notificationId);
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _notifications,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _notifications = _loadNotifications(),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final received =
                List<Map<String, dynamic>>.from(data['received'] as List);
            final sent = List<Map<String, dynamic>>.from(data['sent'] as List);

            return TabBarView(
              children: [
                _notificationList(received, isReceived: true),
                _notificationList(sent, isReceived: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _notificationList(
    List<Map<String, dynamic>> notifications, {
    required bool isReceived,
  }) {
    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: Center(
                child: Text(
                  isReceived
                      ? 'No notifications received yet.'
                      : 'You have not sent any notifications yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final isUnread = isReceived && notification['read_at'] == null;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title']?.toString() ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isUnread)
                        Icon(
                          Icons.fiber_new,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      if (isUnread)
                        IconButton(
                          tooltip: 'Mark as read',
                          onPressed: () => _markAsRead(
                            int.parse(notification['id'].toString()),
                          ),
                          icon: const Icon(Icons.mark_email_read_outlined),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(notification['body']?.toString() ?? ''),
                  const SizedBox(height: 12),
                  if (notification['event_title'] != null)
                    _NotificationDetail(
                      icon: Icons.event_outlined,
                      text: notification['event_title'].toString(),
                    ),
                  if (isReceived && notification['sender_name'] != null)
                    _NotificationDetail(
                      icon: Icons.person_outline,
                      text: 'From ${notification['sender_name']}',
                    ),
                  if (!isReceived)
                    _NotificationDetail(
                      icon: Icons.people_outline,
                      text: '${notification['recipient_count']} recipients',
                    ),
                  _NotificationDetail(
                    icon: Icons.schedule_outlined,
                    text: DateFormatter.formatShortDate(
                      notification['sent_at']?.toString(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationDetail extends StatelessWidget {
  const _NotificationDetail({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
