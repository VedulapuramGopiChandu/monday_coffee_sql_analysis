-- SQL ANALYSIS PROJECT --


select * from city;
select * from products;
select * from sales;
select * from customers;


-- Question 1
  /*Coffee Consumers Count
How many people in each city are estimated to consume coffee, given that 25% of the population does?*/
select city_name,
city_population,
city_rank
from city
order by 2 desc;

select city_name,
round((city_population  * 0.25) / 1000000, 2) as coffee_comsuption,
city_rank
from city
order by 2 desc;

 -- Question 2
 /*Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?*/


select *, 
extract(year from sale_date) as year,
extract(quarter from sale_date) as quarters
from sales
where
extract(year from sale_date) = 2023 and 
extract(quarter from sale_date) = 4 ;

select ci.city_name,
sum(s.total) as total_revanue
from sales as s join
customers as c on s.customer_id = c.customer_id
join city as ci on ci.city_id = c.city_id
where 
extract(year from s.sale_date) = 2023 and 
extract(quarter from s.sale_date) = 4 
group by 1 
order by 2 desc;

-- Question 3
/*Sales Count for Each Product
How many units of each coffee product have been sold?*/

select p.product_name,
count(s.sale_id) as total_order
from products as p left join
sales as s on p.product_id = s. product_id
group by 1
order by 2 desc;

-- Question 4
/*Average Sales Amount per City
What is the average sales amount per customer in each city?*/




select ci.city_name,
sum(s.total) as total_revanue,
count(distinct s.customer_id) as total_cx,
round(sum(s.total) / count(distinct s.customer_id), 2) as avg_sale_per_customer
from sales as s join
customers as c on s.customer_id = c.customer_id
join city as ci on ci.city_id = c.city_id
group by 1 
order by 2 desc;

-- Question 5
/*City Population and Coffee Consumers
Provide a list of cities along with their populations and estimated coffee consumers?*/

with city_table as 
( select city_name,
round((city_population  * 0.25) / 1000000, 2) as coffee_comsuption 
from city),
customers_table as 
( select 
ci.city_name,
count(distinct c.customer_id) as unique_cus
from sales as s 
join 
customers as c on
s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1 )
select 
customers_table.city_name,
city_table.coffee_comsuption as coffee_consumer_per_million,
customers_table.unique_cus
from city_table
join customers_table 
on city_table.city_name = customers_table.city_name;



-- Question 6
/*Top Selling Products by City
What are the top 3 selling products in each city based on sales volume?*/

select * from
(
select ci.city_name,
p.product_name,
count(s.sale_id) as total_orders,
dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as ranks
from sales as s
join products as p
on s.product_id = p.product_id join
customers as c on 
c.customer_id = s.customer_id join
city as ci on 
ci.city_id = c.city_id
group by 1, 2
) as t1
where ranks <= 3;


-- Question 7
/*Customer Segmentation by City
How many unique customers are there in each city who have purchased coffee products?*/

select ci.city_name,
count(distinct c.customer_id) as unique_cu
from city as ci
left join customers as c
on ci.city_id = c.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
group by 1;

-- Question 8
/*Customer Segmentation by City
How many unique customers are there in each city who have purchased coffee products?*/

WITH city_table AS (
    SELECT ci.city_name,
           SUM(s.total) AS total_revenue,
           COUNT(DISTINCT s.customer_id) AS total_cx,
           ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT city_name,
           estimated_rent
    FROM city
)
SELECT cr.city_name,
       cr.estimated_rent,
       ct.total_cx,
       ct.avg_sale_per_customer,
       ROUND(cr.estimated_rent / ct.total_cx, 2) AS avg_rent_per_customer
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY 4 desc;

-- Question 9
/*Monthly Sales Growth
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).*/


WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        EXTRACT(MONTH FROM sale_date) AS month,
        EXTRACT(YEAR FROM sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c 
    ON c.customer_id = s.customer_id
    JOIN city AS ci 
    ON ci.city_id = c.city_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 3, 2
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) / last_month_sale * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
where last_month_sale is not null;


-- Question 10
/*Market Potential Analysis
Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer*/


WITH city_table AS (
    SELECT ci.city_name,
           SUM(s.total) AS total_revenue,
           COUNT(DISTINCT s.customer_id) AS total_cx,
           ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
    FROM sales AS s
    JOIN customers AS c ON s.customer_id = c.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT city_name,
           estimated_rent,
           round( City_population * 0.25 / 1000000, 2) as estimated_coffee_consumer_per_millions
    FROM city
)
SELECT cr.city_name,
	    total_revenue,
       cr.estimated_rent as total_rent,
       ct.total_cx,
       estimated_coffee_consumer_per_millions,
       ct.avg_sale_per_customer,
       ROUND(cr.estimated_rent / ct.total_cx, 2) AS avg_rent_per_customer
FROM city_rent AS cr
JOIN city_table AS ct ON cr.city_name = ct.city_name
ORDER BY 2 desc;


