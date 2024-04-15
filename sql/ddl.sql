-- ------------------------------------------------------------------------------
--   DDL code by Eric Anacleto Ribeiro
--   Contains the Data Definition Language code for creating the database schema
--   2024-03-31
-- ------------------------------------------------------------------------------


-- Statements for debugging
DROP TABLE Dependent CASCADE CONSTRAINTS;
DROP TABLE EmployeeDepartmentHistory CASCADE CONSTRAINTS;
DROP TABLE Department CASCADE CONSTRAINTS;
DROP TABLE Location CASCADE CONSTRAINTS;
DROP TABLE ProductTransfer CASCADE CONSTRAINTS;
DROP TABLE Inventory CASCADE CONSTRAINTS;
DROP TABLE Warehouse CASCADE CONSTRAINTS;
DROP TABLE OrderDetail CASCADE CONSTRAINTS;
DROP TABLE SalesOrder CASCADE CONSTRAINTS;
DROP TABLE Product CASCADE CONSTRAINTS;
DROP TABLE Customer CASCADE CONSTRAINTS;
DROP TABLE Assignment CASCADE CONSTRAINTS;
DROP TABLE Project CASCADE CONSTRAINTS;
DROP TABLE Employee CASCADE CONSTRAINTS;


-- Generating the tables
-- The Department table stores information about the different departments in the organization.
CREATE TABLE Department (
    DepartmentNumber NUMBER,
    DepartmentName VARCHAR2(30) NOT NULL,
    DepartmentManager NUMBER NOT NULL,
    ManagerStartDate DATE NOT NULL,
    ManagerEndDate DATE,
    PRIMARY KEY (DepartmentNumber)
);

-- The Location table stores information about the different locations where departments are located.
CREATE TABLE Location (
    LocationCode NUMBER,
    DepartmentNumber NUMBER NOT NULL,
    LocationAddress VARCHAR2(200) NOT NULL,
    PRIMARY KEY (LocationCode),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber)
);

-- The Employee table stores information about the employees in the organization.
CREATE TABLE Employee (
    EmployeeID NUMBER,
    SupervisorID NUMBER,
    DepartmentNumber NUMBER NOT NULL,
    JobTile VARCHAR2(30) NOT NULL,
    FirstName VARCHAR2(15) NOT NULL,
    LastName VARCHAR2(30) NOT NULL,
    Address VARCHAR2(100) NOT NULL,
    Salary NUMBER NOT NULL,
    DateOfBirth DATE NOT NULL,
    Email VARCHAR2(50) NOT NULL UNIQUE,
    PhoneNumber VARCHAR2(20) NOT NULL,
    StartDate DATE NOT NULL,
    LeavingDate DATE,
    PRIMARY KEY (EmployeeID),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber),
    FOREIGN KEY (SupervisorID) REFERENCES Employee(EmployeeID)
);

-- Adding a foreign key constraint to the DepartmentManager column in the Department table.
ALTER TABLE Department
ADD CONSTRAINT FK_DepartmentManager
FOREIGN KEY (DepartmentManager) REFERENCES Employee(EmployeeID);

-- The Dependent table stores information about the dependents of employees.
CREATE TABLE Dependent (
    DependentID NUMBER,
    EmployeeID NUMBER NOT NULL,
    FirstName VARCHAR2(15) NOT NULL,
    BirthDate DATE NOT NULL,
    Relationship VARCHAR2(50) NOT NULL,
    PRIMARY KEY (DependentID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

-- The EmployeeDepartmentHistory table stores information about the department transfers of employees.
CREATE TABLE EmployeeDepartmentHistory (
    TransferID NUMBER,
    EmployeeID NUMBER NOT NULL,
    DepartmentNumber NUMBER NOT NULL,
    StartDate DATE NOT NULL,
    TransferDate DATE,
    PRIMARY KEY (TransferID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber)
);

-- The Project table stores information about the projects in the organization.
CREATE TABLE Project (
    ProjectNumber NUMBER,
    DepartmentNumber NUMBER NOT NULL,
    LocationCode NUMBER NOT NULL,
    ProjectName VARCHAR2(50) NOT NULL,
    StartDate DATE NOT NULL,
    PRIMARY KEY (ProjectNumber),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber),
    FOREIGN KEY (LocationCode) REFERENCES Location(LocationCode)
);

-- The Assignment table stores information about the assignments of employees to projects.
CREATE TABLE Assignment (
    EmployeeID NUMBER,
    ProjectNumber NUMBER,
    HoursPerWeek NUMBER NOT NULL,
    PRIMARY KEY (EmployeeID, ProjectNumber),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
    FOREIGN KEY (ProjectNumber) REFERENCES Project(ProjectNumber)
);

-- The Customer table stores information about the customers of the organization.
CREATE TABLE Customer (
    CustomerID NUMBER,
    CustomerName VARCHAR2(50) NOT NULL,
    CustomerEmail VARCHAR2(50),
    SalesRepresentative NUMBER NOT NULL,
    PRIMARY KEY (CustomerID),
    FOREIGN KEY (SalesRepresentative) REFERENCES Employee(EmployeeID)
);

-- The Product table stores information about the products sold by the organization.
CREATE TABLE Product (
    ProductID NUMBER,
    ProductName VARCHAR2(20) NOT NULL,
    PRIMARY KEY (ProductID)
);

-- The SalesOrder table stores information about the sales orders placed by customers.
CREATE TABLE SalesOrder (
    OrderNumber NUMBER,
    CustomerID NUMBER NOT NULL,
    PRIMARY KEY (OrderNumber),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- The OrderDetail table stores information about the products ordered in each sales order.
CREATE TABLE OrderDetail (
    OrderNumber NUMBER,
    ProductID NUMBER, 
    Quantity NUMBER NOT NULL,
    PRIMARY KEY (OrderNumber, ProductID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (OrderNumber) REFERENCES SalesOrder(OrderNumber)
);

-- The Warehouse table stores information about the different warehouses where products are stored.
CREATE TABLE Warehouse (
    WarehouseID NUMBER,
    LocationCode NUMBER NOT NULL,
    PRIMARY KEY (WarehouseID),
    FOREIGN KEY (LocationCode) REFERENCES Location(LocationCode)
);

-- Tracks inventory levels for products in each warehouse.
CREATE TABLE Inventory (
    InventoryID NUMBER,
    ProductID NUMBER NOT NULL,
    WarehouseID NUMBER NOT NULL,
    Quantity NUMBER NOT NULL,
    PRIMARY KEY (InventoryID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID)
);

-- The ProductTransfer table stores information about product transfers between warehouses.
CREATE TABLE ProductTransfer (
    TransferID NUMBER,
    ProductID NUMBER NOT NULL,
    FromWarehouseID NUMBER NOT NULL,
    ToWarehouseID NUMBER NOT NULL,
    Quantity NUMBER NOT NULL,
    TransferDate DATE NOT NULL,
    PRIMARY KEY (TransferID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (FromWarehouseID) REFERENCES Warehouse(WarehouseID),
    FOREIGN KEY (ToWarehouseID) REFERENCES Warehouse(WarehouseID),
    CHECK (FromWarehouseID <> ToWarehouseID)
);
