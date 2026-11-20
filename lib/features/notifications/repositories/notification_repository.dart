import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/network/api_client.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

class NotificationRepository {
  const NotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> sendEventNotification({
    required int eventId,
    required String title,
    required String body,
  }) {
    return _apiClient.post(
      ApiConstants.sendNotification,
      body: {
        'event_id': eventId,
        'title': title,
        'body': body,
      },
    );
  }
}
