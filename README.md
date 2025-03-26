# ZAGI Data Warehouse ETL
A tutorial-like transformation of the ZAGI relational database into a data warehouse using an ETL (Extract, Transform, Load) pipeline for analytics in phpMyAdmin.

# Contents
ZAGI DW 0 creation code.sql: Code for creating the data staging phase and data warehouse.<br/>
ZAGI DW ETL 1 Populating a dimension.sql: An example of how dimensions are created with incremental keys, they are not populated yet.<br/>
ZAGI DW ETL 2 Loops.sql: Includes an example of the population of a dimension in the data staging phase and population of the Calendar dimension using proceedure with a loop.<br/>
ZAGI DW ETL 3 Multiple Sources.sql: Inserting into a dimension that comes from multiple relations from the ZAGI database (rental and sales products).<br/>
ZAGI DW ETL 4 Fact table for sales product.sql: Creation and population of the fact table for sales transactions only.<br/>
ZAGI DQ ETL 5 Fact table for rental products.sql: Population of the fact table for rental products only.<br/>
ZAGI DW ETL 6 Post Load snapshots and aggregates.sql: Creation and population of aggregate fact tables and snapshot tables with supplementary dimensions.<br/>
ZAGI DW 7 Daily refresh ETL.sql: Example code for ETL pipeline for daily refreshes of new records.
