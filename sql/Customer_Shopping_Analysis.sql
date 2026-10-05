
CREATE DATABASE customer_shopping_analysis;
USE customer_shopping_analysis;

SELECT * FROM customer;


-- Q1: Which product categories have an average purchase amount above the overall average?
SELECT category, ROUND(AVG(purchase_amount), 2) AS avg_purchase,
ROUND(AVG(purchase_amount) - (SELECT AVG(purchase_amount) FROM customer), 2) AS difference
FROM customer
GROUP BY category
HAVING AVG(purchase_amount) > (SELECT AVG(purchase_amount) FROM customer)
ORDER BY difference DESC;


-- Q2: Which age groups spend more on average than the overall average?
SELECT age_group, COUNT(*) AS total_customers,
ROUND(AVG(purchase_amount), 2) AS avg_purchase,
ROUND(AVG(purchase_amount) - (SELECT AVG(purchase_amount) FROM customer), 2) AS difference
FROM customer
GROUP BY age_group
HAVING AVG(purchase_amount) > (SELECT AVG(purchase_amount) FROM customer)
ORDER BY difference DESC;


-- Q3: Which payment methods have an average purchase amount above the overall average, with at least 400 records?
SELECT payment_method, COUNT(*) AS total_records,
ROUND(AVG(purchase_amount), 2) AS avg_purchase
FROM customer
GROUP BY payment_method
HAVING COUNT(*) >= 400
AND AVG(purchase_amount) > (SELECT AVG(purchase_amount) FROM customer)
ORDER BY avg_purchase DESC;


-- Q4: Which product categories have the highest average purchase amount within each age group?
WITH category_analysis AS (
SELECT age_group, category, AVG(purchase_amount) AS avg_purchase,
RANK() OVER(PARTITION BY age_group ORDER BY AVG(purchase_amount) DESC) AS category_rank
FROM customer
GROUP BY age_group, category
)
SELECT age_group, category, ROUND(avg_purchase, 2) AS avg_purchase
FROM category_analysis
WHERE category_rank = 1
ORDER BY age_group;


-- Q5: Which customers spend more than their age group's average purchase amount?
WITH customer_analysis AS (
SELECT customer_id, age_group, category, purchase_amount,
AVG(purchase_amount) OVER(PARTITION BY age_group) AS group_avg
FROM customer
)
SELECT customer_id, age_group, category, purchase_amount,
ROUND(group_avg, 2) AS group_average,
ROUND(purchase_amount - group_avg, 2) AS difference
FROM customer_analysis
WHERE purchase_amount > group_avg
ORDER BY difference DESC;


-- Q6: Which categories show the largest average spending difference between subscribers and non-subscribers?
SELECT category,
ROUND(AVG(CASE WHEN subscription_status = 'Yes' THEN purchase_amount END), 2) AS subscriber_avg,
ROUND(AVG(CASE WHEN subscription_status = 'No' THEN purchase_amount END), 2) AS non_subscriber_avg,
ROUND(AVG(CASE WHEN subscription_status = 'Yes' THEN purchase_amount END) -
AVG(CASE WHEN subscription_status = 'No' THEN purchase_amount END), 2) AS difference
FROM customer
GROUP BY category
ORDER BY ABS(AVG(CASE WHEN subscription_status = 'Yes' THEN purchase_amount END) -
AVG(CASE WHEN subscription_status = 'No' THEN purchase_amount END)) DESC;


-- Q7: How are customers distributed across previous-purchase ranges?
SELECT
CASE
WHEN previous_purchases BETWEEN 1 AND 5 THEN '1-5 Purchases'
WHEN previous_purchases BETWEEN 6 AND 10 THEN '6-10 Purchases'
WHEN previous_purchases BETWEEN 11 AND 20 THEN '11-20 Purchases'
WHEN previous_purchases > 20 THEN 'Above 20 Purchases'
ELSE 'Other'
END AS purchase_group,
COUNT(*) AS total_customers
FROM customer
GROUP BY purchase_group
ORDER BY total_customers DESC;


-- Q8: Which three products have the highest average review ratings?
SELECT item_purchased, COUNT(review_rating) AS total_reviews,
ROUND(AVG(review_rating), 2) AS avg_rating
FROM customer
GROUP BY item_purchased
HAVING COUNT(review_rating) > 0
ORDER BY avg_rating DESC
LIMIT 3;


-- Q9: Which three products have the most customer records within each category?
WITH item_counts AS (
SELECT category, item_purchased, COUNT(*) AS total_records,
ROW_NUMBER() OVER(PARTITION BY category ORDER BY COUNT(*) DESC, item_purchased) AS item_rank
FROM customer
GROUP BY category, item_purchased
)
SELECT category, item_purchased, total_records, item_rank
FROM item_counts
WHERE item_rank <= 3
ORDER BY category, item_rank;


-- Q10: How does average purchase amount differ between customers who used discounts and those who did not?
SELECT category,
ROUND(AVG(CASE WHEN discount_applied = 'Yes' THEN purchase_amount END), 2) AS discounted_avg,
ROUND(AVG(CASE WHEN discount_applied = 'No' THEN purchase_amount END), 2) AS non_discounted_avg,
ROUND(AVG(CASE WHEN discount_applied = 'Yes' THEN purchase_amount END) -
AVG(CASE WHEN discount_applied = 'No' THEN purchase_amount END), 2) AS difference,
ROUND((AVG(CASE WHEN discount_applied = 'Yes' THEN purchase_amount END) -
AVG(CASE WHEN discount_applied = 'No' THEN purchase_amount END)) /
NULLIF(AVG(CASE WHEN discount_applied = 'No' THEN purchase_amount END), 0) * 100, 2) AS percentage_difference
FROM customer
GROUP BY category
ORDER BY percentage_difference DESC;

