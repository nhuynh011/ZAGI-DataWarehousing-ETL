-- Full proceedure of Daily Refreshes:
DELIMITER //
CREATE PROCEDURE DailyRefresh()
BEGIN
    DROP TABLE IntTable;
    CREATE TABLE IntTable AS
    SELECT sv.noofitems*p.productprice AS RevAmount, sv.tid, 'sales' AS RevenueType, st.customerid AS CustomerID, st.storeid AS StoreID, p.productid AS ProductID, st.tdate AS CalendarDate
    FROM mihuynh_ZAGImore.soldvia sv, mihuynh_ZAGImore.product p, mihuynh_ZAGImore.salestransaction st
    WHERE sv.productid = p.productid AND sv.tid = st.tid 
    AND st.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact);

    -- Change data type for RevenueType table:
    ALTER TABLE IntTable
    MODIFY RevenueType VARCHAR(24);

    -- daily rentals
    INSERT INTO IntTable (RevAmount, tid, RevenueType, CustomerID, StoreID, ProductID, CalendarDate)
    SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, daily' AS RevenueType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
    FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
    WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'D'
    AND rt.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact);

    -- weekly rentals
    INSERT INTO IntTable (RevAmount, tid, RevenueType, CustomerID, StoreID, ProductID, CalendarDate)
    SELECT rv.duration * p.productpricedaily AS RevAmount, rv.tid, 'rentals, weekly' AS RevenueType, rt.customerid AS CustomerID, rt.storeid AS StoreID, p.productID, rt.tdate AS FullDate
    FROM mihuynh_ZAGImore.rentaltransaction rt, mihuynh_ZAGImore.rentalProducts p, mihuynh_ZAGImore.rentvia rv
    WHERE rv.productid = p.productid AND rt.tid = rv.tid AND rv.rentalType = 'W'
    AND rt.tdate > (SELECT MAX(DATE(ExtractionTimestamp)) FROM Revenue_Fact);

    -- Insert into fact table:
    INSERT INTO Revenue_Fact (TransactionID, RevAmount, ProductKey, CustKey, CalendarKey, StoreKey, RevenueType, ExtractionTimeStamp, f_loaded)
    SELECT i.tid, i.RevAmount, p.ProductKey, c.CustKey, cld.CalendarKey, s.StoreKey, i.RevenueType, NOW(), FALSE
    FROM IntTable i, Product_Dimension p, Customer_Dimension c, Calendar_Dimension cld, Store_Dimension s
    WHERE c.CustomerID = i.CustomerID AND p.ProductID = i.ProductID AND s.StoreID = i.StoreID AND UPPER(LEFT(p.ProductType, 1)) = UPPER(LEFT(i.RevenueType, 1)) AND i.CalendarDate = cld.FullDate;

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
