<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Helpers\Response;
use App\Helpers\Validator;
use App\Repositories\EventRepository;
use App\Repositories\NotificationRepository;
use App\Services\FcmService;

final class NotificationController
{
    public function saveDeviceToken(array $context): void
    {
        $input = Response::readJsonBody();
        $errors = Validator::requireFields($input, ['fcm_token']);
        if ($errors !== []) {
            Response::error('Validation failed', 422, $errors);
        }

        $platform = in_array($input['platform'] ?? 'android', ['android', 'ios', 'web'], true)
            ? $input['platform']
            : 'android';

        (new NotificationRepository())->saveDeviceToken(
            (int) $context['user']['id'],
            trim((string) $input['fcm_token']),
            $platform
        );

        Response::ok('Device token registered');
    }

    public function deleteDeviceToken(array $context): void
    {
        $input = Response::readJsonBody();
        $errors = Validator::requireFields($input, ['fcm_token']);
        if ($errors !== []) {
            Response::error('Validation failed', 422, $errors);
        }

        (new NotificationRepository())->deleteDeviceToken(
            (int) $context['user']['id'],
            trim((string) $input['fcm_token'])
        );

        Response::ok('Device token unregistered');
    }

    public function index(array $context): void
    {
        $repository = new NotificationRepository();
        $userId = (int) $context['user']['id'];

        Response::ok('Notifications retrieved', [
            'received' => $repository->getReceivedNotifications($userId),
            'sent' => $repository->getSentNotifications($userId),
        ]);
    }

    public function markAsRead(array $context): void
    {
        $notificationId = (int) ($context['params']['id'] ?? 0);
        if ($notificationId < 1) {
            Response::error('Notification not found', 404);
        }

        $userId = (int) $context['user']['id'];
        if (!(new NotificationRepository())->markNotificationAsRead($userId, $notificationId)) {
            Response::error('Notification not found', 404);
        }

        Response::ok('Notification marked as read');
    }

    public function send(array $context): void
    {
        $input = Response::readJsonBody();
        $errors = Validator::requireFields($input, ['event_id', 'title', 'body']);
        if ($errors !== []) {
            Response::error('Validation failed', 422, $errors);
        }

        $eventId = (int) $input['event_id'];
        $event = (new EventRepository())->findById($eventId);
        if ($event === null) {
            Response::error('Event not found', 404);
        }

        $user = $context['user'];
        if ($user['role'] !== 'admin' && (int) $event['organizer_id'] !== (int) $user['id']) {
            Response::error('Forbidden: only the event organizer can send notifications', 403);
        }

        $notifRepo = new NotificationRepository();
        $recipientUserIds = $notifRepo->getRecipientUserIdsForEvent($eventId);
        $tokens = $notifRepo->getTokensForEventRegistrants($eventId);
        $result = (new FcmService())->sendToTokens(
            $tokens,
            trim((string) $input['title']),
            trim((string) $input['body']),
            ['event_id' => (string) $eventId, 'type' => 'event_update']
        );

        $notificationId = $notifRepo->logNotification(
            $eventId,
            (int) $user['id'],
            trim((string) $input['title']),
            trim((string) $input['body']),
            $recipientUserIds
        );

        Response::ok('Notification processed', array_merge($result, [
            'notification_id' => $notificationId,
            'recipient_count' => count($recipientUserIds),
        ]));
    }
}
