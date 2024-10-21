-- CREATING TABLES
CREATE TABLE Client (
    C_ID INT PRIMARY KEY,
    F_NAME VARCHAR(50),
    L_NAME VARCHAR(50),
    DOB DATE,
    CITY VARCHAR(100),
    GENDER CHAR(1)
);

CREATE TABLE Vehicle (
    V_ID INT PRIMARY KEY,
    V_MODEL VARCHAR(100),
    V_MAKE VARCHAR(100),
    COST_PER_DAY DECIMAL(10, 2),
    Availability VARCHAR2(5) DEFAULT 'TRUE' CHECK (availability IN ('TRUE', 'FALSE'))
);

CREATE TABLE Reservation (
    R_ID INT PRIMARY KEY,
    START_DATE DATE,
    END_DATE DATE,
    RETURN_DATE DATE,
    C_ID INT,
    V_ID INT,
    TOTAL_COST DECIMAL(10, 2),
    FOREIGN KEY (C_ID) REFERENCES Client(C_ID),
    FOREIGN KEY (V_ID) REFERENCES Vehicle(V_ID)
);


CREATE TABLE Archived_Reservation (
    R_ID INT,
    START_DATE DATE,
    END_DATE DATE,
    RETURN_DATE DATE,
    C_ID INT,
    V_ID INT,
    TOTAL_COST DECIMAL(10, 2),
    ADDED_BY VARCHAR(100),
    ADDED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (C_ID) REFERENCES Client(C_ID),
    FOREIGN KEY (V_ID) REFERENCES Vehicle(V_ID)
);

CREATE TABLE Black_List (
    C_ID INT PRIMARY KEY,
    F_NAME VARCHAR(50),
    L_NAME VARCHAR(50),
    DOB DATE,
    CITY VARCHAR(100),
    GENDER CHAR(1),
    REASON VARCHAR2(100),
    ADDED_BY VARCHAR2(50),
    ADDED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (C_ID) REFERENCES Client(C_ID)
);

CREATE TABLE Stats (
    YEAR INT,
    C_ID INT,
    AGE INT,
    GENDER CHAR(1),
    TOT_RESERVATIONS INT,
    TOT_DAYS_OF_RESERVATIONS INT,
    TOT_COST_OF_RESERVATIONS DECIMAL(10, 2),
    FOREIGN KEY (C_ID) REFERENCES Client(C_ID)
);

--CREATING PROCEDURE TO ADD A CLIENT
CREATE OR REPLACE PROCEDURE addClient (
    customerID IN Client.C_ID%type,
    fName IN Client.f_name%type,
    lName IN Client.L_NAME%type,
    dateOfB IN Client.DOB%type,
    citi IN Client.CITY%type,
    gend IN Client.gender%type
)
AS
BEGIN
    INSERT INTO Client (C_ID, F_NAME, L_NAME, DOB, CITY, GENDER)
    VALUES (customerID, fName, lName, dateOfB, citi, gend);
   
    DBMS_OUTPUT.PUT_LINE('Client Added');
END;

--CREATING PROCEDURE TO ADD A VEHICLE
CREATE OR REPLACE PROCEDURE addVehicle (
    vehicleID IN Vehicle.V_ID%type,
    model IN Vehicle.V_MODEL%type,
    make IN Vehicle.V_MAKE%type,
    cost IN Vehicle.COST_PER_DAY%type
)
AS
BEGIN
    INSERT INTO Vehicle (V_ID, V_MODEL, V_MAKE, COST_PER_DAY, AVAILABILITY)
    VALUES (vehicleID, model, make, cost, DEFAULT);
   
    DBMS_OUTPUT.PUT_LINE('Vehicle Added');
END;


--ADDING TEST CLIENTS
EXEC addClient(1, 'John', 'Doe', TO_DATE('1990-05-15', 'YYYY-MM-DD'), 'New York', 'M');
EXEC addClient(2, 'Jane', 'Smith', TO_DATE('1985-09-23', 'YYYY-MM-DD'), 'Los Angeles', 'F');
EXEC addClient(3, 'Michael', 'Johnson', TO_DATE('1978-11-10', 'YYYY-MM-DD'), 'Chicago', 'M');
EXEC addClient(4, 'Emily', 'Brown', TO_DATE('1995-03-28', 'YYYY-MM-DD'), 'Houston', 'F');
EXEC addClient(5, 'David', 'Martinez', TO_DATE('1983-07-20', 'YYYY-MM-DD'), 'Miami', 'M');
EXEC addClient(6, 'David', 'Beckham', TO_DATE('2008-05-27', 'YYYY-MM-DD'), 'Miami', 'M');


--ADDING TEST VEHICLES
EXEC addVehicle(1001, 'Aventador', 'Lamborghini', 1500.00);
EXEC addVehicle(1002, '488 GTB', 'Ferrari', 2000.00);
EXEC addVehicle(1003, 'Chiron', 'Bugatti', 5000.00);
EXEC addVehicle(1004, 'Senna', 'McLaren', 3000.00);
EXEC addVehicle(1005, 'Veyron', 'Bugatti', 4500.00);


--CREATING RESERVATION SEQUENCE
CREATE SEQUENCE reservation_seq START WITH 9000 INCREMENT BY 1;


--FUNCTION TO ISSUE A CAR
CREATE OR REPLACE FUNCTION IssueCar(client_id INT, vehicle_id INT, start_date DATE, end_date DATE)  
RETURN INT
IS
    reservation_id INT;
    estimate_budget DECIMAL(10, 2);
is_available CHAR(5);
    client_dob DATE; -- variable to store client's date of birth

BEGIN

    --Making sure that the end date is greater than start date
    IF (end_date < start_date) THEN
        RAISE_APPLICATION_ERROR(-20003, 'End date must be greater than start date.');
    END IF;

    SELECT availability INTO is_available FROM Vehicle WHERE V_ID = vehicle_id;

IF (is_available = 'TRUE') THEN  --checking if vehicle is available

        SELECT DOB INTO client_dob FROM Client WHERE C_ID = client_id;
   
        -- Check if client is eligible based on age
        IF (EXTRACT(YEAR FROM start_date) - EXTRACT(YEAR FROM client_dob) >= 18) THEN
            -- Calculate estimate budget
            SELECT (COST_PER_DAY * (end_date - start_date)) INTO estimate_budget FROM Vehicle WHERE V_ID = vehicle_id;

            -- Insert reservation
            INSERT INTO Reservation (R_ID, START_DATE, END_DATE, C_ID, V_ID, TOTAL_COST)  
                VALUES (reservation_seq.NEXTVAL, start_date, end_date, client_id, vehicle_id, estimate_budget);

             UPDATE Vehicle SET availability = 'FALSE' WHERE V_ID = vehicle_id;

            RETURN reservation_seq.CURRVAL;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Client is under the age of 18 and cannot rent a car.');
        END IF;
ELSE
        RAISE_APPLICATION_ERROR(-20002, 'Vehicle is not available for rental.');
    END IF;
END;

--Testing the IssueCar function by making a reservation
DECLARE
    reservation_id INT;
BEGIN
    reservation_id := IssueCar(5, 1002, TO_DATE('2024-03-09', 'YYYY-MM-DD'), TO_DATE('2024-03-22', 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Reservation ID: ' || reservation_id);
END;


--FUNCTION TO RETURN A CAR
CREATE OR REPLACE FUNCTION ReturnCar(reservation_id INT, returnDate DATE)
RETURN DECIMAL
IS
    total_charges DECIMAL(10, 2);
    discount DECIMAL(10, 2) := 0.0;
christmasDiscount DECIMAL(10, 2) := 0.0;
    reservation_start_date DATE; -- variable to store reservation start date
BEGIN
   
    IF (returnDate < reservation_start_date) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Return date must be greater than start date.');
    END IF;

    --Calculate total cost based on reservation details
    SELECT (COST_PER_DAY * (returnDate - r.START_DATE)) INTO total_charges
    FROM Reservation r
    JOIN Vehicle v ON r.V_ID = v.V_ID
    WHERE r.R_ID = reservation_id;

    --Check if reservation is longer than 10 days
    SELECT START_DATE INTO reservation_start_date FROM Reservation WHERE R_ID = reservation_id;

    IF (returnDate - reservation_start_date) > 10 THEN
        discount := total_charges * 0.10;
    END IF;

    --Check if reservation includes Christmas day
    IF TO_CHAR(reservation_start_date, 'MM-DD') <= '12-25' AND TO_CHAR(returnDate, 'MM-DD') >= '12-25' THEN
        christmasDiscount := total_charges * 0.20; --Apply 20% discount
    END IF;

    -- Apply only one discount (either 10% or 20%)
    total_charges := total_charges - GREATEST(discount, christmasDiscount);

    -- Update return date in reservation table
    UPDATE Reservation SET RETURN_DATE = returnDate WHERE R_ID = reservation_id;

    -- Reset vehicle availability
    UPDATE Vehicle SET availability = 'TRUE' WHERE V_ID = (SELECT V_ID FROM Reservation WHERE R_ID = reservation_id);

    RETURN total_charges;
END;


--Testing the ReturnCar function
DECLARE
    reservation_id INT := 9023; -- Provide the reservation ID of the reservation to be returned
    returnDate DATE := TO_DATE('2024-04-22', 'YYYY-MM-DD'); -- Provide the return date
    total_charges DECIMAL(10, 2);
BEGIN
    total_charges := ReturnCar(reservation_id, returnDate);
    DBMS_OUTPUT.PUT_LINE('Total charges after return: ' || total_charges);
    UPDATE Reservation SET TOTAL_COST = total_charges WHERE R_ID = reservation_id;
END;


--Procedure to Blacklist a client
CREATE OR REPLACE PROCEDURE BlackListClient (client_id Client.C_ID%type , blacklistReason VARCHAR2, clientAdded_by VARCHAR2)
AS
BEGIN
DECLARE
        v_c_id Client.C_ID%TYPE;
        v_f_name Client.F_NAME%TYPE;
        v_l_name Client.L_NAME%TYPE;
        v_dob Client.DOB%TYPE;
        v_city Client.CITY%TYPE;
        v_gender Client.GENDER%TYPE;
BEGIN
        -- Retrieve client details
        SELECT C_ID, F_NAME, L_NAME, DOB, CITY, GENDER INTO v_c_id, v_f_name, v_l_name, v_dob, v_city, v_gender
        FROM Client
        WHERE C_ID = client_id;

        -- Insert client into Black_List table with reason and added by info
        INSERT INTO Black_List(C_ID, F_NAME, L_NAME, DOB, CITY, GENDER, REASON, ADDED_BY, ADDED_DATE)
        VALUES (v_c_id, v_f_name, v_l_name, v_dob, v_city, v_gender, blacklistReason, clientAdded_by, CURRENT_TIMESTAMP);
END;
END;

--FUNCTION TO CHECK IF A CLIENT IS BLACKLISTED
CREATE OR REPLACE FUNCTION CheckBlackList(client_id INT)
RETURN INT
IS
    blacklist_count INT;
BEGIN
    SELECT COUNT(*) INTO blacklist_count
    FROM Black_List
    WHERE C_ID = client_id;
   
    -- If there are any records, return 1 (blacklisted), otherwise return 0
    IF blacklist_count > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;

--TRIGGER TO CHECK IF A CLIENT IS BLACKLISTED USING CheckBlackList FUNCTION
CREATE OR REPLACE TRIGGER check_blacklist_trigger
BEFORE INSERT ON Reservation
FOR EACH ROW
DECLARE
    is_blacklisted INT;
BEGIN
    SELECT CheckBlackList(:NEW.C_ID) INTO is_blacklisted FROM dual;
   
    IF (is_blacklisted = 1) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Client is blacklisted and cannot rent a car.');
    END IF;
END;

--Testing BlackListClient procedure
EXEC BlackListClient (1, 'Damaged', 'Ishpreet');


--Procedure to move completed reservations to Archive_Reservations table
CREATE OR REPLACE PROCEDURE ArchiveReservations(DataAdded_by VARCHAR2)
AS
BEGIN
    -- Move records from Reservation table to Archived_Reservation table
    INSERT INTO Archived_Reservation (R_ID, START_DATE, END_DATE, RETURN_DATE, C_ID, V_ID, TOTAL_COST, ADDED_BY, ADDED_DATE)
    SELECT R_ID, START_DATE, END_DATE, RETURN_DATE, C_ID, V_ID, TOTAL_COST, DataAdded_by, CURRENT_TIMESTAMP
    FROM Reservation
    WHERE RETURN_DATE IS NOT NULL;
   
    --Delete records from Reservation table
    DELETE FROM Reservation WHERE RETURN_DATE IS NOT NULL;
END;

--Testing ArchiveReservations procedure
EXEC ArchiveReservations('Deeparsh Singh');


--FUNCTION TO GENERATE YEARLY STATS
CREATE OR REPLACE FUNCTION GenerateYearlyStats(year IN INT)
RETURN INT
IS
    -- Declare variables to store statistics
    v_year INT := year;
    client_age INT;
BEGIN
    -- Calculate statistics for each client
    FOR client_rec IN (SELECT C_ID, DOB, GENDER FROM Client)
    LOOP
        -- Calculate age of the client
        client_age := v_year - EXTRACT(YEAR FROM client_rec.DOB);

        -- Calculate statistics for the current client and year
        INSERT INTO Stats (YEAR, C_ID, AGE, GENDER, TOT_RESERVATIONS, TOT_DAYS_OF_RESERVATIONS, TOT_COST_OF_RESERVATIONS)
        SELECT v_year, client_rec.C_ID, client_age, client_rec.GENDER,
               COUNT(*),
               SUM(end_date - start_date),
               SUM(TOTAL_COST)
        FROM Reservation
        WHERE EXTRACT(YEAR FROM START_DATE) = v_year
        AND C_ID = client_rec.C_ID
        GROUP BY C_ID, client_age, client_rec.GENDER;

        COMMIT;
    END LOOP;

    -- Return 1 if successful
    RETURN 1;

EXCEPTION
    WHEN OTHERS THEN
        -- Return 0 if an error occurs
        RETURN 0;
END;

--Testing the GenerateYearlyStats function
DECLARE
    result INT;
BEGIN
   
    result := GenerateYearlyStats(2024);
    IF result = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Yearly stats for 2024 generated successfully.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Failed to generate yearly stats for 2024.');
    END IF;
END;


--Tests
SELECT * FROM Reservation WHERE RETURN_DATE IS NULL;


SELECT * FROM Client WHERE C_ID IN (Select C_ID FROM Reservation WHERE START_DATE = TRUNC(SYSDATE));


SELECT * FROM black_list;


SELECT COUNT(*) AS "Number of reservations for Christmas" FROM Reservation
WHERE TO_CHAR(START_DATE, 'MM-DD') <= '12-25'
AND TO_CHAR(END_DATE, 'MM-DD') >= '12-25';


SELECT SUM(TOTAL_COST) AS "TOTAL REVENUE"
FROM Reservation
WHERE V_ID = 1002;


select * from client;
select * from vehicle;
SELECT * from reservation;
select * from black_list;
select * from stats;
select * from archived_reservation;

select sysdate from dual;