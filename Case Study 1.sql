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
With rank_order as
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

-- BONUS QEUSTION 1
select s.customer_id, order_date, product_name, price, case
when order_date < join_date then 'N'
when order_date >= join_date then 'Y'
end as Membership
from sales s
join menu
using (product_id)
join members
using (customer_id) ;

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

