use retail_events_db

select * from retail_events_db.dim_campaigns

select * from retail_events_db.dim_products

select * from retail_events_db.dim_stores

select * from retail_events_db.fact_events

#1.

select p.product_code, p.product_name, f.promo_type, sum(f.base_price) as total_base_price from retail_events_db.fact_events as f
inner join retail_events_db.dim_products as p
on f.product_code = p.product_code
where base_price > 500 and promo_type = 'BOGOF' and p.product_code IS NOT NULL
group by product_code, product_name, promo_type
order by p.product_name

#2. Generate a report that provides an overview of the number of stores in each city. The results will be sorted in descending order of store 
# counts, allowing us to identify the cities with the highest store presence. The report includes two essential fields: city and store count, 
# which will assist in optimizing our retail operations. 

select city, count(*) as Store_count from retail_events_db.dim_stores
group by city
order by count(*) desc
 
 #3. Generate a report that displays each campaign along with the total revenue generated before and after the campaign? The report includes
 # three key fields: campaign_name, total_ revenue (before _promotion), total revenue(after promotion). This report should help in evaluating
 # the financial impact of our promotional campaigns. (Display the values in millions)
 
 # - changing the column names:

ALTER TABLE retail_events_db.fact_events
CHANGE COLUMN `quantity_sold(after_promo)` `quantity_sold_before_promo` INT;

ALTER TABLE retail_events_db.fact_events
CHANGE COLUMN `quantity_sold(after_promo)` `quantity_sold_after_promo` INT;


 select 
	c.campaign_name,
	SUM( e.base_price * e.quantity_sold_before_promo) AS total_revenue_before_promotion,
    SUM(e.base_price * e.quantity_sold_after_promo) AS total_revenue_after_promotion
 from retail_events_db.dim_campaigns as c
 join retail_events_db.fact_events as e
 on e.campaign_id = c.campaign_id
group by campaign_name


#4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign. 
# Additionally, provide rankings for the categories based on their ISU%. The report will include three key fields: category, isu%,
# and rank order. This information will assist in assessing the category-wise success and impact of the Diwali campaign on incremental sales.
# Note: ISU% (Incremental Sold Quantity Percentage) is calculated as the percentage increase/decrease in quantity sold (after promo) compared 
# to quantity sold (before promo)


select category, 
concat(round(((sum(quantity_sold_after_promo)-sum(quantity_sold_before_promo))/sum(quantity_sold_before_promo))*100,2),"%") as Incremental_Sold_Quantity,
rank() over(order by ((sum(quantity_sold_after_promo)-sum(quantity_sold_before_promo))/(sum(quantity_sold_before_promo))) desc) as rank_order
from retail_events_db.fact_events as e
inner join retail_events_db.dim_products as p
on e.product_code = p.product_code
join retail_events_db.dim_campaigns as c
on c.campaign_id = e.campaign_id
where campaign_name ="Diwali"
group by category
order by rank_order;

#5. Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
# The report will provide essential information including product name, category, and ir%. This analysis helps identify the most successful 
# products in terms of incremental revenue across our campaigns, assisting in product optimization.

select product_name, category, 
round(((sum(base_price * quantity_sold_after_promo) - sum(base_price * quantity_sold_before_promo))/ sum(base_price * quantity_sold_before_promo))*100,2) as IRP
from retail_events_db.fact_events as e
inner join retail_events_db.dim_products as p
on e.product_code = p.product_code
inner join retail_events_db.dim_campaigns as c
on e.campaign_id = c.campaign_id
group by product_name, category
order by IRP DESC
limit 5