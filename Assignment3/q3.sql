DROP VIEW IF EXISTS highest CASCADE;

-- The highest total number of accepted papers for any conference
CREATE VIEW highest AS
SELECT MAX(num_accepted) AS max
FROM
    (SELECT c.name AS conference, COUNT(*) AS num_accepted
    FROM Conference c JOIN Submission s ON c.id = s.conference_id
    JOIN Research r ON s.research_id = r.id
    WHERE s.decision = 'accept' AND r.type = 'paper'
    GROUP BY c.name) AS subquery;

SELECT h.conference, CONCAT(p.first_name, ' ', p.last_name) AS first_author
FROM
    (SELECT c.name AS conference
    FROM highest h, Conference c JOIN Submission s ON c.id = s.conference_id
    JOIN Research r ON s.research_id = r.id
    WHERE s.decision = 'accept' AND r.type = 'paper'
    GROUP BY c.name, h.max
    HAVING COUNT(*) = h.max) AS h
JOIN Conference c ON h.conference = c.name
JOIN Submission s ON c.id = s.conference_id
JOIN Research r ON s.research_id = r.id
JOIN ResearchAuthor ra ON s.research_id = ra.research_id
JOIN Person p ON ra.author_id = p.id
WHERE s.decision = 'accept' AND r.type = 'paper' AND ra.n_order = 1;