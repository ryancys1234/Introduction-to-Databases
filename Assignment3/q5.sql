DROP VIEW IF EXISTS avg_papers CASCADE;
DROP VIEW IF EXISTS avg_posters CASCADE;

-- The average number of papers in paper sessions for a conference occurrence
CREATE VIEW avg_papers AS
SELECT conference_id, AVG(count_papers) AS average_papers
FROM
    (SELECT s.conference_id, ps.id AS paper_session, COUNT(*) AS count_papers
    FROM Submission s JOIN PaperSession ps
    ON s.conference_id = ps.conference_id
    JOIN PaperPresentation pp ON ps.id = pp.paper_session_id
    AND s.research_id = pp.paper_id
    GROUP BY s.conference_id, ps.id) AS subquery
GROUP BY conference_id;

-- The average number of posters in paper sessions for a conference occurrence
CREATE VIEW avg_posters AS
SELECT conference_id, AVG(count_posters) AS average_posters
FROM
    (SELECT s.conference_id, ps.id AS poster_session, COUNT(*) AS count_posters
    FROM Submission s JOIN PosterSession ps
    ON s.conference_id = ps.conference_id
    JOIN PosterPresentation pp ON ps.id = pp.poster_session_id
    AND s.research_id = pp.poster_id
    GROUP BY s.conference_id, ps.id) AS subquery
GROUP BY conference_id;

(SELECT a.conference_id, a.average_papers,
COALESCE(o.average_posters, 0) AS average_posters
FROM avg_papers a LEFT JOIN avg_posters o
ON a.conference_id = o.conference_id)
UNION
(SELECT o.conference_id, COALESCE(a.average_papers, 0) AS average_papers,
o.average_posters
FROM avg_papers a RIGHT JOIN avg_posters o
ON a.conference_id = o.conference_id);