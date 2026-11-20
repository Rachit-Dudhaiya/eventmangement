CREATE TABLE IF NOT EXISTS notification_recipients (
    notification_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    read_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (notification_id, user_id),
    INDEX idx_notif_recipients_user_read (user_id, read_at),
    CONSTRAINT fk_notif_recipient_notification FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    CONSTRAINT fk_notif_recipient_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;
