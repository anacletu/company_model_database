-- ------------------------------------------------------------------------------
--   PL/SQL code by Eric Anacleto Ribeiro
--   Contains the Procedure Language code for populating the Company database
--   2024-04-16; last update on 2024-04-19
-- ------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------
-- Although it is mostly possible to use the DBMS_RANDOM package directly in SQL
-- statement, for learning and readability purposes, I created separate functions
-- ------------------------------------------------------------------------------


-- Function to generate a random date between today and aprox. 10 years ago for the StartDate columns
CREATE OR REPLACE FUNCTION random_date
RETURN DATE AS
BEGIN
    RETURN TRUNC(sysdate - dbms_random.value(0,3650));
END;
/

-- Function to generate a random date between aprox. 20 and 50 years ago for the DateOfBirth columns
CREATE OR REPLACE FUNCTION random_birth_date 
RETURN DATE AS
BEGIN
    RETURN TRUNC(sysdate - dbms_random.value(20*365, 50*365));
END;
/

-- Function to generate a random salary between 1000 and 10000
CREATE OR REPLACE FUNCTION random_salary
RETURN NUMBER AS
BEGIN
    RETURN ROUND(DBMS_RANDOM.value(1000,10000), 2);
END;
/

-- Function to generate a random national insurance number
CREATE OR REPLACE FUNCTION random_national_insurance_number
RETURN VARCHAR2 AS
    result VARCHAR2(9);
BEGIN
    FOR i IN 1..9 LOOP
        result := result || DBMS_RANDOM.string('U', 1);
    END LOOP;
    RETURN result;
END;
/

-- Function to generate a random phone number
CREATE OR REPLACE FUNCTION random_phone_number
RETURN VARCHAR2 AS
    result VARCHAR2(20);
BEGIN
    result := '(' || TRUNC(DBMS_RANDOM.value(100,999)) || ') ' || TRUNC(DBMS_RANDOM.value(1000,9999)) || '-' || TRUNC(DBMS_RANDOM.value(1000,9999));
    RETURN result;
END;
/

-- Function to generate a random postcode
CREATE OR REPLACE FUNCTION random_uk_postcode
RETURN VARCHAR2 IS
    letters VARCHAR2(26) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    numbers VARCHAR2(10) := '1234567890';
    postcode VARCHAR2(10);
BEGIN
    postcode := 
        SUBSTR(letters, DBMS_RANDOM.VALUE(1, 26), 1) ||
        SUBSTR(letters, DBMS_RANDOM.VALUE(1, 26), 1) ||
        SUBSTR(numbers, DBMS_RANDOM.VALUE(1, 10), 1) ||
        SUBSTR(numbers, DBMS_RANDOM.VALUE(1, 10), 1) ||
        ' ' ||
        SUBSTR(numbers, DBMS_RANDOM.VALUE(1, 10), 1) ||
        SUBSTR(letters, DBMS_RANDOM.VALUE(1, 26), 1) ||
        SUBSTR(letters, DBMS_RANDOM.VALUE(1, 26), 1);
    RETURN postcode;
END;
/