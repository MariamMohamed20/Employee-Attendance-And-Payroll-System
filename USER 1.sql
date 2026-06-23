-- Create Employees Table
CREATE TABLE Employees (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50),
    position VARCHAR2(50),
    department VARCHAR2(50),
    salary NUMBER,
    status VARCHAR2(20) CHECK (status IN ('active','suspended'))
);

select *from employees;

-- Create Attendance Table
CREATE TABLE Attendance (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    Attend_date DATE,
    in_time TIMESTAMP,
    out_time TIMESTAMP,
    total_hours NUMBER,
    CONSTRAINT fk_emp FOREIGN KEY (employee_id) REFERENCES Employees(id)
);

Select *from Attendance;

-- Create SuspendedAttendanceAttempts Table
CREATE TABLE SuspendedAttendanceAttempts (
    attempt_id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    attempt_time TIMESTAMP,
    reason VARCHAR2(200)
);

-- Create sequence for SuspendedAttendanceAttempts
CREATE SEQUENCE attempt_seq START WITH 1 INCREMENT BY 1;

-- Grant privileges to user2
GRANT INSERT ON Employees TO user2;
GRANT INSERT ON Attendance TO user2;
GRANT SELECT ON Employees TO user2;
GRANT SELECT ON Attendance TO user2;


GRANT SELECT ON user1.Employees TO manager;
GRANT SELECT ON user1.Attendance TO manager;



GRANT SELECT,update ON Employees TO manager;
GRANT SELECT,update ON Attendance TO manager;


--Task 2:Attendance Validation Trigger

-- Create BEFORE INSERT Trigger on Attendance
CREATE OR REPLACE TRIGGER ValidateAttendance 
BEFORE INSERT ON Attendance 
FOR EACH ROW 
DECLARE     
    emp_status VARCHAR2(20);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN     
    -- Get employee status     
    SELECT status INTO emp_status     
    FROM Employees     
    WHERE id = :NEW.employee_id;      
    
    -- Check if employee is suspended     
    IF emp_status = 'suspended' THEN         
        -- Log the attempt         
        INSERT INTO SuspendedAttendanceAttempts VALUES (             
            attempt_seq.NEXTVAL,             
            :NEW.employee_id,             
            SYSTIMESTAMP,             
            'Attempt to insert attendance for suspended employee'         
        );         
        COMMIT;          
        
        -- Raise error to prevent insertion         
        RAISE_APPLICATION_ERROR(             
            -20001,             
            'Attendance denied: Employee is suspended'         
        );     
    END IF;  
    
EXCEPTION     
    WHEN NO_DATA_FOUND THEN         
        RAISE_APPLICATION_ERROR(-20003, 'Employee ID does not exist'); 
END;
/

-- View all employees

SELECT * FROM Employees ORDER BY id;

-- View all attendance records
SELECT * FROM Attendance ORDER BY id;

-- View suspended attendance attempts log
SELECT * FROM SuspendedAttendanceAttempts ORDER BY attempt_id;

----------------------------------------------------------------
--Task 3 :  Work Hours Calculation 

CREATE OR REPLACE FUNCTION CalculateWorkHourss(
    p_attendance_id NUMBER,
    p_in_time       TIMESTAMP,
    p_out_time      TIMESTAMP
) RETURN NUMBER
IS
    PRAGMA AUTONOMOUS_TRANSACTION; 

    v_total_hours   NUMBER;
    v_minutes_late  NUMBER;
    v_shift_start   TIMESTAMP;
BEGIN
    -- Official shift start time (08:00 AM same day)
    v_shift_start := TRUNC(p_in_time) + INTERVAL '8' HOUR;

    -- Calculate total worked hours
    v_total_hours := (CAST(p_out_time AS DATE) - CAST(p_in_time AS DATE)) * 24;

    -- Calculate minutes late
    IF p_in_time > v_shift_start THEN
        v_minutes_late := (CAST(p_in_time AS DATE) - CAST(v_shift_start AS DATE)) * 24 * 60;
    ELSE
        v_minutes_late := 0;
    END IF;

    -- Apply 5-minute grace period
    IF v_minutes_late > 5 THEN
        v_total_hours := v_total_hours - (v_minutes_late / 60);
    END IF;

    -- Round to 2 decimal places
    v_total_hours := ROUND(v_total_hours, 2);

    -- Update Attendance table
    UPDATE user1.Attendance
    SET in_time     = p_in_time,
        out_time    = p_out_time,
        total_hours = v_total_hours
    WHERE id = p_attendance_id;

    COMMIT;

    -- Return the total hours
    RETURN v_total_hours;
END;
/
-------------------------------
--Work Hours Calculation 
-- test case 1 : no grace period
SET SERVEROUTPUT ON;

DECLARE
    v_hours NUMBER;
BEGIN
   v_hours := CalculateWorkHourss(
        1,
        TO_TIMESTAMP('2024-12-01 08:00:00','YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2024-12-01 16:00:00','YYYY-MM-DD HH24:MI:SS')
    );

    DBMS_OUTPUT.PUT_LINE('Calculated Hours = ' || v_hours);
END;
/

SELECT id, in_time, out_time, total_hours
FROM user1.Attendance
WHERE id = 1;
---------------------------------------------------------

--------------------------------------------------
--test case 3 : grace period = 10
SET SERVEROUTPUT ON;
DECLARE
    v_hours NUMBER;
BEGIN
    v_hours := CalculateWorkHourss(
        3,
        TO_TIMESTAMP('2024-12-01 08:10:00','YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2024-12-01 16:00:00','YYYY-MM-DD HH24:MI:SS')
    );

    DBMS_OUTPUT.PUT_LINE('Calculated Hours = ' || v_hours);
END;
/

SELECT id, in_time, out_time, total_hours
FROM user1.Attendance
WHERE id = 3;
-----------------------------------------------------
-- test case 4 : arrive early

SET SERVEROUTPUT ON;
DECLARE
    v_hours NUMBER;
BEGIN
    v_hours := CalculateWorkHourss(
        4,
        TO_TIMESTAMP('2024-12-01 07:55:00','YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2024-12-01 16:00:00','YYYY-MM-DD HH24:MI:SS')
    );

    DBMS_OUTPUT.PUT_LINE('Calculated Hours = ' || v_hours);
END;
/

SELECT id, in_time, out_time, total_hours
FROM user1.Attendance
WHERE id = 4;

------------------------------------------ 
-- test case 5 
-- work overtime

SET SERVEROUTPUT ON;
DECLARE
    v_hours NUMBER;
BEGIN
    v_hours := CalculateWorkHourss(
        5,
        TO_TIMESTAMP('2024-12-01 07:55:00','YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2024-12-01 17:00:00','YYYY-MM-DD HH24:MI:SS')
    );

    DBMS_OUTPUT.PUT_LINE('Calculated Hours = ' || v_hours);
END;
/

SELECT id, in_time, out_time, total_hours
FROM user1.Attendance
WHERE id = 5;
--------------------------------
-- test case 6
--late 5 hours and take half hour overtime
SET SERVEROUTPUT ON;
DECLARE
    v_hours NUMBER;
BEGIN
    v_hours := CalculateWorkHourss(
        6,
        TO_TIMESTAMP('2024-12-01 08:05:00','YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2024-12-01 16:30:00','YYYY-MM-DD HH24:MI:SS')
    );

    DBMS_OUTPUT.PUT_LINE('Calculated Hours = ' || v_hours);
END;
/

SELECT id, in_time, out_time, total_hours
FROM user1.Attendance
WHERE id = 6
----------------------------------------------
CREATE OR REPLACE TRIGGER CheckAttendanceTimes
BEFORE INSERT OR UPDATE ON Attendance
FOR EACH ROW
BEGIN
    IF :NEW.out_time <= :NEW.in_time THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'Invalid attendance: out_time must be later than in_time'
        );
    END IF;
END;
/

-- Trigger to ensure attendance times are valid
CREATE OR REPLACE TRIGGER CheckAttendanceTimes
BEFORE INSERT OR UPDATE ON user1.Attendance
FOR EACH ROW
BEGIN
    IF :NEW.out_time <= :NEW.in_time THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'Invalid attendance: Out time must be later than In time.'
        );
    END IF;
END;
/
SELECT * FROM user1.Attendance WHERE ROWNUM = 1;
--------------------------------------------------------


--bonus

-- User1
CREATE OR REPLACE FUNCTION RaiseDepartmentSalary(p_dept VARCHAR2) RETURN NUMBER IS
    v_rows NUMBER;
BEGIN
    UPDATE Employees
    SET salary = salary * 1.1
    WHERE department = p_dept;

    v_rows := SQL%ROWCOUNT;

    -- DO NOT COMMIT here, leave the transaction open
    RETURN v_rows;
END;
/

-- User1 Session 1: Blocker
SET SERVEROUTPUT ON;

DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('User1: Raising IT salaries...');
    v_count := RaiseDepartmentSalary('IT');

    DBMS_OUTPUT.PUT_LINE('User1: Updated ' || v_count || ' rows.');

    -- Keep transaction open, DO NOT COMMIT yet
    DBMS_OUTPUT.PUT_LINE('User1: Transaction is open, holding locks...');
END;
/

GRANT EXECUTE ON RaiseDepartmentSalary TO user2;

