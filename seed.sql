USE shortlink;

INSERT INTO users (email)
VALUES
	('alice@example.com'),
    ('bob@example.com'),
    ('charlie@example.com');
    
INSERT INTO links (short_code, original_url, click_count, user_id)
VALUES ('a', 'https://a.com', 13, (SELECT id FROM users WHERE email = 'alice@example.com')),
       ('c', 'https://github.com', 15, (SELECT id FROM users WHERE email = 'alice@example.com')),
       ('d', 'https://a.com', 6, (SELECT id FROM users WHERE email = 'bob@example.com')),
       ('e', 'https://e.com', 8, (SELECT id FROM users WHERE email = 'bob@example.com')),
       ('f', 'https://f.com', 9, NULL);
