/* ASSIGNMENT 2 */
--Please write responses between the QUERY # and END QUERY blocks
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */
--QUERY 1
SELECT product_name || ', ' || coalesce(product_size, '') || ' (' || coalesce(product_qty_type, 'unit') || ')' AS list_of_products
FROM product; 


--END QUERY


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
Filter the visits to dates before April 29, 2022. */
--QUERY 2
SELECT DISTINCT market_date, customer_id
,DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date ASC) AS visit_num
FROM customer_purchases
WHERE market_date < '2022-04-29';




--END QUERY


/* 2. Reverse the numbering of the query so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit.
HINT: Do not use the previous visit dates filter. */
--QUERY 3

SELECT *
FROM
		(
		SELECT DISTINCT market_date, customer_id
		,DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS visit_num
		FROM customer_purchases
		) x
WHERE x.visit_num = 1;


--END QUERY


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. 

You can make this a running count by including an ORDER BY within the PARTITION BY if desired.
Filter the visits to dates before April 29, 2022. */
--QUERY 4
SELECT * 
,COUNT() OVER (PARTITION BY customer_id, product_id ORDER BY market_date, transaction_time ASC) AS times_purchased 
FROM customer_purchases
WHERE market_date < '2022-04-29'; 
--the reason I included transaction_time in ORDER BY is because there are ties (where the same customer purchases the same product multiple times on the same market date), and COUNT does not resolve these ties well
--ie for three purchases on the same day of the same product, COUNT would increment by 3 and apply that value to all 3 purchases (e.g. 1, 2, 3, 6, 6, 6). 
--instead of including transaction_time, an alternative would be simply to use ROW_NUMBER instead of COUNT


--END QUERY


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--QUERY 5
SELECT * 
,CASE 
		WHEN INSTR(product_name, '-') != 0 THEN LTRIM(SUBSTR(product_name, INSTR(product_name, '-')+1)) 
		ELSE NULL 
END AS 'description'
FROM product;

--INSTR returns 0 when no match is found, which when wrapped by SUBSTR will just return the entire product_name. Therefore a case statement is necessary to force those products to adopt a NULL value.


--END QUERY


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
--QUERY 6
SELECT product_size 
FROM product
WHERE product_size REGEXP '[0-9]';



--END QUERY


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--QUERY 7

DROP TABLE IF EXISTS temp.total_spend_by_date; 
CREATE TABLE temp.total_spend_by_date AS 

SELECT market_date, SUM(quantity * cost_to_customer_per_qty) as total_spend 
FROM customer_purchases
GROUP BY market_date;

DROP TABLE IF EXISTS temp.total_spend_by_date_ranked; 
CREATE TABLE temp.total_spend_by_date_ranked AS 
SELECT market_date, total_spend 
,DENSE_RANK() OVER(ORDER BY total_spend ASC) as worst_day
,DENSE_RANK() OVER(ORDER BY total_spend DESC) as best_day
FROM temp.total_spend_by_date; 

SELECT market_date, total_spend 
FROM temp.total_spend_by_date_ranked
WHERE worst_day == 1 

UNION 

SELECT market_date, total_spend
FROM temp.total_spend_by_date_ranked
WHERE best_day == 1;



--END QUERY



/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
--QUERY 8

DROP TABLE IF EXISTS temp.vendor_inventory_x5;
CREATE TABLE temp.vendor_inventory_x5 AS 
SELECT vendor_id, product_id, 5*original_price as price_per_customer
FROM vendor_inventory
GROUP BY vendor_id, product_id; 

DROP TABLE IF EXISTS temp.vendor_sales_x5; 
CREATE TABLE temp.vendor_sales_x5 AS 
SELECT vendor_id, product_id, price_per_customer, customer_id 
FROM temp.vendor_inventory_x5 
CROSS JOIN customer; 
--vendor_inventory_x5 = 8 rows, customer = 26 rows, cross join product = 208 rows √

SELECT vendor_name, product_name, SUM(price_per_customer) as total_earnings_by_product
FROM temp.vendor_sales_x5 as vs
INNER JOIN vendor as v 
		ON vs.vendor_id = v.vendor_id
INNER JOIN product as p 
		ON vs.product_id = p.product_id
GROUP BY vs.vendor_id, vs.product_id; 


--END QUERY


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
--QUERY 9
DROP TABLE IF EXISTS temp.product_units; 
CREATE TABLE temp.product_units AS 
SELECT *, CURRENT_TIMESTAMP as snapshot_timestamp
FROM product
WHERE product_qty_type == 'unit'; 



--END QUERY


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
--QUERY 10
INSERT INTO temp.product_units 
VALUES(8,'Cherry Pie','10"',3,'unit',CURRENT_TIMESTAMP);

SELECT * FROM temp.product_units;


--END QUERY


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
--QUERY 11
DELETE FROM temp.product_units 
WHERE product_id == 8 AND snapshot_timestamp == '2026-04-07 09:38:50';

SELECT * FROM temp.product_units;


--END QUERY


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */
--QUERY 12

--add a new column current_quantity to product_units 
ALTER TABLE temp.product_units 
ADD current_quantity INT; 


--get the most recent quantity per product for each vendor 
DROP TABLE IF EXISTS temp.last_inventory;
CREATE TABLE temp.last_inventory AS 

SELECT x.market_date, x.quantity, x.product_id
FROM 
(
		SELECT *
		,ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY market_date DESC) as date_rank --temp.product_units is not grouped by vendor_id, otherwise I would partition by vendor_id, product_id instead
		FROM vendor_inventory
) x
WHERE x.date_rank = 1;

--create rows for products in product_units but missing from vendor_inventory, and set their quantity to 0 
--note products in vendor_inventory but missing from product_units are excluded; these are products with product_qty_type ≠ 'unit'
DROP TABLE IF EXISTS temp.last_inventory_zeroed;

CREATE TABLE temp.last_inventory_zeroed AS
SELECT pu.product_id, li.market_date, IFNULL(li.quantity, 0) as quantity
FROM temp.product_units as pu
LEFT JOIN temp.last_inventory as li
		ON pu.product_id = li.product_id; 

--set current_quantity in product_units using last_inventory
UPDATE temp.product_units
SET current_quantity = temp.last_inventory_zeroed.quantity 
FROM temp.last_inventory_zeroed
WHERE temp.product_units.product_id = temp.last_inventory_zeroed.product_id; 



--END QUERY



