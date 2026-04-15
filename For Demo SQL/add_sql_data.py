import sqlite3
from pathlib import Path

DB_FILE = "CA_db.db"
DATA_SQL = "Test data.sql"


def clean_mysql_sql(sql: str) -> str:
    lines = []
    for line in sql.splitlines():
        stripped = line.strip().lower()
        if stripped.startswith("create database"):
            continue
        if stripped.startswith("use "):
            continue
        lines.append(line)
    sql = "\n".join(lines)
    sql = sql.replace("`CA_db`.", "")
    sql = sql.replace("CA_db.", "")

    sql = sql.replace("`", "")
    return sql


def run_sql_file(cursor, filepath: str):
    sql = Path(filepath).read_text(encoding="utf-8")
    sql = clean_mysql_sql(sql)
    cursor.executescript(sql)


def main():
    conn = sqlite3.connect(DB_FILE)
    conn.execute("PRAGMA foreign_keys = ON;")

    try:
        cur = conn.cursor()
        run_sql_file(cur, DATA_SQL)
        conn.commit()
        print(f"Done. SQLite database created: {DB_FILE}")

        for table in ["ca_roles", "ca_users", "ca_customers", "ca_products", "ca_stock"]:
            count = cur.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            print(f"{table}: {count} rows")

    except Exception as e:
        conn.rollback()
        print("Error while building database:")
        print(e)
    finally:
        conn.close()


if __name__ == "__main__":
    main()