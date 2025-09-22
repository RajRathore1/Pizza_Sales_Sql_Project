create database pizzahut;
create table pizzas(
pizza_id varchar(30),
pizza_type_id varchar(30),
size varchar (10),
price float
);
CREATE TABLE pizza_types (
    pizza_type_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    ingredients TEXT
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_date DATE,
    order_time TIME
);
CREATE TABLE order_details (
    order_details_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    pizza_id TEXT NOT NULL,
    quantity INT NOT NULL
);
select * from order_details;
select * from orders;
select * from pizza_types;
select * from pizzas;
-- Basic:
-- 1.Retrieve the total number of orders placed.
select count(order_id) as total_orders from order_details; 
-- 2.Calculate the total revenue generated from pizza sales.
SELECT ROUND(SUM(p.price * od.quantity)::numeric, 2) AS total_revenue
FROM order_details od
JOIN pizzas p 
  ON od.pizza_id = p.pizza_id;
-- 3.Identify the highest-priced pizza.
-- Highest-priced pizza with name
SELECT pt.name, p.price,p.pizza_id
FROM pizzas p
JOIN pizza_types pt 
  ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 3;
-- 4.Identify the most common pizza size ordered.
-- Most common pizza size ordered
SELECT p.size, p.pizza_id, count(od.quantity) AS total_ordered
FROM order_details od
JOIN pizzas p 
  ON od.pizza_id = p.pizza_id
GROUP BY p.size, p.pizza_id
ORDER BY total_ordered DESC
LIMIT 1;
-- 5.List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pt.name AS pizza_name,
    Sum(od.quantity) AS total_ordered
FROM order_details od
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt 
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_ordered DESC
LIMIT 5;

-- Intermediate:
-- 6.Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
    pt.category AS pizza_category,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt 
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_quantity DESC;

-- 7.Determine the distribution of orders by hour of the day.
SELECT 
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY order_hour;
-- 8.Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
    pt.category AS pizza_category,
    COUNT(p.pizza_id) AS total_pizzas
FROM pizzas p
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_pizzas DESC;
-- 9.Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    order_date,
    SUM(od.quantity) AS total_pizzas_ordered,
    ROUND(AVG(SUM(od.quantity)) OVER (), 2) AS avg_pizzas_per_day
FROM orders o
JOIN order_details od 
    ON o.order_id = od.order_id
GROUP BY order_date
ORDER BY order_date;
--10. Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt 
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_revenue DESC
LIMIT 3;
-- Advanced:
-- 11.Calculate the percentage contribution of each pizza type to total revenue.
SELECT 
    pt.category AS pizza_category,
    ROUND(SUM(od.quantity * p.price)::numeric, 2) AS total_revenue,
    ROUND(
        (SUM(od.quantity * p.price)::numeric 
        / (SELECT SUM(od2.quantity * p2.price)
             FROM order_details od2
             JOIN pizzas p2 ON od2.pizza_id = p2.pizza_id)::numeric) * 100, 
        2
    ) AS revenue_percentage
FROM order_details od
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt 
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_revenue DESC;
-- 12.Analyze the cumulative revenue generated over time.
SELECT 
    o.order_date,
    ROUND(SUM(od.quantity * p.price)::numeric, 2) AS daily_revenue,
    ROUND(SUM(SUM(od.quantity * p.price)) 
          OVER (ORDER BY o.order_date)::numeric, 2) AS cumulative_revenue
FROM orders o
JOIN order_details od 
    ON o.order_id = od.order_id
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
GROUP BY o.order_date
ORDER BY o.order_date;
-- 13.Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT 
    pizza_category,
    pizza_name,
    total_revenue
FROM (
    SELECT 
        pt.category AS pizza_category,
        pt.name AS pizza_name,
        SUM(od.quantity * p.price) AS total_revenue,
        RANK() OVER (PARTITION BY pt.category ORDER BY SUM(od.quantity * p.price) DESC) AS rnk
    FROM order_details od
    JOIN pizzas p 
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt 
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
) ranked
WHERE rnk <= 3
ORDER BY pizza_category, total_revenue DESC;
-- 14.Orders that include pizzas from at least 3 different categories
SELECT 
    o.order_id,
    COUNT(DISTINCT pt.category) AS distinct_categories
FROM orders o
JOIN order_details od 
    ON o.order_id = od.order_id
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt 
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY o.order_id
HAVING COUNT(DISTINCT pt.category) >= 3
ORDER BY distinct_categories DESC;
--15. Top 2 pizza sizes per category by total quantity ordered
SELECT pizza_category, size, total_quantity
FROM (
    SELECT 
        pt.category AS pizza_category,
        p.size,
        SUM(od.quantity) AS total_quantity,
        ROW_NUMBER() OVER (
            PARTITION BY pt.category 
            ORDER BY SUM(od.quantity) DESC
        ) AS rn
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, p.size
) ranked
WHERE rn <= 2
ORDER BY pizza_category, total_quantity DESC;