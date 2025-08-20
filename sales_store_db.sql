create table sales_store
(
transaction_id varchar(15),
customer_id varchar(15),
customer_name varchar(30),
customer_age int,
gender varchar(15),
product_id varchar(15),
product_name varchar(15),
product_category varchar(15),
quantity int,
prce float,
payment_mode varchar(15),
purchase_date date,
time_of_purchase time,
status varchar(15)

)
select * from sales_store
select table_schema,table_name from information_schema.tables where table_name='sales_store'
select * into sales from sales_store
select * from sales

-- Data cleaning
-- STEP1. To check for duplicate
--1.
select transaction_id , count(*)
from sales
group by transaction_id
having COUNT(transaction_id) > 1
"TXN855235"
"TXN240646"
"TXN342128"
"TXN981773"

--2.
with cte as (
select ctid,
row_number() over (partition  by transaction_id order by transaction_id)as row_num
from sales
)
delete from sales
using cte
where sales.ctid=cte.ctid 
and cte.row_num >1
and sales.transaction_id in ('TXN855235', 'TXN240646', 'TXN342128', 'TXN981773');

select * from cte
where transaction_id in ('TXN855235', 'TXN240646', 'TXN342128', 'TXN981773')

-- step2. correction of header
select * from sales
ALTER TABLE sales RENAME COLUMN prce TO price;

--step3. to check datatype
select column_name, data_type
from information_schema.columns
where table_name='sales'

-- step4. to check null values
DO $$
DECLARE
    col_list TEXT;
    sql_query TEXT;
BEGIN
    -- build condition for all columns
    SELECT string_agg(format('%I IS NULL', column_name), ' OR ')
    INTO col_list
    FROM information_schema.columns
    WHERE table_name = 'sales';

    -- build and run final query
    sql_query := format('SELECT * FROM sales WHERE %s;', col_list);
    EXECUTE sql_query;
END;
$$ language plpgsql;

--step5- treating null values


SELECT *
FROM sales
WHERE transaction_id is NULL

OR customer_id IS NULL
OR customer_name IS NULL
OR transaction_id IS NULL
OR customer_age IS NULL
OR gender IS NULL
OR product_id IS NULL
OR product_name IS NULL
OR product_category IS NULL
OR quantity IS NULL
OR price IS NULL
OR purchase_date IS NULL

OR payment_mode IS NULL
OR time_of_purchase IS NULL
OR status IS NULL


DELETE FROM sales
WHERE transaction_id is NULL

SELECT * FROM sales
WHERE customer_name ='Ehsaan Ram'

UPDATE sales 
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900'

SELECT * FROM sales
WHERE customer_name ='Damini Raju'

UPDATE sales 
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663'

select * from sales 
where customer_id ='CUST1003'

UPDATE sales
set customer_name ='Mahika Saini', customer_age='35', gender = 'male'
where customer_id ='CUST1003'

-- step6- data cleaning
select distinct gender from sales

update sales
set gender= 'M' where gender= 'Male'or gender='male'
set gender= 'F' where gender= 'Female'

select distinct payment_mode from sales

update sales
set payment_mode= 'Credit Card' where payment_mode= 'CC'

-- DATA ANALYSIS--

--1. what are the top 5 most selling product by quality ?
select product_name , sum(quantity)as total_quantity_sold
from sales
where status= 'delivered'
group by product_name
order by total_quantity_sold desc
limit 5
--Business problem - So that, we will able to know which product is in demand and we can manage our stocks accordingly

-- 2. which products are most frequently cancelled?
select product_name, count(*) as total_cancelled 
from sales
where status = 'cancelled'
group by product_name
order by total_cancelled desc
limit 5
--Business problem - frequently cancelled ,affect revenue and break customer trust. so that we can identify poor performing of the product.

--3. what time of the day has the highest number of purchase?
select 
    case
        when extract(hour from time_of_purchase) between 0 and 5 then 'NIGHT'
        when extract(hour from time_of_purchase) between 6 and 11 then 'MORNING'
        when extract(hour from time_of_purchase) between 12 and 17 then 'AFTERNOON'
        when extract(hour from time_of_purchase) between 18 and 23 then 'EVENING'
    end as time_of_day,
    count(*) as total_orders
from sales
group by time_of_day
order by total_orders desc
limit 1
--Bussiness problem - find peak sales time. so that we optimize our staff, promotions, and server loads.

--4. who are the top 5 highest spending customers?
select customer_name,
'₹'|| TO_CHAR(sum(price * quantity),'FM999,999,999,999') AS total_spend
from sales
group by customer_name
order by sum(price * quantity) desc
limit 5
--Bussiness problem- Identify VIP customers. So that, We can offer them loyality rewards and extra concern.

--5. which product category generate the highest revenue?
select product_category, 
'₹'|| TO_CHAR(sum(price * quantity),'FM999,999,999,999') AS total_revenue
from sales
group by product_category
order by sum(price * quantity) desc
limit 1
-- Business problem- Identify top_performing product categorty. So that, we can analyse high demand category.

--6. What is the return/cancellation rate per product category?
-- Cancelled
SELECT 
    product_category,
    ROUND((COUNT(CASE WHEN status = 'cancelled' THEN 1 END)::decimal * 100.0 / COUNT(*)), 3)
        || ' %' AS cancelled_percent
FROM sales
GROUP BY product_category
ORDER BY cancelled_percent DESC;

-- Return
SELECT 
    product_category,
    ROUND((COUNT(CASE WHEN status = 'returned' THEN 1 END)::decimal * 100.0 / COUNT(*)), 3)
        || ' %' AS returned_percent
FROM sales
GROUP BY product_category
ORDER BY returned_percent DESC;
-- Business Problem- Reduce returns, improve product description/expectations. It helps to identify and fix product or logistic issues.

--7. what is the most preffered payment mode?
select payment_mode, count(*) as total_count
from sales
group by payment_mode
order by total_count desc

-- Business problem- To Know which payment option customer prefer.

--8. How does age group affect purchasing behaviour?
select case
when customer_age between 18 AND 30 then '18-30'
when customer_age between 31 and 45 then '31-45'
when customer_age between 46 and 60 then '46-60'
end as age_group,
'₹'|| TO_CHAR(sum(price * quantity),'FM999,999,999,999') AS total_purchase
from sales 
group by age_group
order by total_purchase 
-- Business problem - To understand customer demographics and targeted marketing product recommendations by the age group.

--9. What's the monthly sales trend?
select 
To_char(purchase_date, 'YYYY-MM') as Month_Year,
'₹'|| TO_CHAR(sum(price * quantity),'FM999,999,999,999') AS total_sales,
sum(quantity) as total_quantity
from sales
group by month_year
order by month_year
--Business Problem- Sales fluctuations go unnoticed. So that, we plan marketing according to seasonal trends.

--10.Are certain gender buying more specific product category?

SELECT 
    product_category,
    COUNT(*) FILTER (WHERE gender = 'M') AS male_count,
    COUNT(*) FILTER (WHERE gender = 'F') AS female_count
FROM sales
GROUP BY product_category
ORDER BY product_category;
--Business Problem- Gender based product prefrences. So that, we can provide personalized ads, gender focused campaigns.
-----------------------------------------------------------------------------------------------------------------------------
























