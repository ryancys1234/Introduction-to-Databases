DROP VIEW IF EXISTS downsview_unreturned_books CASCADE;
DROP VIEW IF EXISTS downsview_overdue_books CASCADE;
DROP VIEW IF EXISTS criteria_1 CASCADE;
DROP VIEW IF EXISTS criteria_2 CASCADE;

CREATE VIEW downsview_unreturned_books AS
SELECT c.id AS checkout_id, c.patron, c.checkout_time
FROM Checkout c JOIN LibraryHolding lh ON c.copy = lh.barcode
JOIN Holding h ON lh.holding = h.id
JOIN LibraryBranch lb ON lh.library = lb.code
WHERE h.htype = 'books' AND lb.name = 'Downsview'
AND c.id NOT IN
    (SELECT checkout FROM Return);

CREATE VIEW downsview_overdue_books AS
SELECT *
FROM downsview_unreturned_books
WHERE date(NOW()) > date(checkout_time) + 21;

CREATE VIEW criteria_1 AS
SELECT patron
FROM downsview_unreturned_books
GROUP BY patron
HAVING count(*) <= 5;

CREATE VIEW criteria_2 AS
SELECT patron
FROM downsview_overdue_books
GROUP BY patron
HAVING max(date(NOW()) - date(checkout_time) - 21) <= 7;

UPDATE Checkout
SET checkout_time = checkout_time + INTERVAL '14 DAYS'
WHERE patron IN
    ((SELECT patron FROM criteria_1) INTERSECT (SELECT patron FROM criteria_2));