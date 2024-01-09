create database codebasic_r; -- Create a database

use codebasic_r; -- 

-- dim_customers table i loaded using table import wizard as data is small

create table fact_spends
(
customer_id varchar(20),
month varchar(10),
category varchar(30),
payment_type varchar(30),
spend int
);
select * from fact_spends;

-- way to load large data in mysql
load data infile 'D:/blackX/Data Science_SID/Projects-PowerBi/Competetion/Code Basic/
26th Nov 2023/C8_Input_Files/C8_Input_Files/fact_spends.csv' into table fact_spends
fields terminated by "," -- for CSV files
optionally enclosed by '"' 
lines terminated by '\r\n'  -- this for new line
ignore 1 rows; -- we already created the table, so we can remove the first row with header

-- to check the data row counts matched with excel or not
select count(*) from fact_spends;

-- once table loaded (csv files) through table wizard check the tables
-- small trick - you can double click on table name on schema section to appear that name in query.

select * from fact_spends;
select * from dim_customers;

-- lets check count and distinct count of cust_id in both table 
select count(customer_id)  as count
from dim_customers;
select count(distinct customer_id)  as dist_cnt
from dim_customers; 

-- cust_id is primary key in dim_customers and foreign key in fact_spends

select count(customer_id) as count
from fact_spends;
select count(distinct customer_id) as dist_cnt
from fact_spends;


-- --------------------------------------------------------------------------------------------------------------------
-- Demographic classification

-- total customers
select count(distinct customer_id) as total_distinct_customers
from fact_spends;
-- or 
select count(distinct customer_id) as total_distinct_customers
from dim_customers;

-- occupation wise customer counts and percentage of total 4000
select occupation,
		count(distinct customer_id) as total_customers,
		round((count(distinct customer_id)/4000)*100,2) as percentage_distribution
from dim_customers
group by occupation
order by total_customers;

-- age group wise customer distribution
select age_group,
		count(distinct customer_id) as total_customers
from dim_customers
group by age_group
order by total_customers;

-- lets see in each payment type how many customers are there
select payment_type,
		count(distinct s.customer_id) as total_customers
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by payment_type
order by total_customers;
-- from above its seems like all people using all payment type 😀

-- lets see what the city wise distribution
select city,
		count(distinct customer_id) as total_customers
from dim_customers
group by city
order by total_customers;

-- ----------------------------------------------------------------------------------------------------------------------------
-- spend analysis
-- total spend
select sum(spend) from fact_spends;

-- but here on above we saw the data distribution is not equal so lets take avergae
select round((Sum(spend)/6)/count(distinct customer_id),2) as Average_spend
from fact_spends;

-- gender wise avg spends = lets see which gender spends most whats the % age of total spends in 6 months
select t.gender , 
		round(p.total_average,2),
		format(t.average_spend,0) as average_spend from -- by default format function will show data in million format, here its INR, so better avoid , we can change the style to INR but i did only for knowledge
        -- concat(((t.average_spend/P.total_average)*100)," %")as percentage from    -- i did not take it as this will display > 100 % for male 
( -- this query will give gender wise spends
select 	c.gender,
		(Sum(s.spend)/6)/count(distinct s.customer_id) as Average_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.gender
order by average_spend desc
) as t
join
( -- this section query gives total spend 
select (Sum(spend)/6)/count(distinct customer_id) as total_average from fact_spends
) as p ;
-- from above males spendings are double compare to female

-- agegroup wise
select t.age_group , p.total_average,t.Average_spend from 
(
select 	c.age_group,
		(Sum(s.spend)/6)/count(distinct s.customer_id) as Average_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.age_group
order by average_spend desc
) as t
join
(
select (Sum(spend)/6)/count(distinct customer_id) as total_average from fact_spends
) as p ;


-- occupation wise
select t.occupation , p.total_average,t.Average_spend  from 
(
select 	c.occupation,
		(Sum(s.spend)/6)/count(distinct s.customer_id) as Average_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.occupation
order by Average_spend desc
) as t
join
(
select (Sum(spend)/6)/count(distinct customer_id) as total_average from fact_spends
) as p ;

-- marital status wise
select t.m_stat , p.total_average,t.Average_spend from 
(
select 	`marital status` as m_stat,
		(Sum(s.spend)/6)/count(distinct s.customer_id) as Average_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by `marital status`
order by average_spend desc
) as t
join
(
select (Sum(spend)/6)/count(distinct customer_id) as total_average from fact_spends
) as p ;


-- ----------------------------------------------------------------------------------------

-- agegroup wise drill down
-- agegroup wise

select t.age_group , t.total_spend, (t.total_spend/P.total)*100 as percentage from 
(
select 	c.age_group,
		Sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.age_group
order by total_spend desc
) as t
join
(
select sum(spend) as total from fact_spends
) as p ;

-- from above we got to know for age_group 25 to 45 have spends 75% of total while 21-24 and 45+ have 25% of total
/* for above i did not go by avg spend in deeper, we can go that way also, 
but just to know in our data set %age wise spending distribution in each age group simillary for below */

-- top occupation for age group 25-45
select t.occupation, t.total_spend, (t.total_spend/P.total)*100 as percentage from 
( -- this table to get spends data occupation wise forn age group 25 to 45
select 	c.occupation,
		Sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where age_group in ('25-34','35-45')
group by c.occupation
order by total_spend desc
) as t

join
( -- this is the total for  25 - 45
select Sum(s.spend) as total
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where age_group in ('25-34','35-45')
) as p ;

-- from above we say in between age 25 to 45 It employees spending is highest and Govt employees spendings is lowest.
-- rest 3 category occupation spendings are near about same for this age group that is 25 to 45 

-- lets see which age group spends most in which payment type

(select age_group,
		payment_type,
        dense_rank() over (partition by age_group order by sum(spend) desc) as ranks,
		sum(spend) as total_spend
from dim_customers as c
inner join
fact_spends as f
on c.customer_id = f.customer_id
group by age_group, payment_type
order by age_group asc ,total_spend desc);

-- from above we see 25 to 34 age groups using credit card followed by UPI for their most spending spend
-- simillarly we see 34 to 45 age groups using credit card followed by Debit and UPI for their most spending spend
-- intrestingly gen Z  are using UPI uses are high followed by credit and debit 

-- lets now see for age group 25 to 45, and IT employees which gender has high spend
(select c.gender,
		Sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where age_group in ('25-34','35-45') and c.occupation = "Salaried IT Employees"
group by c.gender
order by total_spend desc
);  

-- we get male has highest spend followed by women


-- ----------------------------------------------------------------------------------------------------
-- maretial statuswise drill down
-- marital status wise
select t.m_stat , t.total_spend, (t.total_spend/P.total)*100 as percentage from 
( -- data as per maretial status spends
select 	`marital status` as m_stat,
		Sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by `marital status`
order by total_spend desc
) as t
join
(-- total spends
select sum(spend) as total from fact_spends
) as p ;

-- so married people have significant spend which is obivious

-- in married people occupation wise analysis
select  t.occupation,t.total_spend, (t.total_spend/P.total)*100 as percentage from 
( -- data as per maretial status spends
select 	c.occupation,
		Sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where `marital status` = "Married"
group by c.occupation
order by total_spend desc
) as t
join
(-- total spends for married people
select Sum(s.spend) as total
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where `marital status` = "Married"
) as p ;

-- in married people gender wise analysis
select  t.gender,t.total_spend, (t.total_spend/P.total)*100 as percentage from 
( -- data as per age wise spends for married people
select 	c.gender,
		Sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where `marital status` = "Married"
group by c.gender
order by total_spend desc
) as t
join
(-- total spends for married people
select Sum(s.spend) as total
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where `marital status` = "Married"
) as p ;

-- -- in married people payment_type wise analysis
select  t.payment_type,t.total_spend, (t.total_spend/P.total)*100 as percentage from 
( -- data as per married people
select 	payment_type,
		Sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where `marital status` = "Married"
group by payment_type
order by total_spend desc
) as t
join
(-- total spends for married people
select Sum(s.spend) as total
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
where `marital status` = "Married"
) as p ;

-- married people uses Credit card followed by UPI and debit card for their most spending


-- ---------------------------------------------------------------------------------------------------------
-- average income utilisation %age
-- average spends / average income
-- there is point need to concern here
/*
the income data is income for a month thats why it named as avg_income
spend data is there for 6 months , so better we do first spend monthly then spend by income
*/
-- lets see overall income utilisation % age wise
with temp as(
select
		avg(c.avg_income) as avg_monthly_income,
        (sum(s.spend)/6)/count(distinct s.customer_id) as avg_monthly_spend
        
from 
dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id)
select *, avg_monthly_spend/avg_monthly_income from temp;

-- lets see it occupation wise
with temp as
(-- click on plus sign to see the code
select 	c.occupation,
		(sum(s.spend)/6)/count(distinct s.customer_id) as average_spend,
        avg(c.avg_income) as average_income
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.occupation
) select *,
		round(((average_spend / average_income)*100),2) as avg_income_utilisation
from temp
order by avg_income_utilisation desc;

-- lets see which age group has high average income utilisation
with temp as
(-- click on plus sign to see the code
select 	c.age_group,
		(sum(s.spend)/6)/count(distinct s.customer_id) as average_spend,
        avg(c.avg_income) as average_income
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.age_group
) select *,
		round(((average_spend / average_income)*100),2) as avg_income_utilisation
from temp
order by avg_income_utilisation desc;


-- lets see which category has high spending
select category,
		sum(spend) as total_spend

from fact_spends
group by category
order by total_spend desc;

-- in each category what is the spendings in each payment type
select 	category,
		payment_type,
        dense_rank() over (partition by category order by sum(spend) desc) as ranks,
		sum(spend) as total_spend
from fact_spends
group by category, payment_type
order by category asc ,total_spend desc;

-- find out the category in which highest spends done by credit card
with temp as(
select category,
		payment_type,
        dense_rank() over (partition by category order by sum(spend) desc) as ranks,
		sum(spend) as total_spend
from fact_spends
group by category, payment_type
order by category asc ,total_spend desc
)
select * from temp
where ranks = 1 and payment_type = "Credit Card";

-- ------------------------------------------------------------------------------------------------------------------
-- month wise analysis
select 	month,
		sum(spend) as Total_Spend
from fact_spends
group by month
order by total_spend desc;  -- festive sessions that is septempber, aug and Oct have high spend


-- in which month , which age groups has high spends
select 	s.month,
		c.age_group,
		sum(s.spend) as Total_Spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by month,c.age_group
order by month asc,total_spend desc; -- seems like on festive session age group 25 - 34 Leads age group 35-45 in spendings 


-- lets see in which month, which payment_type leads
select 	s.month,
		s.payment_type,
		sum(s.spend) as Total_Spend
from fact_spends as s
group by month,s.payment_type
order by month asc,total_spend desc; -- in every month credit card and UPI spendings are high

-- and further deep dive if we see in which category which payment type have high spending in eavery month
with temp as (
select 	s.month,
		s.category,
		s.payment_type,
		sum(s.spend) as Total_Spend,
        dense_rank() over(partition by s.month order by sum(s.spend) desc) as ranks
from fact_spends as s
group by month,s.payment_type,s.category
order by month asc,total_spend desc
)
select *
from temp where ranks between 1 and 3;

-- so from above we can say almost each month credit card and UPI uses are high
-- and also in festive session people spends high in electronic items by credit card


-- -----------------------------------------------------------------------------------------------------------

-- city wise analysis
-- which city high spend
select c.city,
		sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.city
order by total_spend desc;  -- mumbai, delhi ncr and bengaluru are top 3

-- which city high occupation high spend
select c.city,
		c.occupation,
		sum(s.spend) as total_spend
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.city, c.occupation
order by city asc,total_spend desc;  -- from this we can focus on city wise offers as per occupation
-- for example we can give package idea to customer to choose the location and as per that they will get some cutomized plan
-- IT people have high spending in all cities almost, but if you see top three city that is Mumbai, delhi, bengaluru the 2nd high spending is diff


-- which city has high income utilisation %age , for little deeper to know which city has most chance of opting our new Cred
select c.city,
		(sum(s.spend)/6)/count(distinct s.customer_id) as average_spend,
        round(avg(c.avg_income),2) as avg_income,
        round(((((sum(s.spend)/6)/count(distinct s.customer_id))/avg(c.avg_income))*100),2) as income_utilisation
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.city
order by income_utilisation desc;


-- which city has high income utilisation %age month wise
-- here as we show in monthwise breakup, dont devide by 6
select c.city,
		s.month,
		(sum(s.spend))/count(distinct s.customer_id) as avg_spend,
        round(avg(c.avg_income),2) as avg_income,
        round(((((sum(s.spend))/count(distinct s.customer_id))/avg(c.avg_income))*100),2) as income_utilisation
from dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id
group by c.city, s.month
order by c.city,income_utilisation desc;

-- lets see the customers who did not spend in credit card
with temp as
(select s.customer_id,
		s.payment_type,
        t.customer_id as mat
from fact_spends as s
left join 
(select distinct customer_id   
from 
fact_spends where payment_type = "Credit Card") as t

on t.customer_id=s.customer_id
where t.customer_id is null
)
select count(distinct temp.customer_id) as distinct_cnt
from temp;
-- here i could have used subquery, but its not working now so i used self join
-- There are 0 customers out of 4000 who never used Credit card in these 6 months


select sum(spend) from fact_spends;

select sum(avg_income)/4000 from dim_customers;
with temp as(
select 
		sum(c.avg_income)/count(c.customer_id) as avg_income,
        sum(s.spend)/count(c.customer_id) as avg_spend
from
dim_customers as c
inner join
fact_spends as s
on c.customer_id = s.customer_id)
select *, (avg_spend/avg_income) as avg_income_utilization
 from temp;
 

 
 
-- cross  check of some CUST ID as for this CustID Income utilisation in >100% in power BI dashboard, that means spend is higher than income
select customer_id , avg_income
from dim_customers
where customer_id = "ATQCUS0163";

select customer_id,sum(spend)
from fact_spends
where customer_id = "ATQCUS0163" and month = "September"
group by customer_id;
