DROP VIEW IF EXISTS unsuccessful_submissions CASCADE;
DROP VIEW IF EXISTS submitted_most CASCADE;

-- The number of unsuccessful submissions for each accepted research. Assume
-- accepted research cannot be submitted again to any conference
CREATE VIEW unsuccessful_submissions AS
SELECT a.research_id, COUNT(*) AS num_reject
FROM
    (SELECT s.research_id FROM Submission s WHERE s.decision = 'accept') AS a
    NATURAL JOIN Submission s
WHERE s.decision = 'reject'
GROUP BY a.research_id;

-- The maximum number of unsuccessful submissions for any accepted research
CREATE VIEW submitted_most AS
SELECT MAX(us.num_reject) AS max
FROM unsuccessful_submissions us;

SELECT r.name AS title, c.name AS accepting_conference, c.year AS year
FROM unsuccessful_submissions us JOIN submitted_most sm
ON us.num_reject = sm.max
JOIN Research r ON us.research_id = r.id
JOIN Submission s ON r.id = s.research_id
JOIN Conference c ON s.conference_id = c.id
WHERE decision = 'accept';