Drop table if exists dbo.employess;
Create table  dbo.employess (
    employee_id int , 
    first_name VARCHAR(50), 
    last_name VARCHAR(50),
    middle_name VARCHAR(50),
    department VARCHAR(50),
    title VARCHAR(50),
    login_id VARCHAR(50),
    PRIMARY KEY (employee_id)
)
;

with employees_cte AS (
    select
    cast(employee_id as int) as employee_id, 
    first_name, 
    last_name,
    middle_name,
    department,
    title,
    login_id
    FROM test_db.analytics.employees

)
INSERT INTO dbo.employess
SELECT * FROM employees_cte;