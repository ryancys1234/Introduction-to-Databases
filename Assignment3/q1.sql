DROP VIEW IF EXISTS accepted CASCADE;
DROP VIEW IF EXISTS rejected CASCADE;

-- The number of accepted submissions for a conference for each year that
-- it was held
CREATE VIEW accepted AS
SELECT c.name AS conference, c.year AS year, COUNT(*) AS num_accepted
FROM Conference c JOIN Submission s ON c.id = s.conference_id
WHERE s.decision = 'accept'
GROUP BY c.name, c.year;

-- The number of rejected submissions for a conference for each year that
-- it was held
CREATE VIEW rejected AS
SELECT c.name AS conference, c.year AS year, COUNT(*) AS num_rejected
FROM Conference c JOIN Submission s ON c.id = s.conference_id
WHERE s.decision = 'reject'
GROUP BY c.name, c.year;

SELECT conference, year,
100*(CAST(num_accepted AS FLOAT)/CAST((num_accepted + num_rejected) AS FLOAT))
AS percent_accepted
FROM
    ((SELECT a.conference, a.year,
    COALESCE(a.num_accepted, 0) AS num_accepted,
    COALESCE(r.num_rejected, 0) AS num_rejected
    FROM accepted a LEFT JOIN rejected r
    ON a.conference = r.conference AND a.year = r.year)
    UNION
    (SELECT r.conference, r.year,
    COALESCE(a.num_accepted, 0) AS num_accepted,
    COALESCE(r.num_rejected, 0) AS num_rejected
    FROM accepted a RIGHT JOIN rejected r
    ON a.conference = r.conference AND a.year = r.year)) AS subquery;