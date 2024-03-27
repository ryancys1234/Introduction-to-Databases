SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q1 cascade;

CREATE TABLE q1 (
    branch CHAR(5) NOT NULL,
    year INT NOT NULL,
    events INT NOT NULL,
    sessions FLOAT NOT NULL,
    registration INT NOT NULL,
    holdings INT NOT NULL,
    checkouts INT NOT NULL,
    duration FLOAT NOT NULL
);

DROP VIEW IF EXISTS branch_events CASCADE;
DROP VIEW IF EXISTS event_num_sessions CASCADE;
DROP VIEW IF EXISTS event_avg_sessions CASCADE;
DROP VIEW IF EXISTS event_library CASCADE;
DROP VIEW IF EXISTS event_registrations CASCADE;
DROP VIEW IF EXISTS branch_holdings CASCADE;
DROP VIEW IF EXISTS branch_checkouts CASCADE;
DROP VIEW IF EXISTS holding_duration CASCADE;
DROP VIEW IF EXISTS years CASCADE;

CREATE VIEW branch_events AS
SELECT lr.library AS branch,
extract(year FROM es.edate) AS year,
count(distinct le.id) AS events
FROM LibraryRoom lr JOIN LibraryEvent le ON lr.id = le.room
JOIN EventSchedule es ON le.id = es.event
GROUP BY lr.library, EXTRACT(YEAR FROM es.edate);

-- Intermediate for event_avg_sessions
CREATE VIEW event_num_sessions AS
SELECT lr.library AS branch,
extract(year FROM es.edate) AS year,
count(*) AS count
FROM LibraryRoom lr JOIN LibraryEvent le ON lr.id = le.room
JOIN EventSchedule es ON le.id = es.event
GROUP BY lr.library, extract(year FROM es.edate), es.event;

CREATE VIEW event_avg_sessions AS
SELECT branch, year, avg(count) AS sessions
FROM event_num_sessions
GROUP BY branch, year;

-- Intermediate for event_registrations
CREATE VIEW event_library AS
SELECT DISTINCT lr.library AS branch, le.id AS event,
extract(year FROM es.edate) AS year
FROM LibraryRoom lr JOIN LibraryEvent le ON lr.id = le.room
JOIN EventSchedule es ON le.id = es.event;

CREATE VIEW event_registrations AS
SELECT el.branch, el.year, count(*) AS registration
FROM event_library el JOIN EventSignUp esu ON el.event = esu.event
GROUP BY el.branch, el.year;

CREATE VIEW branch_holdings AS
SELECT lh.library AS branch, count(*) AS holdings
FROM LibraryHolding lh
GROUP BY lh.library;

CREATE VIEW branch_checkouts AS
SELECT lh.library AS branch,
extract(year FROM c.checkout_time) AS year,
count(*) AS checkouts
FROM Checkout c JOIN LibraryHolding lh ON c.copy = lh.barcode
GROUP BY lh.library, extract(year FROM c.checkout_time);

CREATE VIEW holding_duration AS
SELECT lh.library AS branch,
extract(year FROM c.checkout_time) AS year,
avg(date(r.return_time) - date(c.checkout_time)) AS duration
FROM Checkout c JOIN Return r ON c.id = r.checkout
JOIN LibraryHolding lh ON c.copy = lh.barcode
GROUP BY lh.library, extract(year FROM c.checkout_time);

-- Intermediate for final answer
CREATE VIEW years AS
(SELECT 2019 AS year) UNION (SELECT 2020 AS year) UNION (SELECT 2021 AS year)
UNION (SELECT 2022 AS year) UNION (SELECT 2023 AS year);

INSERT INTO q1
SELECT byr.branch, byr.year, COALESCE(be.events, 0) AS events,
COALESCE(eas.sessions, 0) AS sessions,
COALESCE(er.registration, 0) AS registration,
COALESCE(bh.holdings, 0) AS holdings,
COALESCE(bc.checkouts, 0) AS checkouts,
COALESCE(hd.duration, 0.0) AS duration
FROM (SELECT DISTINCT code AS branch, year FROM LibraryBranch, years) as byr
LEFT JOIN branch_events be ON
(byr.branch = be.branch AND byr.year = be.year)
LEFT JOIN event_avg_sessions eas ON
(byr.branch = eas.branch AND byr.year = eas.year)
LEFT JOIN event_registrations er ON
(byr.branch = er.branch AND byr.year = er.year)
LEFT JOIN branch_holdings bh ON
(byr.branch = bh.branch)
LEFT JOIN branch_checkouts bc ON
(byr.branch = bc.branch AND byr.year = bc.year)
LEFT JOIN holding_duration hd ON
(byr.branch = hd.branch AND byr.year = hd.year)
ORDER BY branch, year;