-- Today we will impliment type 2 changes
-- Changes in product price

-- focus only on sales products currently
UPDATE `product` SET `productprice` = '200.00' WHERE `product`.`productid` = '1X3'; 
UPDATE `product` SET `productprice` = '60.00' WHERE `product`.`productid` = '2X3'; 

-- Add 3 columns, date valid from, date valid until, and current status (boolean) to the product dimension for the Type 2 change
ALTER TABLE Product_Dimension
ADD dvfrom DATE,
ADD dvuntil DATE,
ADD currentStatus CHAR(1);

-- Assume all the products entered the catalog on Jan 1st 2013
UPDATE Product_Dimension
SET dvfrom = '2013-01-01', currentStatus = 'C';

-- We can pick a date in the distant future to be the dvuntil
-- Why is this convenient?
UPDATE Product_Dimension
SET dvuntil = '2040-01-01';

-- Change current status of product to n and dvu to yesterday (since it's not valid anymore)
-- Then add the updated product to the Product Dimension and set the dvfrom to today

-- Create temp table with product ids of sales products that need to be updated
CREATE TABLE pd_type2change AS
SELECT p.productid
FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v, mihuynh_ZAGImoreDS.Product_Dimension pd
WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid AND pd.ProductID = p.productid AND pd.ProductType = "SalesProduct" 
AND pd.SalesProductPrice <> p.productprice;

-- MISC: Drop if exist
-- DROP TABLE IF EXISTS [table]; 

-- Update old product records:
UPDATE Product_Dimension
SET dvuntil = NOW() - INTERVAL 1 DAY, currentStatus = 'N' WHERE ProductID IN (SELECT * FROM pd_type2change);

-- Now add new columns with the updated details:
INSERT INTO Product_Dimension(ProductID, ProductName, SalesProductPrice, VendorID, VendorName, CategoryID, CategoryName, ProductType, ExtractionTimestamp, pd_loadstatus, dvfrom, dvuntil, currentStatus)
SELECT p.productid, p.productname, p.productprice, p.vendorid, v.vendorname, p.categoryid, c.categoryname, "SalesProduct", NOW(), FALSE, NOW(), '2040-01-01', 'C'
FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v
WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid AND p.productid IN (SELECT * FROM pd_type2change);

-- Date valid from, date valid until also need to exist in the data warehouse
ALTER TABLE mihuynh_ZAGImoreDW.Product_Dimension
ADD dvfrom DATE,
ADD dvuntil DATE,
ADD currentStatus CHAR(1);

UPDATE mihuynh_ZAGImoreDW.Product_Dimension
SET dvfrom = '2013-01-01', currentStatus = 'C';

UPDATE mihuynh_ZAGImoreDW.Product_Dimension
SET dvuntil = '2040-01-01';

-- Load into data warehouse:
REPLACE INTO mihuynh_ZAGImoreDW.Product_Dimension(ProductKey, ProductID, ProductName, SalesProductPrice, RentalProductPriceDaily, RentalProductPriceWeekly,  VendorID, VendorName, CategoryID, CategoryName, ProductType, dvfrom, dvuntil, currentStatus)
SELECT ProductKey, ProductID, ProductName, SalesProductPrice, RentalProductPriceDaily, RentalProductPriceWeekly,  VendorID, VendorName, CategoryID, CategoryName, ProductType, dvfrom, dvuntil, currentStatus
FROM Product_Dimension;

-- Once a row changes, I don't want to detect it anymore.
UPDATE Product_Dimension
SET pd_loadstatus = TRUE WHERE pd_loadstatus = FALSE;

CREATE TABLE pd_type2change AS
SELECT p.productid
FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v, mihuynh_ZAGImoreDS.Product_Dimension pd
WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid AND pd.ProductID = p.productid AND pd.ProductType = "SalesProduct" 
AND pd.SalesProductPrice <> p.productprice AND pd.currentStatus = 'C';

-- In addition to the price, the vendor and name can change as well.
-- rewrite the type2 table 
CREATE TABLE pd_type2change AS
SELECT p.productid
FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v, mihuynh_ZAGImoreDS.Product_Dimension pd
WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid AND pd.ProductID = p.productid AND pd.ProductType = "SalesProduct" 
AND (pd.SalesProductPrice <> p.productprice OR pd.ProductName <> p.productname OR pd.VendorID <> p.vendorid) -- this is not an exclusive or
AND pd.currentStatus = 'C';

-- Testing the implimentation with new changes in vendor, product name, and product price:
-- All changes:
UPDATE `product` SET `productname` = 'Treaded Tire', `productprice` = '130.00' WHERE `product`.`productid` = '3X4'; 
UPDATE `product` SET `vendorid` = 'PG' WHERE `product`.`productid` = '2X2'; 
UPDATE `product` SET `productname` = 'Easy Shoe' WHERE `product`.`productid` = '2X2'; 
UPDATE `product` SET `vendorid` = 'WL' WHERE `product`.`productid` = '5X2'; 

-- Proceedure for handling type 2 changes in product dimension (sales products only)
-- new revised code:
DELIMITER //
CREATE PROCEDURE UpdateProductDimension()
BEGIN
    DROP TABLE IF EXISTS pd_type2change;
    CREATE TABLE pd_type2change AS
    SELECT p.productid
    FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v, mihuynh_ZAGImoreDS.Product_Dimension pd
    WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid AND pd.ProductID = p.productid AND pd.ProductType = "SalesProduct" 
    AND (pd.SalesProductPrice <> p.productprice OR pd.ProductName <> p.productname OR pd.VendorID <> p.vendorid) -- this is not an exclusive or
    AND pd.currentStatus = 'C';

    UPDATE Product_Dimension
    SET dvuntil = NOW() - INTERVAL 1 DAY, currentStatus = 'N' 
    WHERE ProductID IN (SELECT * FROM pd_type2change) AND currentStatus = 'C' AND ProductType = "SalesProduct";

    INSERT INTO Product_Dimension(ProductID, ProductName, SalesProductPrice, VendorID, VendorName, CategoryID, CategoryName, ProductType, ExtractionTimestamp, pd_loadstatus, dvfrom, dvuntil, currentStatus)
    SELECT p.productid, p.productname, p.productprice, p.vendorid, v.vendorname, p.categoryid, c.categoryname, "SalesProduct", NOW(), FALSE, NOW(), '2040-01-01', 'C'
    FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v
    WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid AND p.productid IN (SELECT * FROM pd_type2change);

    ALTER TABLE mihuynh_ZAGImoreDW.Revenue_Fact DROP FOREIGN KEY Revenue_Fact_ibfk_4;

    REPLACE INTO mihuynh_ZAGImoreDW.Product_Dimension(ProductKey, ProductID, ProductName, SalesProductPrice, RentalProductPriceDaily, RentalProductPriceWeekly,  VendorID, VendorName, CategoryID, CategoryName, ProductType, dvfrom, dvuntil, currentStatus)
    SELECT ProductKey, ProductID, ProductName, SalesProductPrice, RentalProductPriceDaily, RentalProductPriceWeekly,  VendorID, VendorName, CategoryID, CategoryName, ProductType, dvfrom, dvuntil, currentStatus
    FROM Product_Dimension;

    UPDATE Product_Dimension
    SET pd_loadstatus = TRUE WHERE pd_loadstatus = FALSE;

    ALTER TABLE mihuynh_ZAGImoreDW.Revenue_Fact ADD CONSTRAINT Revenue_Fact_ibfk_4 FOREIGN KEY (ProductKey) REFERENCES Product_Dimension(ProductKey);
END//
-- to check if the current amount of products is accurate:
SELECT COUNT(*) FROM mihuynh_ZAGImoreDS.Product_Dimension WHERE currentStatus = 'C';

SELECT (SELECT COUNT(*) FROM mihuynh_ZAGImore.product)
+
(SELECT COUNT(*) FROM mihuynh_ZAGImore.rentalProducts);

-- Or we can just check if it's equal to 0:
SELECT 
(SELECT COUNT(*) FROM mihuynh_ZAGImoreDS.Product_Dimension p WHERE p.currentStatus = 'C')
-
(SELECT COUNT(*) FROM mihuynh_ZAGImore.product)
-
(SELECT COUNT(*) FROM mihuynh_ZAGImore.rentalProducts);

-- Check in the database:
SELECT 
(SELECT COUNT(*) FROM mihuynh_ZAGImoreDS.Product_Dimension)
-
(SELECT COUNT(*) FROM mihuynh_ZAGImoreDW.Product_Dimension);
