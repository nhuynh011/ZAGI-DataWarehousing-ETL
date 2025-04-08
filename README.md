# ZAGI Data Warehouse ETL
A tutorial-like transformation of the ZAGI relational database into a data warehouse using an ETL (Extract, Transform, Load) pipeline for analytics in MySQL.

# Contents
Data warehouse creation:<br/>
ZAGI DW 0 creation code.sql: Code for creating the data staging phase and data warehouse.<br/><br/>
Initial load for data warehouse:<br/>
ZAGI DW ETL 1 Populating a dimension.sql: An example of how dimensions are created with incremental keys, they are not populated yet.<br/>
ZAGI DW ETL 2 Loops.sql: Includes an example of the population of a dimension in the data staging phase and population of the Calendar dimension using proceedure with a loop.<br/>
ZAGI DW ETL 3 Multiple Sources.sql: Inserting into a dimension that comes from multiple relations from the ZAGI database (rental and sales products).<br/>
ZAGI DW ETL 4 Fact table for sales product.sql: Creation and population of the fact table for sales transactions only.<br/>
ZAGI DQ ETL 5 Fact table for rental products.sql: Population of the fact table for rental products only.<br/><br/>
Snapshots and aggregates for data warehouse:<br/>
ZAGI DW ETL 6 Post Load snapshots and aggregates.sql: Creation and population of aggregate fact tables and snapshot tables with supplementary dimensions.<br/><br/>
Updates, refreshes for data warehouse:<br/>
ZAGI DW 7 Daily refresh ETL.sql: Example code for ETL pipeline for daily refreshes of new records.<br/>
ZAGI DW 7.5 Daily Refresh Proceedure.sql: The daily refresh queries, packed into a proceedure for easy implimentation.<br/>
ZAGI DW 8 Late Arriving Facts Refresh.sql: A procedure for late arriving facts that were not updated on time. <br/>
ZAGI DW 9 Updating Dimensions.sql: A proceedure for updating dimensions when there is a new record in the database.<br/>
