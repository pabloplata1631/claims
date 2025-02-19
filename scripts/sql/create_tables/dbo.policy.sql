
Drop table if exists dbo.policy;
Create table  dbo.policy (	
    [policy_number] [smallint] NOT NULL,
	[policy_deductible] [float] NOT NULL,
	[policy_amount] [float] NOT NULL,
	[start_date] [date] NOT NULL,
	[end_date] [date]NOT NULL,
	[policy_type] [nvarchar](50) NOT NULL,
	[customer_id] [bigint] NOT NULL,
	[first_name] [nvarchar](50) NOT NULL,
	[last_name] [nvarchar](50) NOT NULL
)
;



with policy_cte AS (
    SELECT    
    cast(policy_number as smallint) as policy_number,
	cast(policy_deductible as float) as policy_deductible,
	cast(policy_amount as float) as policy_amount,
    cast(start_date as date) as start_date,
	cast(end_date as datetime2) as end_date,
	policy_type,
	cast(customer_id as bigint) as customer_id,
	first as first_name,
	last as last_name
    FROM test_db.analytics.policies

)
INSERT INTO dbo.policy
SELECT * FROM policy_cte;
