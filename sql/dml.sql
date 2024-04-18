-- ------------------------------------------------------------------------------
--    DML code by Eric Anacleto Ribeiro
--    Contains Data Manipulation Language code for the Company database
--    2024-04-15; last update on 2024-04-18
-- ------------------------------------------------------------------------------


-- ------------------------------------------------------------------------------
-- Drop statements for debugging and development purposes
-- ------------------------------------------------------------------------------
DROP SEQUENCE assignment_seq;
DROP SEQUENCE order_number_seq;

DROP TRIGGER check_stock;
DROP TRIGGER update_inventory_on_order_update;
DROP TRIGGER set_is_manager;
DROP TRIGGER end_of_managing_period;
DROP TRIGGER update_employee_department;
DROP TRIGGER handle_employee_deletion;
DROP TRIGGER handle_employee_leaving;
DROP TRIGGER handle_product_deletion;
DROP TRIGGER check_inventory;
DROP TRIGGER update_warehouse_inventory;
DROP TRIGGER check_assignment_dates;
DROP TRIGGER check_sales_rep;
DROP TRIGGER calculate_subtotal;
DROP TRIGGER calculate_total_price;


-- ------------------------------------------------------------------------------
-- Sequences to generate unique identifiers for the tables
-- ------------------------------------------------------------------------------
CREATE SEQUENCE assignment_seq
    START WITH 1
    INCREMENT BY 1;

CREATE SEQUENCE order_number_seq 
    START WITH 1 
    INCREMENT BY 1;


