DROP VIEW IF EXISTS unsorted CASCADE;

-- The number of conferences that each person attended
CREATE VIEW unsorted AS
(SELECT cr.attendee_id AS person_id, COUNT(*) AS num_conferences
FROM ConferenceRegistration cr
GROUP BY cr.attendee_id)
UNION
(SELECT p.id AS person_id, 0 AS num_conferences
FROM Person p
WHERE p.id NOT IN (SELECT attendee_id FROM ConferenceRegistration));

SELECT * FROM unsorted ORDER BY person_id;
