-- Create user1 and user2
CREATE USER user1 IDENTIFIED BY user1123;
GRANT CREATE SESSION TO user1;
GRANT CREATE TABLE TO user1;
GRANT CREATE TRIGGER TO user1;
GRANT CREATE PROCEDURE TO user1;
GRANT UNLIMITED TABLESPACE TO user1;
grant create sequence to user1;


-- create user 2 
CREATE USER user2 IDENTIFIED BY user2123;
GRANT CREATE SESSION TO user2;



-- Create Log Table
CREATE TABLE DBUserCreationLog (
    log_id NUMBER PRIMARY KEY,
    created_username VARCHAR2(30),
    created_by VARCHAR2(30),
    creation_time TIMESTAMP
);

-- Create sequence for log_id
CREATE SEQUENCE log_seq START WITH 1 INCREMENT BY 1;


CREATE OR REPLACE PROCEDURE LogUserCreation(
    p_username VARCHAR2
) AS 
BEGIN
    INSERT INTO DBUserCreationLog (
        log_id,
        created_username,
        created_by,
        creation_time
    )
    VALUES (
        log_seq.NEXTVAL,
        p_username,
        USER,
        SYSTIMESTAMP
    );
END;
/



-- Log user creations
BEGIN
    LogUserCreation('USER1');
    LogUserCreation('USER2');
END;
/


-- verify log_user_creation
SELECT * FROM DBUserCreationLog; 

-- Create Payroll Table
CREATE TABLE Payroll (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    pay_month VARCHAR2(20),
    total_hours_worked NUMBER,
    deductions NUMBER,
    bonuses NUMBER,
    net_salary NUMBER
); 
ALTER TABLE Payroll ADD (
    OVERTIME_HOURS   NUMBER DEFAULT 0,
    OVERTIME_PAY     NUMBER DEFAULT 0,
    ALLOWANCES       NUMBER DEFAULT 0,
    GROSS_SALARY     NUMBER DEFAULT 0
);
select * from payroll;

-- Create sequence for Payroll
CREATE SEQUENCE payroll_seq START WITH 1 INCREMENT BY 1;

-- Create LeaveRequests Table
CREATE TABLE LeaveRequests (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    leave_date DATE,
    reason VARCHAR2(200),
    approval_status VARCHAR2(20)
);
select * from leaverequests;

-- Create sequence for LeaveRequests
CREATE SEQUENCE leave_seq START WITH 1 INCREMENT BY 1;

-- Create AuditTrail Table
CREATE TABLE AuditTrail (
    id NUMBER PRIMARY KEY,
    table_name VARCHAR2(50),
    operation VARCHAR2(20),
    old_data VARCHAR2(4000),
    new_data VARCHAR2(4000),
    change_time TIMESTAMP
);
select * from audittrail;
-- Create sequence for AuditTrail
CREATE SEQUENCE audit_seq START WITH 1 INCREMENT BY 1;

-- Create Deductions Table
CREATE TABLE Deductions (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    deduction_reason VARCHAR2(200),
    amount NUMBER,
    deduction_date DATE
);
select *from deductions;

-- Create sequence for Deductions
CREATE SEQUENCE deduction_seq START WITH 1 INCREMENT BY 1;

-- Grant privileges on sequences to user1 and user2
GRANT SELECT ON payroll_seq TO user1;
GRANT SELECT ON payroll_seq TO user2;
GRANT SELECT ON leave_seq TO user1;
GRANT SELECT ON leave_seq TO user2;
GRANT SELECT ON audit_seq TO user1;
GRANT SELECT ON audit_seq TO user2;
GRANT SELECT ON deduction_seq TO user1;
GRANT SELECT ON deduction_seq TO user2;

-- Grant privileges on manager tables to user1 and user2
GRANT SELECT, INSERT, UPDATE, DELETE ON Payroll TO user1;
GRANT SELECT, INSERT, UPDATE, DELETE ON Payroll TO user2;

GRANT SELECT, INSERT, UPDATE, DELETE ON LeaveRequests TO user1;
GRANT SELECT, INSERT, UPDATE, DELETE ON LeaveRequests TO user2;

GRANT SELECT, INSERT, UPDATE, DELETE ON AuditTrail TO user1;
GRANT SELECT, INSERT, UPDATE, DELETE ON AuditTrail TO user2;

GRANT SELECT, INSERT, UPDATE, DELETE ON Deductions TO user1;
GRANT SELECT, INSERT, UPDATE, DELETE ON Deductions TO user2;

grant create sequence to user1;
-----------------------------

-- View manager tables 
SELECT * FROM Payroll;

SELECT * FROM LeaveRequests;

SELECT * FROM AuditTrail;

SELECT * FROM Deductions;
 select *from user1.Employees;



---------------------------------------------------------------------------------------------------------------------------------------------
--Task 4 : Monthly Payroll Generation 

CREATE OR REPLACE PROCEDURE GenerateMonthlyPayroll (
    p_month VARCHAR2  -- format: YYYY-MM (e.g., '2024-12')
) IS
    CURSOR c_emp IS
        SELECT e.id, e.salary
        FROM user1.Employees e
        WHERE e.status = 'active';
    
    v_total_hours NUMBER;
    v_deductions  NUMBER;
    v_bonus       NUMBER;
    v_net_salary  NUMBER;
    v_standard_hours  NUMBER := 8;
    v_overtime_hours  NUMBER;
    v_overtime_pay    NUMBER;
    v_hourly_rate     NUMBER;
    v_allowances      NUMBER;
    v_gross_salary    NUMBER;
    
BEGIN
    FOR emp_rec IN c_emp LOOP
        
        -- *** CHANGED THIS LINE ***
        -- Now uses 'YYYY-MM' format instead of 'MM-YYYY'
        SELECT NVL(SUM(a.total_hours), 0)
        INTO v_total_hours
        FROM user1.Attendance a
        WHERE a.employee_id = emp_rec.id
          AND TO_CHAR(a.Attend_date, 'YYYY-MM') = p_month;  -- Changed format here
        
        -- Calculate overtime
        IF v_total_hours > v_standard_hours THEN
            v_overtime_hours := v_total_hours - v_standard_hours;
            v_hourly_rate := emp_rec.salary / v_standard_hours;
            v_overtime_pay := v_overtime_hours * v_hourly_rate * 1.5;
        ELSE
            v_overtime_hours := 0;
            v_overtime_pay := 0;
        END IF;
        
        -- Allowances
        v_allowances := 800;
        
        -- Deductions
        IF v_total_hours < 8 THEN
            v_deductions := 500;
        ELSE
            v_deductions := 0;
        END IF;
        
        -- Bonuses
        IF v_total_hours > 10 THEN
            v_bonus := 1000;
        ELSE
            v_bonus := 0;
        END IF;
        
        -- Gross = Basic + Allowances + Overtime + Bonus
        v_gross_salary := emp_rec.salary + v_allowances + v_overtime_pay + v_bonus;
        
        -- Net = Gross - Deductions
        v_net_salary := v_gross_salary - v_deductions;
        
        -- Try to UPDATE first
        UPDATE Payroll
        SET TOTAL_HOURS_WORKED = v_total_hours,
            OVERTIME_HOURS     = v_overtime_hours,
            OVERTIME_PAY       = v_overtime_pay,
            ALLOWANCES         = v_allowances,
            GROSS_SALARY       = v_gross_salary,
            DEDUCTIONS         = v_deductions,
            BONUSES            = v_bonus,
            NET_SALARY         = v_net_salary
        WHERE EMPLOYEE_ID = emp_rec.id
          AND PAY_MONTH   = p_month;
        
        -- If no rows updated, INSERT
        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO Payroll
            (ID, EMPLOYEE_ID, PAY_MONTH, TOTAL_HOURS_WORKED, 
             OVERTIME_HOURS, OVERTIME_PAY, ALLOWANCES, GROSS_SALARY,
             DEDUCTIONS, BONUSES, NET_SALARY)
            VALUES (payroll_seq.NEXTVAL, emp_rec.id, p_month, v_total_hours, 
                    v_overtime_hours, v_overtime_pay, v_allowances, v_gross_salary,
                    v_deductions, v_bonus, v_net_salary);
        END IF;
        
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Payroll generated for month: ' || p_month);
    
END GenerateMonthlyPayroll;
/

SELECT 
    employee_id,
    TO_CHAR(Attend_date, 'YYYY-MM') as month,
    COUNT(*) as days,
    SUM(total_hours) as total_hours
FROM user1.Attendance
GROUP BY employee_id, TO_CHAR(Attend_date, 'YYYY-MM')
ORDER BY month, employee_id;

SELECT 
    employee_id,
    pay_month,
    total_hours_worked,  -- Should NOT be 0 now!
    overtime_hours,
    deductions,
    bonuses,
    net_salary
FROM Payroll
ORDER BY employee_id;



-- Step 3: Generate payroll with CORRECT format

-- ============================================================================
-- ============================================================================
BEGIN
    GenerateMonthlyPayroll('12-2024');
END;
/


SELECT * FROM Payroll ORDER BY EMPLOYEE_ID;


  
  --test case:
  -- ============================================================================
-- TEST CASE 1: Perfect Employee (Exactly 160 hours)
-- ============================================================================

-- Verify employee data
SELECT 
    e.id,
    e.name,
    e.salary,
    e.status
FROM user1.Employees e
WHERE e.id = 1;

-- Verify working hours
SELECT 
    employee_id,
    COUNT(*) as days_worked,
    SUM(total_hours) as total_hours
FROM user1.Attendance
WHERE employee_id = 1
  AND TO_CHAR(Attend_date, 'MM-YYYY') = '12-2024'
GROUP BY employee_id;

-- Execute the Procedure
BEGIN
    GenerateMonthlyPayroll('12-2024');
END;
/

-- Verify results
SELECT 
    EMPLOYEE_ID,
    PAY_MONTH,
    TOTAL_HOURS_WORKED,
    OVERTIME_HOURS,
    OVERTIME_PAY,
    ALLOWANCES,
    GROSS_SALARY,
    DEDUCTIONS,
    BONUSES,
    NET_SALARY
FROM Payroll
WHERE EMPLOYEE_ID = 1 
  AND PAY_MONTH = '12-2024';

----------------------------------------------------------------------------------
  -- Task 5
  
  --Trigger before insert on leaveRequests table
  
  CREATE OR REPLACE TRIGGER trg_leave_before_insert
BEFORE INSERT ON LeaveRequests
FOR EACH ROW
BEGIN
    INSERT INTO AuditTrail(
        id,
        table_name,
        operation,
        old_data,
        new_data,
        change_time
    )
    VALUES (
        audit_seq.NEXTVAL,
        'LeaveRequests',
        'INSERT',
        NULL,  
        'employee_id=' || :NEW.employee_id || 
        ', leave_date=' || TO_CHAR(:NEW.leave_date,'YYYY-MM-DD') || 
        ', reason=' || :NEW.reason || 
        ', approval_status=' || :NEW.approval_status,
        SYSTIMESTAMP
    );
END;
/

-- Trigger After Insert on leaveRequestTable

CREATE OR REPLACE TRIGGER trg_leave_after_update
AFTER UPDATE ON LeaveRequests
FOR EACH ROW
BEGIN
    INSERT INTO AuditTrail(
        id,
        table_name,
        operation,
        old_data,
        new_data,
        change_time
    )
    VALUES (
        audit_seq.NEXTVAL,
        'LeaveRequests',
        'UPDATE',
        'employee_id=' || :OLD.employee_id || 
        ', leave_date=' || TO_CHAR(:OLD.leave_date,'YYYY-MM-DD') || 
        ', reason=' || :OLD.reason || 
        ', approval_status=' || :OLD.approval_status,
        'employee_id=' || :NEW.employee_id || 
        ', leave_date=' || TO_CHAR(:NEW.leave_date,'YYYY-MM-DD') || 
        ', reason=' || :NEW.reason || 
        ', approval_status=' || :NEW.approval_status,
        SYSTIMESTAMP
    );
END;
/

  --Test cases:
  INSERT INTO LeaveRequests(id, employee_id, leave_date, reason, approval_status)
VALUES (1, 101, DATE '2025-01-15', 'Medical leave', 'Pending');



--case 2:
UPDATE LeaveRequests
SET approval_status = 'Approved'
WHERE id = 1;

--case 3:
INSERT INTO LeaveRequests(id, employee_id, leave_date, reason, approval_status)
VALUES (2, 102, DATE '2025-01-20', 'Personal leave', 'Pending');

--case 4:
UPDATE LeaveRequests
SET approval_status = 'Rejected', reason = 'Insufficient leave balance'
WHERE id = 2;

Select *from LeaveRequests;
select *from AuditTrail;


----------------------------------------
-- Task 6
---- Create PerformanceReport table
CREATE TABLE PerformanceReport (
    id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    employee_name VARCHAR2(50),
    total_hours_worked NUMBER,
    approved_leaves NUMBER,
    late_arrivals NUMBER,
    report_period VARCHAR2(50),
    top_performer VARCHAR2(3)
);

-- Create sequence
CREATE SEQUENCE perf_seq START WITH 1 INCREMENT BY 1;

-- Procedure: GeneratePerformanceReport
CREATE OR REPLACE PROCEDURE GeneratePerformanceReport (
    p_start_date DATE,
    p_end_date   DATE
)
IS
    CURSOR c_emp IS
        SELECT id, name
        FROM user1.Employees
        WHERE status = 'active';

    v_total_hours     NUMBER;
    v_late_arrivals   NUMBER;
    v_approved_leaves NUMBER;
    v_max_hours       NUMBER;
    v_top             VARCHAR2(3);
    v_report_period   VARCHAR2(50);
BEGIN
    -- Set report period
    v_report_period := TO_CHAR(p_start_date,'YYYY-MM-DD') || ' to ' || TO_CHAR(p_end_date,'YYYY-MM-DD');

    -- Find maximum hours worked by any employee
    SELECT NVL(MAX(emp_total), 0)
    INTO v_max_hours
    FROM (
        SELECT SUM(total_hours) AS emp_total
        FROM user1.Attendance
        WHERE Attend_date BETWEEN p_start_date AND p_end_date
        GROUP BY employee_id
    );

    -- Process each employee
    FOR emp_rec IN c_emp LOOP
        
        -- Total hours worked
        SELECT NVL(SUM(total_hours), 0)
        INTO v_total_hours
        FROM user1.Attendance
        WHERE employee_id = emp_rec.id
          AND Attend_date BETWEEN p_start_date AND p_end_date;

        -- Late arrivals (in_time after 08:05:00)
        SELECT COUNT(*)
        INTO v_late_arrivals
        FROM user1.Attendance
        WHERE employee_id = emp_rec.id
          AND Attend_date BETWEEN p_start_date AND p_end_date
          AND in_time IS NOT NULL
          AND TO_CHAR(in_time, 'HH24:MI:SS') >= '08:05:00';

        -- Approved leaves
        SELECT COUNT(*)
        INTO v_approved_leaves
        FROM manager.LeaveRequests
        WHERE employee_id = emp_rec.id
          AND leave_date BETWEEN p_start_date AND p_end_date
          AND approval_status = 'Approved';

        -- Determine top performer
        IF v_total_hours = v_max_hours AND v_max_hours > 0 THEN
            v_top := 'YES';
        ELSE
            v_top := 'NO';
        END IF;

        -- Insert into PerformanceReport
        INSERT INTO PerformanceReport(
            id, 
            employee_id, 
            employee_name,
            total_hours_worked, 
            approved_leaves, 
            late_arrivals, 
            report_period, 
            top_performer
        )
        VALUES (
            perf_seq.NEXTVAL, 
            emp_rec.id,
            emp_rec.name,
            v_total_hours, 
            v_approved_leaves, 
            v_late_arrivals, 
            v_report_period, 
            v_top
        );
    END LOOP;

    COMMIT;
END;
/

--Test Case

-- Clear old reports
DELETE FROM manager.PerformanceReport;
COMMIT;

-- Generate report for December 2024
BEGIN
    manager.GeneratePerformanceReport(DATE '2024-12-01', DATE '2024-12-03');
END;
/

-- View results
SELECT * FROM manager.PerformanceReport ORDER BY total_hours_worked DESC;
select *from user1.Attendance;
select * from payroll




--------------------------------------------
--Task 7
CREATE OR REPLACE PROCEDURE ProcessLeaveDeductions (
    p_month VARCHAR2   -- format: YYYY-MM or MM-YYYY
) AS
    -- Cursor to fetch unapproved leaves for the specified month
    CURSOR c_unapproved IS
        SELECT lr.employee_id,
               e.salary,
               COUNT(*) as leave_days
        FROM manager.LeaveRequests lr
        JOIN user1.Employees e ON lr.employee_id = e.id
        WHERE UPPER(lr.approval_status) IN ('PENDING', 'REJECTED')  -- Unapproved statuses
          AND TO_CHAR(lr.leave_date, 'YYYY-MM') = p_month  -- Filter by month
        GROUP BY lr.employee_id, e.salary;

    v_deduction NUMBER;
    v_payroll_exists NUMBER;
BEGIN
    FOR rec IN c_unapproved LOOP

        -- Calculate deduction: (salary / 30 days) * number of unapproved leave days
        v_deduction := ROUND((rec.salary / 30) * rec.leave_days,2);

        -- Log deduction in Deductions table
        INSERT INTO manager.Deductions (
            id,
            employee_id,
            deduction_reason,
            amount,
            deduction_date
        ) VALUES (
            manager.deduction_seq.NEXTVAL,
            rec.employee_id,
            'Unapproved Leave (' || rec.leave_days || ' days)',
            v_deduction,
            SYSDATE
        );

        -- Check if payroll record exists for this employee and month
        SELECT COUNT(*)
        INTO v_payroll_exists
        FROM manager.Payroll
        WHERE employee_id = rec.employee_id
          AND pay_month = p_month;

        -- Only update if payroll exists
        IF v_payroll_exists > 0 THEN
            UPDATE manager.Payroll
            SET deductions = NVL(deductions, 0) + v_deduction,
                net_salary = net_salary - v_deduction
            WHERE employee_id = rec.employee_id
              AND pay_month = p_month;
        END IF;

    END LOOP;

    COMMIT;
END;
/

--test case:
-- Clear all deductions
DELETE FROM manager.Deductions;
COMMIT;

-- Reset payroll to original values (re-generate)
DELETE FROM manager.Payroll WHERE pay_month = '2024-12';
COMMIT;

BEGIN
    manager.GenerateMonthlyPayroll('2024-12');
END;
/

-- Clear old leave requests
DELETE FROM manager.LeaveRequests WHERE id IN (201, 202, 203);
COMMIT;

-- Insert fresh unapproved leaves for December 2024
INSERT INTO manager.LeaveRequests (id, employee_id, leave_date, reason, approval_status)
VALUES (201, 1, DATE '2024-12-15', 'Personal leave', 'PENDING');

INSERT INTO manager.LeaveRequests (id, employee_id, leave_date, reason, approval_status)
VALUES (202, 1, DATE '2024-12-16', 'Personal leave', 'REJECTED');

INSERT INTO manager.LeaveRequests (id, employee_id, leave_date, reason, approval_status)
VALUES (203, 2, DATE '2024-12-20', 'Medical leave', 'PENDING');

COMMIT;

-- Run deduction procedure
BEGIN
    manager.ProcessLeaveDeductions('2024-12');
END;
/

-- View clean results
SELECT * FROM manager.Deductions ORDER BY id;

SELECT employee_id, pay_month, deductions, net_salary 
FROM manager.Payroll 
WHERE pay_month = '2024-12'
ORDER BY employee_id;

-- ============================================================================
-- STEP 1: Check the Deductions Table (This is the main output for Task 7)
-- ============================================================================
SELECT 
    id,
    employee_id,
    deduction_reason,
    amount,
    TO_CHAR(deduction_date, 'YYYY-MM-DD') as deduction_date
FROM manager.Deductions 
ORDER BY id;

-- ============================================================================
-- STEP 2: Check the Leave Requests (What caused the deductions)
-- ============================================================================

SELECT 
    id,
    employee_id,
    TO_CHAR(leave_date, 'YYYY-MM-DD') as leave_date,
    reason,
    approval_status
FROM manager.LeaveRequests 
WHERE id IN (201, 202, 203)
ORDER BY employee_id, id;

-- ============================================================================
-- STEP 3: Check Which Payroll Records Were Updated
-- ============================================================================

-- Check all payroll records
SELECT 
    id,
    employee_id,
    pay_month,
    deductions,
    net_salary
FROM manager.Payroll 
ORDER BY pay_month, employee_id;

select * from payroll

select *from user1.Attendance;
--------------- 
--task 8

CREATE TABLE MonthlyAttendanceSummary (
    employee_id NUMBER,
    month VARCHAR2(7),
    total_days_worked NUMBER,
    days_late NUMBER,
    avg_daily_hours NUMBER
);

DECLARE
    v_month VARCHAR2(7) := '2024-12';
BEGIN
    INSERT INTO MonthlyAttendanceSummary
    SELECT
        employee_id,
        v_month,
        COUNT(*) AS total_days_worked,
        SUM(
            CASE
                WHEN in_time >
                     TO_TIMESTAMP(
                        TO_CHAR(attend_date,'YYYY-MM-DD') || ' 08:05:00',
                        'YYYY-MM-DD HH24:MI:SS'
                     )
                THEN 1
                ELSE 0
            END
        ) AS days_late,
        ROUND(AVG(total_hours),2) AS avg_daily_hours
    FROM user1.Attendance
    WHERE TO_CHAR(attend_date,'YYYY-MM') = v_month
    GROUP BY employee_id;

    COMMIT;
END;
/

SELECT 
    a.employee_id,
    e.name,
    TO_CHAR(a.Attend_date, 'YYYY-MM-DD') as attendance_date,
    TO_CHAR(a.in_time, 'HH24:MI:SS') as arrival_time,
    a.total_hours,
    CASE 
        WHEN a.in_time > TO_TIMESTAMP(TO_CHAR(a.Attend_date,'YYYY-MM-DD') || ' 08:05:00', 'YYYY-MM-DD HH24:MI:SS')
        THEN 'LATE'
        ELSE 'ON TIME'
    END as status
FROM user1.Attendance a
JOIN user1.Employees e ON a.employee_id = e.id
WHERE TO_CHAR(a.Attend_date, 'YYYY-MM') = '2024-12'
ORDER BY a.employee_id, a.Attend_date;

DECLARE
    v_month VARCHAR2(7) := '2024-12';
    v_rows_inserted NUMBER;
BEGIN
    -- Clear old data for this month
    DELETE FROM MonthlyAttendanceSummary WHERE month = v_month;
    
    -- Insert summary data
    INSERT INTO MonthlyAttendanceSummary
    SELECT
        employee_id,
        v_month,
        COUNT(*) AS total_days_worked,
        SUM(
            CASE
                WHEN in_time >
                     TO_TIMESTAMP(
                        TO_CHAR(Attend_date,'YYYY-MM-DD') || ' 08:05:00',
                        'YYYY-MM-DD HH24:MI:SS'
                     )
                THEN 1
                ELSE 0
            END
        ) AS days_late,
        ROUND(AVG(total_hours), 2) AS avg_daily_hours
    FROM user1.Attendance
    WHERE TO_CHAR(Attend_date, 'YYYY-MM') = v_month
    GROUP BY employee_id;
    
    v_rows_inserted := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ Summary generated successfully');
    DBMS_OUTPUT.PUT_LINE('✓ ' || v_rows_inserted || ' employee(s) processed');
END;
/

-- Step 3: View the results
PROMPT 
PROMPT Step 3: Attendance Summary Results
PROMPT ---------------------------------------------------

SELECT 
    mas.employee_id,
    e.name,
    mas.month,
    mas.total_days_worked,
    mas.days_late,
    mas.avg_daily_hours,
    CASE 
        WHEN mas.days_late = 0 THEN '✓ Perfect Attendance'
        WHEN mas.days_late <= 2 THEN '⚠ Minor Issues'
        ELSE '✗ Frequent Late'
    END as performance
FROM MonthlyAttendanceSummary mas
JOIN user1.Employees e ON mas.employee_id = e.id
WHERE mas.month = '2024-12'
ORDER BY mas.total_days_worked DESC, mas.days_late ASC;

SELECT * FROM manager.Deductions;
SELECT * FROM manager.Payroll;
SELECT * FROM MonthlyAttendanceSummary;
--------------------------------------------------------------

-- task 9

-- Create AdjustmentAudit Table
CREATE TABLE AdjustmentAudit (
    audit_id NUMBER PRIMARY KEY,
    department VARCHAR2(50),
    adjustment_amount NUMBER,
    adjusted_by VARCHAR2(50),
    adjustment_time TIMESTAMP
);

-- Create sequence for AdjustmentAudit
CREATE SEQUENCE adjustment_seq START WITH 1 INCREMENT BY 1;

-- PL/SQL Block to apply bulk bonuses
DECLARE
    v_department VARCHAR2(50) := 'IT';  -- Department to give bonus
    v_bonus NUMBER := 500;              -- Bonus amount per employee
BEGIN
    -- Start a savepoint for transaction control
    SAVEPOINT before_bonus;

    -- Update bonuses for all employees in the department
    UPDATE Payroll p
    SET p.bonuses = NVL(p.bonuses, 0) + v_bonus
    WHERE p.employee_id IN (
        SELECT employee_id FROM user1.Employees e WHERE e.department = v_department
    );

    -- Log the adjustment in AdjustmentAudit
    INSERT INTO AdjustmentAudit VALUES (
        adjustment_seq.NEXTVAL,
        v_department,
        v_bonus,
        USER,
        SYSTIMESTAMP
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Bonus applied successfully for department: ' || v_department);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_bonus;
        DBMS_OUTPUT.PUT_LINE('Error applying bonus. Transaction rolled back.');
END;
/

--Test Case 1 – Transactional Payroll Adjustment (Task 9)

SET SERVEROUTPUT ON;

DECLARE
    v_department VARCHAR2(50) := 'IT';
    v_bonus NUMBER := 500;
BEGIN
    -- Before applying bonus, check current bonuses
    DBMS_OUTPUT.PUT_LINE('Before Bonus:');
    FOR rec IN (SELECT p.employee_id, p.bonuses 
                FROM manager.Payroll p
                JOIN user1.Employees e ON p.employee_id = e.id
                WHERE e.department = v_department) LOOP
        DBMS_OUTPUT.PUT_LINE('Employee ' || rec.employee_id || ' bonus: ' || NVL(rec.bonuses,0));
    END LOOP;

    -- Apply bonus using the existing block
    SAVEPOINT before_bonus;

    UPDATE manager.Payroll p
    SET p.bonuses = NVL(p.bonuses, 0) + v_bonus
    WHERE p.employee_id IN (
        SELECT e.id FROM user1.Employees e WHERE e.department = v_department
    );

    INSERT INTO manager.AdjustmentAudit VALUES (
        adjustment_seq.NEXTVAL,
        v_department,
        v_bonus,
        USER,
        SYSTIMESTAMP
    );

    COMMIT;

    -- After applying bonus
    DBMS_OUTPUT.PUT_LINE('After Bonus:');
    FOR rec IN (SELECT p.employee_id, p.bonuses 
                FROM manager.Payroll p
                JOIN user1.Employees e ON p.employee_id = e.id
                WHERE e.department = v_department) LOOP
        DBMS_OUTPUT.PUT_LINE('Employee ' || rec.employee_id || ' bonus: ' || NVL(rec.bonuses,0));
    END LOOP;
END;
/

--------------------------------------------------------
--task 10
-- Function to calculate monthly tax deduction
-- Function to calculate monthly tax deduction
CREATE OR REPLACE FUNCTION CalculateTaxDeduction(
    p_employee_id NUMBER,
    p_month VARCHAR2
) RETURN NUMBER
IS
    v_net_salary NUMBER;
    v_tax NUMBER;
BEGIN
    -- Get net salary for the employee in the given month
    SELECT net_salary INTO v_net_salary
    FROM Payroll
    WHERE employee_id = p_employee_id
      AND pay_month = p_month;  -- correct column name

    -- Simple tax calculation (tiered example)
    IF v_net_salary <= 5000 THEN
        v_tax := v_net_salary * 0.05;
    ELSIF v_net_salary <= 10000 THEN
        v_tax := v_net_salary * 0.10;
    ELSE
        v_tax := v_net_salary * 0.15;
    END IF;

    RETURN v_tax;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Employee or month not found in Payroll table.');
        RETURN NULL;
END;
/
-------------------------
-- Test 1: Calculate Tax Deduction
SET SERVEROUTPUT ON;

DECLARE
    v_employee_id NUMBER := 1;  -- employee_id to test
    v_month VARCHAR2(20) := 'December 2024';
    v_tax NUMBER;
BEGIN
    v_tax := CalculateTaxDeduction(v_employee_id, v_month);
    DBMS_OUTPUT.PUT_LINE('Tax for employee ' || v_employee_id || ' in ' || v_month || ' is: ' || v_tax);
END;
/

-- Test 2: Check Attendance Trigger
-- Test 2 – Valid Attendance Entry
SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'INSERT INTO user1.Attendance (id, employee_id, "date", in_time, out_time, total_hours)
                       VALUES (100, 1, DATE ''2024-12-01'',
                               TO_TIMESTAMP(''2024-12-01 08:00:00'',''YYYY-MM-DD HH24:MI:SS''),
                               TO_TIMESTAMP(''2024-12-01 16:00:00'',''YYYY-MM-DD HH24:MI:SS''),
                               8)';
    DBMS_OUTPUT.PUT_LINE('Valid attendance inserted successfully.');
END;
/

--bonus

-- Check blocker/waiting
SELECT 
    s1.sid AS blocker_sid,
    s1.serial# AS blocker_serial,
    s1.username AS blocker_user,
    s2.sid AS waiting_sid,
    s2.serial# AS waiting_serial,
    s2.username AS waiting_user,
    l.lock_type,
    l.mode_held,
    l.mode_requested
FROM v$locked_object l
JOIN v$session s1 ON l.session_id = s1.sid
JOIN v$session s2 ON l.blocking_session = s2.sid;
