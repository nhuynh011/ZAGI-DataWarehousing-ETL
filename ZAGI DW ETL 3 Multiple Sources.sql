-- ETL for Products category

-- Loading sales product
-- Select sales products
SELECT p.productid, p.productname, p.productprice, p.vendorid, p.categoryid, c.categoryname, v.vendorname
FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v
WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid

-- insert into, make sure that the order is the same
INSERT INTO Product_Dimension(ProductID, ProductName, SalesProductPrice, VendorID, VendorName, CategoryID, CategoryName, ProductType, ExtractionTimestamp, pd_loadstatus)
SELECT p.productid, p.productname, p.productprice, p.vendorid, v.vendorname, p.categoryid, c.categoryname, "SalesProduct", NOW(), FALSE
FROM mihuynh_ZAGImore.product p, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v
WHERE p.vendorid = v.vendorid AND p.categoryid = c.categoryid;


-- Loading rental product
-- make sure you have the right variable type set for these columns ^^
-- this is only sales product, we have to add rental products into this as well.
SELECT r.productid, r.productname, r.productpricedaily, r.productpriceweekly, r.vendorid, v.vendorname, r.categoryid, c.categoryname,  "RentalProduct", NOW(), FALSE
FROM mihuynh_ZAGImore.rentalProducts r, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v
WHERE r.vendorid = v.vendorid AND r.categoryid = c.categoryid;

-- Now we should be able to insert into:
INSERT INTO Product_Dimension(ProductID, ProductName, RentalProductPriceDaily, RentalProductPriceWeekly, VendorID, VendorName, CategoryID, CategoryName, ProductType, ExtractionTimestamp, pd_loadstatus)
SELECT r.productid, r.productname, r.productpricedaily, r.productpriceweekly, r.vendorid, v.vendorname, r.categoryid, c.categoryname,  "RentalProduct", NOW(), FALSE
FROM mihuynh_ZAGImore.rentalProducts r, mihuynh_ZAGImore.category c, mihuynh_ZAGImore.vendor v
WHERE r.vendorid = v.vendorid AND r.categoryid = c.categoryid;
