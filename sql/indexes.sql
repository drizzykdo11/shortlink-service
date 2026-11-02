USE shortlink;

SET SESSION cte_max_recursion_depth = 200000;

INSERT INTO links (short_code, original_url, click_count, user_id)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 200000
)
SELECT CONCAT('s', n),
       CONCAT('https://example.com/page/', n),
       n % 1000,
       (n % 3) + 1
FROM seq;

SELECT COUNT(*) FROM links;

SHOW INDEX FROM links;

EXPLAIN SELECT * FROM links WHERE short_code = 's150000';
EXPLAIN SELECT * FROM links WHERE click_count = 500;

CREATE INDEX idx_links_click_count ON links(click_count);
EXPLAIN SELECT * FROM links WHERE click_count = 500;

EXPLAIN SELECT * FROM links WHERE short_code LIKE 's1500%';
EXPLAIN SELECT * FROM links WHERE short_code LIKE '%1500';

DROP INDEX idx_links_click_count ON links;
CREATE INDEX idx_links_user_clicks ON links(user_id, click_count);
EXPLAIN SELECT * FROM links WHERE user_id = 2 AND click_count > 990;
EXPLAIN SELECT * FROM links WHERE click_count > 990;
SHOW INDEX FROM links;

EXPLAIN SELECT * FROM links WHERE user_id = 2 AND click_count > 990;
EXPLAIN SELECT user_id, click_count FROM links WHERE user_id = 2 AND click_count > 990;
