-- ------------------------------------------------------------------------------
--    Triggers code by Eric Anacleto Ribeiro
--    Contains triggers for the Company database
--    2024-04-15; last update on 2024-04-19
-- ------------------------------------------------------------------------------


-- Trigger to check if there is enough stock for a product before placing an order.
CREATE OR REPLACE TRIGGER check_stock
BEFORE INSERT OR UPDATE ON OrdersDetails
FOR EACH ROW
DECLARE
   stock_quantity Inventory.Quantity%TYPE;
BEGIN
   SELECT Quantity INTO stock_quantity
   FROM Inventory
   WHERE ProductID = :NEW.ProductID;

   IF :NEW.Quantity > stock_quantity THEN
      RAISE_APPLICATION_ERROR(-20001, 'Not enough stock for this product.');
   END IF;
END;
/

-- Trigger to update the inventory of a warehouse when a product is ordered.
CREATE OR REPLACE TRIGGER update_inventory_on_order_update
AFTER UPDATE OF Quantity ON OrdersDetails
FOR EACH ROW
BEGIN
    UPDATE Inventory
    SET Quantity = Quantity - (:new.Quantity - :old.Quantity)
    WHERE ProductID = :new.ProductID;
END;
/

-- Trigger to update the IsManager column in the Employees table when a new manager is assigned to a department.
CREATE OR REPLACE TRIGGER set_is_manager
AFTER INSERT OR UPDATE ON DepartmentManagers
FOR EACH ROW
BEGIN
    UPDATE Employees
    SET IsManager = 1
    WHERE EmployeeID = :new.EmployeeID;
END;
/

-- Trigger to update the IsManager column in the Employees table when a manager's management period ends.
CREATE OR REPLACE TRIGGER end_of_managing_period
BEFORE UPDATE OF EndDate ON DepartmentManagers
FOR EACH ROW
BEGIN
    UPDATE Employees
    SET IsManager = 0
    WHERE EmployeeID = :old.EmployeeID;
END;
/

-- Trigger to update the department of an employee when a transfer is recorded.
CREATE OR REPLACE TRIGGER update_employee_department
AFTER INSERT ON EmployeeTransfers
FOR EACH ROW
BEGIN
    UPDATE Employees
    SET DepartmentNumber = :new.ToDepartmentNumber
    WHERE EmployeeID = :new.EmployeeID;
END;
/

-- Trigger to handle the deletion of an employee from the Employees table, updating all related tables.
-- In case an employee leaves the company, but their information must be kept for future reference, the trigger can be adjusted to update the LeavingDate column instead of deleting the record.
-- The deletions in the trigger are illustrative and might be adjusted to the specific needs of the organization.
CREATE OR REPLACE TRIGGER handle_employee_deletion
AFTER DELETE ON Employees
FOR EACH ROW
BEGIN
    DELETE FROM DepartmentManagers WHERE EmployeeID = :old.EmployeeID;
    DELETE FROM Dependents WHERE EmployeeID = :old.EmployeeID;
    DELETE FROM EmployeeTransfers WHERE EmployeeID = :old.EmployeeID;
    DELETE FROM Assignments WHERE EmployeeID = :old.EmployeeID;
    UPDATE Customers SET SalesRepresentative = NULL WHERE SalesRepresentative = :old.EmployeeID;
END;
/

-- Trigger to handle the update of the LeavingDate column in the Employees table, updating all related tables.
-- This is an alternative to the previous trigger depending on data retention policies. Both triggers can be used together if necessary.
-- I am including two conditions in the WHEN clause to cover the case in which the company decides to use a fictitious date for the LeavingDate column, such as 9999-01-01, instead of NULL.
CREATE OR REPLACE TRIGGER handle_employee_leaving
AFTER UPDATE OF LeavingDate ON Employees
FOR EACH ROW
WHEN (NEW.LeavingDate IS NOT NULL AND NEW.LeavingDate < SYSDATE)
BEGIN
    DELETE FROM DepartmentManagers WHERE EmployeeID = :NEW.EmployeeID;
    DELETE FROM Dependents WHERE EmployeeID = :NEW.EmployeeID;
    DELETE FROM EmployeeTransfers WHERE EmployeeID = :NEW.EmployeeID;
    DELETE FROM Assignments WHERE EmployeeID = :NEW.EmployeeID;
    UPDATE Customers SET SalesRepresentative = NULL WHERE SalesRepresentative = :NEW.EmployeeID;
END;
/

-- Trigger to handle the deletion of a product from the Products table, updating all related tables.
-- The behavios of this trigger is illustrative and might be adjusted to the specific needs of the organization, for example when there is a need to keep a record of old orders even after a product is retired.
CREATE OR REPLACE TRIGGER handle_product_deletion
AFTER DELETE ON Products
FOR EACH ROW
BEGIN
    DELETE FROM OrdersDetails WHERE ProductID = :old.ProductID;
    DELETE FROM Inventory WHERE ProductID = :old.ProductID;
    DELETE FROM ProductTransfers WHERE ProductID = :old.ProductID;
END;
/

-- Trigger to check if there is enough inventory to transfer a product between warehouses.
CREATE OR REPLACE TRIGGER check_inventory
BEFORE INSERT ON ProductTransfers
FOR EACH ROW
DECLARE
    v_quantity Inventory.Quantity%TYPE;
BEGIN
    SELECT Quantity INTO v_quantity
    FROM Inventory
    WHERE ProductID = :new.ProductID;

    IF v_quantity - :new.Quantity < 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'Not enough products in inventory');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Product not found in inventory');
END;
/

-- Trigger to update the inventory of a warehouse when a product transfer is recorded.
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

-- Trigger to check if the assignment dates fall within the project dates.
CREATE OR REPLACE TRIGGER check_assignment_dates
BEFORE INSERT OR UPDATE ON Assignments
FOR EACH ROW
DECLARE
    project_start Projects.StartDate%TYPE;
    project_end Projects.EndDate%TYPE;
BEGIN
    SELECT StartDate, EndDate INTO project_start, project_end
    FROM Projects
    WHERE ProjectNumber = :NEW.ProjectNumber;

    IF :NEW.AssignmentStart < project_start OR :NEW.AssignmentEnd > project_end THEN
        RAISE_APPLICATION_ERROR(-20001, 'Assignment dates must fall within the project dates.');
    END IF;
END;
/

-- Trigger to check if the selected employee is in a sales role when assigning them as a sales representative for a customer.
-- This trigger is just an illustrative exercise and might not be feasible depending on the company's organization.
CREATE OR REPLACE TRIGGER check_sales_rep
BEFORE INSERT OR UPDATE ON Customers
FOR EACH ROW
DECLARE
    employee_job Employees.JobTitle%TYPE;
BEGIN
    SELECT JobTitle INTO employee_job
    FROM Employees
    WHERE EmployeeID = :NEW.SalesRepresentative;

    IF NOT UPPER(employee_job) LIKE '%SALES%' THEN
        RAISE_APPLICATION_ERROR(-20002, 'The employee you selected is not in a sales role.');
    END IF;
END;
/

-- Trigger to calculate the total price of an order based on the sum of the subtotals of the order details.
CREATE OR REPLACE TRIGGER calculate_total_price
AFTER INSERT OR UPDATE ON OrdersDetails
FOR EACH ROW
DECLARE
   total_price NUMBER(12, 2);
BEGIN
   SELECT SUM(SubTotal) INTO total_price
   FROM OrdersDetails
   WHERE OrderNumber = :NEW.OrderNumber;

   UPDATE SalesOrders
   SET TotalPrice = total_price
   WHERE OrderNumber = :NEW.OrderNumber;
END;
/

-- Procedure to update the total price of a sales order when an order detail is filled.
-- I created a procedure instead of a trigger to prevent the mutation of the table error.
CREATE OR REPLACE PROCEDURE update_sales_orders AS 
BEGIN
    UPDATE SalesOrders
    SET TotalPrice = (
        SELECT SUM(SubTotal)
        FROM OrdersDetails
        WHERE OrderNumber = SalesOrders.OrderNumber
    );
    COMMIT;
END;
/