DROP TABLE IF EXISTS Order_Refunds;
DROP TABLE IF EXISTS Ordered_Items;
DROP TABLE IF EXISTS Products;
drop table if exists Orders;
DROP TABLE IF EXISTS Web_Pageviews;
DROP TABLE IF EXISTS Web_Sessions;

CREATE TABLE Web_Sessions (
Session_ID SERIAL PRIMARY KEY,
Session_Date DATE,
Session_Time TIME,
User_ID INT,
Revisited_Web BOOLEAN,
UTM_Source TEXT,
Campaign_Name TEXT,
Content_Parameters TEXT,
Device_Used TEXT,
URL_Used TEXT
);



CREATE TABLE Web_Pageviews (
Pageview_ID SERIAL PRIMARY KEY,
Pageview_Date DATE,
Pageview_Time TIME,
Session_ID INT REFERENCES Web_Sessions(Session_ID),
Pageview_URL TEXT
);


create table Orders (
Order_ID SERIAL PRIMARY KEY,
Order_Date DATE,
Order_Time TIME,
Session_ID INT REFERENCES Web_Sessions(Session_ID),
User_ID INT,
Primary_Product_ID INT,
Quantity_purchased INT,
Total_Amt NUMERIC(10,2),
Total_COGS NUMERIC(10,2)
);


CREATE TABLE Products (
Product_ID SERIAL PRIMARY KEY,
Launch_Date DATE,
Launch_Time TIME,
Product_Name TEXT
);


CREATE TABLE Ordered_Items (
Order_item_ID SERIAL PRIMARY KEY,
Order_Date DATE,
Order_Time TIME,
Order_ID INT REFERENCES Orders(Order_ID),
Product_ID INT REFERENCES Products(Product_ID),
Primary_Item BOOLEAN,
Price NUMERIC(10,2),
COGS NUMERIC(10,2)
);


CREATE TABLE Order_Refunds (
Refund_ID SERIAL PRIMARY KEY,
Refund_Date DATE,
Refund_Time TIME,
Order_item_ID INT REFERENCES Ordered_Items(Order_item_ID),
Order_ID INT REFERENCES Orders(Order_ID),
Amt_Refunded NUMERIC(10,2)
);

--Checking tables 
SELECT * FROM products;
SELECT * FROM ordered_items;
SELECT * FROM web_sessions;
SELECT * FROM orders;



-- Executive KPI summary

WITH monthly_data AS(
SELECT 
	EXTRACT(YEAR FROM orders.order_date) AS year,
	EXTRACT (MONTH FROM orders.order_date) AS month_num,
	TO_CHAR (orders.order_date, 'Mon') AS month,
--calculating the KPI's
	SUM(orders.total_amt)- SUM (COALESCE (order_refunds.amt_refunded,0)) AS net_revenue,
	COUNT (DISTINCT orders.order_id) AS total_orders ,
	ROUND((SUM(orders.total_amt)-SUM(COALESCE (order_refunds.amt_refunded,0)))/COUNT(DISTINCT orders.order_id),2) AS aov,
	SUM(orders.total_amt)- SUM (COALESCE (order_refunds.amt_refunded,0))- SUM(orders.total_cogs) AS net_GP	
FROM orders 
	LEFT JOIN order_refunds
	ON orders.order_id = order_refunds.order_id
GROUP BY year, month_num, month
ORDER BY year, month_num ),

comparison AS(
SELECT  *,
--calculating previous values
	LAG(net_revenue) OVER (ORDER BY year, month_num) AS previous_revenue,
	LAG(total_orders) OVER (ORDER BY year, month_num) AS previous_order,
	LAG(aov) OVER (ORDER BY year, month_num) AS previous_aov,
	LAG(net_GP) OVER (ORDER BY year, month_num) AS previous_GP,
--calculating the change in KPI's
	net_revenue - LAG(net_revenue) OVER (ORDER BY year, month_num) AS net_revenue_change,
	total_orders - LAG(total_orders) OVER (ORDER BY year, month_num) AS  order_change ,
	aov - LAG(aov) OVER (ORDER BY year, month_num) AS aov_change,
	net_GP - LAG(net_GP) OVER (ORDER BY year, month_num) AS net_GP_change
FROM monthly_data
ORDER BY year, month_num ) 

SELECT 
	year, month, net_revenue, total_orders, aov, net_GP,
--calculating percentage of growth
	ROUND(100.0 * (net_revenue_change/NULLIF(previous_revenue,0)),2) AS net_revenue_pnt,
	ROUND(100.0 * (order_change ::NUMERIC / NULLIF(previous_order,0)) ,2)AS order_pnt,
	ROUND(100.0 * (aov_change/ NULLIF(previous_aov,0)),2) AS aov_pnt,
	ROUND(100.0 * (net_GP_change/NULLIF(previous_GP,0)),2) AS gp_pnt
FROM comparison
ORDER BY year, month;
-------------------------------------------------------------------------------------------------------------------------------------------

--Stratigic Growth - Channel perfromance

WITH refund_summary AS (
SELECT 
	order_id, 
	SUM(amt_refunded) AS amt_refunded
FROM order_refunds
GROUP BY order_id )

SELECT 
  	EXTRACT(YEAR FROM ws.session_date) AS year,
   	TO_CHAR (ws.session_date, 'Mon') AS month,
  	ws.utm_source AS channel,
--calculating session conversion rate
  	COUNT(DISTINCT ws.session_id) AS total_sessions,
    	COUNT(DISTINCT o.order_id) AS total_orders,
   	ROUND(COUNT(DISTINCT o.order_id) * 100.0 / NULLIF(COUNT(DISTINCT ws.session_id), 0), 2) AS conversion_rate,
--calculating net revenue
   	SUM(o.total_amt - COALESCE(r.amt_refunded, 0)) AS net_revenue
FROM web_sessions ws
	LEFT JOIN orders o ON ws.session_id = o.session_id
	LEFT JOIN refund_summary r ON o.order_id = r.order_id
GROUP BY 1,2,3;
------------------------------------------------------------------------------------------------------------------------------------------------------

--Product Performance

WITH refund_summary AS (
SELECT
        	order_item_id,
       	SUM(amt_refunded) AS amt_refunded
FROM order_refunds
GROUP BY order_item_id
)
SELECT
    	EXTRACT(YEAR FROM oi.order_date)::INT AS year,
    	TO_CHAR(oi.order_date, 'Mon') AS month,
    	p.product_name AS name,
    	MIN(MIN(oi.order_date)::DATE) OVER (PARTITION BY oi.product_id) AS launch_date,

   	SUM(oi.price - COALESCE(r.amt_refunded, 0)) AS net_revenue,

    	SUM(oi.price - oi.cogs) AS Gross_profit,

    	ROUND ( 100.0 * SUM(COALESCE(r.amt_refunded, 0)) / NULLIF(SUM(oi.price), 0), 2 ) AS refund_amt_pct,

   	COUNT(oi.order_item_id) AS quantity,

    	ROUND (
		SUM(COUNT(oi.order_item_id)) OVER (PARTITION BY oi.product_id)::NUMERIC 
		 / GREATEST( ('2015-03-19'::DATE - MIN(MIN(oi.order_date)::DATE) OVER (PARTITION BY oi.product_id)) + 1, 1 ) , 2
		 ) AS overall_sales_rate

FROM ordered_items oi
	LEFT JOIN products p ON oi.product_id = p.product_id
	LEFT JOIN refund_summary r ON oi.order_item_id = r.order_item_id

GROUP BY
    	EXTRACT(YEAR FROM oi.order_date)::INT,
    	EXTRACT(MONTH FROM oi.order_date)::INT,
    	TO_CHAR(oi.order_date, 'Mon'),
    	oi.product_id,
    	p.product_name

ORDER BY
   	 year,
   	 EXTRACT(MONTH FROM oi.order_date)::INT,
   	 name;

---------------------------------------------------------------------------------------------------------------------------------------------------------

--Refund & Return breakdown

WITH refund_summary AS (
SELECT
	order_item_id,
	SUM(amt_refunded) AS amt_refunded
FROM order_refunds
GROUP BY order_item_id )

SELECT
	EXTRACT(YEAR FROM oi.order_date) AS year,
	TO_CHAR(oi.order_date, 'Mon') AS month,
	p.product_name AS name,
--calculating net revenue
	SUM(oi.price) AS gross_rev,
	SUM(oi.price - COALESCE(r.amt_refunded, 0)) AS net_rev

FROM ordered_items oi
	LEFT JOIN refund_summary r ON oi.order_item_id = r.order_item_id
	LEFT JOIN products p ON oi.product_id = p.product_id
GROUP BY 1, 2, 3
ORDER BY 1, 2;
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--New vs Returning Customers

WITH first_orders AS (
SELECT 
	user_id, 
	MIN(order_id) AS first_order_id
FROM orders
GROUP BY user_id ),

refund_summary AS (
SELECT 
	order_id, 
	SUM(amt_refunded) AS amt_refunded
FROM order_refunds
GROUP BY order_id )

SELECT 
	EXTRACT(YEAR FROM ws.session_date) AS year,
	TO_CHAR(ws.session_date, 'Mon') AS month,
	ws.utm_source AS channel,
-- Customer Counts
	COUNT(DISTINCT CASE WHEN o.order_id = fo.first_order_id THEN o.user_id END) AS new_customers,
	COUNT(DISTINCT CASE WHEN o.order_id > fo.first_order_id THEN o.user_id END) AS returning_customers,
-- Net Revenue Breakdown
	SUM(CASE 
        		WHEN o.order_id = fo.first_order_id 
        		THEN (o.total_amt - COALESCE(r.amt_refunded, 0)) 
        		ELSE 0 
    		END) AS new_cust_net_rev,
   	 SUM(CASE 
       	 	WHEN o.order_id > fo.first_order_id 
        		THEN (o.total_amt - COALESCE(r.amt_refunded, 0)) 
       	 	ELSE 0 
    		END) AS returning_cust_net_rev

FROM web_sessions ws
	LEFT JOIN orders o ON ws.session_id = o.session_id
	LEFT JOIN first_orders fo ON o.user_id = fo.user_id
	LEFT JOIN refund_summary r ON o.order_id = r.order_id
GROUP BY 1,2,3 ;