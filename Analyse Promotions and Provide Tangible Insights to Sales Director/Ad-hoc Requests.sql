use retail_events_db; -- use current data base

-- data study
-- --------------------------------------------------------------------
-- lets see the table char first like primary key , reference key
-- then count of data rows for each table
-- then lets see all columns and their data
-- then Ad-hoc qstn

desc dim_campaigns; -- campaign_id = PK
select count(*) from dim_campaigns; -- 2 rows
select * from dim_campaigns;

-- no. of days for each campaign
select *, 
	datediff(end_date,start_date) as no_of_days_campaign 
    from dim_campaigns;
-- so both campaign ran for 6 days

-- -------------------------------------------------------------------------------------

desc dim_products; -- product_code = PK
select count(*) from dim_products;
select * from dim_products;

-- unique types of category and count of unique products under each category
select distinct category , count(distinct product_name) as no_of_products
from dim_products
group by category
order by count(distinct product_name) desc; -- 5 distinct category

-- -------------------------------------------------------------------------------------

desc dim_stores;  -- store_id = PK
select count(*) from dim_stores;
select * from dim_stores;

-- no of city
select count(distinct city) as no_of_city from dim_stores; -- 10

-- -------------------------------------------------------------------------------------
desc fact_events;
select count(*) from fact_events; -- 1500
select * from fact_events;

-- how many types of promo ran
select distinct promo_type
from fact_events
order by promo_type; -- 5

-- note : BOGOF IS Buy one get one free 

-- Ad-hoc req1:
/* Provide the list of product with a base price greater than 500 and 
that are featured in promotype of BOGOF. 
This information will help to identify high value product that are current been heavily discounted, 
which cane be useful for pricing and promotion strategies*/

with prod as
(
select
p.product_code, p.product_name,promo_type,e.base_price ,
sum(e.`quantity_sold(before_promo)`) as "total_quantity_sold(before_promo)",
sum(e.`quantity_sold(after_promo)`) as "total_quantity_sold(after_promo)"
from fact_events as e
inner join
dim_products as p
using (product_code)
where promo_type = "BOGOF"
group by p.product_code, p.product_name,promo_type,e.base_price
order by e.base_price desc)
select * from prod
where base_price > 500;

-- ----------------------------------------------------------------------------------------------------------------

-- Ad hoc Req2 : city wise store count
select distinct city, count(store_id) as no_of_stores
from dim_stores
group by city
order by count(store_id) desc;

-- ----------------------------------------------------------------------------------------------------------------

-- ad hoc Req 3
/* generate a report that displays each campaign along with the total revenue generated before and after the campaign?
The reprot includes 3 key fields
campaign_name, total_revenue(before promotion), total_revenue(after promotion). Display value in Million */
with temp as
(
select 
product_code,campaign_name,base_price,promo_type,
sum(`quantity_sold(before_promo)`) as "total_quantity_sold(before_promo)",
sum(`quantity_sold(after_promo)`) as "total_quantity_sold(after_promo)"
from
dim_campaigns
inner join
fact_events
using (campaign_id)
group by product_code,campaign_name,base_price,promo_type
order by product_code
)
,temp1 as
( -- this CTE for total revenue before promotion
select 
*,round((base_price*`total_quantity_sold(before_promo)`)/(1000000),2) as "Total_revenue(before_promo)"
from temp
)
, temp2 as
( -- this CTE i created to see the revenue after PROMO
select *,
case -- CASE statement for revenue after promotion
	when promo_type = "33% OFF" then round(((base_price - (base_price*0.33))* `total_quantity_sold(after_promo)`)/1000000,2)
    when promo_type = "25% OFF" then round(((base_price - (base_price*0.25))* `total_quantity_sold(after_promo)`)/1000000,2)
    when promo_type = "50% OFF" then round(((base_price - (base_price*0.50))* `total_quantity_sold(after_promo)`)/1000000,2)
    when promo_type = "500 Cashback" then round(((base_price - 500)* `total_quantity_sold(after_promo)`)/1000000,2)
    when promo_type = "BOGOF" then round(((base_price)* `total_quantity_sold(after_promo)`)/1000000,2)
end as "Total_revenue(after_promo)"
from temp1
)
select campaign_name, sum(`Total_revenue(before_promo)`) as `Total_revenue(before_promo)`,
sum(`Total_revenue(after_promo)`) as `Total_revenue(after_promo)`
from temp2
group by campaign_name; -- values are in million

-- ----------------------------------------------------------------------------------------------------------------

-- Ad hoc Req4
/*
Produce a report that calculates The incremental Sold Quantity (ISU %) for each category 
during the Diwali campaign.
Additionally provide the ranking for the categories based on their ISU %age.
The report will include 3 key fields : Category, ISU%, RankOrder
*/
with temp as
( -- this CTE is for required columns, revised Quantity for BOGOF, and data on basis of product level
select 	e.campaign_id,
		p.product_code,
        e.promo_type,
        p.category,
		e.`quantity_sold(before_promo)`,
		e.`quantity_sold(after_promo)`,
	case
		when promo_type = "BOGOF" then `quantity_sold(after_promo)`*2
		else `quantity_sold(after_promo)`
	end "quantity_sold(after_promo)_revised"
from fact_events as e
inner join
dim_products as p
on e.product_code = p.product_code
where e.campaign_id = "CAMP_DIW_01"
) ,
temp2 as (-- this CTE is for aggreageting value and creating ISU% with required columns only
select category,
		sum(`quantity_sold(before_promo)`) as "Total_quantity_sold(before_promo)",
		sum(`quantity_sold(after_promo)_revised`) as "Total_quantity_sold(after_promo)",
        ( (sum(`quantity_sold(after_promo)_revised`) - sum(`quantity_sold(before_promo)`) )/sum(`quantity_sold(before_promo)`)) as "ISU%" 
from temp
group by category
)

select category,concat(round(`ISU%`*100,2),"%") as "ISU%",
dense_rank() over(order by `ISU%` desc) -- Ranking on basis of ISU% from largest to smallest
from temp2;

-- ----------------------------------------------------------------------------------------------------------------

-- Ad hoc req 5
/*
Create a report featuring the top 5 products, Ranked by incremental revenue percentage (IR%) . across all campaigns.
The report will provide essential information including product name , category and IR% . This analysis helps identify the
most successful products in terms of incremental revenue across our campaigns , assiting in product optimization
*/
with temp as
(
select 
e.product_code,p.product_name,p.category,c.campaign_name,e.base_price,e.promo_type,
sum(`quantity_sold(before_promo)`) as "total_quantity_sold(before_promo)",  -- THIS WILL GIVE TOTAL REVENUE PRODUCTWISE before promo
sum(`quantity_sold(after_promo)`) as "total_quantity_sold(after_promo)" -- THIS WILL GIVE TOTAL REVENUE PRODUCTWISE after promo
from
dim_campaigns as c
inner join
fact_events as e
on e.campaign_id = c.campaign_id
inner join
dim_products as p
on e.product_code = p.product_code
group by e.product_code,p.product_name,c.campaign_name,e.base_price,e.promo_type
order by p.product_code
)
,temp1 as
( -- this CTE for total revenue before promotion
select 
*,(base_price*`total_quantity_sold(before_promo)`) as "Total_revenue(before_promo)"
from temp
)
, temp2 as
( -- this CTE i created to see the revenue after PROMO
select *,
case -- CASE statement for revenue after promotion
	when promo_type = "33% OFF" then ((base_price - (base_price*0.33))* `total_quantity_sold(after_promo)`)
    when promo_type = "25% OFF" then ((base_price - (base_price*0.25))* `total_quantity_sold(after_promo)`)
    when promo_type = "50% OFF" then ((base_price - (base_price*0.50))* `total_quantity_sold(after_promo)`)
    when promo_type = "500 Cashback" then ((base_price - 500)* `total_quantity_sold(after_promo)`)
    when promo_type = "BOGOF" then ((base_price)* `total_quantity_sold(after_promo)`)
end as "Total_revenue(after_promo)"
from temp1
)
,temp3 as
( -- this CTE for Productname, Category, IR%
select product_name,category, 
((sum(`Total_revenue(after_promo)`) - sum(`Total_revenue(before_promo)`))/sum(`Total_revenue(before_promo)`))*100 as "IR%"
from temp2
group by product_name,category
order by `IR%` DESC
)
,temp4 as
( -- this CTE to add the ranking as per IR%
select product_name,category,round(`IR%`,2)  as `IR%`,
		rank() over(order by `IR%` desc) as rankorder
from temp3 
order by `IR%` desc
)
select * from temp4 where rankorder < 6;

-- ----------------------------------------------------------------------------------------------------------------

/* This is additional not ad hoc request
-- add on my point lets see which product listed in multiple promo and their corresponding base price and quantity sold
with prod as
(
select
p.product_name, e.promo_type,e.base_price
from fact_events as e
inner join
dim_products as p
using (product_code)),
prod2 as
(select product_name , count(distinct promo_type) as cnt_promo
from prod
group by product_name
having count(distinct promo_type)>1)
select prod.product_name,prod.promo_type,prod.base_price
from prod inner join
prod2
using(product_name)
group by prod.product_name,prod.promo_type,prod.base_price
order by prod.product_name,prod.promo_type,prod.base_price desc;
8/
