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