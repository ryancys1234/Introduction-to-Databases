SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q3 cascade;

DROP DOMAIN IF EXISTS patronCategory;
CREATE DOMAIN patronCategory AS varchar(10)
  CHECK (value in ('inactive', 'reader', 'doer', 'keener'));

CREATE TABLE q3 (
    patronID Char(20) NOT NULL,
    category patronCategory
);

DROP VIEW IF EXISTS libraries_used CASCADE;
DROP VIEW IF EXISTS sum_attended CASCADE;
DROP VIEW IF EXISTS sum_checked_out CASCADE;
DROP VIEW IF EXISTS share_library_attended CASCADE;
DROP VIEW IF EXISTS share_library_checked_out CASCADE;
DROP VIEW IF EXISTS attended CASCADE;
DROP VIEW IF EXISTS checked_out CASCADE;
DROP VIEW IF EXISTS result CASCADE;

CREATE VIEW libraries_used AS
(SELECT esu.patron AS patron, lr.library AS library, 'a' AS use
FROM EventSignUp esu JOIN LibraryEvent le ON esu.event = le.id
JOIN LibraryRoom lr ON le.room = lr.id)
UNION
(SELECT c.patron AS patron, lh.library AS library, 'c' AS use
FROM Checkout c JOIN LibraryHolding lh ON c.copy = lh.barcode);

CREATE VIEW sum_attended AS
SELECT lu.patron, COALESCE(COUNT(esu.event), 0) AS sum_per_patron
FROM EventSignUp esu RIGHT JOIN
  (SELECT DISTINCT patron FROM libraries_used) AS lu ON esu.patron = lu.patron
GROUP BY lu.patron;

CREATE VIEW sum_checked_out AS
SELECT lu.patron, COALESCE(COUNT(c.id), 0) AS sum_per_patron
FROM Checkout c RIGHT JOIN
  (SELECT DISTINCT patron FROM libraries_used) AS lu ON c.patron = lu.patron
GROUP BY lu.patron;

CREATE VIEW share_library_attended AS
SELECT DISTINCT t1.patron AS patron1, t2.patron AS patron2,
s1.sum_per_patron AS sum1, s2.sum_per_patron AS sum2
FROM libraries_used t1 CROSS JOIN libraries_used t2
JOIN sum_attended s1 ON t1.patron = s1.patron
JOIN sum_attended s2 ON t2.patron = s2.patron
WHERE t1.library = t2.library AND t2.use = 'a';

CREATE VIEW share_library_checked_out AS
SELECT DISTINCT t1.patron AS patron1, t2.patron AS patron2,
s1.sum_per_patron AS sum1, s2.sum_per_patron AS sum2
FROM libraries_used t1 CROSS JOIN libraries_used t2
JOIN sum_checked_out s1 ON t1.patron = s1.patron
JOIN sum_checked_out s2 ON t2.patron = s2.patron
WHERE t1.library = t2.library AND t2.use = 'c';

CREATE VIEW attended AS
(SELECT patron1 AS patron, 'low' AS c1
FROM share_library_attended
GROUP BY patron1
HAVING avg(sum1) < 0.25*avg(sum2))
UNION
(SELECT DISTINCT patron, 'low' AS c1
FROM libraries_used
WHERE patron NOT IN (SELECT patron1 FROM share_library_attended))
UNION
(SELECT patron1 AS patron, 'high' AS c1
FROM share_library_attended
GROUP BY patron1
HAVING avg(sum1) > 0.75*avg(sum2));

CREATE VIEW checked_out AS
(SELECT patron1 AS patron, 'low' AS c2
FROM share_library_checked_out
GROUP BY patron1
HAVING avg(sum1) < 0.25*avg(sum2))
UNION
(SELECT DISTINCT patron, 'low' AS c1
FROM libraries_used
WHERE patron NOT IN (SELECT patron1 FROM share_library_checked_out))
UNION
(SELECT patron1 AS patron, 'high' AS c2
FROM share_library_checked_out
GROUP BY patron1
HAVING avg(sum1) > 0.75*avg(sum2));

INSERT INTO q3
SELECT patron AS patronID,
CASE
  WHEN c1 = 'low' AND c2 = 'low' THEN 'inactive'
  WHEN c1 = 'low' AND c2 = 'high' THEN 'reader'
  WHEN c1 = 'high' AND c2 = 'low' THEN 'doer'
  WHEN c1 = 'high' AND c2 = 'high' THEN 'keener'
END AS category
FROM attended NATURAL JOIN checked_out;