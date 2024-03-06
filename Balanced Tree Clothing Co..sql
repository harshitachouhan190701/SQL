use balanced_tree;
show tables;
select * from product_details;
select * from sales;
select * from product_hierarchy;
select * from product_prices;


# What was the total quantity sold for all products?
select sum(qty) as total_qty_Sold
from sales;
select p.product_name, sum(s.qty) as quantity_sold
from product_details p
join sales s on
p.product_id = s.prod_id
group by product_name
order by product_name;

# What is the total generated revenue for all products before discounts?

select sum(qty * price) as total_revenue
from sales;

# What was the total discount amount for all products?
select sum(discount) as total_discount
from sales;

# How many unique transactions were there?
select count( distinct txn_id) as unique_transaction
from sales;

# What is the average unique products purchased in each transaction?
select sum(qty)/count(distinct txn_id) as avg_unique_txn
from sales;

# What are the 25th, 50th and 75th percentile values for the revenue per transaction?
SELECT
  txn_id,
  ROUND(PERCENT_RANK() OVER (ORDER BY revenue_per_transaction), 2) AS PCT_Rank,
  revenue_per_transaction
FROM (
  SELECT txn_id, SUM(qty * price) AS revenue_per_transaction
  FROM balanced_tree.sales
  GROUP BY txn_id
) AS transaction_revenues;

select * from Sales;

with cte as 
( select txn_id, qty, price, (price*qty) as Revenue, ROUND(PERCENT_RANK() OVER (ORDER BY (qty*price)),2) As PCT_Rank
	from sales
)

select  txn_id, qty, price, (price*qty) as Revenue, ROUND(PERCENT_RANK() OVER (ORDER BY (qty*price)),2) as PCT_Rank
from cte
where PCT_Rank = 0.2
;

# What is the average discount value per transaction?
select txn_id, avg(discount) as avg_disc_per_transaction
from sales
group by txn_id;

# What is the percentage split of all transactions for members vs non-members?
select * from sales;

select member,
count(member),
(count(member) * 100) / (select count(*) from sales) as PCT_Split
from sales
group by member;

# What is the average revenue for member transactions and non-member transactions?
select member, avg(qty * price) as avg_revenue
from sales
group by member;

# What are the top 3 products by total revenue before discount?
with ProductRevenue as (
select s.prod_id,
sum(s.qty * s.price) as revenue,
dense_rank () over (order by (s.qty * s.price) desc) as revenue_rank
from sales s
group by s.prod_id
)
select  p.product_name, pr.revenue, pr.revenue_rank
from ProductRevenue pr join 
product_details p on 
pr.prod_id = product_id
order by pr.revenue_rank
limit 3;

# What is the total quantity, revenue and discount for each segment?

select p.segment_name,
 sum(s.qty) as total_qunatity, 
 sum(s.qty * s.price) as total_revenue,
 s.discount as discount
 from sales s 
 join product_details p
 on prod_id = product_id
 group by segment_name
 order by segment_name;

# What is the top selling product for each segment
select segment_name as segment,
product_name as top_Selling_products,
total_quantity
from (
select p.segment_name, 
p.product_name,
sum(s.qty)as total_quantity,
row_number() over(partition by p.segment_id order by sum(s.qty) desc)as rnk
from product_details p
join sales s
on product_id = prod_id
group by p.product_name,p.segment_name)
as rnked_prodcuts
where rnk = 1;

# What is the top selling product for each category?
select category, 
top_selling_product,
total_quantity
from (
select p.category_name as category,
p.product_name as top_selling_product,
sum(s.qty) as total_quantity,
row_number() over (partition by category_id order by sum(s.qty)) as rnk
from product_details p
join sales s
on product_id = prod_id
group by category_name, product_name) as Ranked_products
where rnk = 1
;

# What is the percentage split of revenue by product for each segment?
select * from sales;
select * from product_details;


select p.segment_name as segment,
p.product_name as product,
sum(s.qty * s.price) as revenue,
(sum(s.qty * s.price) / sum(sum(s.qty * s.price)) over (partition by p.segment_name)) * 100 as revenue_pct
from sales s
join product_details p
on product_id = prod_id
group by segment_name, product_name;

# What is the percentage split of revenue by segment for each category?
select p.category_name as category,
p.segment_name as segment,
sum(s.qty * s.price) as revenue,
sum(s.qty * s.price)/sum(sum(s.qty * s.price)) over (partition by p.category_name) * 100 as revenue_pct
from product_details p
join sales s
on product_id = prod_id
group by category_name, segment_name;

# What is the percentage split of total revenue by category?

select 
p.category_name as category,
sum(s.qty * s.price) as revenue,
sum(s.qty * s.price) / sum(sum(s.qty * s.price)) over () * 100 as revenue_pct
from 
product_details p
join sales s 
on product_id = prod_id
group by category_name;

# What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
select p.product_name,
count(distinct case when qty > 0 then s.txn_id end) * count(distinct s.txn_id) as penetration
from sales s
join product_details p
on product_id = product_id
group by p.product_name;

# What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

WITH TransactionProducts AS (
    SELECT DISTINCT txn_id, prod_id
    FROM balanced_tree.sales
    WHERE qty > 0
),
TransactionProductCounts AS (
    SELECT txn_id, COUNT(*) AS product_count
    FROM TransactionProducts
    GROUP BY txn_id
    HAVING COUNT(*) >= 3
)
SELECT t1.prod_id AS product_1, t2.prod_id AS product_2, t3.prod_id AS product_3, COUNT(*) AS transaction_count
FROM TransactionProducts t1
JOIN TransactionProducts t2 ON t1.txn_id = t2.txn_id AND t1.prod_id < t2.prod_id
JOIN TransactionProducts t3 ON t1.txn_id = t3.txn_id AND t2.txn_id = t3.txn_id AND t2.prod_id < t3.prod_id
JOIN TransactionProductCounts tp ON t1.txn_id = tp.txn_id
GROUP BY t1.prod_id, t2.prod_id, t3.prod_id
ORDER BY transaction_count DESC
LIMIT 1;



