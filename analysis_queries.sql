# How many orders has each customer completed
CREATE TEMPORARY TABLE orders_per_customer AS
SELECT
  Customers.customer_unique_id,
  COUNT(*) AS number_of_orders
FROM
  `target-ecommerce.target_ecommerce_data.Orders` AS Orders JOIN `target-ecommerce.target_ecommerce_data.Customers` AS Customers
  ON Orders.customer_id = Customers.customer_id
GROUP BY
  Customers.customer_unique_id;


# Number of customers per number of orders
SELECT
  number_of_orders,
  COUNT(*) AS number_of_customers
FROM
  orders_per_customer
GROUP BY
  number_of_orders
ORDER BY
  number_of_customers DESC;


# Number of order by month
SELECT
  FORMAT_TIMESTAMP('%m-%Y', order_purchase_timestamp) AS month,
  COUNT(*) AS number_of_orders
FROM
  `target-ecommerce.target_ecommerce_data.Orders`
GROUP BY
  month
ORDER BY
  RIGHT(month, 4), LEFT(month, 2);


# Compare average delivery time between one time customers and returning cutsomers
SELECT
  IF(number_of_orders > 1, 1, 0) AS returning_customer,
  AVG(average_delivery_time) AS average_delivery_time
FROM
  (
  SELECT
    Customers.customer_unique_id,
    COUNT(*) AS number_of_orders,
    AVG(TIMESTAMP_DIFF(Orders.order_estimated_delivery_date, Orders.order_purchase_timestamp, DAY)) AS average_delivery_time
  FROM
    `target-ecommerce.target_ecommerce_data.Orders` AS Orders JOIN `target-ecommerce.target_ecommerce_data.Customers` AS Customers
    ON Orders.customer_id = Customers.customer_id
  GROUP BY
    Customers.customer_unique_id
  ) AS orders_per_customer
GROUP BY
  returning_customer;


# Average deliery time by city
SELECT
  Customers.customer_city AS city,
  AVG(TIMESTAMP_DIFF(Orders.order_estimated_delivery_date, Orders.order_purchase_timestamp, DAY)) AS average_delivery_time
FROM
  `target-ecommerce.target_ecommerce_data.Customers` AS Customers JOIN `target-ecommerce.target_ecommerce_data.Orders` AS Orders
    ON Customers.customer_id = Orders.customer_id
WHERE Customers.customer_city IN (
  # Only look at the cities with the top 25 revenues
  SELECT
    Customers.customer_city AS city,
  FROM
    (`target-ecommerce.target_ecommerce_data.Orders` AS Orders JOIN `target-ecommerce.target_ecommerce_data.Customers` AS Customers 
      ON Orders.customer_id = Customers.customer_id) JOIN `target-ecommerce.target_ecommerce_data.Payments` AS Payments
      ON Orders.order_id = Payments.order_id
  GROUP BY
    city
  HAVING
    SUM(Payments.payment_value) > 71000
  LIMIT (25)
)
GROUP BY
  city
ORDER  BY
  average_delivery_time;

# Number of orders by city
CREATE TEMPORARY TABLE Orders_per_city AS
SELECT
  Customers.customer_city AS city,
  COUNT(*) AS number_of_orders
FROM
  `target-ecommerce.target_ecommerce_data.Orders` AS Orders JOIN `target-ecommerce.target_ecommerce_data.Customers` AS Customers
    ON Orders.customer_id = Customers.customer_id
GROUP BY
  Customers.customer_city
ORDER BY
  number_of_orders DESC;

# Number of sellers by city
CREATE TEMPORARY TABLE Sellers_per_city AS
SELECT
  Sellers.seller_city AS city,
  COUNT(*) AS number_of_sellers
FROM
  `target-ecommerce.target_ecommerce_data.Sellers` AS Sellers
GROUP BY
  city;

# Order-seller ratio
SELECT
  Sellers.city,
  number_of_orders / number_of_sellers AS orders_per_seller
FROM
Sellers_per_city AS Sellers JOIN Orders_per_city AS Orders
    ON Sellers.city = Orders.city
ORDER BY
  orders_per_seller DESC
LIMIT 10;


# Revenue by city (Top 25)
SELECT
  Customers.customer_city AS city,
  ROUND(SUM(Payments.payment_value), 2) AS revenue
FROM
  (`target-ecommerce.target_ecommerce_data.Orders` AS Orders JOIN `target-ecommerce.target_ecommerce_data.Customers` AS Customers 
    ON Orders.customer_id = Customers.customer_id) JOIN `target-ecommerce.target_ecommerce_data.Payments` AS Payments
    ON Orders.order_id = Payments.order_id
GROUP BY
  city
ORDER BY
  revenue DESC
LIMIT (25);

# Number of purchases per product
SELECT
  product_id,
  AVG(price) AS price,
  COUNT(*) AS number_of_orders
FROM
  `target-ecommerce.target_ecommerce_data.Order_items`
GROUP BY
  product_id
