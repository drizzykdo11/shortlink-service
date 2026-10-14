USE shortlink;

SELECT COUNT(*) AS total_links,
	   SUM(click_count) AS total_clicks,
       AVG(click_count) AS avg_clicks
FROM links;

SELECT u.email, COUNT(l.id) AS link_count, SUM(l.click_count) AS total_clicks
FROM users u
INNER JOIN links l ON l.user_id = u.id
GROUP BY u.id, u.email;

SELECT u.email, COUNT(l.id) AS link_count, COALESCE(SUM(l.click_count), 0) AS total_clicks
FROM users u
LEFT JOIN links l ON l.user_id = u.id
GROUP BY u.id, u.email;

SELECT u.email, SUM(l.click_count) AS total_clicks
FROM users u
INNER JOIN links l ON l.user_id = u.id
GROUP BY u.id, u.email
HAVING SUM(l.click_count) > 20;

INSERT INTO links (short_code, original_url, user_id)
VALUES('bad999', 'https://example.com', 999);