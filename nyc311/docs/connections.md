# Connection checklist

## GitHub

Connect the GitHub integration and authorize access to `pabloplata1631/claims`.
The foundation work uses branch `feature/nyc311-foundation`.
The original claims files remain in place. The user's Windows checkout is a
different filesystem from this working copy and needs a fetch and checkout after publication.

## SQL Server / SSMS

Confirm server/instance name, target database, SQL Server version/edition, and
whether Windows authentication is used. A screenshot is enough for non-secret
settings; never send passwords or tokens in chat. The screenshot previously
showed `test_db`; do not assume it is still the intended target.

No direct connection to the user's desktop SQL Server is established. SQL and
Python can run on the Windows machine that already reaches it. Keep connection
strings in environment variables and use an appropriate installed ODBC driver.
Do not expose a database to the public internet simply to connect this project.

## Power BI / Fabric

Connect the Microsoft Power BI integration. Inspect actual workspace access,
license/capacity, and tenant restrictions before choosing promotion features.
Azure access alone does not establish Fabric capacity or Power BI licensing.
Confirm Desktop availability and export/save report source as PBIP where supported.
For cloud refresh from local SQL Server, configure and test the on-premises gateway.

## First environment details needed

1. Exact local Windows path of the repository (for commands to run there).
2. SQL Server instance and chosen database; Windows versus SQL authentication.
3. Power BI workspace URL and license/capacity if available.

This checklist requests configuration, not credentials. Connecting GitHub or
Power BI does not automatically authorize or establish a SQL Server connection.
