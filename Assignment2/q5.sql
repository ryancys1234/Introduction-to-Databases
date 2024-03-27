SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q5 cascade;

CREATE TABLE q5 (
    patronID CHAR(20) NOT NULL,
    email TEXT NOT NULL,
    usage INT NOT NULL,
    decline INT NOT NULL,
    missed INT NOT NULL
);

DROP VIEW IF EXISTS every_2022 CASCADE;
DROP VIEW IF EXISTS five_to_twelve_2023 CASCADE;
DROP VIEW IF EXISTS none_2024 CASCADE;
DROP VIEW IF EXISTS patrons CASCADE;
DROP VIEW IF EXISTS patron_usage CASCADE;
DROP VIEW IF EXISTS patron_decline CASCADE;
DROP VIEW IF EXISTS patron_missed CASCADE;

-- Intermediate for patrons
CREATE VIEW every_2022 AS
SELECT patron
FROM Checkout
WHERE EXTRACT(YEAR FROM checkout_time) = 2022
GROUP BY patron
HAVING COUNT(DISTINCT EXTRACT(MONTH FROM checkout_time)) = 12;

-- Intermediate for patrons
CREATE VIEW five_to_twelve_2023 AS
SELECT patron
FROM Checkout
WHERE EXTRACT(YEAR FROM checkout_time) = 2023
GROUP BY patron
HAVING COUNT(DISTINCT EXTRACT(MONTH FROM checkout_time)) >= 5
AND COUNT(DISTINCT EXTRACT(MONTH FROM checkout_time)) < 12;

-- Intermediate for patrons
CREATE VIEW none_2024 AS
SELECT patron
FROM Checkout
WHERE patron NOT IN
    (SELECT patron
    FROM Checkout
    WHERE EXTRACT(YEAR FROM checkout_time) = 2024);

CREATE VIEW patrons AS
(SELECT * FROM every_2022) INTERSECT (SELECT * FROM five_to_twelve_2023)
INTERSECT (SELECT * FROM none_2024);

CREATE VIEW patron_usage AS
SELECT c.patron, COUNT(DISTINCT lh.holding) AS usage
FROM Checkout c JOIN LibraryHolding lh ON c.copy = lh.barcode
GROUP BY c.patron;

CREATE VIEW patron_decline AS
SELECT patron, (count_2022 - count_2023) AS decline
FROM
    (SELECT patron, COUNT(*) AS count_2022
    FROM Checkout
    WHERE EXTRACT(YEAR FROM checkout_time) = 2022
    GROUP BY patron) AS subquery1
    NATURAL JOIN
    (SELECT patron, COUNT(*) AS count_2023
    FROM Checkout
    WHERE EXTRACT(YEAR FROM checkout_time) = 2023
    GROUP BY patron) AS subquery2;

CREATE VIEW patron_missed AS
SELECT patron,
(12 - COUNT(DISTINCT EXTRACT(MONTH FROM checkout_time))) AS missed
FROM Checkout
WHERE EXTRACT(YEAR FROM checkout_time) = 2023
GROUP BY patron;

INSERT INTO q5
SELECT p.patron AS patronID, COALESCE(email, 'none') AS email, usage,
decline, missed
FROM patrons p NATURAL JOIN patron_usage NATURAL JOIN patron_decline
NATURAL JOIN patron_missed NATURAL JOIN
    (SELECT card_number AS patron, email FROM Patron) AS subquery;