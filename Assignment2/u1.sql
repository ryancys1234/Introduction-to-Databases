DROP VIEW IF EXISTS acceptable_sessions CASCADE;

CREATE VIEW acceptable_sessions AS
SELECT es.event, es.edate
FROM EventSchedule es JOIN LibraryEvent le ON es.event = le.id
JOIN LibraryRoom lr ON le.room = lr.id
JOIN LibraryHours lh ON lr.library = lh.library
WHERE to_char(es.edate + '00:00:01'::time, 'dy') = lh.day::TEXT
AND es.start_time >= lh.start_time AND es.end_time <= lh.end_time;

DELETE FROM EventSchedule
WHERE (event, edate) NOT IN (SELECT * FROM acceptable_sessions);

DELETE FROM LibraryEvent
WHERE id NOT IN (SELECT event AS id FROM EventSchedule);

DELETE FROM EventSignUp
WHERE event NOT IN (SELECT event FROM EventSchedule);