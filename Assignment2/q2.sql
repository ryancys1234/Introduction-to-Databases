SET SEARCH_PATH TO Library, public;
DROP TABLE IF EXISTS q2 cascade;

CREATE TABLE q2 (
    branch CHAR(5) NOT NULL,
    patron CHAR(20),
    title TEXT NOT NULL,
    overdue INT NOT NULL
);

DROP VIEW IF EXISTS php_patrons CASCADE;
DROP VIEW IF EXISTS overdue_category_1 CASCADE;
DROP VIEW IF EXISTS overdue_category_2 CASCADE;

-- All patrons with an overdue item from a branch in 'Parkdale-High Park'
CREATE VIEW php_patrons AS
SELECT lb.code AS branch, h.title, h.htype, c.patron, c.checkout_time
FROM Ward w JOIN LibraryBranch lb ON w.id = lb.ward
JOIN LibraryHolding lh ON lb.code = lh.library
JOIN Holding h ON lh.holding = h.id
JOIN Checkout c ON lh.barcode = c.copy
WHERE w.name = 'Parkdale-High Park' AND c.id NOT IN
    (SELECT checkout FROM Return);

-- Category 1 overdue
CREATE VIEW overdue_category_1 AS
SELECT branch, patron, title,
(date(NOW()) - date(checkout_time) - 21) AS overdue
FROM php_patrons
WHERE (htype = 'books' OR htype = 'audiobooks')
AND date(NOW()) > date(checkout_time) + 21;

-- Category 2 overdue
CREATE VIEW overdue_category_2 AS
SELECT branch, patron, title,
(date(NOW()) - date(checkout_time) - 7) AS overdue
FROM php_patrons
WHERE (htype = 'music' OR htype = 'movies'
OR htype = 'magazines and newspapers')
AND date(NOW()) > date(checkout_time) + 7;

INSERT INTO q2
SELECT branch, patron, title, overdue
FROM ((SELECT * FROM overdue_category_1)
UNION (SELECT * FROM overdue_category_2)) AS u;