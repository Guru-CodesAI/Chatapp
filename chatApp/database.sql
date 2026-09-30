-- IRONCHAT database schema
-- IRONCHAT is configured to connect to db01.dbhost.dev:5051 / db_454ruhspn.
-- Run this script after selecting the target database.
-- Run this script once, then create at least two users to test chat.

CREATE TABLE IF NOT EXISTS users (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS messages (
    id BIGINT NOT NULL AUTO_INCREMENT,
    sender VARCHAR(50) NOT NULL,
    receiver VARCHAR(50) NOT NULL,
    message VARCHAR(1000) NOT NULL,
    message_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_messages_conversation (sender, receiver, message_time),
    CONSTRAINT fk_messages_sender
        FOREIGN KEY (sender) REFERENCES users(username)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_messages_receiver
        FOREIGN KEY (receiver) REFERENCES users(username)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Demo accounts. Change these passwords before production.
INSERT INTO users (username, password) VALUES
('tony', '1234'),
('pepper', '1234'),
('rhodey', '1234')
ON DUPLICATE KEY UPDATE username = VALUES(username);
