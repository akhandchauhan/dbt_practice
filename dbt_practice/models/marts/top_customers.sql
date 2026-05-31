SELECT 
    c.id,
    c.first_name,
    c.last_name,
    SUM(p.amount) / 100 AS lifetime_spend_usd
FROM {{ ref('raw_customers') }} AS c
JOIN {{ ref('raw_orders') }} AS o 
    ON c.id = o.user_id
JOIN {{ ref('raw_payments') }} AS p
    ON p.order_id = o.id
GROUP BY 
    c.id,
    c.first_name,
    c.last_name
ORDER BY SUM(p.amount) / 100 DESC
LIMIT 10