-- How many customers has Foodie-Fi ever had?
SELECT count(distinct customer_id) as count_of_customers
FROM foodie_fi.subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value



-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select plan_name, count(plan_id)
FROM plans p 
inner join subscriptions s 
using (plan_id)
where start_date >= '2020-01-01'
group by plan_name

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select 
