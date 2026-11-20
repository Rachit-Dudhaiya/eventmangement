<?php

declare(strict_types=1);

namespace App\Repositories;

use App\Config\Database;
use PDO;

final class NotificationRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::getConnection();
    }

    public function saveDeviceToken(int $userId, string $fcmToken, string $platform = 'android'): void
    {
        $stmt = $this->db->prepare(
            'INSERT INTO device_tokens (user_id, fcm_token, platform, last_seen_at)
             VALUES (:user_id, :fcm_token, :platform, NOW())
             ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), platform = VALUES(platform), last_seen_at = NOW()'
        );
        $stmt->execute([
            'user_id' => $userId,
            'fcm_token' => $fcmToken,
            'platform' => $platform,
        ]);
    }

    public function deleteDeviceToken(int $userId, string $fcmToken): void
    {
        $stmt = $this->db->prepare(
            'DELETE FROM device_tokens WHERE user_id = :user_id AND fcm_token = :fcm_token'
        );
        $stmt->execute([
            'user_id' => $userId,
            'fcm_token' => $fcmToken,
        ]);
    }

    public function getRecipientUserIdsForEvent(int $eventId): array
    {
        $stmt = $this->db->prepare(
            "SELECT DISTINCT user_id
             FROM event_registrations
             WHERE event_id = :event_id AND status = 'registered'"
        );
        $stmt->execute(['event_id' => $eventId]);
        return array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));
    }

    public function getTokensForEventRegistrants(int $eventId): array
    {
        $stmt = $this->db->prepare(
            "SELECT DISTINCT dt.fcm_token
             FROM device_tokens dt
             INNER JOIN event_registrations r ON r.user_id = dt.user_id
             WHERE r.event_id = :event_id AND r.status = 'registered'"
        );
        $stmt->execute(['event_id' => $eventId]);
        return $stmt->fetchAll(PDO::FETCH_COLUMN);
    }

    public function logNotification(
        ?int $eventId,
        int $senderId,
        string $title,
        string $body,
        array $recipientUserIds
    ): int
    {
        $recipientUserIds = array_values(array_unique(array_map('intval', $recipientUserIds)));
        $this->db->beginTransaction();

        try {
            $stmt = $this->db->prepare(
                'INSERT INTO notifications (event_id, sender_id, title, body, recipient_count)
                 VALUES (:event_id, :sender_id, :title, :body, :recipient_count)'
            );
            $stmt->execute([
                'event_id' => $eventId,
                'sender_id' => $senderId,
                'title' => $title,
                'body' => $body,
                'recipient_count' => count($recipientUserIds),
            ]);
            $notificationId = (int) $this->db->lastInsertId();

            if ($recipientUserIds !== []) {
                $recipientStmt = $this->db->prepare(
                    'INSERT INTO notification_recipients (notification_id, user_id)
                     VALUES (:notification_id, :user_id)'
                );
                foreach ($recipientUserIds as $userId) {
                    $recipientStmt->execute([
                        'notification_id' => $notificationId,
                        'user_id' => $userId,
                    ]);
                }
            }

            $this->db->commit();
            return $notificationId;
        } catch (\Throwable $error) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            throw $error;
        }
    }

    public function getReceivedNotifications(int $userId): array
    {
        $stmt = $this->db->prepare(
            'SELECT n.id, n.event_id, e.title AS event_title, n.title, n.body,
                    sender.full_name AS sender_name, n.sent_at, nr.read_at
             FROM notification_recipients nr
             INNER JOIN notifications n ON n.id = nr.notification_id
             LEFT JOIN events e ON e.id = n.event_id
             INNER JOIN users sender ON sender.id = n.sender_id
             WHERE nr.user_id = :user_id
             ORDER BY n.sent_at DESC, n.id DESC'
        );
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getSentNotifications(int $userId): array
    {
        $stmt = $this->db->prepare(
            'SELECT n.id, n.event_id, e.title AS event_title, n.title, n.body,
                    n.recipient_count, n.sent_at
             FROM notifications n
             LEFT JOIN events e ON e.id = n.event_id
             WHERE n.sender_id = :user_id
             ORDER BY n.sent_at DESC, n.id DESC'
        );
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function markNotificationAsRead(int $userId, int $notificationId): bool
    {
        $stmt = $this->db->prepare(
            'SELECT 1 FROM notification_recipients
             WHERE notification_id = :notification_id AND user_id = :user_id'
        );
        $stmt->execute([
            'notification_id' => $notificationId,
            'user_id' => $userId,
        ]);
        if ($stmt->fetchColumn() === false) {
            return false;
        }

        $stmt = $this->db->prepare(
            'UPDATE notification_recipients
             SET read_at = COALESCE(read_at, NOW())
             WHERE notification_id = :notification_id AND user_id = :user_id'
        );
        $stmt->execute([
            'notification_id' => $notificationId,
            'user_id' => $userId,
        ]);
        return true;
    }
}
