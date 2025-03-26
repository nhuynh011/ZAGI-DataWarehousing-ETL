-- Data Staging Creation Code
CREATE TABLE Product_Dimension
(
  ProductKey INT AUTO_INCREMENT,
  ProductID CHAR(3) NOT NULL,
  ProductName VARCHAR(25) NOT NULL,
  CategoryID CHAR(2) NOT NULL,
  CategoryName VARCHAR(25) NOT NULL,
  VendorID CHAR(2) NOT NULL,
  VendorName VARCHAR(25) NOT NULL,
  ProductType VARCHAR(8) NOT NULL,
  SalesProductPrice DECIMAL(7,2),
  RentalProductPriceDaily DECIMAL(7,2),
  RentalProductPriceWeekly DECIMAL(7,2),
  PRIMARY KEY (ProductKey)
);

CREATE TABLE Customer_Dimension
(
  CustomerID CHAR(7) NOT NULL,
  CustKey INT AUTO_INCREMENT,
  CustomerName VARCHAR(15) NOT NULL,
  CustomerZIP CHAR(5) NOT NULL,
  PRIMARY KEY (CustKey)
);

CREATE TABLE Calendar_Dimension
(
  CalendarKey INT AUTO_INCREMENT,
  FullDate DATE NOT NULL,
  MonthYear INT NOT NULL,
  CalendarYear INT NOT NULL,
  PRIMARY KEY (CalendarKey)
);

CREATE TABLE Store_Dimension
(
  StoreKey INT AUTO_INCREMENT,
  StoreID VARCHAR(3) NOT NULL,
  StoreZip CHAR(5) NOT NULL,
  RegionID CHAR(1) NOT NULL,
  RegionName VARCHAR(25) NOT NULL,
  PRIMARY KEY (StoreKey)
);

CREATE TABLE Revenue_Fact
(
  TransactionID VARCHAR(8) NOT NULL,
  RevAmount DECIMAL(9,2) NOT NULL,
  TransactionType INT NOT NULL,
  ProductKey INT NOT NULL,
  CustKey INT NOT NULL,
  CalendarKey INT NOT NULL,
  StoreKey INT NOT NULL,
  PRIMARY KEY (TransactionID, TransactionType, ProductKey, CustKey, CalendarKey, StoreKey)
);

-- Data Warehouse Creation Code
CREATE TABLE Product_Dimension
(
  ProductKey INT NOT NULL,
  ProductID CHAR(3) NOT NULL,
  ProductName VARCHAR(25) NOT NULL,
  CategoryID CHAR(2) NOT NULL,
  CategoryName VARCHAR(25) NOT NULL,
  VendorID CHAR(2) NOT NULL,
  VendorName VARCHAR(25) NOT NULL,
  ProductType VARCHAR(8) NOT NULL,
  SalesProductPrice DECIMAL(7,2),
  RentalProductPriceDaily DECIMAL(7,2),
  RentalProductPriceWeekly DECIMAL(7,2),
  PRIMARY KEY (ProductKey)
);

CREATE TABLE Customer_Dimension
(
  CustomerID CHAR(7) NOT NULL,
  CustKey INT NOT NULL,
  CustomerName VARCHAR(15) NOT NULL,
  CustomerZIP CHAR(5) NOT NULL,
  PRIMARY KEY (CustKey)
);

CREATE TABLE Calendar_Dimension
(
  CalendarKey INT NOT NULL,
  FullDate DATE NOT NULL,
  MonthYear INT NOT NULL,
  CalendarYear INT NOT NULL,
  PRIMARY KEY (CalendarKey)
);

CREATE TABLE Store_Dimension
(
  StoreKey INT NOT NULL,
  StoreID VARCHAR(3) NOT NULL,
  StoreZip CHAR(5) NOT NULL,
  RegionID CHAR(1) NOT NULL,
  RegionName VARCHAR(25) NOT NULL,
  PRIMARY KEY (StoreKey)
);

CREATE TABLE Revenue_Fact
(
  TransactionID VARCHAR(8) NOT NULL,
  RevAmount DECIMAL(9,2) NOT NULL,
  TransactionType INT NOT NULL,
  ProductKey INT NOT NULL,
  CustKey INT NOT NULL,
  CalendarKey INT NOT NULL,
  StoreKey INT NOT NULL,
  PRIMARY KEY (TransactionID, TransactionType, ProductKey, CustKey, CalendarKey, StoreKey),
  FOREIGN KEY (ProductKey) REFERENCES Product_Dimension(ProductKey),
  FOREIGN KEY (CustKey) REFERENCES Customer_Dimension(CustKey),
  FOREIGN KEY (CalendarKey) REFERENCES Calendar_Dimension(CalendarKey),
  FOREIGN KEY (StoreKey) REFERENCES Store_Dimension(StoreKey)
);

-- You want to create 2 data wasrehouses so we can test queries/perform joins and import them into the actual warehouse after everything is done.
-- Data warehouse should be read only so we will populate it through the data staging environment actually.
-- We will use aliases.