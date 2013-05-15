import psycopg2
import sys

# Drop all tables from a given database

def drop_tables():
    try:
        conn = psycopg2.connect("dbname='postgres' user='postgres' password=''")
        conn.set_isolation_level(0)
    except:
        print "Unable to connect to the database."

    cur = conn.cursor()

    try:
        cur.execute("SELECT table_schema,table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_schema,table_name")
        rows = cur.fetchall()
        for row in rows:
            print "dropping table: ", row[1]
            cur.execute("drop table " + row[1] + " cascade")
        cur.close()
        conn.close()
    except:
        print "Error: ", sys.exc_info()[1]

if __name__ == "__main__":
    drop_tables()