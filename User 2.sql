SET SERVEROUTPUT ON;

-- Insert 5 employees
INSERT INTO user1.Employees VALUES (1,'Ali','Developer','IT',9000,'active');
INSERT INTO user1.Employees VALUES (2,'Mona','HR','HR',7000,'active');
INSERT INTO user1.Employees VALUES (3,'Tamer','Accountant','Finance',6000,'suspended');
INSERT INTO user1.Employees VALUES (4,'Sara','Engineer','IT',8500,'active');
INSERT INTO user1.Employees VALUES (5,'Yara','Designer','Marketing',6500,'active');

COMMIT;

select *from user1.Employees

-- Insert 5 attendance records
INSERT INTO user1.Attendance 
VALUES (
    1, 
    1, 
    DATE '2024-12-01',
    NULL,
    NULL,
    0
);
INSERT INTO user1.Attendance VALUES (
    2, 2, DATE '2024-12-01',
    null,
    null,
    0
);
INSERT INTO user1.Attendance VALUES (
    3, 4, DATE '2024-12-01',
    null,
    null,
    0
);


INSERT INTO user1.Attendance VALUES (
    4, 5, DATE '2024-12-01',
    null,
    null,
    0
);

INSERT INTO user1.Attendance VALUES (
    5, 1, DATE '2024-12-02',
    null,
    null,
    0
);

commit;


select *from user1.Attendance;

select *from user1.Employees;


-- Test attendance for SUSPENDED employee (should fail)

suspended employee (Should FAIL)
INSERT INTO user1.Attendance VALUES (
    101, 3, DATE '2024-12-10',
    TIMESTAMP '2024-12-10 09:00:00',
    TIMESTAMP '2024-12-10 17:00:00',
    8
);

--bonus

-- User2 Session 2: Waiting
SET SERVEROUTPUT ON;

DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('User2: Trying to raise IT salaries...');
    v_count := user1.RaiseDepartmentSalary('IT');  -- Calls function in User1

    DBMS_OUTPUT.PUT_LINE('User2: Updated ' || v_count || ' rows.');
END;
/
