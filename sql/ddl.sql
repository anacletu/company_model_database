-- ------------------------------------------------------------------------------
--   DDL code by Eric Anacleto Ribeiro
--   Contains the Data Definition Language code for creating the Company database schema
--   2024-03-31; last update on 2024-04-15
-- ------------------------------------------------------------------------------


-- ------------------------------------------------------------------------------
-- Drop statements for debugging and development purposes
-- ------------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE Dependents CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE EmployeeTranfers CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Departments CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Locations CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE DepartmentManagers CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE ProductTransfers CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Inventory CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Warehouses CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE OrdersDetails CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE SalesOrders CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Products CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Customers CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Assignments CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Projects CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Employees CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -4043 THEN
            RAISE;
        END IF;
END;
/


-- ------------------------------------------------------------------------------
-- Tables to store information about the company and compose the database schema
-- ------------------------------------------------------------------------------

-- The Departments table stores information about the different departments in the organization.
-- Managers will be dealt with in a separate table, as they can change over time and the period of management must be stored, as per instructions.
CREATE TABLE Departments (
    DepartmentNumber NUMBER,
    DepartmentName VARCHAR2(30) NOT NULL,
    PRIMARY KEY (DepartmentNumber)
);

-- The Locations table stores information about the different locations where departments, warehouses and/or projects are located.
-- As Departments can have multiple locations, the DepartmentNumber column is a foreign key. The same does not apply for Warehouses and Projects.
-- DepartmentNumber can be NULL as this table also stores information about locations that are not directly related to a department.
CREATE TABLE Locations (
    LocationCode NUMBER,
    DepartmentNumber NUMBER,
    StreetAddress VARCHAR2(100) NOT NULL,
    City VARCHAR2(50) NOT NULL,
    ZipCode VARCHAR2(10) NOT NULL,
    PRIMARY KEY (LocationCode),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber)
);

-- The Employees table stores information about the employees in the organization.
-- The SupervisorID column is a foreign key that references the EmployeeID column in the same table. It can be NULL as not all employees have a supervisor (e.g. C-Level).
-- The address is stored in a single column within the table, as the Locations table refers only to entities that belong to the company.
-- Even though a DEFAULT value is set for some columns, the NOT NULL constraint prevents future insertion manipulations without a value. This also applies to all other tables.
CREATE TABLE Employees (
    EmployeeID NUMBER,
    SupervisorID NUMBER,
    DepartmentNumber NUMBER NOT NULL,
    IsManager NUMBER DEFAULT 0 NOT NULL,
    JobTitle VARCHAR2(30) NOT NULL,
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

-- The Projects table stores information about the projects in the organization.
-- The use of DEFAULT SYSDATE vs only NOT NULL to ensure completion varies according to the organization's needs. Most likely, the organization will have a specific date for the start of a project, thus the choice to not use DEFAULT for this table.
CREATE TABLE Projects (
    ProjectNumber NUMBER,
    DepartmentNumber NUMBER NOT NULL,
    LocationCode NUMBER NOT NULL,
    ProjectName VARCHAR2(50) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE,
    PRIMARY KEY (ProjectNumber),
    FOREIGN KEY (DepartmentNumber) REFERENCES Department(DepartmentNumber),
    FOREIGN KEY (LocationCode) REFERENCES Location(LocationCode)
);

-- The Assignments table stores information about the assignments of employees to projects.
-- This table resolves the many-to-many relationship between Employees and Projects.
-- AssignmentID as a PK accomodates the edge case in which an employee is assigned to the same project multiple times (which invalidades a composite key of EmployeeID and ProjectNumber).
-- AssignmentStart and AssignmentEnd refers to the period in which the employee is assigned to the project, not necessarily the project's start and end dates, which is handled by the Projects table. To ensure that the assignment dates fall within the project dates, a stored procedure is used (dml.sql file).
CREATE TABLE Assignments (
    AssignmentID NUMBER,
    EmployeeID NUMBER NOT NULL,
    ProjectNumber NUMBER NOT NULL,
    HoursPerWeek NUMBER NOT NULL,
    AssignmentStart DATE NOT NULL,
    AssignmentEnd DATE,
    PRIMARY KEY (AssignmentID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
    FOREIGN KEY (ProjectNumber) REFERENCES Project(ProjectNumber)
);

-- The Customers table stores information about the customers of the organization.
-- The SalesRepresentative column is a foreign key that references the EmployeeID column in the Employees table responsible for the contact.
-- The SalesRepresentative can be an attribute since each customer always contacts one and the same salesperson.
-- The CHECK constraint ensures that at least one contact method is provided.
CREATE TABLE Customers (
    CustomerID NUMBER,
    CustomerName VARCHAR2(50) NOT NULL,
    CustomerEmail VARCHAR2(50),
    CustomerPhone VARCHAR2(20),
    SalesRepresentative NUMBER NOT NULL,
    PRIMARY KEY (CustomerID),
    FOREIGN KEY (SalesRepresentative) REFERENCES Employee(EmployeeID)
    CHECK (CustomerEmail IS NOT NULL OR CustomerPhone IS NOT NULL)
);

-- The Products table stores information about the products sold by the organization.
CREATE TABLE Products (
    ProductID NUMBER,
    ProductName VARCHAR2(20) NOT NULL,
    ProductWeight NUMBER NOT NULL,
    ProductPrice NUMBER(3, 2) NOT NULL,
    PRIMARY KEY (ProductID)
);

-- The SalesOrdes table stores information about the sales orders placed by customers.
-- Since an order can have more than one product, this table simply links an order to a customer (adhering to the 1NF).
-- Total price is allowed to be NULL as it can be calculated automatically from the OrdersDetails table once it is completed.
CREATE TABLE SalesOrders (
    OrderNumber NUMBER,
    CustomerID NUMBER NOT NULL,
    TotalPrice NUMBER(12, 2),
    PRIMARY KEY (OrderNumber),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- The OrdersDetails table stores information about the products ordered in each sales order.
-- The OrdersDetails table is necessary as SalesOrders and Products have a many-to-many relationship.
-- Each combination of OrderNumber and ProductID is unique, as a product can only appear once in the same order.
CREATE TABLE OrdersDetails (
    OrderNumber NUMBER,
    ProductID NUMBER, 
    Quantity NUMBER NOT NULL,
    SubTotal NUMBER(12, 2) NOT NULL,
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
-- This table is necessary as products and warehouses have a many-to-many relationship.
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
-- Data type for TransferDate is of TIMESTAMP to accomodate details that might be useful for future consultations.
CREATE TABLE ProductTransfers (
    TransferID NUMBER,
    ProductID NUMBER NOT NULL,
    FromWarehouseID NUMBER NOT NULL,
    ToWarehouseID NUMBER NOT NULL,
    Quantity NUMBER NOT NULL,
    TransferDate TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    PRIMARY KEY (TransferID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    FOREIGN KEY (FromWarehouseID) REFERENCES Warehouse(WarehouseID),
    FOREIGN KEY (ToWarehouseID) REFERENCES Warehouse(WarehouseID),
    CHECK (FromWarehouseID <> ToWarehouseID)
);