/*
A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.*/

with cte as 
(select s.*, plan_name
from subscriptions s
join plans
on s.plan_id = plans.plan_id)

select *,
CONCAT(DATEDIFF(day,start_date,LEAD(start_date)over(partition by customer_id order by start_date)),' ','days') as day_diff
from cte
where customer_id in (1,2,11,13,15,16,18,19);

/*
customer 1:  signed up for a free trial on 2020-08-01 and downgraded to basic plan after the 7-day trial
customer 2:  signed up for a free trial on 2020-08-08 and upgraded to pro annual after the trial
customer 11: signed up for a free trial on 2020-11-19 and churned after the trial period
customer 13: signed up for a free trial on 2020-12-22 and initially started off on the basic, 97 days after switched to pro monthly
customer 15: signed up for a free trial on 2020-03-17 and started off on the pro monthly, 36 days after, churned
customer 16: signed up for a free trial on 2020-05-31 and switched to the basic monthly, and after 136 days upgraded to pro annual
customer 18: signed up for a free trial on 2020-07-06 and after the trial, remained on the pro monthly
customer 19: signed up for a free trial on 2020-06-22 and after the trial, remained on the pro monthly for 61 days before switching to pro annual plan
*/

/*
B1 How many customers has Foodie-Fi ever had? */

SELECT COUNT(DISTINCT customer_id) as no_of_customers
from subscriptions;

/*
B2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value*/
SELECT MONTH(start_date) as month, count(plan_id) as distribution 
from subscriptions 
where plan_id = 0
group by MONTH(start_date)
order by 1;

/* B3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name */

SELECT YEAR(start_date) as year, p.plan_name, count(s.plan_id) as events
from subscriptions s
join plans p
on s.plan_id = p.plan_id
where YEAR(start_date) > 2020
group by YEAR(start_date),p.plan_name;

/*B4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?*/

with cte as
(select customer_id, s.plan_id, p.plan_name
from subscriptions s
join plans p
on s.plan_id = p.plan_id)

select sum(
case when plan_id = 4 then 1
else 0 end) as churn_customer_count, 
ROUND(sum(
case when plan_id = 4 then 1
else 0 end) * 100 /count(DISTINCT customer_id),1) as percent_churn
from cte;

/* B5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number? */

with cte as 
(SELECT customer_id, plan_id, 
LEAD(plan_id)over(partition by customer_id order by start_date) as next_plan_id
from subscriptions)

SELECT SUM(
CASE WHEN plan_id = 0 and next_plan_id = 4 THEN 1
	 ELSE 0 END) AS churned_cust,
ROUND(SUM(
CASE WHEN plan_id = 0 and next_plan_id = 4 THEN 1
	 ELSE 0 END) * 100 / count(DISTINCT customer_id),0) as perc_churn
from cte;

/* B6 What is the number and percentage of customer plans after their initial free trial? */

with cte as
(SELECT customer_id, plan_id, 
LEAD(plan_id)over(partition by customer_id order by start_date) as next_plan_id
from subscriptions),

cte_2 as
(select p.plan_name, count(next_plan_id) as no_of_plans
from cte
join plans p
 on cte.next_plan_id = p.plan_id
where cte.plan_id = 0
group by p.plan_name)

select plan_name, no_of_plans, round(cast(no_of_plans as float)/sum(no_of_plans) over () * 100,1) as perc
from cte_2
group by plan_name,no_of_plans;


/* B7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31? */


WITH cte AS 
(SELECT *, 
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS row_num
  FROM subscriptions
  WHERE start_date <= '2020-12-31'),

max_row_per_customer AS (
	SELECT customer_id, MAX(row_num) AS max_row
  	FROM cte
  	GROUP BY customer_id);


/* B8 How many customers have upgraded to an annual plan in 2020? */
SELECT count(customer_id) as cust_count
from subscriptions
where plan_id = 3 and 
YEAR(start_date) = 2020;

/* B9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi */

SELECT cast(avg(datediff(day,a.start_date,b.start_date)) as float) as days
from subscriptions a
join subscriptions b 
on a.customer_id = b.customer_id
where a.plan_id = 0 and 
b.plan_id = 3;


/*B10* Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)*/

WITH cte AS (
SELECT a.customer_id,datediff(day,a.start_date,b.start_date) as date_interval
from subscriptions a
join subscriptions b 
on a.customer_id = b.customer_id
where a.plan_id = 0 and b.plan_id = 3
),

cte2 as (SELECT *,
  CASE WHEN date_interval BETWEEN 0 AND 30 THEN '0-30 days'
      WHEN date_interval BETWEEN 31 AND 60 THEN '31-60 days'
      WHEN date_interval BETWEEN 61 AND 90 THEN '61-90 days'
      WHEN date_interval BETWEEN 91 AND 120 THEN '91-120 days'
      WHEN date_interval BETWEEN 121 AND 150 THEN '121-150 days'
      WHEN date_interval BETWEEN 151 AND 180 THEN '151-180 days'
      WHEN date_interval > 180 THEN '181 +' END AS interval_group
  FROM cte)

SELECT interval_group,
COUNT(*) AS no_of_customers
from cte2
group by interval_group;

/*B11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020? */

with cte as
(SELECT customer_id, year(start_date) as year , plan_id, lead(plan_id)over(partition by customer_id order by start_date) as next
from subscriptions)

select count(customer_id) as count
from cte
where year = 2020 and 
plan_id = 2 and 
next = 1;
