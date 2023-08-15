



DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
  -- What is the total amount each customer spent at the restaurant?
select customer_id, sum(price)
from sales
join menu
using (product_id)
group by customer_id;
-------------------------------------------------------------------------------------
-- How many days has each customer visited the restaurant?
Select customer_id, count(distinct(order_date)) as no_of_days
From Sales
Group by customer_id;
--------------------------------------------------------------------------------------
-- What was the first item from the menu purchased by each customer?
with rank_order as
(select customer_id,order_date,m.product_name as name ,price,
dense_rank() over(partition by customer_id order by order_date) as ranking
from sales as s
join menu as m
using(product_id))

select customer_id, name, ranking
from rank_order
where ranking = 1
group by customer_id, name;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
Select m.product_name as name, Count(s.product_id) as purchased_time
From Menu m
join Sales s
using(product_id)
Group by name
Order by purchased_time desc
limit 1;
   /* Count(s.product_id) as purchased_time*/
-- Which item was the most popular for each customer?
with popular as 
(
Select customer_id, m.product_name as name, Count(s.product_id) as purchase,        
dense_rank() over(partition by customer_id order by Count(s.product_id) desc ) as ranked
From Menu m
join Sales s
using(product_id)
Group by customer_id, name)
select customer_id, name, purchase
from popular
where ranked = 1;

-- Which item was purchased first by the customer after they became a member?
with joining as
(select s.customer_id, order_date, product_id,
dense_rank()over(partition by customer_id order by order_date) as ranking
from sales as s
join members
using(customer_id)
where join_date <= order_date)
select customer_id, order_date, product_name as name
from joining
join menu
using (product_id)
where ranking = 1
order by customer_id;

-- Which item was purchased just before the customer became a member?
with joining as
(select s.customer_id, order_date, product_id,
dense_rank()over(partition by customer_id order by order_date desc) as ranking
from sales as s
join members
using(customer_id)
where join_date > order_date)
select customer_id, order_date, product_name as name
from joining
join menu
using (product_id)
where ranking = 1
order by customer_id;

-- What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(s.product_id) total_items,sum(price) total_sum
from sales s
join members
using(customer_id)
join menu
using (product_id)
where order_date < join_date
group by customer_id 
order by customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with new_point as 
(select customer_id, product_name, price, case
when product_name = 'sushi' then price * 20
else price * 10 end as points
from sales
join menu
using (product_id))

select customer_id, sum(points)
from new_point
group by customer_id
order by customer_id;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with dates as (SELECT customer_id, join_date, DATE_ADD(join_date, INTERVAL 6 DAY) AS validity_period
 FROM members)
 
SELECT d.customer_id,d.validity_period,s.order_date,d.join_date,m.price AS price,m.product_name,SUM(CASE
    WHEN order_date BETWEEN d.join_date AND d.validity_period THEN m.price * 20
    ELSE m.price * 10 END) AS points
FROM dates d
	LEFT JOIN sales s
		ON s.customer_id = d.customer_id
	LEFT JOIN menu m
		ON s.product_id = m.product_id
WHERE s.order_date >= d.join_date AND s.order_date <= '2021-01-31'
GROUP BY
	customer_id;

-- BONUS Question 1
select s.customer_id, order_date, product_name, price, case
when order_date < join_date then 'N'
when order_date >= join_date then 'Y'
end as Membership
from sales s
join menu
using (product_id)
join members
using (customer_id);

-- BONUS QUESTION 2
with new_table as
(select s.customer_id, order_date, product_name, price, case
when order_date < join_date then 'N'
when order_date >= join_date then 'Y'
end as membership
from sales s
join menu
using (product_id)
join members
using (customer_id))
select *, case
when membership = 'Y' then
dense_rank()over(partition by customer_id, membership order by order_date) 
end as ranking
from new_table

