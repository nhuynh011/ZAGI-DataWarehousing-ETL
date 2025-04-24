-- ZAGI Type 2 change for customer.
-- I don't think it makes sense to do a type2 change for store because if a store changes any attribute 
-- then in real life it's deleted and therefore would have a new store ID

-- First make the columns for type 2 changes in both DS and DW, currentStatus, dvuntil and dvfrom
ALTER TABLE Customer_Dimension
ADD dvfrom DATE,
ADD dvuntil DATE,
ADD currentStatus CHAR(1);

-- Assume all the customers registered on Jan 1st 2013
UPDATE Customer_Dimension
SET dvfrom = '2013-01-01', currentStatus = 'C';

UPDATE Customer_Dimension
SET dvuntil = '2040-01-01';

ALTER TABLE mihuynh_ZAGImoreDW.Customer_Dimension
ADD dvfrom DATE,
ADD dvuntil DATE,
ADD currentStatus CHAR(1);

-- Assume all the customers registered on Jan 1st 2013
UPDATE Customer_Dimension
SET dvfrom = '2013-01-01', currentStatus = 'C';

UPDATE Customer_Dimension
SET dvuntil = '2040-01-01';

DROP TABLE IF EXISTS cd_type2change;
CREATE TABLE cd_type2change AS
    -- I copied the code from the type2change for product
    -- my question is why does the comparison between vendor and category have to happen?
    -- When I run the SQL code, it returns a bunch of duplicate IDs, I can just do distinct instead can't I ?
    -- So I can select distinct, it seems to give me the same result

    -- When we select with multiple froms, something weird happens. That's why you need group-by comparisons for all the categories that are FK for product dimension
    -- The same should be applied to customer dimension
    -- Are there any FKs?
    -- Customer doesn't have any FKs, I guess I don't have to worry? Let's test it out:

    UPDATE `customer` SET `customername` = 'Elle' WHERE `customer`.`customerid` = '4-5-666';
    UPDATE `customer` SET `customername` = 'Borris', `customerzip` = '55988' WHERE `customer`.`customerid` = '9-7-000'; 
    UPDATE `customer` SET `customerzip` = '55497' WHERE `customer`.`customerid` = '0-1-222'; 
    
SELECT c.customerid
FROM mihuynh_ZAGImore.customer c, mihuynh_ZAGImoreDS.Customer_Dimension cd
WHERE cd.CustomerID = c.customerid 
AND (cd.CustomerName <> c.customername OR cd.CustomerZIP <> c.customerzip)
AND cd.currentStatus = 'C';
    -- This select query worked for 3 changes

UPDATE Customer_Dimension
SET dvuntil = NOW() - INTERVAL 1 DAY, currentStatus = 'N' 
WHERE CustomerID IN (SELECT * FROM cd_type2change) AND currentStatus = 'C';
-- this worked as well

-- Insert the changes into the dimension
INSERT INTO Customer_Dimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loadstatus, dvfrom, dvuntil, currentStatus)
SELECT customerid, customername, customerzip, NOW(), FALSE, NOW(), '2040-01-01', 'C'
FROM mihuynh_ZAGImore.customer c
WHERE c.customerid IN (SELECT * FROM mihuynh_ZAGImoreDS.cd_type2change);

-- Remove the foreign key restraint
ALTER TABLE mihuynh_ZAGImoreDW.Revenue_Fact DROP FOREIGN KEY Revenue_Fact_ibfk_3;
ALTER TABLE mihuynh_ZAGImoreDW.OneWayAggregateBYCat DROP FOREIGN KEY OneWayAggregateBYCat_ibfk_4;

REPLACE INTO mihuynh_ZAGImoreDW.Customer_Dimension(CustKey, CustomerID, CustomerName, CustomerZip, dvfrom, dvuntil, currentStatus)
SELECT CustKey, CustomerID, CustomerName, CustomerZip, dvfrom, dvuntil, currentStatus
FROM mihuynh_ZAGImoreDS.Customer_Dimension;

UPDATE Customer_Dimension
SET cd_loadstatus = TRUE WHERE cd_loadstatus = FALSE;

ALTER TABLE mihuynh_ZAGImoreDW.Revenue_Fact ADD CONSTRAINT Revenue_Fact_ibfk_3 FOREIGN KEY (CustKey) REFERENCES Customer_Dimension(CustKey);
ALTER TABLE mihuynh_ZAGImoreDW.OneWayAggregateBYCat ADD CONSTRAINT OneWayAggregateBYCat_ibfk_4 FOREIGN KEY (CustKey) REFERENCES Customer_Dimension(CustKey);

-- Or we can just check if it's equal to 0:
SELECT 
(SELECT COUNT(*) FROM mihuynh_ZAGImoreDS.Customer_Dimension c WHERE c.currentStatus = 'C')
-
(SELECT COUNT(*) FROM mihuynh_ZAGImore.customer);

-- Check in the database:
SELECT 
(SELECT COUNT(*) FROM mihuynh_ZAGImoreDS.Customer_Dimension)
-
(SELECT COUNT(*) FROM mihuynh_ZAGImoreDW.Customer_Dimension);


-- FULL PROCEDURE
DELIMITER //
CREATE PROCEDURE UpdateCustomerDimension()
BEGIN
    DROP TABLE IF EXISTS cd_type2change;
    CREATE TABLE cd_type2change AS
    SELECT c.customerid
    FROM mihuynh_ZAGImore.customer c, mihuynh_ZAGImoreDS.Customer_Dimension cd
    WHERE cd.CustomerID = c.customerid 
    AND (cd.CustomerName <> c.customername OR cd.CustomerZIP <> c.customerzip)
    AND cd.currentStatus = 'C';
        -- This select query worked for 3 changes

    UPDATE Customer_Dimension
    SET dvuntil = NOW() - INTERVAL 1 DAY, currentStatus = 'N' 
    WHERE CustomerID IN (SELECT * FROM cd_type2change) AND currentStatus = 'C';
    -- this worked as well

    -- Insert the changes into the dimension
    INSERT INTO Customer_Dimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loadstatus, dvfrom, dvuntil, currentStatus)
    SELECT customerid, customername, customerzip, NOW(), FALSE, NOW(), '2040-01-01', 'C'
    FROM mihuynh_ZAGImore.customer c
    WHERE c.customerid IN (SELECT * FROM mihuynh_ZAGImoreDS.cd_type2change);

    -- Remove the foreign key restraint
    ALTER TABLE mihuynh_ZAGImoreDW.Revenue_Fact DROP FOREIGN KEY Revenue_Fact_ibfk_3;
    ALTER TABLE mihuynh_ZAGImoreDW.OneWayAggregateBYCat DROP FOREIGN KEY OneWayAggregateBYCat_ibfk_4;

    REPLACE INTO mihuynh_ZAGImoreDW.Customer_Dimension(CustKey, CustomerID, CustomerName, CustomerZip, dvfrom, dvuntil, currentStatus)
    SELECT CustKey, CustomerID, CustomerName, CustomerZip, dvfrom, dvuntil, currentStatus
    FROM mihuynh_ZAGImoreDS.Customer_Dimension;

    UPDATE Customer_Dimension
    SET cd_loadstatus = TRUE WHERE cd_loadstatus = FALSE;

    ALTER TABLE mihuynh_ZAGImoreDW.Revenue_Fact ADD CONSTRAINT Revenue_Fact_ibfk_3 FOREIGN KEY (CustKey) REFERENCES Customer_Dimension(CustKey);
    ALTER TABLE mihuynh_ZAGImoreDW.OneWayAggregateBYCat ADD CONSTRAINT OneWayAggregateBYCat_ibfk_4 FOREIGN KEY (CustKey) REFERENCES Customer_Dimension(CustKey);
END//