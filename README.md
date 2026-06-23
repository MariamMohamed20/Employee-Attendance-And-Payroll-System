# Employee-Attendance-And-Payroll-System
# Employee Attendance & Payroll System

An Oracle Database project that automates employee attendance tracking, payroll processing, leave management, and audit logging using SQL and PL/SQL.

---

## Features

* Employee attendance management
* Monthly payroll generation
* Leave request tracking
* Overtime and deduction calculations
* Attendance validation using triggers
* Audit trail and activity logging
* Role-based access control
* Multi-user database environment

---

## Technologies Used

* Oracle Database
* SQL
* PL/SQL
* Triggers
* Stored Procedures
* Functions
* Sequences

---

## System Architecture

### Users

| User    | Responsibility                     |
| ------- | ---------------------------------- |
| SYS     | Database Administrator             |
| Manager | Payroll and system management      |
| User1   | Employee and attendance management |
| User2   | Data entry and testing             |

---

## Database Objects

### Tables

* Employees
* Attendance
* Payroll
* LeaveRequests
* Deductions
* AuditTrail
* SuspendedAttendanceAttempts
* DBUserCreationLog

### Procedures

* `LogUserCreation`
* `GenerateMonthlyPayroll`

### Functions

* `CalculateWorkHourss`

### Triggers

* `ValidateAttendance`

---

## Project Structure

```text
Employee-Attendance-And-Payroll-System
│
├── SQL
│   ├── System.sql
│   ├── Manager.sql
│   ├── User1.sql
│   └── User2.sql
│
├── Documentation
│   ├── Project_Report.pdf
│   └── Version3.docx
│
└── README.md
```

---

## Key Functionalities

### Attendance Validation

A database trigger prevents attendance records from being inserted for suspended employees and stores unauthorized attempts for auditing purposes.

### Payroll Processing

Payroll is generated automatically based on:

* Basic salary
* Overtime hours
* Bonuses
* Allowances
* Deductions

### Audit Logging

System activities are recorded to improve accountability and monitoring.

---

## Learning Outcomes

This project demonstrates:

* Database design and normalization
* SQL and PL/SQL development
* Trigger implementation
* Payroll automation
* Database security and privilege management
* Multi-user Oracle database environments

---

## Getting Started

1. Run `System.sql`
2. Run `Manager.sql`
3. Run `User1.sql`
4. Run `User2.sql`
5. Execute the provided test cases

---


Developed as part of a Advanced Database Systems course project using Oracle SQL Developer.
