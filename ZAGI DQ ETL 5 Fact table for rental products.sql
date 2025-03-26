-- Today, we'll be populating the Fact table with the rental products now.
-- For the larger part of the etl, you want to not do it directly. You want to have an intermeddiate step (data staging tab)
-- But since I did it directly, I will pretend that already did it and deleted it.

-- For rental daily products:
SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, daily' AS TransactionType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.product p, mihuynh_ZAGImore.rentvia rv
WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'D'

-- Make sure that you get 11 rows from this select statement
-- We'll use this to populate a temp table

DROP TABLE IntTable;
CREATE TABLE IntTable AS
SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, daily' AS TransactionType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'D';

-- Now that we have daily rentals, we can work on weekly rentals:

INSERT INTO IntTable (RevAmount, tid, TransactionType, CustomerID, StoreID, ProductID, FullDate)
SELECT rv.duration * p.productpriceweekly AS RevAmount, rv.tid, 'rentals,weekly' AS TransactionType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'W';

-- Should be 16 rows in total here ^^
-- The reason why you have a staging phase is because analytical machines should be dedicated to analytics only.
-- You don't want to do anything unrelated (like these queries) in the analytical machine.

-- Now we write code to put the int table into the warehouse fact table
SELECT i.tid, i.RevAmount, p.ProductKey, c.CustKey, cld.CalendarKey, s.StoreKey, i.TransactionType
FROM IntTable i, Product_Dimension p, Customer_Dimension c, Calendar_Dimension cld, Store_Dimension s
WHERE c.CustomerID = i.CustomerID AND p.ProductID = i.ProductID AND s.StoreID = i.StoreID AND p.ProductType = "RentalProduct" AND i.FullDate = cld.FullDate

-- I get 16 for the select, so let's do spot checks because sometimes things may cause problems.
-- row 3 tid 123, amount 30, pkey 40, ckey 1, calendarkey 2207, skey 1, rentals daily
-- for tid 123, daily: pid 7x7, daily, duration for 2 days, price is 20 daily
-- customer is 0 1 222 store id is s1, tdate is 2019 01 16
-- just check that product is actually 7x7 for the product
INSERT INTO Revenue_Fact (TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType)
SELECT i.tid, i.RevAmount, p.ProductKey, c.CustKey, cld.CalendarKey, s.StoreKey, i.TransactionType
FROM IntTable i, Product_Dimension p, Customer_Dimension c, Calendar_Dimension cld, Store_Dimension s
WHERE c.CustomerID = i.CustomerID AND p.ProductID = i.ProductID AND s.StoreID = i.StoreID AND p.ProductType = "RentalProduct" AND i.FullDate = cld.FullDate

-- 66 total rows ^^, the correct amount
-- Most issues happen during the select, syntax, wrong joins, etc etc.
-- Sometimes when you insert you can have the wrong order as well, which then if the data types are the same, there will be issues here...
-- that's why you want to do several spot checks,

DROP TABLE IntTable

