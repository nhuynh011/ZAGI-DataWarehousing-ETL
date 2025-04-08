-- Query to determine which transactions have not yet been loaded into the fact table
SELECT s.tid, r.tid
FROM mihuynh_ZAGImore.salestransaction s, mihuynh_ZAGImore.rentaltransaction r
WHERE tid NOT IN (SELECT TransactionID FROM mihuynh_ZAGImoreDS.Revenue_Fact)

-- or
SELECT s.tid, r.tid
FROM mihuynh_ZAGImore.salestransaction s, mihuynh_ZAGImore.rentaltransaction r
WHERE tid NOT IN (SELECT TransactionID FROM mihuynh_ZAGImoreDS.Revenue_Fact)
UNION
SELECT tid
FROM mihuynh_ZAGImore.rentaltransaction
WHERE tid NOT IN (SELECT TransactionID FROM mihuynh_ZAGImoreDS.Revenue_Fact)

-- I have to run these seperately, we should be able to join them together without having to run seperate queries,
-- troubleshoot later
-- HELP

-- Let's add a record just to see if it works at all.
-- So this does work, make sure that transactions and vias are consistent (run the same query but instead of revenue fact then it should be the via tables)
-- LATE ARRIVING FACTS:
-- Let's say an accident happened and we couldn't update them on time?
-- We still need to import them.
-- We can modify the daily refresh proceedure code:
-- Full proceedure of Daily Refreshes:
DELIMITER //
CREATE PROCEDURE LateRefresh()
BEGIN
    DROP TABLE IntTable;
    DROP TABLE Int2Fact;
    CREATE TABLE IntTable AS
    SELECT sv.noofitems*p.productprice AS RevAmount, sv.tid, 'sales' AS RevenueType, st.customerid AS CustomerID, st.storeid AS StoreID, p.productid AS ProductID, st.tdate AS CalendarDate
    FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p, mihuynh_ZAGImore.salestransaction st
    WHERE sv.productid = p.productid AND sv.tid = st.tid ;
    -- we removed the time condition for here

    -- Change data type for RevenueType table:
    ALTER TABLE IntTable
    MODIFY RevenueType VARCHAR(24);

    -- daily rentals
    INSERT INTO IntTable (RevAmount, tid, RevenueType, CustomerID, StoreID, ProductID, CalendarDate)
    SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, daily' AS RevenueType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
    FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
    WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'D';
    -- removed here


    -- weekly rentals
    INSERT INTO IntTable (RevAmount, tid, RevenueType, CustomerID, StoreID, ProductID, CalendarDate)
    SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, weekly' AS RevenueType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
    FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
    WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'W';
    -- removed here too
    -- this returns the total amount of records in the via tables

    -- here, you can drop the fact table and reload everything but that is not a good idea at all
    -- complexity, and you lose info (extraction timestamp is overwritten)
    -- even this method is overkill. You should be able to extract everything not in the fact table with the tid query to make the int table.

    -- there's a reason they don't do a tid lookup because even with the tid lookup, things can still be missing
    -- for example, if you did a tid comparison, if the other line-items were logged except the late arriving fact, you'd have the same tid
    -- if you did a tid lookup you wouldn't find it.

    -- you'd do a full import (drop rev table and do a new one) when your company's database needs to be 100% refreshed
    -- for example, 10 years+ data doesn't need to be tracked anymore. You can delete all and then do an "initial load" with your more recent data

    CREATE TABLE Int2Fact AS
    SELECT i.tid, i.RevAmount, p.ProductKey, c.CustKey, cld.CalendarKey, s.StoreKey, i.RevenueType, NOW(), FALSE
    FROM IntTable i, Product_Dimension p, Customer_Dimension c, Calendar_Dimension cld, Store_Dimension s
    WHERE c.CustomerID = i.CustomerID AND p.ProductID = i.ProductID AND s.StoreID = i.StoreID AND UPPER(LEFT(p.ProductType, 1)) = UPPER(LEFT(i.RevenueType, 1)) AND i.CalendarDate = cld.FullDate;
    -- this table has everything we need. We need to add into the revenue fact everything this table has that the other one doesn't have
    -- we can make a combination using an outer join and then where the Int2Fact is different from Revenue_fact, it is null
    INSERT INTO Revenue_Fact(TransactionID, RevAmount, ProductKey, CustKey, calendarKey, RevenueType, StoreKey, ExtractionTimeStamp, f_loaded)
    SELECT r2.tid, r2.RevAmount, r2.ProductKey, r2.CustKey, r2.CalendarKey, r2.RevenueType, r2.StoreKey, NOW(), FALSE
    FROM mihuynh_ZAGImoreDS.Int2Fact r2 
    LEFT JOIN mihuynh_ZAGImoreDS.Revenue_Fact r1 ON (r2.tid=r1.TransactionID) AND (r2.ProductKey=r1.ProductKey) AND (r2.CustKey=r1.CustKey) AND (r2.CalendarKey=r1.CalendarKey) AND (r2.RevenueType=r1.RevenueType) AND (r2.StoreKey=r1.StoreKey)
    WHERE r1.TransactionID IS NULL;


    -- Insert into data warehouse
    INSERT INTO mihuynh_ZAGImoreDW.Revenue_Fact (TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType)
    SELECT TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType
    FROM Revenue_Fact 
    WHERE f_loaded = FALSE;

    -- Now to make sure we never have duplicates:
    UPDATE Revenue_Fact
    SET f_loaded = TRUE
    WHERE f_loaded = FALSE;
END//