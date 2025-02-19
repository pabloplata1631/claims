
---ARCHIVING Table
INSERT INTO archive.reporting_claim_v01
select
    CURRENT_TIMESTAMP as_of_date,
    rc.*
from dbo.reporting_claim rc;
---
-----
-----
---
drop table if exists dbo.reporting_claim;

with
    customer_number_of_claims
    as
    (
        select customer_id,
            Case when count(customer_id) > 1 
    then count(customer_id) 
    else count(customer_id) 
    end as customer_number_of_claims
        from claims
        group by customer_id
    )
select
    cnc.customer_number_of_claims,
    c.claim_number,
    c.statu_code as status_code,
    case when c.statu_code = 'R1' 
                    then 'Rejected'
                    when c.statu_code = 'DR07' 
                    then 'Received'
                    when c.statu_code = 'F1' 
                    then 'Paid Out'
                    when c.statu_code = 'F2' 
                    then 'Information Requested'
                    when c.statu_code = 'A2' 
                    then 'Pending'
                    when c.statu_code = 'P1' 
                    then 'Approved'
                    END as claim_status,
    c.customer_id,
    c.incident_date as claim_date,
    c.incident_city as claim_city,
    c.incident_state as claim_state,
    c.total_claim_amount as claim_amount,
    cust.first as client_first_name,
    cust.last as client_last_name,
    cust.address as client_address,
    cust.city as client_city,
    cust.state as client_state,
    p.policy_deductible,
    p.policy_amount,
    p.start_date as policy_start_date,
    p.end_date as policy_end_date,
    p.policy_type,
    e.first_name as agents_first_name,
    e.last_name as agents_last_name
into dbo.reporting_claim
from dbo.claims c
    left join customer_number_of_claims cnc on c.customer_id = cnc.customer_id
    left join (select distinct *
    from customers) cust ON c.customer_id = cust.customer_id
    left join (select distinct *
    from policy) p ON c.customer_id = p.customer_id
    left join (select distinct *
    from employees) e on c.employee_id = e.employee_id
;



