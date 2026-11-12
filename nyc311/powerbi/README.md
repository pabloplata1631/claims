# Report implementation (planned)

Pages: Overview, Demand & Closure Trends, Open Request Aging, Data Quality.

Design: restrained navy/teal theme, clear page titles, consistent filters,
accessible contrast, last successful load timestamp, cohort scope on every page,
metric definitions in tooltips, and drillthrough to supporting request records.
Do not rank unlike agencies by speed without controlling for problem category.

Save as a Power BI Project (PBIP) from Power BI Desktop so report and semantic
model definitions can be reviewed in Git. Desktop performs the conversion; a
renamed PBIX file is not a PBIP project. Ignore local caches and credentials.

Parameters: SQL server and database. Import analytics views only, using a
least-privilege reporting identity. Use environment-specific database bindings.
Local SQL Server refresh from the service will require an appropriate gateway.

Workspaces: NYC311-DEV, NYC311-UAT, NYC311-PROD, subject to actual license/capacity
and tenant permissions. Update the app after production validation; deployment
is not evidence that app content or scheduled refresh is already current.
