-- Daily updates/refresh

-- We currently have 66 transactions in ZAGI database currently
-- Daily, we want to add 2 transactions. We want to ETL only those 2 transactions

-- Add two more columns in the data staging fact table
-- One for when the new entries are and one for if the facts have been loaded into the DW
ALTER TABLE Revenue_Fact ADD ExtractionTimestamp TIMESTAMP, ADD f_loaded BOOLEAN;

-- Now we have to fill these columns since the data staging has the initial load
UPDATE Revenue_Fact SET f_loaded = TRUE;
UPDATE Revenue_Fact SET ExtractionTimestamp = NOW(); --today, this minute and hour

-- The point of this is to distinguish between new and old facts
-- You do not do this in the DW, only in the data staging phase

-- Creating new facts!!
-- In class, we insert the new transactions using the insert field on phpMyAdmin into the database
-- Insert with today's date, this is very important so the daily load ETL makes sense
INSERT INTO salestransaction (tid, customerid, storeid, tdate) VALUES ('321', '1-2-333', 'S1', '2025-03-29');
INSERT INTO soldvia (productid, tid, noofitems) VALUES ('2X4', '321', '3');
INSERT INTO soldvia (productid, tid, noofitems) VALUES ('3X1', '321', '6');
INSERT INTO rentaltransaction (tid, customerid, storeid, tdate) VALUES ('543', '3-4-555', 'S3', '2025-03-29');
INSERT INTO rentvia (productid, tid, rentaltype, duration) VALUES ('3X3', '543', 'D', '5');
INSERT INTO rentvia (productid, tid, rentaltype, duration) VALUES ('4X4', '543', 'W', '7');

-- Whenever the ETL process' time is, it'll check the database for transactions that happened today
-- Usually when people don't use the system
-- We have 70 records in the database but 66 in the warehouse, so we need to add the new 4
-- No need to add the 66 again, that's redundant

-- Extract new facts into data staging, only the ones that happened since the most recent extraction
-- this is old code for making the intermediate table to the revenue fact table
DROP TABLE IntTable;
CREATE TABLE IntTable AS
SELECT sv.noofitems*p.productprice AS RevAmount, sv.tid, 'sales' AS RevenueType, st.customerid AS CustomerID, st.storeid AS StoreID, p.productid AS ProductID, st.tdate AS CalendarDate
FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p, mihuynh_ZAGImore.salestransaction st
WHERE sv.productid = p.productid AND sv.tid = st.tid ;


-- in the rev fact table, we can use MAX(date) to get the last update date
SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact;
-- since ExtractionTimestamp is timestamp data type

DROP TABLE IntTable;
CREATE TABLE IntTable AS
SELECT sv.noofitems*p.productprice AS RevAmount, sv.tid, 'sales' AS RevenueType, st.customerid AS CustomerID, st.storeid AS StoreID, p.productid AS ProductID, st.tdate AS CalendarDate
FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p, mihuynh_ZAGImore.salestransaction st
WHERE sv.productid = p.productid AND sv.tid = st.tid 
AND st.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact);

-- Change the data type of RevenueType since the varchar only allows 5 letters while rental is 6 letters
ALTER TABLE IntTable
MODIFY RevenueType VARCHAR(24);

-- loads the 2 sold items, we have 2 more rental items to add:
-- daily rentals
INSERT INTO IntTable (RevAmount, tid, RevenueType, CustomerID, StoreID, ProductID, CalendarDate)

SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, daily' AS RevenueType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'D'
-- with the new date condition
AND rt.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact);

-- weekly rentals
INSERT INTO IntTable (RevAmount, tid, RevenueType, CustomerID, StoreID, ProductID, CalendarDate)

SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, weekly' AS RevenueType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'W'
-- with the new date condition
AND rt.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact)

-- But this is inconvenient because you may have to run stuff individually
-- we can use union to help, union only works with select statements

-- Start
DROP TABLE IntTable;
CREATE TABLE IntTable AS
SELECT sv.noofitems*p.productprice AS RevAmount, sv.tid, 'sales' AS RevenueType, st.customerid AS CustomerID, st.storeid AS StoreID, p.productid AS ProductID, st.tdate AS CalendarDate
FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p, mihuynh_ZAGImore.salestransaction st
WHERE sv.productid = p.productid AND sv.tid = st.tid 
AND st.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact)
UNION
SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, daily' AS RevenueType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'D'
-- with the new date condition
AND rt.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact)
UNION
SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, weekly' AS RevenueType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'W'
-- with the new date condition
AND rt.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact);
-- End


-- Now that we have our int table, let's populate the fact table with ExtractionTimeStamp ANDDD f_loaded
INSERT INTO Revenue_Fact (TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType, ExtractionTimeStamp, f_loaded)
SELECT i.tid, i.RevAmount, p.ProductKey, c.CustKey, cld.CalendarKey, s.StoreKey, i.RevenueType, NOW(), FALSE
FROM IntTable i, Product_Dimension p, Customer_Dimension c, Calendar_Dimension cld, Store_Dimension s
WHERE c.CustomerID = i.CustomerID AND p.ProductID = i.ProductID AND s.StoreID = i.StoreID AND UPPER(LEFT(p.ProductType, 1)) = UPPER(LEFT(i.RevenueType, 1)) AND i.CalendarDate = cld.FullDate

-- Has the illegal collation mixing error/data type error with Product Type and Revenue Type '=' comparison
-- Fix with:
ALTER TABLE `IntTable` CHANGE `RevenueType` `RevenueType` VARCHAR(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL; 

-- This is going to speed up the process by comparing the first letter of both (r for rental, s for sales)
UPPER(LEFT(p.ProductType, 1)) = UPPER(LEFT(i.RevenueType, 1))
-- You may need to troubleshoot this comparison due to the data type.

-- so now we have 70 inside the data staging
-- Load all new facts into data warehouse
INSERT INTO mihuynh_ZAGImoreDW.Revenue_Fact (TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType)
SELECT TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType
FROM Revenue_Fact 
WHERE f_loaded = FALSE

-- Now to make sure we never have duplicates:
UPDATE Revenue_Fact
SET f_loaded = TRUE
WHERE f_loaded = FALSE
