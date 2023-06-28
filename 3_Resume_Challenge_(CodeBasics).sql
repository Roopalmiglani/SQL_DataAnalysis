################################# Request 1 #########################################
# Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select distinct market from dim_customer where customer="Atliq Exclusive" and region="APAC";
################################# Request 2 #########################################
# What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
select P20 as unique_products_2020,P21 as unique_products_2021,round((P21-P20)/P20 *100,2) as percentage_chg from (
(select count(distinct product_code) as P20 from fact_sales_monthly where fiscal_year=2020) as C20,
(select count(distinct product_code) as P21 from fact_sales_monthly where fiscal_year=2021) as C21);
################################# Request 3 #########################################
# Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count
select segment ,count(distinct product_code) as product_code from dim_product group by segment order by product_code desc;
################################# Request 4 ######################################### 
# Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference
WITH yearly_segment AS
(SELECT dp.segment AS segment,COUNT(DISTINCT(CASE WHEN fiscal_year = 2020 THEN fs.product_code END)) AS product_count_2020,
COUNT(DISTINCT(CASE WHEN fiscal_year = 2021 THEN fs.product_code END)) AS product_count_2021        
 FROM fact_sales_monthly AS fs
 INNER JOIN dim_product AS dp
 ON fs.product_code = dp.product_code
 GROUP BY dp.segment
)
SELECT segment, product_count_2020, product_count_2021, (product_count_2021-product_count_2020) AS difference
FROM yearly_segment
ORDER BY difference DESC;
################################# Request 5 ######################################### 
# Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost codebasics
select product,dp.product_code,round(manufacturing_cost,2) as manufacturing_cost from dim_product dp join
 fact_manufacturing_cost fm on fm.product_code=dp.product_code WHERE fm.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
OR    fm.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost) 
ORDER BY fm.manufacturing_cost DESC;
################################# Request 6 ######################################### 
# 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
#The final output contains these fields, customer_code customer average_discount_percentage.
select customer,dc.customer_code,round(avg(pre_invoice_discount_pct),4) as average_discount_percentage from dim_customer dc join fact_pre_invoice_deductions fpi on dc.customer_code=fpi.customer_code
where fiscal_year=2021 and market="India" group by customer,dc.customer_code order by average_discount_percentage desc  limit 5;
################################# Request 7 ######################################### 
# Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
# This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
# The final report contains these columns: Month Year Gross sales Amount.
select CONCAT(MONTHNAME(date), ' (', YEAR(date), ')') AS Month ,fm.fiscal_year ,(gross_price * sold_quantity) as Gross_sales_Amount from dim_customer dc join fact_sales_monthly fm on dc.customer_code=fm.customer_code join fact_gross_price fp on fp.product_code=fm.product_code
where customer="Atliq Exclusive" group by Month,fm.fiscal_year order by fm.fiscal_year;
################################# Request 8 #########################################
# In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity 
select case when month(date) in (9,10,11) then "Q1"
			  when month(date) in (12,1,2) then "Q2"
               when month(date) in (3,4,5) then "Q3"
               else "Q4" end as Quarters,sum(sold_quantity) as total_sold_quantity
              from fact_sales_monthly where fiscal_year=2020
              group by Quarters
              order by total_sold_quantity desc;
################################# Request 9 #########################################
# Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage .
with gross_sales  as (select channel,round(sum(gross_price * sold_quantity)/1000000,2) as gross_sales_mln from dim_customer dc join fact_sales_monthly fm 
on dc.customer_code=fm.customer_code join fact_gross_price fp on fp.product_code=fm.product_code
where fm.fiscal_year=2021 group by dc.channel order by gross_sales_mln desc ) 
select channel,  gross_sales_mln ,round(gross_sales_mln /sum(gross_sales_mln) over()*100,2) as percentage from gross_sales ;  
################################# Request 10 #########################################  
# Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division product_codeproduct total_sold_quantity rank_order
with top3 as (select division,fm.product_code,product,sum(sold_quantity) total_sold_quantity,rank() over (partition by division ORDER BY sum(sold_quantity)
 DESC) as rank_order from fact_sales_monthly fm join dim_product dp on fm.product_code=dp.product_code group by fm.product_code,division order by total_sold_quantity desc)
select * from top3 where rank_order<=3;
