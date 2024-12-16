SELECT * FROM order_detail;
SELECT * FROM sku_detail;
SELECT * FROM customer_detail;
SELECT * FROM payment_detail;

--Check null value in table order_detail
SELECT
	COUNT(*) AS total_rows,
	SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS id_nulls,
	SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
	SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS order_date_nulls,
	SUM(CASE WHEN sku_id IS NULL THEN 1 ELSE 0 END) AS sku_id_nulls,
	SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS price_nulls,
	SUM(CASE WHEN qty_ordered IS NULL THEN 1 ELSE 0 END) AS qty_ordered_nulls,
	SUM(CASE WHEN before_discount IS NULL THEN 1 ELSE 0 END) AS before_discount_nulls,
	SUM(CASE WHEN after_discount IS NULL THEN 1 ELSE 0 END) AS after_discount_nulls,
	SUM(CASE WHEN is_gross IS NULL THEN 1 ELSE 0 END) AS is_gross_nulls,
	SUM(CASE WHEN is_valid IS NULL THEN 1 ELSE 0 END) AS is_valid_nulls,
	SUM(CASE WHEN is_net IS NULL THEN 1 ELSE 0 END) AS is_net_nulls,
	SUM(CASE WHEN payment_id IS NULL THEN 1 ELSE 0 END) AS payment_id_nulls
FROM order_detail;

--Check null value in table sku_detail
SELECT
	COUNT(*) AS total_rows,
	SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS id_nulls,
	SUM(CASE WHEN sku_name IS NULL THEN 1 ELSE 0 END) AS sku_name_nulls,
	SUM(CASE WHEN base_price IS NULL THEN 1 ELSE 0 END) AS base_price_nulls,
	SUM(CASE WHEN cogs IS NULL THEN 1 ELSE 0 END) AS cogs_nulls,
	SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS category_nulls
FROM sku_detail;

--Check null value in table customer_detail
SELECT
	COUNT(*) AS total_rows,
	SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS id_nulls,
	SUM(CASE WHEN registered_date IS NULL THEN 1 ELSE 0 END) AS registered_date_nulls
FROM customer_detail;

--Check null value in table payment_detail
SELECT
	COUNT(*) AS total_rows,
	SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS id_nulls,
	SUM(CASE WHEN payment_method IS NULL THEN 1 ELSE 0 END) AS payment_method_nulls
FROM payment_detail;

--Check duplicate data order_detail
SELECT
	id, customer_id, order_date, sku_id, price, qty_ordered, before_discount,
	after_discount, is_gross, is_valid, is_net, payment_id, COUNT(*)
FROM order_detail
GROUP BY 
	id, customer_id, order_date, sku_id, price, qty_ordered, before_discount,
	after_discount, is_gross, is_valid, is_net, payment_id
HAVING COUNT(*) > 1;

--Check duplicate data sku_detail
SELECT
	id, sku_name, base_price, cogs, category, COUNT(*)
FROM sku_detail
GROUP BY 
	id, sku_name, base_price, cogs, category
HAVING COUNT(*) > 1;

--Check duplicate data customer_detail
SELECT
	id, registered_date, COUNT(*)
FROM customer_detail
GROUP BY id, registered_date
HAVING COUNT(*) > 1;

--Check duplicate data payment_detail
SELECT 
	id, payment_method, COUNT(*)
FROM payment_detail
GROUP BY id, payment_method
HAVING COUNT(*) > 1;


--Number 1
SELECT
    TO_CHAR(order_date, 'Month') AS month_transaction,
    ROUND(SUM(after_discount)) AS total_transaction
FROM order_detail
WHERE EXTRACT(YEAR FROM order_date) = 2021 AND is_valid = 1
GROUP BY month_transaction
ORDER BY total_transaction DESC
LIMIT 5;

--Number 2
SELECT 
    sd.category AS category_product,
	ROUND(SUM(od.after_discount)) AS total_transaction
FROM 
    order_detail AS od
INNER JOIN 
    sku_detail AS sd ON od.sku_id = sd.id
WHERE 
    EXTRACT(YEAR FROM od.order_date) = 2022 AND is_valid = 1
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

--Number 3
WITH total_transaction AS (
    SELECT
        sd.category,
        EXTRACT(YEAR FROM od.order_date) AS year_transaction,
        SUM(od.after_discount) AS total_transaction
    FROM order_detail AS od
    JOIN sku_detail AS sd ON od.sku_id = sd.id
    WHERE od.is_valid = 1
    GROUP BY sd.category, year_transaction
)
SELECT
    tt2021.category AS category,
    ROUND(tt2021.total_transaction) AS total_2021,ROUND(tt2022.total_transaction) AS total_2022,
    CASE 
        WHEN tt2021.total_transaction = 0 THEN NULL  
        ELSE CONCAT(ROUND(CAST(((tt2022.total_transaction - tt2021.total_transaction)::numeric / tt2021.total_transaction) * 100 AS numeric), 2), '%')
    END AS difference_percentage,
    CASE
        WHEN tt2022.total_transaction > tt2021.total_transaction THEN 'Increase'
		WHEN tt2022.total_transaction < tt2021.total_transaction THEN 'Decrease'
        ELSE 'Stable'
    END AS information
FROM (SELECT category, total_transaction FROM total_transaction WHERE year_transaction = 2021) tt2021
FULL OUTER JOIN (SELECT category, total_transaction FROM total_transaction WHERE year_transaction = 2022) tt2022
ON tt2021.category = tt2022.category
ORDER BY category;

--Number 4
SELECT payment_method,
		COUNT(DISTINCT o.id) AS total_transaction
FROM order_detail o
INNER JOIN payment_detail pd ON o.payment_id = pd.id
WHERE EXTRACT(YEAR FROM order_date) = 2022 AND is_valid = 1
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

--Number 5
WITH top_product AS (
    SELECT
        CASE
            WHEN LOWER(sd.sku_name) LIKE '%samsung%' THEN 'samsung'
            WHEN LOWER(sd.sku_name) LIKE '%apple%' 
                OR LOWER(sd.sku_name) LIKE '%iphone%' 
                OR LOWER(sd.sku_name) LIKE '%mackbook%' THEN 'apple'
            WHEN LOWER(sd.sku_name) LIKE '%sony%' THEN 'sony'
            WHEN LOWER(sd.sku_name) LIKE '%huawei%' THEN 'huawei'
            WHEN LOWER(sd.sku_name) LIKE '%lenovo%' THEN 'lenovo'
        END AS name_product,
        ROUND(SUM(od.after_discount)) AS total_transaction_value
    FROM order_detail AS od
    INNER JOIN sku_detail AS sd ON od.sku_id = sd.id
    WHERE is_valid = 1
    GROUP BY 1
	ORDER BY 2 DESC
)
SELECT * 
FROM top_product
WHERE name_product IS NOT NULL;



	


