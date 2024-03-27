SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q4 cascade;

CREATE TABLE q4 (
    patronID CHAR(20) NOT NULL
);

DROP VIEW IF EXISTS wards_per_patron_year CASCADE;
DROP VIEW IF EXISTS num_wards CASCADE;

CREATE VIEW wards_per_patron_year AS
SELECT esu.patron,
COUNT(DISTINCT lb.ward) as count,
EXTRACT(YEAR from edate) AS year
FROM EventSignUp esu JOIN LibraryEvent le ON esu.event = le.id
JOIN EventSchedule es ON le.id = es.event
JOIN LibraryRoom lr ON le.room = lr.id
JOIN LibraryBranch lb ON lr.library = lb.code
GROUP BY esu.patron, EXTRACT(YEAR from edate);

CREATE VIEW num_wards AS
SELECT COUNT(id) as num FROM Ward;

INSERT INTO q4
SELECT DISTINCT patron AS patronID
FROM wards_per_patron_year w, num_wards n
WHERE w.count = n.num;