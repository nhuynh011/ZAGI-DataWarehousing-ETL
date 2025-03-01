-- Extract from database
-- This code runs in data staging, but it selects from a table in another database.
-- Table name needs to be preceeded with the database name:
SELECT customerid, customername, customerzip
FROM mihuynh_ZAGImore.customer

-- Sometimes our data will not be present on the same device/location
-- We will have to do another connection to the other device's database's table
-- We will use aliases as practice for the future
FROM mihuynh_ZAGImore.customer c

-- To add this into the DW:
INSERT INTO customer_dim(CustomerID, CustomerName, CustomerZip)
SELECT customerid, customername, customerzip
FROM mihuynh_ZAGImore.customer c

-- Don't forget that the CustomerKey is auto-increment
CREATE TABLE customer_dim (
    CustomerKey int NOT NULL AUTO_INCREMENT, --right here
    CustomerID int NOT NULL,
    CustomerName varchar(255),
    CustomerZip varchar(6),
    PRIMARY KEY (CustomerKey)
);

