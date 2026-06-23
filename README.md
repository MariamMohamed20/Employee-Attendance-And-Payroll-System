# Employee Attendance & Payroll System

An Oracle Database project that automates employee attendance tracking, payroll processing, leave management, salary deductions, and audit logging using SQL and PL/SQL.

## Overview

This project implements a multi-user employee management system in Oracle Database. The system tracks employee attendance, calculates working hours, generates monthly payroll records, processes leave deductions, and maintains audit logs for critical operations.

The project demonstrates the use of:

* SQL
* PL/SQL
* Stored Procedures
* Functions
* Triggers
* Sequences
* Database Security & Privilege Management
* Multi-user Database Architecture

---

## System Architecture

The system is divided into multiple users with different responsibilities:

| User    | Responsibility                                     |
| ------- | -------------------------------------------------- |
| SYS     | Database Administrator                             |
| Manager | Payroll, leave management, reporting, and auditing |
| User1   | Employee and attendance management                 |
| User2   | Testing and sample data operations                 |

---

## Features

### Employee Management

* Employee information storage
* Employee status tracking (Active / Suspended)
* Department management
* Salary management

### Attendance Management

* Employee attendance recording
* Attendance validation
* Automatic working-hours calculation
* Late arrival handling
* Attendance audit logging

### Payroll Management

* Monthly payroll generation
* Overtime calculation
* Salary deductions
* Net salary calculation
* Tax deduction support

### Leave Management

* Leave request submission
* Leave approval tracking
* Automatic deduction processing for unapproved leaves

### Audit & Monitoring

* Audit trail generation
* User creation logging
* Attendance violation logging

---

## Database Tables

### Employee & Attendance

* Employees
* Attendance
* SuspendedAttendanceAttempts

### Payroll & Deductions

* Payroll
* Deductions

### Leave Management

* LeaveRequests

### Auditing

* AuditTrail
* DBUserCreationLog

---

## Stored Procedures

### LogUserCreation

Logs newly created database users into the audit table.

**Purpose**

* Tracks database user creation activities.
* Maintains accountability for administrative actions.

---

### GenerateMonthlyPayroll

Automatically generates payroll records for active employees.

**Calculations include**

* Total worked hours
* Overtime hours
* Overtime pay
* Gross salary
* Allowances
* Bonuses
* Deductions
* Net salary

**Input**

```sql
p_month VARCHAR2
```

Example:

```sql
EXEC GenerateMonthlyPayroll('2024-12');
```

---

### GeneratePerformanceReport

Generates employee performance reports for a specified period.

**Measures**

* Total hours worked
* Late arrivals
* Approved leaves
* Employee performance statistics

**Inputs**

```sql
p_start_date DATE
p_end_date DATE
```

---

### ProcessLeaveDeductions

Processes salary deductions for employees who have pending or rejected leave requests.

**Features**

* Counts unapproved leave days.
* Calculates salary deductions.
* Updates payroll records.
* Records deductions in the Deductions table.

---

## Functions

### CalculateWorkHourss

Calculates employee working hours based on attendance records.

**Features**

* Calculates total worked hours.
* Applies a 5-minute grace period.
* Deducts excessive late minutes.
* Updates attendance records automatically.

**Returns**

* Total working hours.

---

### RaiseDepartmentSalary

Increases salaries for all employees in a specified department.

**Input**

```sql
p_dept VARCHAR2
```

**Returns**

* Number of updated employees.

Example:

```sql
SELECT RaiseDepartmentSalary('IT')
FROM dual;
```

---

### CalculateTaxDeduction

Calculates tax deductions based on employee net salary.

**Tax Rules**

| Net Salary | Tax Rate |
| ---------- | -------- |
| ≤ 5000     | 5%       |
| ≤ 10000    | 10%      |
| > 10000    | 15%      |

**Returns**

* Tax amount.

---

## Triggers

### ValidateAttendance

Executed before inserting attendance records.

**Responsibilities**

* Checks employee status.
* Prevents attendance insertion for suspended employees.
* Logs unauthorized attempts.
* Raises database errors when violations occur.

---

### CheckAttendanceTimes

Executed before inserting or updating attendance records.

**Validation**

* Ensures `out_time` is later than `in_time`.
* Prevents invalid attendance records from being stored.

---

### trg_leave_before_insert

Executed before inserting a leave request.

**Purpose**

* Creates an audit record whenever a leave request is submitted.

---

### trg_leave_after_update

Executed after updating a leave request.

**Purpose**

* Records both old and new leave request data.
* Maintains a complete audit history of leave status changes.

---

## Security Features

* User privilege management
* Controlled access between database users
* Audit logging
* Autonomous transactions for security logging
* Error handling using `RAISE_APPLICATION_ERROR`

---

## Project Structure

```text
Employee-Attendance-And-Payroll-System
│
├── SQL
│   ├── System.sql
│   ├── Manager.sql
│   ├── USER1.sql
│   └── USER2.sql
│
├── Documentation
│   ├── Project_Report.pdf
│   └── Version3.docx
│
└── README.md
```

---

## Setup Instructions

1. Connect as SYS.
2. Execute `System.sql`.
3. Connect as Manager and execute `Manager.sql`.
4. Connect as User1 and execute `USER 1.sql`.
5. Connect as User2 and execute `User 2.sql`.
6. Run the provided test cases.

---

## Learning Outcomes

This project demonstrates practical experience with:

* Oracle Database Administration
* SQL Development
* PL/SQL Programming
* Stored Procedures
* Functions
* Triggers
* Database Security
* Payroll Automation
* Attendance Management Systems
* Audit Logging Systems

---

Developed as part of a Database Systems course project using Oracle SQL Developer.
