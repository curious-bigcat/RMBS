# Housing for All Platform

## Affordable Housing Marketplace powered by Snowflake Native Apps

[![Version](https://img.shields.io/badge/version-0.4.0-blue.svg)](https://github.com)
[![Snowflake](https://img.shields.io/badge/Snowflake-Native%20App-29B5E8.svg)](https://snowflake.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Features](#features)
7. [User Roles](#user-roles)
8. [API Reference](#api-reference)
9. [Database Schema](#database-schema)
10. [Testing](#testing)
11. [Deployment](#deployment)
12. [Troubleshooting](#troubleshooting)

---

## Overview

**Housing for All** is a comprehensive affordable housing finance marketplace that connects borrowers with lenders and enables RMBS (Residential Mortgage-Backed Securities) securitization. Built entirely on Snowflake, it provides:

- **Borrower Onboarding**: Aadhaar-based eKYC with DigiLocker document verification
- **Eligibility Engine**: Real-time credit assessment based on CIBIL score, DTI ratio, and age
- **Loan Origination**: Digital application, approval workflow, and disbursement tracking
- **EMI Management**: Amortization schedules, payment tracking, and notifications
- **RMBS Securitization**: 6-month MHP compliant loan pooling for investors
- **Multi-Role Access**: Borrower, Originator, Investor, and Admin portals

### Key Metrics (Current Implementation)
- 18 Database Tables
- 21 Stored Procedures
- 4 Analytics Views
- 16 Streamlit Pages
- 4 User Roles

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        STREAMLIT UI LAYER                           │
│  ┌─────────┐ ┌───────────┐ ┌──────────┐ ┌─────────┐                │
│  │Borrower │ │Originator │ │ Investor │ │  Admin  │                │
│  │ Portal  │ │  Portal   │ │  Portal  │ │ Portal  │                │
│  └────┬────┘ └─────┬─────┘ └────┬─────┘ └────┬────┘                │
└───────┼────────────┼────────────┼────────────┼──────────────────────┘
        │            │            │            │
┌───────▼────────────▼────────────▼────────────▼──────────────────────┐
│                     SNOWFLAKE STORED PROCEDURES                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐                 │
│  │  KYC Layer   │ │ Loan Layer   │ │  RMBS Layer  │                 │
│  │ VERIFY_AADHAAR│ │UPDATE_STATUS │ │ASSIGN_TO_POOL│                 │
│  │ PERFORM_KYC  │ │RECORD_EMI    │ │INVEST_IN_POOL│                 │
│  └──────────────┘ └──────────────┘ └──────────────┘                 │
└─────────────────────────────────────────────────────────────────────┘
        │            │            │            │
┌───────▼────────────▼────────────▼────────────▼──────────────────────┐
│                        DATA LAYER (TABLES)                           │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐        │
│  │ BORROWERS  │ │   LOANS    │ │ RMBS_POOLS │ │ AUDIT_LOG  │        │
│  │ ELIGIBILITY│ │ EMI_PAYMENTS│ │ INVESTOR_  │ │NOTIFICATIONS│       │
│  │ CERTIFICATES│ │AMORTIZATION│ │ PORTFOLIO  │ │            │        │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘        │
└─────────────────────────────────────────────────────────────────────┘
        │            │            │            │
┌───────▼────────────▼────────────▼────────────▼──────────────────────┐
│                    MOCK INTEGRATION LAYER (MVP)                      │
│  ┌─────────────────────┐ ┌─────────────────────┐                    │
│  │  MOCK_UIDAI_REGISTRY │ │MOCK_DIGILOCKER_DOCS │                    │
│  │  (Aadhaar Database)  │ │ (Document Store)    │                    │
│  └─────────────────────┘ └─────────────────────┘                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Snowflake Requirements
- Snowflake Account (Enterprise or higher recommended)
- Role: ACCOUNTADMIN (for initial setup)
- Warehouse: COMPUTE_WH (or any X-Small+)

### Local Development
- Snowflake CLI (`snow`) v2.0+
- Python 3.8+ (for local testing)
- Git

### Installation Commands
```bash
# Install Snowflake CLI
pip install snowflake-cli-labs

# Verify installation
snow --version

# Configure connection
snow connection add
```

---

## Installation

### Step 1: Clone Repository
```bash
git clone https://github.com/your-org/housing-for-all.git
cd housing-for-all
```

### Step 2: Configure Snowflake Connection
```bash
# Create connection (interactive)
snow connection add --connection-name housing_platform

# Or edit ~/.snowflake/config.toml
[connections.housing_platform]
account = "YOUR_ACCOUNT"
user = "YOUR_USER"
password = "YOUR_PASSWORD"
warehouse = "COMPUTE_WH"
database = "HOUSING_PLATFORM"
schema = "CORE"
role = "ACCOUNTADMIN"
```

### Step 3: Create Database and Schema
```sql
-- Run in Snowflake
CREATE DATABASE IF NOT EXISTS HOUSING_PLATFORM;
CREATE SCHEMA IF NOT EXISTS HOUSING_PLATFORM.CORE;
USE DATABASE HOUSING_PLATFORM;
USE SCHEMA CORE;
```

### Step 4: Execute Setup Script
```bash
# Option 1: Using Snowflake CLI
snow sql -f setup.sql

# Option 2: Using Snowsight
# Copy contents of setup.sql and execute in worksheet
```

### Step 5: Deploy Streamlit App
```bash
# Deploy using Snowflake CLI
snow streamlit deploy --replace

# Verify deployment
snow streamlit list
```

### Step 6: Verify Installation
```sql
-- Check tables created
SELECT TABLE_NAME, ROW_COUNT 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'CORE';

-- Check procedures
SHOW PROCEDURES IN SCHEMA HOUSING_PLATFORM.CORE;

-- Test a procedure
CALL HOUSING_PLATFORM.CORE.VERIFY_AADHAAR('123456789012');
```

---

## Configuration

### Environment Variables (snowflake.yml)
```yaml
definition_version: 2
entities:
  housing_streamlit:
    type: streamlit
    identifier:
      name: HOUSING_FOR_ALL_APP
    title: "Housing for All Platform"
    main_file: streamlit_app.py
    query_warehouse: COMPUTE_WH
    pages_dir: pages/
```

### Role Configuration
```sql
-- Create application roles (optional)
CREATE ROLE IF NOT EXISTS HOUSING_BORROWER;
CREATE ROLE IF NOT EXISTS HOUSING_ORIGINATOR;
CREATE ROLE IF NOT EXISTS HOUSING_INVESTOR;
CREATE ROLE IF NOT EXISTS HOUSING_ADMIN;

-- Grant permissions
GRANT USAGE ON DATABASE HOUSING_PLATFORM TO ROLE HOUSING_BORROWER;
GRANT USAGE ON SCHEMA HOUSING_PLATFORM.CORE TO ROLE HOUSING_BORROWER;
```

---

## Features

### 1. eKYC Verification
**Mock UIDAI Aadhaar Verification**
```sql
-- Verify Aadhaar number
CALL HOUSING_PLATFORM.CORE.VERIFY_AADHAAR('123456789012');

-- Response:
{
  "success": true,
  "aadhaar_id": "123456789012",
  "name": "Priya Sharma",
  "date_of_birth": "1990-05-15",
  "gender": "F",
  "is_active": true
}
```

**DigiLocker Document Fetch**
```sql
-- Fetch documents from DigiLocker
CALL HOUSING_PLATFORM.CORE.FETCH_DIGILOCKER_DOCUMENTS('123456789012', NULL);

-- Response includes: PAN, Form 16, ITR, Property Deed, etc.
```

**Complete KYC Check**
```sql
CALL HOUSING_PLATFORM.CORE.PERFORM_KYC_CHECK('123456789012');

-- Validates: Aadhaar active, PAN available, Income proof available
```

### 2. Eligibility Assessment
**Criteria**:
- Credit Score: >= 750 (CIBIL)
- Age: 25-50 years
- DTI Ratio: <= 50%

```sql
-- Check eligibility
CALL HOUSING_PLATFORM.CORE.CHECK_BORROWER_ELIGIBILITY(
    780,      -- credit_score
    100000,   -- monthly_income
    30000,    -- monthly_liabilities
    35        -- age
);

-- Issue certificate for eligible borrowers
CALL HOUSING_PLATFORM.CORE.ISSUE_ELIGIBILITY_CERTIFICATE('123456789012');
```

### 3. Loan Origination
**Application Flow**:
1. Borrower submits application
2. Originator reviews
3. Document verification
4. Approval/Rejection
5. Disbursement

```sql
-- Update loan status
CALL HOUSING_PLATFORM.CORE.UPDATE_LOAN_STATUS(
    'LOAN-001',           -- loan_id
    'APPROVED',           -- new_status
    'ORIGINATOR_001',     -- changed_by
    'All documents verified, approved for disbursement'
);
```

### 4. EMI Management
**Generate Amortization Schedule**
```sql
CALL HOUSING_PLATFORM.CORE.GENERATE_AMORTIZATION_SCHEDULE('LOAN-001');

-- Generates up to 24 EMI entries with:
-- - Opening Balance
-- - EMI Amount
-- - Principal Component
-- - Interest Component
-- - Closing Balance
```

**Record EMI Payment**
```sql
CALL HOUSING_PLATFORM.CORE.RECORD_EMI_PAYMENT(
    'LOAN-001',       -- loan_id
    1,                -- emi_number
    40279.66,         -- paid_amount
    'NACH',           -- payment_mode (NACH/UPI/NEFT/CHEQUE)
    'TXN123456789'    -- transaction_ref
);
```

### 5. RMBS Securitization
**6-Month Minimum Holding Period (MHP)**
```sql
-- Loans become pool-eligible 6 months after disbursement
-- Automatic calculation: POOL_ELIGIBLE_DATE = DISBURSEMENT_DATE + 6 months

-- Assign eligible loans to pools
CALL HOUSING_PLATFORM.CORE.ASSIGN_LOANS_TO_POOLS();
```

**Investor Investment**
```sql
CALL HOUSING_PLATFORM.CORE.INVEST_IN_POOL(
    'INV-001',        -- investor_id
    'RMBS-2025-Q4',   -- pool_id
    1000000           -- investment_amount
);
```

### 6. Notifications
```sql
-- Send notification
CALL HOUSING_PLATFORM.CORE.SEND_NOTIFICATION(
    '123456789012',   -- user_id
    'BORROWER',       -- user_type
    'EMI_DUE',        -- notification_type
    'EMI Due Reminder',
    'Your EMI of Rs.40,280 is due on 2026-02-01',
    'LOAN',
    'LOAN-001'
);

-- Get user notifications
CALL HOUSING_PLATFORM.CORE.GET_USER_NOTIFICATIONS('123456789012');
```

### 7. Platform Analytics
```sql
-- Generate comprehensive report
CALL HOUSING_PLATFORM.CORE.GENERATE_PLATFORM_REPORT();

-- Response includes:
-- - Borrower stats (total, KYC verified, avg credit score)
-- - Loan stats (total, portfolio value, avg rate)
-- - Pool stats (total pools, securitized value, investors)
```

---

## User Roles

### Borrower
| Page | Description |
|------|-------------|
| eKYC Verification | Verify Aadhaar and fetch DigiLocker documents |
| Eligibility Check | Check loan eligibility and get certificate |
| Apply for Loan | Submit new loan application |
| Rate Comparison | Compare platform rates with market |
| My Applications | View loan status and history |
| EMI Payments | View schedule and record payments |
| Notifications | View alerts and reminders |
| Document Upload | Upload additional documents |

### Originator
| Page | Description |
|------|-------------|
| Dashboard | KPIs and pending actions |
| Loan Approvals | Review and approve/reject loans |
| Document Verification | Verify uploaded documents |
| All Borrowers | View all registered borrowers |
| RMBS Dashboard | View securitization pools |
| Platform Report | Generate analytics report |
| Audit Log | View activity history |

### Investor
| Page | Description |
|------|-------------|
| Investor Portal | Portfolio summary and new investments |
| RMBS Dashboard | View all available pools |
| Pool Analytics | Detailed pool performance metrics |

### Admin
| Page | Description |
|------|-------------|
| Admin Dashboard | System overview and quick actions |
| All Originator Pages | Full originator access |
| All Investor Pages | Full investor access |
| User Management | Manage user roles |

---

## API Reference

### Stored Procedures

#### KYC Module
| Procedure | Parameters | Returns |
|-----------|------------|---------|
| `VERIFY_AADHAAR` | `(aadhaar_id VARCHAR)` | OBJECT |
| `FETCH_DIGILOCKER_DOCUMENTS` | `(aadhaar_id VARCHAR, doc_type VARCHAR)` | OBJECT |
| `PERFORM_KYC_CHECK` | `(aadhaar_id VARCHAR)` | OBJECT |
| `REGISTER_BORROWER_FROM_KYC` | `(aadhaar_id, income, liabilities, credit_score)` | OBJECT |

#### Loan Module
| Procedure | Parameters | Returns |
|-----------|------------|---------|
| `UPDATE_LOAN_STATUS` | `(loan_id, status, changed_by, comments)` | OBJECT |
| `GENERATE_AMORTIZATION_SCHEDULE` | `(loan_id VARCHAR)` | OBJECT |
| `RECORD_EMI_PAYMENT` | `(loan_id, emi_number, amount, mode, ref)` | OBJECT |
| `CALCULATE_PREPAYMENT` | `(loan_id, prepay_amount)` | OBJECT |

#### RMBS Module
| Procedure | Parameters | Returns |
|-----------|------------|---------|
| `ASSIGN_LOANS_TO_POOLS` | `()` | VARCHAR |
| `INVEST_IN_POOL` | `(investor_id, pool_id, amount)` | OBJECT |
| `GET_INVESTOR_DASHBOARD` | `(investor_id VARCHAR)` | OBJECT |

#### Platform Module
| Procedure | Parameters | Returns |
|-----------|------------|---------|
| `GET_BORROWER_SUMMARY` | `(aadhaar_id VARCHAR)` | OBJECT |
| `GET_ORIGINATOR_DASHBOARD` | `()` | OBJECT |
| `GENERATE_PLATFORM_REPORT` | `()` | OBJECT |
| `LOG_AUDIT_EVENT` | `(role, user, action, entity_type, entity_id, details, status, error)` | VARCHAR |

#### Notification Module
| Procedure | Parameters | Returns |
|-----------|------------|---------|
| `SEND_NOTIFICATION` | `(user_id, user_type, type, title, message, entity_type, entity_id)` | VARCHAR |
| `GET_USER_NOTIFICATIONS` | `(user_id VARCHAR)` | OBJECT |
| `MARK_NOTIFICATION_READ` | `(notification_id VARCHAR)` | VARCHAR |

---

## Database Schema

### Core Tables

```sql
-- BORROWERS: Registered borrowers with financial info
BORROWERS (
    AADHAAR_ID VARCHAR(12) PRIMARY KEY,
    NAME VARCHAR(255),
    DATE_OF_BIRTH DATE,
    MONTHLY_INCOME NUMBER(15,2),
    MONTHLY_LIABILITIES NUMBER(15,2),
    CREDIT_SCORE NUMBER(3),
    KYC_VERIFIED BOOLEAN,
    CREATED_AT TIMESTAMP_NTZ
)

-- LOANS: Housing loan applications
LOANS (
    LOAN_ID VARCHAR(36) PRIMARY KEY,
    BORROWER_ID VARCHAR(12),
    AMOUNT NUMBER(15,2),
    INTEREST_RATE NUMBER(5,4),
    TENURE_MONTHS NUMBER,
    DISBURSEMENT_DATE DATE,
    POOL_ID VARCHAR(50),
    POOL_ELIGIBLE_DATE DATE,
    STATUS VARCHAR(20),  -- PENDING, APPROVED, ACTIVE, CLOSED
    CREATED_AT TIMESTAMP_NTZ
)

-- RMBS_POOLS: Securitization pools
RMBS_POOLS (
    POOL_ID VARCHAR(50) PRIMARY KEY,
    NAME VARCHAR(100),
    AGGREGATION_DATE DATE,
    TOTAL_VALUE NUMBER(18,2),
    LOAN_COUNT NUMBER,
    TRUSTEE VARCHAR(100),
    STATUS VARCHAR(20)  -- OPEN, CLOSED
)

-- EMI_PAYMENTS: Payment tracking
EMI_PAYMENTS (
    PAYMENT_ID VARCHAR(36) PRIMARY KEY,
    LOAN_ID VARCHAR(36),
    EMI_NUMBER INT,
    DUE_DATE DATE,
    TOTAL_EMI NUMBER(15,2),
    PAID_AMOUNT NUMBER(15,2),
    PAYMENT_STATUS VARCHAR(20),  -- PENDING, PAID, OVERDUE, PARTIAL
    PAYMENT_MODE VARCHAR(20)
)

-- LOAN_AMORTIZATION: EMI schedule
LOAN_AMORTIZATION (
    SCHEDULE_ID VARCHAR(36) PRIMARY KEY,
    LOAN_ID VARCHAR(36),
    EMI_NUMBER INT,
    DUE_DATE DATE,
    OPENING_BALANCE NUMBER(15,2),
    EMI_AMOUNT NUMBER(15,2),
    PRINCIPAL_COMPONENT NUMBER(15,2),
    INTEREST_COMPONENT NUMBER(15,2),
    CLOSING_BALANCE NUMBER(15,2)
)
```

### Analytics Views

```sql
-- V_PORTFOLIO_ANALYTICS: Monthly loan origination metrics
-- V_RISK_DISTRIBUTION: Borrower risk categorization
-- V_POOL_PERFORMANCE: RMBS pool performance
-- V_EMI_COLLECTION: EMI collection rates
```

---

## Testing

### Test Data (Pre-loaded)

| Aadhaar | Name | Has PAN | Has Income Proof | Credit Score |
|---------|------|---------|------------------|--------------|
| 123456789012 | Priya Sharma | Yes | Yes (Form 16) | 780 |
| 234567890123 | Rahul Verma | Yes | Yes (ITR) | 810 |
| 345678901234 | Anita Patel | Yes | No | 750 |
| 456789012345 | Vijay Kumar | Yes | No | 720 |
| 567890123456 | Meera Reddy | No | No | 690 |

### Test Investor
- Investor ID: `INV-001`

### Test Loans
- LOAN-001 through LOAN-010 (pre-loaded)

### Running Tests

```sql
-- Test 1: Aadhaar Verification
CALL HOUSING_PLATFORM.CORE.VERIFY_AADHAAR('123456789012');
-- Expected: success = true, name = "Priya Sharma"

-- Test 2: KYC Check
CALL HOUSING_PLATFORM.CORE.PERFORM_KYC_CHECK('123456789012');
-- Expected: kyc_status = "PASSED"

-- Test 3: Amortization Generation
CALL HOUSING_PLATFORM.CORE.GENERATE_AMORTIZATION_SCHEDULE('LOAN-001');
-- Expected: success = true, emis_generated = 24

-- Test 4: EMI Payment
CALL HOUSING_PLATFORM.CORE.RECORD_EMI_PAYMENT('LOAN-001', 1, 40279.66, 'NACH', 'TEST-TXN');
-- Expected: success = true, status = "PAID"

-- Test 5: Platform Report
CALL HOUSING_PLATFORM.CORE.GENERATE_PLATFORM_REPORT();
-- Expected: Returns borrower_stats, loan_stats, pool_stats

-- Test 6: Investor Dashboard
CALL HOUSING_PLATFORM.CORE.GET_INVESTOR_DASHBOARD('INV-001');
-- Expected: Returns portfolio with investments
```

---

## Deployment

### Deploy to Snowflake

```bash
# 1. Deploy Streamlit app
cd /path/to/housing-platform
snow streamlit deploy --replace

# 2. Verify deployment
snow streamlit list

# 3. Get app URL
snow streamlit describe HOUSING_FOR_ALL_APP
```

### Native App Package (For Marketplace)

```sql
-- Create application package
CREATE APPLICATION PACKAGE HOUSING_FOR_ALL_PKG
    DISTRIBUTION = INTERNAL;

-- Upload files to stage
PUT file://setup.sql @HOUSING_FOR_ALL_PKG.PUBLIC.APP_STAGE;
PUT file://manifest.yml @HOUSING_FOR_ALL_PKG.PUBLIC.APP_STAGE;
PUT file://streamlit_app.py @HOUSING_FOR_ALL_PKG.PUBLIC.APP_STAGE;

-- Register version
ALTER APPLICATION PACKAGE HOUSING_FOR_ALL_PKG
    REGISTER VERSION V0_4 
    USING '@HOUSING_FOR_ALL_PKG.PUBLIC.APP_STAGE';
```

---

## Troubleshooting

### Common Issues

**1. Procedure returns "Loan not found"**
```sql
-- Check if loan exists
SELECT * FROM HOUSING_PLATFORM.CORE.LOANS WHERE LOAN_ID = 'YOUR_LOAN_ID';
```

**2. KYC fails with "Aadhaar not found"**
```sql
-- Verify Aadhaar in mock registry
SELECT * FROM HOUSING_PLATFORM.CORE.MOCK_UIDAI_REGISTRY;
```

**3. Division by zero in amortization**
```sql
-- Check loan has valid interest rate and tenure
SELECT LOAN_ID, INTEREST_RATE, TENURE_MONTHS 
FROM HOUSING_PLATFORM.CORE.LOANS 
WHERE LOAN_ID = 'YOUR_LOAN_ID';
```

**4. Streamlit app not loading**
```bash
# Check app status
snow streamlit describe HOUSING_FOR_ALL_APP

# Redeploy
snow streamlit deploy --replace
```

### Support

- **Documentation**: This README
- **Issues**: GitHub Issues
- **Contact**: support@housingforall.platform

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-01-18 | Initial MVP with KYC, eligibility, loans |
| 0.2.0 | 2026-01-18 | Added RMBS pooling, investor portal |
| 0.3.0 | 2026-01-19 | Added audit logging, document management |
| 0.4.0 | 2026-01-19 | Added EMI tracking, notifications, analytics |

---

## License

MIT License - See LICENSE file for details.

---

## Contributors

- Development Team
- Powered by Snowflake Native Apps
- Generated with Cortex Code
