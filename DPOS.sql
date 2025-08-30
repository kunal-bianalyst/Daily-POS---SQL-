CREATE SCHEMA `DailyPOSales`;
CREATE DATABASE RetailERP;
USE RetailERP;
-- 1. Product Categories
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    CategoryName VARCHAR(50) NOT NULL
);
-- 2. Products
CREATE TABLE Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    ProductName VARCHAR(100) NOT NULL,
    CategoryID INT,
    UnitPrice DECIMAL(10,2),
    ReorderLevel INT,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);
-- 3. Stores
CREATE TABLE Stores (
    StoreID INT PRIMARY KEY AUTO_INCREMENT,
    StoreName VARCHAR(100),
    Location VARCHAR(100)
);

-- 4. Customers
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(100),
    Phone VARCHAR(15),
    Email VARCHAR(100),
    City VARCHAR(50)
);

-- 5. Suppliers
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY AUTO_INCREMENT,
    SupplierName VARCHAR(100),
    ContactPerson VARCHAR(100),
    Phone VARCHAR(15)
);

-- 6. Inventory
CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY AUTO_INCREMENT,
    StoreID INT,
    ProductID INT,
    QuantityInStock INT,
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- 7. Orders
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    StoreID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID)
);

-- 8. Order Details
CREATE TABLE OrderDetails (
    OrderDetailID INT PRIMARY KEY AUTO_INCREMENT,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- 9. Supplier Orders (Purchase Orders)
CREATE TABLE SupplierOrders (
    SupplierOrderID INT PRIMARY KEY AUTO_INCREMENT,
    SupplierID INT,
    StoreID INT,
    OrderDate DATE,
    TotalCost DECIMAL(10,2),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (StoreID) REFERENCES Stores(StoreID)
);
-- Categories
INSERT INTO Categories (CategoryName) VALUES
('Groceries'), ('Electronics'), ('Clothing'), ('Household'), ('DIY Tools');

-- Products
INSERT INTO Products (ProductName, CategoryID, UnitPrice, ReorderLevel) VALUES
('Rice 5kg Bag', 1, 350.00, 10),
('LED TV 42 inch', 2, 25000.00, 2),
('Men T-Shirt', 3, 599.00, 15),
('Detergent Powder 1kg', 4, 150.00, 20),
('Electric Drill Machine', 5, 3200.00, 5);

-- Stores
INSERT INTO Stores (StoreName, Location) VALUES
('Dmart Pune', 'Pune'), ('BigBazaar Mumbai', 'Mumbai'), ('DIY Hub Delhi', 'Delhi');

-- Customers
INSERT INTO Customers (FullName, Phone, Email, City) VALUES
('Ramesh Kumar', '9876543210', 'ramesh@example.com', 'Pune'),
('Priya Singh', '9823456789', 'priya@example.com', 'Mumbai'),
('Amit Sharma', '9812345678', 'amit@example.com', 'Delhi');

-- Suppliers
INSERT INTO Suppliers (SupplierName, ContactPerson, Phone) VALUES
('FreshFoods Ltd', 'Sunil Patil', '9876500000'),
('ElectroWorld', 'Anita Desai', '9823400000'),
('StyleWear', 'Raj Mehta', '9812300000');

-- Inventory
INSERT INTO Inventory (StoreID, ProductID, QuantityInStock) VALUES
(1, 1, 100), (1, 2, 5), (1, 3, 50),
(2, 1, 120), (2, 4, 60), (3, 5, 10);

-- Orders
INSERT INTO Orders (CustomerID, StoreID, OrderDate, TotalAmount) VALUES
(1, 1, '2025-08-10', 700.00),
(2, 2, '2025-08-11', 25000.00);

-- Order Details
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
(1, 1, 2, 350.00),
(2, 2, 1, 25000.00);

-- 1. Total Sales per Store
SELECT s.StoreName, SUM(o.TotalAmount) AS TotalSales
FROM Orders o
JOIN Stores s ON o.StoreID = s.StoreID
GROUP BY s.StoreName;

-- 2. Low Stock Alert
SELECT p.ProductName, i.QuantityInStock
FROM Inventory i
JOIN Products p ON i.ProductID = p.ProductID
WHERE i.QuantityInStock < p.ReorderLevel;

-- 3. Best Selling Products
SELECT p.ProductName, SUM(od.Quantity) AS TotalSold
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalSold DESC;

-- Queries for deeper analysis--

-- Bills = one row per receipt
SELECT
    StoreID,
    OrderDate,
    COUNT(*) AS bill_count,
    SUM(bill_value) AS total_sales,
    ROUND(AVG(bill_value), 2) AS avg_bill_value
FROM (
    SELECT
        o.StoreID,
        o.OrderDate,
        o.OrderID AS sale_id,
        SUM(od.Quantity * od.UnitPrice) AS bill_value,
        SUM(od.Quantity) AS items
    FROM Orders o
    JOIN OrderDetails od 
        ON o.OrderID = od.OrderID
    GROUP BY o.StoreID, o.OrderDate, o.OrderID
) bills
GROUP BY StoreID, OrderDate
ORDER BY OrderDate, StoreID;


/* Store-wise Bill Count */
SELECT 
    s.StoreName, 
    o.OrderDate, 
    COUNT(DISTINCT o.OrderID) AS Bill_Count
FROM Orders o
JOIN Stores s ON o.StoreID = s.StoreID
GROUP BY s.StoreName, o.OrderDate
ORDER BY o.OrderDate, s.StoreName;

/* Total Sales Store performance */
SELECT 
    o.OrderDate, 
    SUM(o.TotalAmount) AS Total_Sales
FROM Orders o
GROUP BY o.OrderDate
ORDER BY o.OrderDate;

/* Store-wise Total Sales */
SELECT 
    s.StoreName, 
    SUM(o.TotalAmount) AS Total_Sales
FROM Orders o
JOIN Stores s ON o.StoreID = s.StoreID
GROUP BY s.StoreName
ORDER BY Total_Sales DESC;

/* Daily Average Bill Value*/
SELECT 
    o.OrderDate, 
    ROUND(SUM(o.TotalAmount) / COUNT(DISTINCT o.OrderID), 2) AS Avg_Bill_Value
FROM Orders o
GROUP BY o.OrderDate
ORDER BY o.OrderDate;

/* Store-wise Average Bill Value*/
SELECT 
    s.StoreName, 
    ROUND(SUM(o.TotalAmount) / COUNT(DISTINCT o.OrderID), 2) AS Avg_Bill_Value
FROM Orders o
JOIN Stores s ON o.StoreID = s.StoreID
GROUP BY s.StoreName
ORDER BY Avg_Bill_Value DESC;

/* Bill Count + Total Sales + Avg Bill Value in one query) */
SELECT
    s.StoreName,
    o.OrderDate,
    COUNT(DISTINCT o.OrderID) AS Bill_Count,
    SUM(o.TotalAmount) AS Total_Sales,
    ROUND(SUM(o.TotalAmount) / COUNT(DISTINCT o.OrderID), 2) AS Avg_Bill_Value
FROM Orders o
JOIN Stores s ON o.StoreID = s.StoreID
GROUP BY s.StoreName, o.OrderDate
ORDER BY o.OrderDate, s.StoreName;