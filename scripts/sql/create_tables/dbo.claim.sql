Drop table if exists dbo.claims;
Create table  dbo.claims (
    [customer_id] [bigint] NOT NULL,
	[first_name] [nvarchar](50) NOT NULL,
	[last_name] [nvarchar](50) NOT NULL,
	[age] [tinyint] NOT NULL,
	[policy_number] [int] NOT NULL,
	[policy_bind_date] [date] NOT NULL,
	[policy_state] [nvarchar](50) NOT NULL,
	[policy_csl] [nvarchar](50) NOT NULL,
	[policy_deductable] [smallint] NOT NULL,
	[policy_annual_premium] [float] NOT NULL,
	[umbrella_limit] [int] NOT NULL,
	[insured_zip] [int] NOT NULL,
	[insured_sex] [nvarchar](50) NOT NULL,
	[insured_education_level] [nvarchar](50) NOT NULL,
	[insured_occupation] [nvarchar](50) NOT NULL,
	[insured_hobbies] [nvarchar](50) NOT NULL,
	[insured_relationship] [nvarchar](50) NOT NULL,
	[capital_gains] [int] NOT NULL,
	[capital_loss] [int] NOT NULL,
	[incident_date] [date] NOT NULL,
	[incident_type] [nvarchar](50) NOT NULL,
	[collision_type] [nvarchar](50) NOT NULL,
	[incident_severity] [nvarchar](50) NOT NULL,
	[authorities_contacted] [nvarchar](50) NOT NULL,
	[incident_state] [nvarchar](50) NOT NULL,
	[incident_city] [nvarchar](50) NOT NULL,
	[employee_id] [int] NOT NULL
)
;



with claims_cte AS (
    SELECT
    cast(customer_id AS BIGINT) AS customer_id, 
	first as first_name,
	last as last_name,
	cast(age AS TINYINT) as age,
    cast(policy_number AS INT) AS policy_number,
    cast(policy_bind_date AS DATE) AS policy_bind_date,
	policy_state,
	policy_csl,
	policy_deductable,
	policy_annual_premium,
	umbrella_limit,
	insured_zip,
	insured_sex,
	insured_education_level,
	insured_occupation,
	insured_hobbies,
	insured_relationship,
	cast(capital_gains AS INT) as capital_gains,
    cast(capital_loss AS INT) as capital_loss,
    cast(incident_date AS date) as incident_date,
	incident_type,
	collision_type,
	incident_severity,
	authorities_contacted,
	incident_state,
	incident_city,
	cast(employee_id as int) as employee_id 
    
    FROM test_db.analytics.insurance_claims

)	
INSERT INTO dbo.claims
SELECT * FROM claims_cte;
