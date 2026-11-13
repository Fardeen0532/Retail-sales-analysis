# Power BI Dashboard: Build Guide

Power BI Desktop files (`.pbix`) can only be created inside Power BI Desktop, so this guide gives you the
exact data model, measures, layout and numbers to check against. Building it yourself takes about 45 minutes,
and you will be able to explain every visual because you made it.

Power BI Desktop is free (Windows only): install it from the Microsoft Store.

## 1. Load the data

1. **Home > Get data > Text/CSV** and choose `data/processed/orders_clean.csv`. Click **Transform Data**.
2. Check the column types in Power Query:

| Column | Type |
|---|---|
| Order Date, Ship Date, Order Month | Date |
| Row ID, Quantity, Year, Ship Days | Whole number |
| Sales, Discount, Profit, Profit Margin | Decimal number |
| Postal Code | **Text** (so 05401 keeps its leading zero) |
| everything else | Text |

3. Rename the query from `orders_clean` to `orders`, then **Close & Apply**.

No relationships are needed: it is one flat table, which keeps the model easy to explain.

## 2. Create the measures

Select the `orders` table, then **Modeling > New measure** for each of these.

```DAX
Total Revenue = SUM(orders[Sales])

Total Profit = SUM(orders[Profit])

Total Orders = DISTINCTCOUNT(orders[Order ID])

Average Order Value = DIVIDE([Total Revenue], [Total Orders])

Profit Margin % = DIVIDE([Total Profit], [Total Revenue])

Returned Orders = CALCULATE(DISTINCTCOUNT(orders[Order ID]), orders[Returned] = "Yes")

Return Rate % = DIVIDE([Returned Orders], [Total Orders])
```

**Why measures and not columns?** A measure is calculated at the moment you use it, inside whatever filters are
active (year, region, a clicked bar). That is why `Profit Margin %` is correct for every bar and every card
without extra work. `DIVIDE` returns blank instead of an error when the denominator is zero.

**Why `DISTINCTCOUNT` for orders?** One order has several lines. Counting rows would overstate the number of
orders (9,994 lines but only 5,009 orders).

For the discount page, add one **calculated column** (Modeling > New column), because a band is a property of
each row:

```DAX
Discount Band =
SWITCH(
    TRUE(),
    orders[Discount] = 0, "1) No discount",
    orders[Discount] <= 0.2, "2) Up to 20%",
    orders[Discount] <= 0.4, "3) 21-40%",
    "4) Over 40%"
)
```

## 3. Page 1: Business Overview

Layout (landscape, 16:9):

| Row | Visuals |
|---|---|
| Top left | Title text box: "Retail Sales & Business Performance" |
| Top right | Slicers: **Year** (tile/buttons) and **Region** (dropdown) |
| Row 1 | 5 **Card** visuals: Total Revenue, Total Profit, Total Orders, Average Order Value, Profit Margin % |
| Row 2 left (wide) | **Line chart**: X = `Order Month`, Y = Total Revenue (title: "Monthly sales trend") |
| Row 2 right | **Clustered bar chart**: Y = Category, X = Total Revenue (title: "Sales by category") |
| Row 3 left | **Clustered column chart**: X = Region, Y = Total Revenue and Profit Margin % shown in data labels (title: "Regional performance") |
| Row 3 right | **Bar chart**: Y = Product Name, X = Total Revenue, with a **Top N** filter (title: "Top 10 products by revenue") |

How to do the Top 10 filter: select the bar chart, open the **Filters** pane, drag `Product Name` into
"Filters on this visual", choose **Filter type: Top N**, show **Top 10** items **By value** `Total Revenue`,
then click **Apply filter**.

Formatting rules for a professional look:
- One accent colour (blue) for profit and revenue, orange for losses. No rainbow palettes.
- No pie charts. Turn off gridlines, keep titles short and say what the chart shows.
- Format cards: revenue/profit as `$#,##0`, margin as `0.0%`.
- Align the visuals to a grid (View > Show gridlines / Snap to grid).

## 4. Page 2: Profit Leaks (the page that shows insight)

| Visual | Setup |
|---|---|
| Column chart "Profit margin by discount band" | X = `Discount Band`, Y = `Profit Margin %`. Format > Columns > Colours > fx > rules: below 0 orange, otherwise blue |
| Bar chart "Profit by sub-category" | Y = Sub-Category, X = Total Profit, sorted ascending, same orange/blue rule |
| Table "States that lose money" | Columns: State, Total Revenue, Total Profit. Sort by profit ascending (or Top N, bottom 10 by Total Profit) |
| Column chart "Return rate by region" | X = Region, Y = `Return Rate %` |

## 5. Check your numbers (the dashboard must match the analysis)

With no slicer selected:

| Card | Expected |
|---|---|
| Total Revenue | 2,297,201 |
| Total Profit | 286,397 |
| Total Orders | 5,009 |
| Average Order Value | 458.61 |
| Profit Margin % | 12.5% |

With a filter:

| Filter | Check |
|---|---|
| Year = 2018 | Revenue 733,215 and Profit 93,439 |
| Region = West | Revenue 725,458, Profit Margin 14.9%, Return Rate 11.7% |
| Region = Central | Profit Margin 7.9% |
| Discount Band = Over 40% | Profit Margin -77.4% |

If a number differs, the type of a column is usually wrong (for example Sales loaded as text).

## 6. Save and publish to GitHub

1. Save as `dashboard/Superstore_Dashboard.pbix`.
2. Take a screenshot of each page and save them as `dashboard/powerbi_page1.png` and
   `dashboard/powerbi_page2.png`.
3. Add them to the README under "Power BI dashboard":
   `![Overview](dashboard/powerbi_page1.png)`

## 7. Questions you should be ready to answer

- *Why is Average Order Value divided by distinct orders?* Because one order has several lines.
- *What is the difference between a measure and a calculated column?* A column is stored per row when the
  data loads. A measure is calculated on demand for the current filter context.
- *Why one table and no star schema?* The dataset is a single flat table. For a bigger model I would separate
  Customers, Products and a Date table, but here extra tables would add complexity without any benefit.
- *What decision does this dashboard support?* Page 1 shows where sales come from, Page 2 shows where money
  is lost (discounts above 20%, specific states and sub-categories, and the West's return rate).
