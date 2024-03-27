SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q6 cascade;

CREATE TABLE q6 (
    patronID Char(20) NOT NULL,
    devotedness INT NOT NULL
);

DROP VIEW IF EXISTS single_contributor_books CASCADE;
DROP VIEW IF EXISTS criteria_1 CASCADE;
DROP VIEW IF EXISTS p_c_pairs CASCADE;
DROP VIEW IF EXISTS criteria_2 CASCADE;
DROP VIEW IF EXISTS p_c_reviews CASCADE;
DROP VIEW IF EXISTS criteria_4 CASCADE;
DROP VIEW IF EXISTS criteria_3 CASCADE;

CREATE VIEW single_contributor_books AS
SELECT holding
FROM HoldingContributor hc JOIN Holding h ON hc.holding = h.id
WHERE htype = 'books'
GROUP BY holding
HAVING COUNT(*) = 1;

CREATE VIEW criteria_1 AS
SELECT contributor, COUNT(*) as count_by_contributor
FROM single_contributor_books NATURAL JOIN HoldingContributor h
GROUP BY contributor
HAVING COUNT(*) >= 2;

CREATE VIEW p_c_pairs AS
SELECT c.patron, c1.contributor, c1.count_by_contributor, hc.holding
FROM criteria_1 c1 JOIN HoldingContributor hc
ON c1.contributor = hc.contributor
JOIN single_contributor_books scb ON hc.holding = scb.holding
JOIN LibraryHolding lh ON hc.holding = lh.holding
JOIN Checkout c ON lh.barcode = c.copy;

CREATE VIEW criteria_2 AS
SELECT patron, contributor
FROM p_c_pairs
GROUP BY patron, contributor, count_by_contributor
HAVING COUNT(DISTINCT holding) >= count_by_contributor - 1;

CREATE VIEW criteria_3 AS
SELECT patron, contributor
FROM criteria_2
WHERE (patron, contributor) NOT IN (SELECT patron, contributor FROM
    ((SELECT patron, holding, contributor
    FROM criteria_2 NATURAL JOIN p_c_pairs)
    EXCEPT
    (SELECT patron, holding, contributor FROM Review))
    AS set_diff);

CREATE VIEW criteria_4 AS
SELECT patron, contributor
FROM criteria_3 NATURAL JOIN HoldingContributor
NATURAL JOIN single_contributor_books
NATURAL JOIN Review
GROUP BY patron, contributor
HAVING avg(stars) >= 4.0;    

INSERT INTO q6
SELECT p.patron AS patronID,
COALESCE(COUNT(DISTINCT c4.contributor), 0) AS devotedness
FROM criteria_4 c4
RIGHT JOIN (SELECT card_number AS patron FROM Patron) as p
ON c4.patron = p.patron
GROUP BY p.patron;