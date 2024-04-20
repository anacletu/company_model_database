-- ------------------------------------------------------------------------------
--   SQL Queries by Eric Anacleto Ribeiro
--   Contains examples of SQL queries for the Company database
--   2024-04-18; last update on 2024-04-19
-- ------------------------------------------------------------------------------


-- ------------------------------------------------------------------------------
-- Code used for generating the charts (Distribution Analysis)
-- ------------------------------------------------------------------------------
--- Revenue From Last Orders
SELECT
    OrderNumber,
    TotalPrice
FROM
    (
        SELECT
            OrderNumber,
            TotalPrice,
            ROW_NUMBER() OVER (ORDER BY OrderNumber DESC) AS row_num
        FROM
            SalesOrders
    )
WHERE
    row_num <= 5
ORDER BY
    OrderNumber;

-- Employees per Department
SELECT DepartmentName AS Department, COUNT(*) AS Employees
FROM Employees
JOIN Departments ON Employees.DepartmentNumber = Departments.DepartmentNumber
GROUP BY DepartmentName
ORDER BY DepartmentName;

-- Highest Salaries
SELECT FirstName || ' ' || LastName || ' - ' || JobTitle AS Employee, Salary AS Salary
FROM Employees
ORDER BY Salary DESC
FETCH FIRST 5 ROWS ONLY;


-- ------------------------------------------------------------------------------
-- Examples of SQL queries for interacting with the Company database
-- ------------------------------------------------------------------------------
-- Query to show the employees with the highest salaries
SELECT FirstName, LastName, TO_CHAR(Salary, 'FM$999,999,999') AS Salary
FROM Employees
ORDER BY Salary DESC
FETCH FIRST 5 ROWS ONLY;

-- Query to show the departments with the most employees
SELECT DepartmentName, COUNT(EmployeeID) as EmployeeCount
FROM Employees E
JOIN Departments D ON E.DepartmentNumber = D.DepartmentNumber
GROUP BY DepartmentName
ORDER BY EmployeeCount DESC
FETCH FIRST 1 ROW ONLY;

-- Query to show thea total number of sales per product
SELECT P.ProductName, SUM(OD.Quantity) as TotalSales
FROM OrdersDetails OD
JOIN Products P ON OD.ProductID = P.ProductID
GROUP BY P.ProductName
ORDER BY TotalSales DESC;

-- Query to show the total number of orders per customer
SELECT C.CustomerName, COUNT(SO.OrderNumber) as TotalOrders
FROM SalesOrders SO
JOIN Customers C ON SO.CustomerID = C.CustomerID
GROUP BY C.CustomerName
ORDER BY TotalOrders DESC
FETCH FIRST 1 ROW ONLY;

-- Query to show the employee that worked the most hours in the last week
SELECT E.FirstName, E.LastName, SUM(A.HoursPerWeek) as TotalHours
FROM Assignments A
JOIN Employees E ON A.EmployeeID = E.EmployeeID
WHERE A.AssignmentStart >= SYSDATE - 7
GROUP BY E.FirstName, E.LastName
ORDER BY TotalHours DESC
FETCH FIRST 1 ROW ONLY;