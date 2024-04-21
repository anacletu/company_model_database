-- ------------------------------------------------------------------------------
--    DML code by Eric Anacleto Ribeiro
--    Contains Data Manipulation Language code for the Company database
--    2024-04-15; last update on 2024-04-19
-- ------------------------------------------------------------------------------


-- ------------------------------------------------------------------------------
-- Delete statements to clear the tables before inserting data
-- ------------------------------------------------------------------------------
DELETE FROM ProductTransfers;
DELETE FROM OrdersDetails;
DELETE FROM SalesOrders;
DELETE FROM Customers;
DELETE FROM Inventory;
DELETE FROM Products;
DELETE FROM Warehouses;
DELETE FROM Assignments;
DELETE FROM Projects;
DELETE FROM Dependents;
DELETE FROM DepartmentManagers;
DELETE FROM Employees;
DELETE FROM Locations;
DELETE FROM Departments;
DELETE FROM EmployeeTransfers;


-- ------------------------------------------------------------------------------
-- Code for inserting data into the Company Database tables
-- ------------------------------------------------------------------------------
INSERT INTO Departments (DepartmentName)
SELECT 'Department' || rownum
FROM dual
CONNECT BY LEVEL <= 5;

-- Using CASE statement to simulate the possibility of an employee leaving the company
INSERT INTO Employees (DepartmentNumber, JobTitle, FirstName, LastName, NationalInsuranceNumber, StreetAddress, Salary, DateOfBirth, Email, PhoneNumber, StartDate, LeavingDate)
SELECT
    CEIL(DBMS_RANDOM.VALUE(0, 5)),
    p.job_title, 
    p.first_name, 
    p.last_name, 
    random_national_insurance_number(), 
    'StreetAddress' || ' ' || rownum, 
    random_salary(), 
    random_birth_date(), 
    p.email, 
    random_phone_number(), 
    random_date() AS StartDate,
    CASE 
        WHEN DBMS_RANDOM.VALUE < 0.2 THEN random_date() + FLOOR(DBMS_RANDOM.VALUE(1,365))
        ELSE NULL
    END AS LeavingDate
FROM People p
WHERE rownum <= 1000;

-- Using CASE statement to insert NULL values in the DepartmentNumber column, as not everylocation is necessarily associated with a department
INSERT INTO Locations (DepartmentNumber, StreetAddress, City, ZipCode)
SELECT
    CASE 
        WHEN DBMS_RANDOM.VALUE < 0.2 THEN NULL
        ELSE CEIL(DBMS_RANDOM.VALUE(1, 5))
    END,
    'LocationAddress' || ' ' || rownum,
    'City' || rownum,
    random_uk_postcode()
FROM dual
CONNECT BY LEVEL <= 20;

-- Perhaps not the most efficient way to do this, but it is a way to populate the DepartmentManagers table making sure that each department has at least one manager and that manager is an employee of the same department
-- This triggers the set_is_manager trigger, which updates the IsManager column in the Employees table
-- StartDate takes the value of the employee's StartDate plus a random number of days between 1 and 365
BEGIN
    FOR i IN 1..6 LOOP
        INSERT INTO DepartmentManagers (EmployeeID, DepartmentNumber, StartDate)
        SELECT
            EmployeeID,
            DepartmentNumber,
            StartDate + FLOOR(DBMS_RANDOM.VALUE(1,365))
        FROM (
            SELECT
                EmployeeID,
                DepartmentNumber,
                StartDate
            FROM Employees
            WHERE LeavingDate IS NOT NULL AND DepartmentNumber = i
            ORDER BY DBMS_RANDOM.VALUE
        )
        WHERE ROWNUM = 1;
    END LOOP;
    COMMIT;
END;
/


-- Inserting dependents for employees, with a 20% chance of being a partner
-- The random_birth_date function is used to generate the birth date of the dependents, which might not be the most accurate way to simulate real data considering it might generate dates before the employee's birth date, for example, but it suffices for example purposes
INSERT INTO Dependents (EmployeeID, FirstName, BirthDate, Relationship)
SELECT
    EmployeeID,
    FirstName,
    random_birth_date(),
    CASE 
        WHEN DBMS_RANDOM.VALUE < 0.2 THEN 'Partner'
        ELSE 'Child'
    END
FROM Employees
ORDER BY DBMS_RANDOM.VALUE
FETCH FIRST 100 ROWS ONLY;

-- Just an example of how to insert data into the EmployeeTransfers table
-- This could use a loop to populate more rows or a SELECT statement to get data from other tables
INSERT INTO EmployeeTransfers (EmployeeID, FromDepartmentNumber, ToDepartmentNumber, TransferDate)
VALUES (FLOOR(DBMS_RANDOM.VALUE(100, 200)), 1, 2, random_date());

-- Inserting data into the Projects table
-- The CASE statement is used to simulate the possibility of a project having an end date or not
INSERT INTO Projects (DepartmentNumber, LocationCode, ProjectName, StartDate, EndDate)
SELECT
    CEIL(DBMS_RANDOM.VALUE(1, 5)),
    CEIL(DBMS_RANDOM.VALUE(1, 20)),
    'Project' || rownum,
    random_date(),
    CASE 
        WHEN DBMS_RANDOM.VALUE < 0.2 THEN random_date() + FLOOR(DBMS_RANDOM.VALUE(1, 365))
        ELSE NULL
    END
FROM dual
CONNECT BY LEVEL <= 100;

-- This code should insert around 50 000 rows into the Assignments table, as it is a cross join between the Employees and Projects tables
-- As there is a trigger to control if the assignment date is within the project's start and end date, the dates here were just copied from the Projects table
INSERT INTO Assignments (EmployeeID, ProjectNumber, HoursPerWeek, AssignmentStart)
SELECT
    EmployeeID,
    FLOOR(DBMS_RANDOM.VALUE(1, 100)),
    FLOOR(DBMS_RANDOM.VALUE(10, 40)),
    random_date()
FROM Employees;

-- This code populates the customers table with employees that work on sales, limiting the number of rows to 100 as an example
INSERT INTO Customers (SalesRepresentative, CustomerName, CustomerEmail, CustomerPhone)
SELECT
    EmployeeID,
    'Customer' || rownum,
    'CustomerName' || rownum || '@example.com',
    random_phone_number()
FROM Employees
WHERE UPPER(Employees.JobTitle) LIKE '%SALES%'
ORDER BY DBMS_RANDOM.VALUE
FETCH FIRST 100 ROWS ONLY;

-- Using the sample_products table provided to populate the Products table
INSERT INTO Products (ProductName, ProductWeight, ProductPrice)
SELECT
    productname,
    weight_kg,
    price
FROM sample_products;

-- Inserting sales orders without total price as this will be updated by the procedure update_sales_orders
INSERT INTO SalesOrders (CustomerID, OrderDate)
SELECT
    CustomerID,
    TRUNC(SYSDATE) - FLOOR(DBMS_RANDOM.VALUE(1, 365))
FROM Customers
ORDER BY DBMS_RANDOM.VALUE
FETCH FIRST 30 ROWS ONLY;

-- Creating the warehouses table with a random selection of locations
INSERT INTO Warehouses (LocationCode)
SELECT
    LocationCode
FROM Locations
ORDER BY DBMS_RANDOM.VALUE
FETCH FIRST 5 ROWS ONLY;

-- Populating the Inventory table with random quantities of products in the warehouses
-- Using DBMS_RANDOM.VALUE instead of a cross join to avoid inserting the same product in multiple warehouses (as this is just an example and not a real-world scenario)
INSERT INTO Inventory (ProductID, WarehouseID, Quantity)
SELECT
    ProductID,
    CEIL(DBMS_RANDOM.VALUE(1, 5)),
    FLOOR(DBMS_RANDOM.VALUE(10, 100))
FROM Products;

-- Creating some random orders details for the sales orders
-- This code only works if the trigger check_stock does not return an error (in case of absence of stock for a product)
-- Here again I am not using a cross join to avoid making things too complicated for this example (as this might extrapolate the number of products in the inventory table)
-- After running this code, it is necessaty to call the update_sales_orders procedure to update the total price of the orders
INSERT INTO OrdersDetails (OrderNumber, ProductID, Quantity, SubTotal)
SELECT
    OrderNumber,
    ProductID,
    Quantity,
    (SELECT ProductPrice FROM Products WHERE ProductID = t.ProductID) * t.Quantity AS SubTotal
FROM (
    SELECT
        OrderNumber,
        FLOOR(DBMS_RANDOM.VALUE(1, 3486)) AS ProductID,
        FLOOR(DBMS_RANDOM.VALUE(1, 5)) AS Quantity
    FROM SalesOrders
) t;

-- Call to update the SalesOrders table after an OrdersDetails insert or update
BEGIN
    update_sales_orders();
END;
/

-- Simple example to insert a product transfer
-- I previously made sure that the product does exist in the inventory of the FromWarehouse by checking the Inventory table
-- The trigger update_inventory will update the quantity of the product in the FromWarehouse and ToWarehouse
INSERT INTO ProductTransfers (ProductID, FromWarehouseID, ToWarehouseID, Quantity)
VALUES (3, 2, 1, 10);
