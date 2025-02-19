
Drop table if exists dbo.customers;
Create table  dbo.customers (
    customer_id BIGINT , 
    first_name VARCHAR(50), 
    last_name VARCHAR(50),
    city VARCHAR(50), 
    address VARCHAR(50), 
    state VARCHAR(50),
    PRIMARY KEY (customer_id)
)
;

with customers_cte AS (
    select 
   customers.*
    FROM test_db.analytics.customers

)
INSERT INTO dbo.customers
SELECT * FROM customers_cte;
