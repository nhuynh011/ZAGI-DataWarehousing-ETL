-- Fact table populating.
-- First, only extract fact and degenerate dimensions.
-- Know how large your fact table may become. Let's say there are 50 entries in a table detailing all transactions
SELECT sv.noofitems*p.productprice FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p
WHERE sv.productid = p.productid

-- This gives us the total revenue from the 50 transactions.
-- This will be the column revamount
SELECT sv.noofitems*p.productprice AS RevAmount FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p
WHERE sv.productid = p.productid

-- Now let's do another column
SELECT sv.noofitems*p.productprice AS RevAmount, sv.tid, 'sales' AS RevType FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p
WHERE sv.productid = p.productid

-- I could insert this but I am missing the keys...
-- Each of these rev generated happened on a certain day, with a certain customer, etc etc.
-- We will not match keys first, we will actually get all the unique attributes (keys) and just leave them in there.
-- We'll put fillers in for now:

SELECT sv.noofitems*p.productprice AS RevAmount, sv.tid, 'sales' AS RevenueType, st.customerid AS CustomerID, st.storeid AS StoreID, p.productid AS ProductID
FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p, mihuynh_ZAGImore.salestransaction st
WHERE sv.productid = p.productid AND sv.tid = st.tid
-- Note the caps for new columns names, make sure that it matches

-- Now we make that a table as a temporary step.
CREATE TABLE IntTable AS
SELECT sv.noofitems*p.productprice AS RevAmount, sv.tid, 'sales' AS RevenueType, st.customerid AS CustomerID, st.storeid AS StoreID, p.productid AS ProductID, st.tdate AS CalendarDate
FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p, mihuynh_ZAGImore.salestransaction st
WHERE sv.productid = p.productid AND sv.tid = st.tid

-- For the daily refreshes, you will make a int Table, use it, and then drop it. better then nested queries.
-- When you make the tabel based on selects, the column types will be inherited from the select statement.
-- In our case, RevenueType is varchar(5), but we need to be able to store 'rental' as well. and maybe in the future, more revenue types?
-- We have to change this.
ALTER TABLE IntTable
MODIFY RevenueType VARCHAR(8);

-- Now that we have a good int table, we can use it to populate the fact table:
-- This is not an explicit join, this is simply a match:
-- The order of the fact table is: TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType

SELECT i.tid, i.RevAmount, pd.ProductKey, cd.CustKey, sd.StoreKey, i.RevenueType
FROM IntTable i, Customer_Dimension cd, Product_Dimension pd, Store_Dimension sd
WHERE cd.CustomerID = i.CustomerID AND pd.ProductID = i.ProductID AND sd.StoreID = i.StoreID
-- Things will be different for type 2 changes, since you will have to check dates of transaction as well.

-- gives us 66 rows as opposed to the 50 rows we expect. The reason for this is ProductID has duplicate Keys since there are sales products and rental products.
-- we have to filter for sales product only

SELECT i.tid, i.RevAmount, pd.ProductKey, cd.CustKey, sd.StoreKey, i.RevenueType
FROM IntTable i, Customer_Dimension cd, Product_Dimension pd, Store_Dimension sd
WHERE cd.CustomerID = i.CustomerID AND pd.ProductID = i.ProductID AND sd.StoreID = i.StoreID AND pd.ProductType = "SalesProduct"
-- Now we have 50

-- Now we can insert into:
INSERT INTO Revenue_Fact(TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType)
SELECT i.tid, i.RevAmount, pd.ProductKey, cd.CustKey, cld.CalendarKey, sd.StoreKey, i.RevenueType
FROM IntTable i, Customer_Dimension cd, Product_Dimension pd, Store_Dimension sd, Calendar_Dimension cld
WHERE cd.CustomerID = i.CustomerID AND pd.ProductID = i.ProductID AND sd.StoreID = i.StoreID AND pd.ProductType = "SalesProduct" AND i.CalendarDate = cld.FullDate


-- This usually happens at hours that people are not awake
-- You can also mart it for quick decision making.
