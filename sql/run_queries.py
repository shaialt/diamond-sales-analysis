# ==========================================
# Run all business queries and export the results
# ==========================================
# Usage (from the repository root):
#   python sql/run_queries.py
#
# Each query in sql/queries.sql is printed and saved as a CSV file in
# sql/results/, which Tableau Public can use as a data source.

import re
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / 'sql' / 'diamonds.db'
QUERIES_PATH = ROOT / 'sql' / 'queries.sql'
RESULTS_DIR = ROOT / 'sql' / 'results'

RESULTS_DIR.mkdir(exist_ok=True)

text = QUERIES_PATH.read_text(encoding='utf-8')

# Split the file on the "-- Q<number> [name]: <question>" headers
blocks = re.split(r'^-- (Q\d+) \[(\w+)\]: (.+)$', text, flags=re.MULTILINE)[1:]
queries = [
    (blocks[i], blocks[i + 1], blocks[i + 2].strip(), blocks[i + 3])
    for i in range(0, len(blocks), 4)
]

pd.set_option('display.width', 200)
pd.set_option('display.max_columns', 20)

with sqlite3.connect(DB_PATH) as conn:
    for number, name, question, sql in queries:
        result = pd.read_sql_query(sql, conn)

        result.to_csv(RESULTS_DIR / f'{number.lower()}_{name}.csv', index=False)

        print('=' * 80)
        print(f'{number}: {question}')
        print('=' * 80)
        print(result.to_string(index=False))
        print()
