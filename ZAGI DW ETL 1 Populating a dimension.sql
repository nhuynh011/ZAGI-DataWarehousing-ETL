-- Extract from database customer relations

-- The dimension has already been made in ZAGI 0, this is the structure of it:

--CREATE TABLE Customer_Dimension(
--    CustomerKey int NOT NULL AUTO_INCREMENT,
--    CustomerID VARCHAR(7) NOT NULL,
--    CustomerName VARCHAR(255),
--    CustomerZip VARCHAR(6),
--    PRIMARY KEY (CustomerKey)
--);

-- This code runs in data staging, but it selects from a table in another database.
-- Table name needs to be preceeded with the database name:
SELECT customerid, customername, customerzip
FROM mihuynh_ZAGImore.customer

-- Sometimes our data will not be present on the same device/location
-- We will have to do another connection to the other device's database's table
-- We will use aliases as practice for the future
FROM mihuynh_ZAGImore.customer c

-- To add this into the DW:
INSERT INTO Customer_Dimension (CustomerID, CustomerName, CustomerZip)
SELECT customerid, customername, customerzip
FROM mihuynh_ZAGImore.customer c;

-- Again for another dimension:
-- Store ETL Extraction for ZAGImore
SELECT s.storeid, s.storezip, s.regionid, r.regionname
FROM mihuynh_ZAGImore.store s, mihuynh_ZAGImore.region r
WHERE s.regionid = r.regionid

-- Then apply insert into
INSERT INTO Store_Dimension (StoreID, StoreZip, RegionID, RegionName)

SELECT s.storeid, s.storezip, s.regionid, r.regionname
FROM mihuynh_ZAGImore.store s, mihuynh_ZAGImore.region r
WHERE s.regionid = r.regionid



