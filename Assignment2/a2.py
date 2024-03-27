import psycopg2 as pg, psycopg2.extensions as pg_ext, psycopg2.extras as pg_extras, subprocess
from typing import Optional, List

class Library:
    connection: Optional[pg_ext.connection]

    def __init__(self):
        self.connection = None

    def connect(self, dbname: str, username: str, password: str) -> bool:
        try:
            self.connection = pg.connect(
                dbname=dbname, user=username, password=password,
                options="-c search_path=Library,public"
            )
            return True
        except pg.Error:
            return False

    def disconnect(self) -> bool:
        try:
            if self.connection and not self.connection.closed:
                self.connection.close()
            return True
        except pg.Error:
            return False

    def search(self, last_name: str, branch: str) -> List[str]:
        lst = []
        try:
            cur = self.connection.cursor()
            query = """
                SELECT sq.title
                FROM (
                    SELECT DISTINCT h.id, h.title FROM
                    Holding h JOIN LibraryCatalogue lc ON h.id = lc.holding
                    JOIN HoldingContributor hc ON h.id = hc.holding
                    JOIN Contributor c ON hc.contributor = c.id
                    WHERE lc.library = %s
                    AND c.last_name = %s
                    ) AS sq;
            """
            cur.execute(query, [branch, last_name])
            for title in cur: lst.append(title[0])
        except pg.Error as ex: print(ex)
        finally:
            cur.close()
            return lst

    def register(self, card_number: str, event_id: int) -> bool:
        try:
            cur = self.connection.cursor()
            lst1, lst2, lst3, lst4, lst5 = [], [], [], [], []

            query = "SELECT card_number FROM Patron WHERE card_number = %s;"
            cur.execute(query, [card_number])
            for tuple in cur: lst1.append(tuple)
            if len(lst1) < 1: return False

            query = "SELECT id FROM LibraryEvent WHERE id = %s;"
            cur.execute(query, [event_id])
            for tuple in cur: lst2.append(tuple)
            if len(lst2) < 1: return False

            query = """SELECT * FROM EventSignUp
                    WHERE patron = %s AND event = %s;"""
            cur.execute(query, [card_number, event_id])
            for tuple in cur: lst3.append(tuple)
            if len(lst3) > 0: return False

            query = "SELECT * FROM EventSchedule WHERE event = %s;"
            cur.execute(query, [event_id])
            for tuple in cur: lst4.append(tuple)

            query = """SELECT * FROM EventSignUp NATURAL JOIN EventSchedule
                    WHERE patron = %s;"""
            cur.execute(query, [card_number])
            for tuple in cur: lst5.append(tuple)
            for i in lst4:
                for j in lst5: # If same day and time is overlapping
                    if i[1] == j[2] and i[2] < j[4] and j[3] < i[3]: return False
            
            query = "INSERT INTO EventSignUp VALUES (%s, %s);"
            cur.execute(query, [card_number, event_id])
            self.connection.commit()

            cur.close()
            return True
        except pg.Error as ex:
            print(ex)

            cur.close()
            return False

    def return_item(self, checkout: int) -> float:
        try:
            cur = self.connection.cursor()
            lst1, lst2, lst3 = [], [], []

            query = "SELECT * FROM Checkout WHERE id = %s;"
            cur.execute(query, [checkout])
            for tuple in cur: lst1.append(tuple)
            if len(lst1) < 1: return -1.0

            query = "SELECT * FROM Return WHERE checkout = %s;"
            cur.execute(query, [checkout])
            for tuple in cur: lst2.append(tuple)
            if len(lst2) > 0: return -1.0

            query = "INSERT INTO Return VALUES (%s, NOW());"
            cur.execute(query, [checkout])
            self.connection.commit()

            # Calculating the fine
            query = """
                SELECT (DATE(NOW()) - DATE(c.checkout_time)) AS difference,
                h.htype
                FROM Checkout c JOIN LibraryHolding lh ON c.copy = lh.barcode
                JOIN Holding h ON lh.holding = h.id
                WHERE c.id = %s;
            """
            cur.execute(query, [checkout])
            for tuple in cur:
                diff = tuple[0]
                if tuple[1] == 'books' or tuple[1] == 'audiobooks':
                    cur.close()
                    return max((diff - 21)*0.50, 0)
                else:
                    cur.close()
                    return max((diff - 7)*1.00, 0)
        except pg.Error as ex:
            print(ex)

            cur.close()
            return -1.0
