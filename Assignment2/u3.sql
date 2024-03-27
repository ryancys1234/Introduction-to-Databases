DROP VIEW IF EXISTS open_sunday CASCADE;
DROP VIEW IF EXISTS open_past_6_weekday CASCADE;
DROP VIEW IF EXISTS no_sunday_past_6 CASCADE;

CREATE VIEW open_sunday AS
SELECT library FROM LibraryHours WHERE day = 'sun' AND start_time < end_time;

CREATE VIEW open_past_6_weekday AS
SELECT library FROM LibraryHours
WHERE (day = 'mon' OR day = 'tue' OR day = 'wed' OR day = 'thu' OR day = 'fri')
AND end_time > '18:00:00';

CREATE VIEW no_sunday_past_6 AS
(SELECT DISTINCT library FROM LibraryHours)
EXCEPT (SELECT * FROM open_sunday)
EXCEPT (SELECT * FROM open_past_6_weekday);

UPDATE LibraryHours
SET end_time = '21:00:00'
WHERE library IN (SELECT * FROM no_sunday_past_6)
AND day = 'thu';

INSERT INTO LibraryHours
SELECT library, 'thu' AS day, '18:00:00' AS start_time, '21:00:00' AS end_time
FROM no_sunday_past_6
WHERE library NOT IN (SELECT library FROM LibraryHours WHERE day = 'thu');