-- Store ETL Extraction for ZAGImore
SELECT s.storeid, s.storezip, s.regionid, r.regionname
FROM mihuynh_ZAGImore.store s, mihuynh_ZAGImore.region r
WHERE s.regionid = r.regionid

-- Then apply insert into
INSERT INTO store_dimension (StoreID, StoreZip, RegionID, RegionName)

SELECT s.storeid, s.storezip, s.regionid, r.regionname
FROM mihuynh_ZAGImore.store s, mihuynh_ZAGImore.region r
WHERE s.regionid = r.regionid


-- For populating calendar dimension: data staging
CREATE PROCEDURE populateCalendar() --function
BEGIN
  DECLARE i INT DEFAULT 0;   -- variable
myloop: LOOP  
 INSERT INTO Calendar_Dimension(FullDate)
 SELECT DATE_ADD('2013-01-01', INTERVAL i DAY); --first day that company started recording data

 SET i=i+1;

    IF i=8000 then
            LEAVE myloop;
    END IF;
END LOOP myloop;

UPDATE Calendar_Dimension
SET CalendarMonth = MONTH(FullDate), CalendarYear = YEAR(FullDate);

END;

-- only issue with this is that calendar month and calendar year has to be NULL temporarily.
-- also when you write proceedures, since ; is used as the delimiter of each line in a proceedure
-- and ; also is used as a delimiter in SQL, running this is gonna crash..? error
-- you have to reset the delimiter in SQL to something else
DELIMITER // --will set the delimiter to //
-- calendar can always be populated ahead of time with a loop to update daily.


-- this is how it looks:
DELIMITER //

CREATE PROCEDURE populateCalendar()
BEGIN
  DECLARE i INT DEFAULT 0;
myloop: LOOP

 INSERT INTO Calendar_Dimension(FullDate)
 SELECT DATE_ADD('2013-01-01', INTERVAL i DAY);

 SET i=i+1;

    IF i=8000 then
            LEAVE myloop;
    END IF;
END LOOP myloop;

UPDATE Calendar_Dimension
SET CalendarMonth = MONTH(FullDate), CalendarYear = YEAR(FullDate);

END//