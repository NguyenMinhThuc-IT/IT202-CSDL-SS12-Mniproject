CREATE DATABASE social_network;
USE social_network;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_posts_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE likes (
    like_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_likes_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,

    CONSTRAINT fk_likes_posts FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE
);

CREATE TABLE comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comments_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,

    CONSTRAINT fk_comments_posts FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE
);

CREATE TABLE friends (
    friend_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    friend_user_id INT NOT NULL,
    status ENUM('pending','accepted','blocked') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_friends_user1 FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,

    CONSTRAINT fk_friends_user2 FOREIGN KEY (friend_user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_posts_created_at
ON posts(created_at);

INSERT INTO users(username, email, password)
VALUES
('nguyenvana', 'vana@gmail.com', '123456'),
('tranthib', 'thib@gmail.com', '123456'),
('levanc', 'vanc@gmail.com', '123456');

INSERT INTO posts(user_id, content, is_deleted)
VALUES
(1, 'Xin chao moi nguoi', FALSE),
(2, 'Hom nay troi dep', FALSE),
(3, 'Dang hoc MySQL', FALSE);

INSERT INTO likes(user_id, post_id)
VALUES
(2, 1),
(3, 1),
(1, 2);

INSERT INTO comments(user_id, post_id, comment_text)
VALUES
(2, 1, 'Bai viet hay'),
(3, 1, 'Toi dong y'),
(1, 2, 'Chuan roi');

INSERT INTO friends(user_id, friend_user_id, status)
VALUES
(1, 2, 'accepted'),
(1, 3, 'accepted'),
(2, 3, 'pending');

CREATE VIEW view_user_info AS
SELECT
    user_id,
    username,
    email,
    created_at
FROM users;

CREATE VIEW view_post_statistics AS
SELECT
    p.post_id,
    u.username,
    p.content,
    COUNT(DISTINCT l.like_id) AS total_likes,
    COUNT(DISTINCT c.comment_id) AS total_comments,
    p.created_at
FROM posts p
LEFT JOIN users u
ON p.user_id = u.user_id
LEFT JOIN likes l
ON p.post_id = l.post_id
LEFT JOIN comments c
ON p.post_id = c.post_id
WHERE p.is_deleted = FALSE
GROUP BY
    p.post_id,
    u.username,
    p.content,
    p.created_at;

DELIMITER $$

CREATE PROCEDURE sp_add_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(100)
)
BEGIN
    DECLARE email_count INT;

    SELECT COUNT(*)
    INTO email_count
    FROM users
    WHERE email = p_email;

    IF email_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email da duoc su dung';
    ELSE
        INSERT INTO users(username, password, email)
        VALUES(p_username, p_password, p_email);
    END IF;

END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT,
    OUT p_new_post_id INT
)
BEGIN

    INSERT INTO posts(user_id, content)
    VALUES(p_user_id, p_content);

    SET p_new_post_id = LAST_INSERT_ID();

END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_get_friends(
    IN p_user_id INT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN

    SELECT
        u.user_id,
        u.username,
        u.email
    FROM friends f
    JOIN users u
    ON f.friend_user_id = u.user_id
    WHERE f.user_id = p_user_id
    AND f.status = 'accepted'
    LIMIT p_limit OFFSET p_offset;

END $$

DELIMITER ;

SELECT * FROM view_user_info;

SELECT * FROM view_post_statistics;


CALL sp_add_user(
    'phamvand',
    '123456',
    'vand@gmail.com'
);

CALL sp_create_post(
    1,
    'Bai viet moi',
    @new_post_id
);

SELECT @new_post_id;

CALL sp_get_friends(
    1,
    10,
    0
);