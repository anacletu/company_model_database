-- ------------------------------------------------------------------------------
--   Views code by Eric Anacleto Ribeiro
--   Contains some examples of views for the Company database
--   2024-04-18; last update on 2024-04-19
-- ------------------------------------------------------------------------------

-- Create a view that shows the details of each employee
CREATE OR REPLACE VIEW EmployeeDetails_view AS
SELECT E.EmployeeID, E.FirstName, E.LastName, E.JobTitle, E.Email, D.DepartmentName, M.FirstName AS ManagerFirstName, M.LastName AS ManagerLastName
FROM Employees E
JOIN Departments D ON E.DepartmentNumber = D.DepartmentNumber
LEFT JOIN DepartmentManagers DM ON D.DepartmentNumber = DM.DepartmentNumber;

-- Create a view that shows the details of each project
CREATE OR REPLACE VIEW ProjectAssignments_view AS
SELECT P.ProjectName, E.FirstName, E.LastName, A.HoursPerWeek
FROM Projects P
JOIN Assignments A ON P.ProjectNumber = A.ProjectNumber
JOIN Employees E ON A.EmployeeID = E.EmployeeID;

-- Create a view that shows the details of each customer order
CREATE OR REPLACE VIEW CustomerOrders_view AS
SELECT C.CustomerName, SO.OrderNumber, SO.OrderDate, OD.ProductID, OD.Quantity
FROM Customers C
JOIN SalesOrders SO ON C.CustomerID = SO.CustomerID
JOIN OrdersDetails OD ON SO.OrderNumber = OD.OrderNumber;

-- Create a view that shows the details of each product in the inventory
CREATE OR REPLACE VIEW InventoryStatus_view AS
SELECT P.ProductName, W.LocationCode, I.Quantity
FROM Inventory I
JOIN Products P ON I.ProductID = P.ProductID
JOIN Warehouses W ON I.WarehouseID = W.WarehouseID;

-- Create a view that shows the details of each product sale
CREATE OR REPLACE VIEW SalesPerProduct_view AS
SELECT P.ProductName, SUM(OD.Quantity) AS TotalSales
FROM OrdersDetails OD
JOIN Products P ON OD.ProductID = P.ProductID
GROUP BY P.ProductName;

-- Create a view that shows the details of each customer order
CREATE OR REPLACE VIEW OrdersPerClient_view AS
SELECT C.CustomerName, COUNT(SO.OrderNumber) AS TotalOrders
FROM SalesOrders SO
JOIN Customers C ON SO.CustomerID = C.CustomerID
GROUP BY C.CustomerName;