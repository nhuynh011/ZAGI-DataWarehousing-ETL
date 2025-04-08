-- Updating dimensions!
-- We want to keep track of all changes to the dimensions, so let's add timestamp and load status
ALTER TABLE Product_Dimension 
ADD ExtractionTimestamp TIMESTAMP DEFAULT (TIMESTAMPADD(DAY, -20, NOW())),
ADD pd_loadstatus BOOLEAN DEFAULT (TRUE);
-- Would you want to do this for all dimensions? yes

-- If we didn't do defaults, then we would have something like this:
ALTER TABLE Product_Dimension
ADD ExtractionTimestamp TIMESTAMP,
ADD pd_loadstatus BOOLEAN;

UPDATE Product_Dimension
SET ExtractionTimestamp = NOW() - INTERVAL 20 DAY;
UPDATE Product_Dimension
SET pd_loadstatus = TRUE;


-- Make a new sales product
INSERT INTO `product` (`productid`, `productname`, `productprice`, `vendorid`, `categoryid`) VALUES ('191', 'Ziptie Hiking Shoes', '85', 'WL', 'FW');

-- And rental product
INSERT INTO `rentalProducts` (`productid`, `productname`, `vendorid`, `categoryid`, `productpricedaily`, `productpriceweekly`) VALUES ('0X0', 'Super Air Matress', 'PG', 'CY', '20', '18');
INSERT INTO `rentalProducts` (`productid`, `productname`, `vendorid`, `categoryid`, `productpricedaily`, `productpriceweekly`) VALUES ('8X8', 'Power Pedals', 'MK', 'CY', '18', '15');

-- So now our data staging is a little behind because we have new products
-- These are not fact table related, so we have to update the dimension.
-- Use the initial load of products:

DELIMITER //
CREATE PROCEDURE ProductDimensionUpdate()
BEGIN
    -- insert into product dimension for sales products
    INSERT INTO Product_Dimension(ProductID, ProductName, SalesProductPrice, VendorID, VendorName, CategoryID, CategoryName, ProductType, ExtractionTimestamp, pd_loadstatus)
    SELECT p.productid, p.productname, p.productprice, p.vendorid, v.vendorname, p.categoryid, c.categoryname, "SalesProduct", NOW(), FALSE
    FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v
    WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid AND p.productid NOT IN (SELECT p.ProductID FROM mihuynh_ZAGImoreDS.Product_Dimension p WHERE p.ProductType = 'SalesProduct');

    -- insert into product dimension for rental products
    INSERT INTO Product_Dimension(ProductID, ProductName, RentalProductPriceDaily, RentalProductPriceWeekly, VendorID, VendorName, CategoryID, CategoryName, ProductType, ExtractionTimestamp, pd_loadstatus)
    SELECT r.productid, r.productname, r.productpricedaily, r.productpriceweekly, r.vendorid, v.vendorname, r.categoryid, c.categoryname,  "RentalProduct", NOW(), FALSE
    FROM mihuynh_ZAGImore.rentalProducts r, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v
    WHERE r.vendorid = v.vendorid AND r.categoryid = c.categoryid AND r.productid NOT IN (SELECT p.ProductID FROM mihuynh_ZAGImoreDS.Product_Dimension p WHERE p.ProductType = 'RentalProduct');
    -- This only works for new products. We will need a different script for updating products (using Type 2 changes)

    -- Load into data warehouse:
    INSERT INTO mihuynh_ZAGImoreDW.Product_Dimension(ProductKey, ProductID, ProductName, SalesProductPrice, RentalProductPriceDaily, RentalProductPriceWeekly,  VendorID, VendorName, CategoryID, CategoryName, ProductType)
    SELECT ProductKey, ProductID, ProductName, SalesProductPrice, RentalProductPriceDaily, RentalProductPriceWeekly,  VendorID, VendorName, CategoryID, CategoryName, ProductType
    FROM Product_Dimension
    WHERE pd_loadstatus = FALSE;

    UPDATE Product_Dimension
    SET pd_loadstatus = TRUE
    WHERE pd_loadstatus = FALSE;
END//

-- Now test this:
INSERT INTO `product` (`productid`, `productname`, `productprice`, `vendorid`, `categoryid`) VALUES ('1X8', 'Folding Cot', '80', 'MK', 'CP');
-- I should have 34 products in total.
-- It works.

--
--
-- Let's make a refresh for the store dimension as well:
-- Make new store:
INSERT INTO `store` (`storeid`, `storezip`, `regionid`) VALUES ('S15', '54978', 'N');

ALTER TABLE Store_Dimension 
ADD ExtractionTimestamp TIMESTAMP DEFAULT (TIMESTAMPADD(DAY, -20, NOW())),
ADD sd_loadstatus BOOLEAN DEFAULT (TRUE);
-- Would you want to do this for all dimensions? yes

DELIMITER //
CREATE PROCEDURE StoreDimensionUpdate()
BEGIN
    -- insert into store dimension
    INSERT INTO Store_Dimension(StoreID, StoreZip, RegionID, RegionName, ExtractionTimestamp, sd_loadstatus)

    SELECT s.storeid, s.storezip, s.regionid, r.regionname, NOW(), FALSE
    FROM mihuynh_ZAGImore.store s, mihuynh_ZAGImore.region r
    WHERE s.regionid = r.regionid AND s.storeid NOT IN (SELECT sd.StoreID FROM mihuynh_ZAGImoreDS.Store_Dimension sd);

    -- Load into data warehouse:
    INSERT INTO mihuynh_ZAGImoreDW.Store_Dimension(StoreKey, StoreID, StoreZip, RegionID, RegionName)
    SELECT StoreKey, StoreID, StoreZip, RegionID, RegionName
    FROM Store_Dimension
    WHERE sd_loadstatus = FALSE;

    UPDATE Store_Dimension
    SET sd_loadstatus = TRUE
    WHERE sd_loadstatus = FALSE;
END//


-- Refresh for customer dimension:
-- Make new customer:
INSERT INTO `customer` (`customerid`, `customername`, `customerzip`) VALUES ('9-7-000', 'Boris', '55987');

ALTER TABLE Customer_Dimension
ADD ExtractionTimestamp TIMESTAMP DEFAULT (TIMESTAMPADD(DAY, -20, NOW())),
ADD cd_loadstatus BOOLEAN DEFAULT (TRUE);
-- Would you want to do this for all dimensions? yes

DELIMITER //
CREATE PROCEDURE CustomerDimensionUpdate()
BEGIN
    -- insert into store dimension
    INSERT INTO Customer_Dimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loadstatus)
    SELECT customerid, customername, customerzip, NOW(), FALSE
    FROM mihuynh_ZAGImore.customer c
    WHERE c.customerid NOT IN (SELECT cd.CustomerID FROM mihuynh_ZAGImoreDS.Customer_Dimension cd);

    -- Load into data warehouse:
    INSERT INTO mihuynh_ZAGImoreDW.Customer_Dimension (CustKey, CustomerID, CustomerName, CustomerZip)
    SELECT CustKey, CustomerID, CustomerName, CustomerZip
    FROM Customer_Dimension
    WHERE cd_loadstatus = FALSE;

    UPDATE Customer_Dimension
    SET cd_loadstatus = TRUE
    WHERE cd_loadstatus = FALSE;
END//