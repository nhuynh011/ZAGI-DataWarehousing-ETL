-- Aggregates by SQL querying


-- Snapshots, can have random stuff, like total number of footware
-- These joins are a little more abnormal in terms of a dw
-- With snapshots you can make a lot of derived facts.

-- For frequently used tables.
-- For snapshots, aggregates, and custom/core facts, we may need to make some additional tables.

-- for a one way aggregate table to the category
CREATE TABLE ProductCategoryDimension AS
SELECT DISTINCT CategoryID, CategoryName
FROM Product_Dimension

ALTER TABLE ProductCategoryDimension
ADD COLUMN CategoryKey INT AUTO_INCREMENT PRIMARY KEY
-- for the surrogate key

-- Now we test the aggregate with a select:
SELECT SUM(r.RevAmount) AS TotalAmount, r.CustKey, r.CalendarKey, r.StoreKey, pcd.CategoryKey 
FROM Revenue_Fact r, ProductCategoryDimension pcd, Product_Dimension pd
WHERE r.ProductKey = pd.ProductKey AND pd.CategoryID = pcd.CategoryID
GROUP BY r.CustKey, r.CalendarKey, r.StoreKey, pcd.CategoryKey

-- create primary keys
CREATE TABLE OneWayAggregateBYCat AS
SELECT SUM(r.RevAmount) AS TotalAmount, r.CustKey, r.CalendarKey, r.StoreKey, pcd.CategoryKey 
FROM Revenue_Fact r, ProductCategoryDimension pcd, Product_Dimension pd
WHERE r.ProductKey = pd.ProductKey AND pd.CategoryID = pcd.CategoryID
GROUP BY r.CustKey, r.CalendarKey, r.StoreKey, pcd.CategoryKey;

ALTER TABLE OneWayAggregateBYCat
ADD PRIMARY KEY(CustKey, CalendarKey, StoreKey, CategoryKey);

-- I have 51 rows here

-- Usually when you copy tables, you can create table as select.
CREATE TABLE mihuynh_ZAGImoreDW.ProductCategoryDimension AS
SELECT * FROM ProductCategoryDimension
-- This is useful for moving things from the data staging to data warehousing phase
-- In this case, you also have to be aware of the structure of each column, so be careful when adding new data
-- The column types will be the same, but their lengths may change

-- Let's do a snapshot!
-- daily store snapshot
SELECT SUM(r.RevAmount) AS TotalAmount, COUNT(DISTINCT TransactionID) AS TotalTransactions, AVG(r.RevAmount) AS AverageRevenue, r.StoreKey, r.CalendarKey
FROM Revenue_Fact r 
GROUP BY r.StoreKey, r.CalendarKey
--gives me 23 days
-- now that it works, I can
CREATE TABLE DailyStoreSnapShot AS
SELECT SUM(r.RevAmount) AS TotalAmount, COUNT(DISTINCT TransactionID) AS TotalTransactions, AVG(r.RevAmount) AS AverageRevenue, r.StoreKey, r.CalendarKey
FROM Revenue_Fact r 
GROUP BY r.StoreKey, r.CalendarKey
-- misc adjustments to the data types
ALTER TABLE DailyStoreSnapShot CHANGE AverageRevenue AverageRevenue DECIMAL(13,2);
ALTER TABLE DailyStoreSnapShot ADD PRIMARY KEY(CalendarKey, StoreKey);

-- All of these steps should be done in data staging first, then you can move to the warehouse after.
-- Warehouse should be a read-only, you want to minimize write operations as much as possible.

-- You also have to connect all foreign keys in the data warehouse.
ALTER TABLE OneWayAggregateBYCat
ADD FOREIGN KEY (StoreKey) REFERENCES Store_Dimension(StoreKey);
ALTER TABLE OneWayAggregateBYCat
ADD FOREIGN KEY (CalendarKey) REFERENCES Calendar_Dimension(CalendarKey);
ALTER TABLE OneWayAggregateBYCat
ADD FOREIGN KEY (CustKey) REFERENCES Customer_Dimension(CustKey);
ALTER TABLE OneWayAggregateBYCat
ADD FOREIGN KEY (CategoryKey) REFERENCES ProductCategoryDimension(CategoryKey);

-- Footwear aggregation table:
SELECT SUM(rf.RevAmount) AS TotalFootwearRevenue, rf.StoreKey, rf.CalendarKey
FROM Revenue_Fact rf, Product_Dimension p WHERE
p.CategoryName = "Footwear" AND rf.ProductKey = p.ProductKey
GROUP BY rf.StoreKey, rf.CalendarKey

--gives me 12 rows
-- since i am using sum, i need group by statements

CREATE TABLE FootwearRevenue AS
SELECT SUM(rf.RevAmount) AS TotalFootwearRevenue, rf.StoreKey, rf.CalendarKey
FROM Revenue_Fact rf, Product_Dimension p WHERE
p.CategoryName = "Footwear" AND rf.ProductKey = p.ProductKey
GROUP BY rf.StoreKey, rf.CalendarKey

-- Alter table for daily snapshot to include more information, you can run this mostly anywhere
ALTER TABLE DailyStoreSnapShot ADD COLUMN TotalFootwearRevenue INT DEFAULT 0

-- In the above statement, we only set the whole column to 0
-- We actually need to set items to the value we found
UPDATE  DailyStoreSnapShot ds, FootwearRevenue f
SET ds.TotalFootwearRevenue = f.TotalFootwearRevenue
WHERE ds.CalendarKey = f.CalendarKey AND ds.StoreKey = f.StoreKey

-- and 12 rows affected is the right amount of rows.

-- Creating a high value transaction table, for transactions above 100 dollars
CREATE TABLE HighValueTransactions AS
SELECT COUNT(DISTINCT(r.TransactionID)) AS HighValueTransactionCount, r.CalendarKey, r.StoreKey
FROM Revenue_Fact r
WHERE r.RevAmount > 100
GROUP BY r.CalendarKey, r.StoreKey

-- 14 entries
-- Let's add this to the daily store snapshot:
ALTER TABLE DailyStoreSnapShot
ADD COLUMN NumberofHVTrans INT DEFAULT 0;

UPDATE  DailyStoreSnapShot ds, HighValueTransactions h
SET ds.NumberofHVTrans = h.HighValueTransactionCount
WHERE h.CalendarKey = ds.CalendarKey AND h.StoreKey = ds.StoreKey;

-- Let's make a local revenue table using the zip codes of store and customer
-- does it make sense to use both?
-- In this example, if the first 2 characters/numbers of the zip code are the same, then the customer is considered a local
CREATE TABLE LocalRevenue AS
SELECT SUM(r.RevAmount) AS TotalLocalRevenue, r.StoreKey, r.CalendarKey, s.StoreZip
FROM Revenue_Fact r, Customer_Dimension c, Store_Dimension s
WHERE r.StoreKey = s.StoreKey AND r.CustKey = c.CustKey AND LEFT(s.StoreZip, 2) = LEFT(c.CustomerZIP,2)
GROUP BY r.CalendarKey, r.StoreKey

-- Now add this into the daily snapshot as well:
ALTER TABLE DailyStoreSnapShot
ADD COLUMN LocalTransactions INT DEFAULT 0;

UPDATE  DailyStoreSnapShot ds, LocalRevenue l
SET ds.LocalTransactions = l.TotalLocalRevenue
WHERE l.CalendarKey = ds.CalendarKey AND l.StoreKey = ds.StoreKey;

-- Now we have to move this revenue fact table into the warehouse since we are doing all of this in the data staging phase.
DROP TABLE mihuynh_ZAGImoreDW.DailyStoreSnapShot;
CREATE TABLE mihuynh_ZAGImoreDW.DailyStoreSnapShot AS
SELECT * FROM DailyStoreSnapShot;

-- Now I need to connect the store and calendar key again.
ALTER TABLE DailyStoreSnapShot
ADD FOREIGN KEY (StoreKey) REFERENCES Store_Dimension(StoreKey);
ALTER TABLE DailyStoreSnapShot
ADD FOREIGN KEY (CalendarKey) REFERENCES Calendar_Dimension(CalendarKey);

ALTER TABLE DailyStoreSnapShot ADD PRIMARY KEY(CalendarKey, StoreKey)
