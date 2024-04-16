-- ------------------------------------------------------------------------------
--   DDL code by Eric Anacleto Ribeiro
--   Contains the Data Definition Language code for creating the database schema
--   2024-03-31; updated on 2024-04-15
-- ------------------------------------------------------------------------------


-- Statements for debugging
DROP TABLE Dependents CASCADE CONSTRAINTS;
DROP TABLE EmployeeTranfers CASCADE CONSTRAINTS;
DROP TABLE Departments CASCADE CONSTRAINTS;
DROP TABLE Locations CASCADE CONSTRAINTS;
DROP TABLE DepartmentManagers CASCADE CONSTRAINTS;
DROP TABLE ProductTransfers CASCADE CONSTRAINTS;
DROP TABLE Inventory CASCADE CONSTRAINTS;
DROP TABLE Warehouses CASCADE CONSTRAINTS;
DROP TABLE OrdersDetails CASCADE CONSTRAINTS;
DROP TABLE SalesOrders CASCADE CONSTRAINTS;
DROP TABLE Products CASCADE CONSTRAINTS;
DROP TABLE Customers CASCADE CONSTRAINTS;
DROP TABLE Assignments CASCADE CONSTRAINTS;
DROP TABLE Projects CASCADE CONSTRAINTS;
DROP TABLE Employees CASCADE CONSTRAINTS;
DROP TRIGGER update_employee_department;
DROP TRIGGER update_warehouse_inventory;


-- Generating the tables
-- The Departments table stores information about the different departments in the organization.
-- Managers will be dealt with in a separate table, as they can change over time and the period of management must be stored, as per instructions.
CREATE TABLE Departments (
    DepartmentNumber NUMBER,
    DepartmentName VARCHAR2(30) NOT NULL,
    PRIMARY KEY (DepartmentNumber)
);

-- The Locations table stores information about the different locations where departments, warehouses and/or projects are located.
-- As Departments can have multiple locations, the DepartmentNumber column is a foreign key. The same does not apply for Warehouses and Projects.
CREATE TABLE Locations (
    LocationCode NUMBER,
    DepartmentNumber NUMBER,
    StreetAddress VARCHAR2(200) NOT NULL,
    City VARCHAR2(50) NOT NULL,
    ZipCode VARCHAR2(10) NOT NULL,
    PRIMARY KEY (LocationCode),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber)
);

-- The Employees table stores information about the employees in the organization.
-- The SupervisorID column is a foreign key that references the EmployeeID column in the same table. It can be NULL as not all employees have a supervisor (e.g. C-Level).
-- The address is stored in a single column within the table, as the Locations table refers only to entities that belong to the company.
CREATE TABLE Employees (
    EmployeeID NUMBER,
    SupervisorID NUMBER,
    DepartmentNumber NUMBER NOT NULL,
    IsManager CHAR(1) DEFAULT 0 NOT NULL,
    JobTile VARCHAR2(30) NOT NULL,
    FirstName VARCHAR2(15) NOT NULL,
    LastName VARCHAR2(30) NOT NULL,
    NationalInsuranceNumber VARCHAR2(20) NOT NULL,
    StreetAddress VARCHAR2(100) NOT NULL,
    Salary NUMBER NOT NULL,
    DateOfBirth DATE NOT NULL,
    Email VARCHAR2(50) NOT NULL UNIQUE,
    PhoneNumber VARCHAR2(20) NOT NULL,
    StartDate DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
    LeavingDate DATE,
    PRIMARY KEY (EmployeeID),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber),
    FOREIGN KEY (SupervisorID) REFERENCES Employee(EmployeeID)
);

-- The DepartmentManagers table stores information about the managers of departments.
-- Composite PK does not work since nothing prevents the same employee to manage the same department multiple times. This allows for a record to be created for each management period.
CREATE TABLE DepartmentManagers (
    ManagerID NUMBER,
    EmployeeID NUMBER NOT NULL,
    DepartmentNumber NUMBER NOT NULL,
    StartDate DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
    EndDate DATE,
    PRIMARY KEY (ManagerID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber)
);

-- Trigger to update the IsManager column in the Employees table when a new manager is assigned to a department
CREATE OR REPLACE TRIGGER set_is_manager
AFTER INSERT OR UPDATE ON DepartmentManagers
FOR EACH ROW
BEGIN
   UPDATE Employees
   SET IsManager = 1
   WHERE EmployeeID = :new.EmployeeID;
END;
/

-- The Dependents table stores information about the dependents of employees.
CREATE TABLE Dependents (
    DependentID NUMBER,
    EmployeeID NUMBER NOT NULL,
    FirstName VARCHAR2(15) NOT NULL,
    BirthDate DATE NOT NULL,
    Relationship VARCHAR2(50) NOT NULL,
    PRIMARY KEY (DependentID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)
);

-- The EmployeeTransfers table stores information about the department transfers of employees.
CREATE TABLE EmployeeTransfers (
    TransferID NUMBER,
    EmployeeID NUMBER NOT NULL,
    FromDepartmentNumber NUMBER NOT NULL,
    ToDepartmentNumber NUMBER NOT NULL,
    TransferDate DATE DEFAULT TRUNC(SYSDATE) NOT NULL,
    PRIMARY KEY (TransferID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
    FOREIGN KEY (FromDepartmentNumber) REFERENCES Department(DepartmentNumber)
    FOREIGN KEY (ToDepartmentNumber) REFERENCES Department(DepartmentNumber)
    CHECK (FromDepartmentNumber <> ToDepartmentNumber)
);

-- Trigger to update the department of an employee when a transfer is recorded
CREATE OR REPLACE TRIGGER update_employee_department
AFTER INSERT ON EmployeeTransfers
FOR EACH ROW
BEGIN
   UPDATE Employee
   SET DepartmentNumber = :new.ToDepartmentNumber
   WHERE EmployeeID = :new.EmployeeID;
END;
/

-- The Projects table stores information about the projects in the organization.
CREATE TABLE Projects (
    ProjectNumber NUMBER,
    DepartmentNumber NUMBER NOT NULL,
    LocationCode NUMBER NOT NULL,
    ProjectName VARCHAR2(50) NOT NULL,
    StartDate DEFAULT TRUNC(SYSDATE) NOT NULL,
    PRIMARY KEY (ProjectNumber),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber),
    FOREIGN KEY (LocationCode) REFERENCES Location(LocationCode)
);

-- The Assignments table stores information about the assignments of employees to projects.
-- AssignmentID as a PK accomodates the edge case in which an employee is assigned to the same project multiple times.
CREATE TABLE Assignments (
    AssignmentID NUMBER,
    EmployeeID NUMBER,
    ProjectNumber NUMBER,
    HoursPerWeek NUMBER NOT NULL,
    PRIMARY KEY (AssignmentID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
    FOREIGN KEY (ProjectNumber) REFERENCES Project(ProjectNumber)
);

-- The Customers table stores information about the customers of the organization.
-- The SalesRepresentative column is a foreign key that references the EmployeeID column in the Employees table responsible for the contact.
-- The SalesRepresentative can be an attribute since each customer always contacts one and the same salesperson.
CREATE TABLE Customers (
    CustomerID NUMBER,
    CustomerName VARCHAR2(50) NOT NULL,
    CustomerEmail VARCHAR2(50),
    CustomerPhone VARCHAR2(20),
    SalesRepresentative NUMBER NOT NULL,
    PRIMARY KEY (CustomerID),
    FOREIGN KEY (SalesRepresentative) REFERENCES Employee(EmployeeID)
);

-- The Products table stores information about the products sold by the organization.
CREATE TABLE Products (
    ProductID NUMBER,
    ProductName VARCHAR2(20) NOT NULL,
    ProductCategory VARCHAR2(20) NOT NULL,
    ProducutDescription VARCHAR2(200),
    PRIMARY KEY (ProductID)
);

-- The SalesOrdes table stores information about the sales orders placed by customers.
-- Since an order can have more than one product, this table simply links an order to a customer (adhering to the 1NF).
CREATE TABLE SalesOrders (
    OrderNumber NUMBER,
    CustomerID NUMBER NOT NULL,
    PRIMARY KEY (OrderNumber),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- The OrdersDetails table stores information about the products ordered in each sales order.
-- Each combination of OrderNumber and ProductID is unique, as a product can only appear once in the same order.
CREATE TABLE OrdersDetails (
    OrderNumber NUMBER,
    ProductID NUMBER, 
    Quantity NUMBER NOT NULL,
    PRIMARY KEY (OrderNumber, ProductID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (OrderNumber) REFERENCES SalesOrder(OrderNumber)
);

-- The Warehouses table stores information about the different warehouses where products are stored.
CREATE TABLE Warehouses (
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

-- The ProductTransfers table stores information about product transfers between warehouses to ensure correct inventory.
CREATE TABLE ProductTransfers (
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

-- Trigger to update the inventory of a warehouse when a product transfer is recorded
CREATE OR REPLACE TRIGGER update_warehouse_inventory
AFTER INSERT ON ProductTransfers
FOR EACH ROW
BEGIN
   -- Decrease the quantity of the product in the FromWarehouse
   UPDATE Inventory
   SET Quantity = Quantity - :new.Quantity
   WHERE WarehouseID = :new.FromWarehouseID AND ProductID = :new.ProductID;

   -- Increase the quantity of the product in the ToWarehouse
   UPDATE Inventory
   SET Quantity = Quantity + :new.Quantity
   WHERE WarehouseID = :new.ToWarehouseID AND ProductID = :new.ProductID;
END;
/