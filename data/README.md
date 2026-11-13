# Data

## Source

**Tableau "Sample - Superstore"**, a fictional US retailer's orders, provided by Tableau as free sample data
for learning ([Tableau Public sample data](https://public.tableau.com/app/learn/sample-data)).
The data is **fictional**: it does not describe a real company or real customers.

The copy used here was downloaded on 2026-11-13 from the public GitHub repository
`leonism/sample-superstore` (file `data/superstore.csv`). It appears to be an export of the Superstore workbook:
the Orders, People and Returns sheets stacked into one CSV (10,800 rows).

- SHA-256 of the raw file: `af443ca30d732c886f7a1d603f9492f98e9a88c268d47cbc146fe758b1f5d65d`
- Order dates in this copy run from 2015-01-03 to 2018-12-30 (9,994 order lines, 5,009 orders, 793 customers).
  Other copies of Superstore circulate with different date ranges, so numbers in this project may not match
  a copy from another source. I did not compare against other copies.

## License

I could not find a formal open license for this dataset. It is distributed by Tableau as sample data for learning,
and many repositories use it for educational purposes. This project uses it only for education and
portfolio purposes. If you reuse it commercially, check Tableau's terms first.

## Files

| Path | What it is | In Git? |
|---|---|---|
| `raw/superstore_raw.csv` | The file exactly as downloaded | No (see `.gitignore`) |
| `processed/orders_clean.csv` | Cleaned orders, one row per order line (9,994 rows), used by Excel and Power BI | Yes |
| `superstore.db` | SQLite database built from the clean data | No (rebuilt by notebook 01) |

To reproduce the project: download the CSV, save it as `data/raw/superstore_raw.csv`, then run
the notebooks in order.
