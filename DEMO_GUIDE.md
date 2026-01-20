# Housing for All Platform - Demo Guide

## Streamlit UI Walkthrough & Testing Guide

This guide provides step-by-step instructions for demonstrating and testing all functionalities of the Housing for All Platform.

---

## Quick Start

**Access the Streamlit App:**
```
URL: https://app.snowflake.com/SFSEAPAC-BSURESH/HOUSING_PLATFORM#/streamlit-apps/HOUSING_PLATFORM.CORE.HOUSING_FOR_ALL_APP
```

Or via Snowsight: Navigate to **Projects > Streamlit** > **HOUSING_FOR_ALL_APP**

---

## Test Data Reference

| Aadhaar | Name | Credit Score | Has PAN | Has Income Proof | Eligible |
|---------|------|--------------|---------|------------------|----------|
| 123456789012 | Priya Sharma | 780 | Yes | Yes (Form 16) | Yes |
| 234567890123 | Rahul Verma | 810 | Yes | Yes (ITR) | Yes |
| 345678901234 | Anita Patel | 750 | Yes | No | Yes |
| 456789012345 | Vijay Kumar | 720 | Yes | No | No (score) |
| 567890123456 | Meera Reddy | 690 | No | No | No |

**Test Investor:** `INV-001`

**Test Loans:** `LOAN-001` through `LOAN-010`

---

## Demo Flow Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         RECOMMENDED DEMO FLOW                           │
├─────────────────────────────────────────────────────────────────────────┤
│  1. Borrower Journey (15 min)                                           │
│     └─> eKYC → Eligibility → Apply → Track → EMI                        │
│                                                                         │
│  2. Originator Workflow (10 min)                                        │
│     └─> Dashboard → Approve Loan → Verify Docs → Pool Assignment        │
│                                                                         │
│  3. Investor Portal (5 min)                                             │
│     └─> View Pools → Invest → Track Portfolio                           │
│                                                                         │
│  4. Admin Analytics (5 min)                                             │
│     └─> Platform Report → Audit Log → Analytics Views                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Part 1: Borrower Journey

### Step 1.1: eKYC Verification

**Role:** Select `Borrower` from the sidebar  
**Page:** Select `eKYC Verification`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter Aadhaar: `123456789012` | Input accepted |
| 2 | Click **"Verify Aadhaar"** | Shows: Name "Priya Sharma", DOB, Gender |
| 3 | Click **"Complete KYC Check"** | Shows: KYC Status "PASSED" |
| 4 | Review DigiLocker Documents | Table shows: PAN, Form 16, Property Deed |
| 5 | Expand "Test Aadhaar Numbers" | Reference table displayed |

**Test Negative Case:**
- Enter `999999999999` → Should show "Aadhaar not found in registry"
- Enter `567890123456` → KYC shows "INCOMPLETE" (missing PAN)

---

### Step 1.2: Eligibility Check

**Page:** Select `Eligibility Check`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Aadhaar auto-fills from KYC (or enter `123456789012`) | Pre-populated |
| 2 | Enter Monthly Income: `150000` | Input accepted |
| 3 | Enter Monthly Liabilities: `30000` | DTI = 20% |
| 4 | Enter CIBIL Score: `780` | Input accepted |
| 5 | Click **"Check Eligibility"** | "Congratulations! You are eligible" |
| 6 | Review "Your Eligible Rates" table | Shows Platform vs Market rates |
| 7 | Click **"Register & Get Certificate"** | "Borrower registered successfully!" + confetti |

**Test Negative Cases:**
| Scenario | Input | Expected |
|----------|-------|----------|
| Low Credit Score | CIBIL: 700 | "Credit score 700 is below minimum 750" |
| High DTI | Income: 50000, Liabilities: 30000 | "DTI ratio 60% exceeds 50%" |
| Age Out of Range | DOB: 2005-01-01 (age 21) | "Age 21 is outside 25-50 year range" |

---

### Step 1.3: Rate Comparison

**Page:** Select `Rate Comparison`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set Loan Amount: `50` Lakhs | Slider adjusted |
| 2 | Set Tenure: `20` Years | Slider adjusted |
| 3 | Review comparison table | 5 lenders with EMI calculations |
| 4 | Check savings metrics | Monthly Savings, Total Savings displayed |

**Key Talking Points:**
- Platform Rate: 7.5% vs Market: 9.5%
- Monthly savings of ~₹6,000 on ₹50L loan
- Total savings of ~₹14L over 20 years

---

### Step 1.4: Apply for Loan

**Page:** Select `Apply for Loan`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select Borrower from dropdown | Shows eligible borrowers only |
| 2 | Enter Loan Amount: `5000000` (₹50L) | Input accepted |
| 3 | Select Tenure: `20` years | Dropdown selected |
| 4 | Interest Rate: `7.5`% | Default or adjusted |
| 5 | Set Disbursement Date | Calendar picker |
| 6 | Review Loan Summary | EMI, Total Interest, Total Payment shown |
| 7 | Click **"Submit Application"** | "Loan application submitted! Loan ID: LOAN-XXXXXXXX" |

---

### Step 1.5: My Applications

**Page:** Select `My Applications`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter Aadhaar: `123456789012` | Loads borrower dashboard |
| 2 | Review borrower metrics | Credit Score, DTI, KYC Status, Eligibility |
| 3 | Review loan summary | Total Loans, Active Loans, Total Amount |
| 4 | Scroll to "Recent Applications" | Table of all loans with status |

---

### Step 1.6: EMI Payments

**Page:** Select `EMI Payments`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select Loan from dropdown | e.g., LOAN-001 |
| 2 | Click **"Generate Schedule"** | Amortization schedule displayed |
| 3 | Review EMI breakdown | Opening Balance, Principal, Interest, Closing Balance |
| 4 | Select EMI Number: `1` | First EMI selected |
| 5 | Enter Payment Amount | Pre-filled with EMI amount |
| 6 | Select Payment Mode: `NACH` | Dropdown selected |
| 7 | Enter Transaction Ref: `TXN123456` | Input accepted |
| 8 | Click **"Record Payment"** | "Payment recorded successfully!" |

---

### Step 1.7: Notifications

**Page:** Select `Notifications`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter Aadhaar: `123456789012` | Loads notifications |
| 2 | Review notification list | EMI reminders, loan updates, etc. |
| 3 | Click on a notification | Mark as read |

---

### Step 1.8: Document Upload

**Page:** Select `Document Upload`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter Aadhaar: `123456789012` | Input accepted |
| 2 | Select Document Type: `SALARY_SLIP` | Dropdown selected |
| 3 | Upload a PDF/JPG file | File selector |
| 4 | Click **"Upload Document"** | "Document uploaded successfully!" |
| 5 | Review "Your Uploaded Documents" | Table shows uploaded docs |

---

## Part 2: Originator Workflow

### Step 2.1: Originator Dashboard

**Role:** Select `Originator` from the sidebar  
**Page:** Select `Originator Dashboard`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Review Key Metrics | Total Loans, Pending Approval, Portfolio Value, Avg Rate |
| 2 | Review Borrower Stats | Total Borrowers, KYC Verified, Avg Credit Score |
| 3 | Check Pending Actions | Loans awaiting approval, Documents to verify |

---

### Step 2.2: Loan Approvals

**Page:** Select `Loan Approvals`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Review pending loans table | Shows all PENDING loans |
| 2 | Select a loan from dropdown | e.g., newly created loan |
| 3 | Click **"Approve Loan"** | "Loan approved successfully!" |
| 4 | Verify status changed | Refresh shows APPROVED status |

**Test Rejection:**
- Select another loan → Click **"Reject Loan"** → Enter reason → Confirm

---

### Step 2.3: Document Verification

**Page:** Select `Document Verification`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Review pending documents | Table of unverified docs |
| 2 | Select a document | Doc details displayed |
| 3 | Click **"Approve Document"** | Status → VERIFIED |
| 4 | Or click **"Reject"** with reason | Status → REJECTED |

---

### Step 2.4: All Borrowers

**Page:** Select `All Borrowers`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Review borrowers table | All registered borrowers |
| 2 | Check eligibility status | Dynamic column shows IS_ELIGIBLE |
| 3 | Filter by KYC status | Verified vs Pending |

---

### Step 2.5: RMBS Dashboard

**Page:** Select `RMBS Dashboard`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Review pool metrics | Total Pools, Total Loans, Total Value |
| 2 | View Pool Details table | Pool IDs, aggregation dates, values |
| 3 | Check pool eligibility | "Eligible Loans" shows MHP-compliant loans |

---

### Step 2.6: Platform Report

**Page:** Select `Platform Report`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click **"Generate Report"** | Comprehensive platform analytics |
| 2 | Review Borrower Statistics | Total, KYC verified, avg credit score |
| 3 | Review Loan Statistics | Total, portfolio value, avg rate |
| 4 | Review Pool Statistics | Total pools, securitized value, investors |

---

### Step 2.7: Audit Log

**Page:** Select `Audit Log`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Review audit entries | All platform actions logged |
| 2 | Filter by action type | LOAN_APPROVE, KYC_CHECK, etc. |
| 3 | View entry details | User, timestamp, entity, status |

---

## Part 3: Investor Portal

### Step 3.1: Investor Dashboard

**Role:** Select `Investor` from the sidebar  
**Page:** Select `Investor Portal`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter Investor ID: `INV-001` | Loads investor dashboard |
| 2 | Review Portfolio Summary | Total invested, number of pools |
| 3 | View current investments | Table of pool investments |

---

### Step 3.2: Invest in Pool

**Page:** Still on `Investor Portal`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Scroll to "Available Pools" | Open pools displayed |
| 2 | Select a pool (e.g., `RMBS-2026-Q2`) | Pool selected |
| 3 | Enter Investment Amount: `1000000` | ₹10L investment |
| 4 | Click **"Invest in Pool"** | "Investment successful!" |
| 5 | Verify in portfolio | New investment appears |

---

### Step 3.3: Pool Analytics

**Page:** Select `Pool Analytics`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a pool | Pool details loaded |
| 2 | Review pool composition | Loan count, total value, avg rate |
| 3 | View underlying loans | Table of loans in pool |

---

## Part 4: Admin Dashboard

### Step 4.1: Admin Overview

**Role:** Select `Admin` from the sidebar  
**Page:** Select `Admin Dashboard`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Review system overview | All platform metrics |
| 2 | Quick action buttons | Generate report, assign pools, etc. |
| 3 | Navigate to any module | Full access to all features |

---

### Step 4.2: User Management

**Page:** Select `User Management`

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View user roles | All users and their roles |
| 2 | Modify role (if implemented) | Role updated |

---

## Part 5: SQL-Based Testing

For deeper testing, run these queries in Snowsight:

### Test KYC Procedures

```sql
-- Verify Aadhaar
CALL HOUSING_PLATFORM.CORE.VERIFY_AADHAAR('123456789012');

-- Full KYC Check
CALL HOUSING_PLATFORM.CORE.PERFORM_KYC_CHECK('123456789012');

-- Fetch DigiLocker Documents
CALL HOUSING_PLATFORM.CORE.FETCH_DIGILOCKER_DOCUMENTS('123456789012', NULL);
```

### Test Loan Procedures

```sql
-- Generate Amortization Schedule
CALL HOUSING_PLATFORM.CORE.GENERATE_AMORTIZATION_SCHEDULE('LOAN-001');

-- Record EMI Payment
CALL HOUSING_PLATFORM.CORE.RECORD_EMI_PAYMENT('LOAN-001', 1, 40279.66, 'NACH', 'TXN-TEST-001');

-- Calculate Prepayment
CALL HOUSING_PLATFORM.CORE.CALCULATE_PREPAYMENT('LOAN-001', 500000);
```

### Test RMBS Procedures

```sql
-- Assign Loans to Pools
CALL HOUSING_PLATFORM.CORE.ASSIGN_LOANS_TO_POOLS();

-- Invest in Pool
CALL HOUSING_PLATFORM.CORE.INVEST_IN_POOL('INV-001', 'RMBS-2026-Q1', 1000000);

-- Get Investor Dashboard
CALL HOUSING_PLATFORM.CORE.GET_INVESTOR_DASHBOARD('INV-001');
```

### Test Analytics

```sql
-- Platform Report
CALL HOUSING_PLATFORM.CORE.GENERATE_PLATFORM_REPORT();

-- Originator Dashboard
CALL HOUSING_PLATFORM.CORE.GET_ORIGINATOR_DASHBOARD();

-- Borrower Summary
CALL HOUSING_PLATFORM.CORE.GET_BORROWER_SUMMARY('123456789012');
```

### View Analytics

```sql
-- Portfolio Analytics
SELECT * FROM HOUSING_PLATFORM.CORE.V_PORTFOLIO_ANALYTICS;

-- Risk Distribution
SELECT * FROM HOUSING_PLATFORM.CORE.V_RISK_DISTRIBUTION;

-- Pool Performance
SELECT * FROM HOUSING_PLATFORM.CORE.V_POOL_PERFORMANCE;

-- EMI Collection
SELECT * FROM HOUSING_PLATFORM.CORE.V_EMI_COLLECTION;
```

---

## Demo Script - 30-Minute Presentation

### Opening (2 min)
- Introduce Housing for All Platform
- Show architecture diagram (README)
- Highlight: All data stays in Snowflake

### Borrower Demo (10 min)
1. eKYC with `123456789012` - Show UIDAI/DigiLocker integration
2. Eligibility check - Show credit scoring rules
3. Rate comparison - Highlight platform savings
4. Apply for loan - Show real-time EMI calculation
5. Track application - Show borrower dashboard

### Originator Demo (8 min)
1. Dashboard KPIs - Show pending actions
2. Approve the loan just created
3. Verify documents
4. Show RMBS pooling (6-month MHP rule)

### Investor Demo (5 min)
1. Show available pools
2. Make an investment
3. View portfolio

### Admin & Analytics (3 min)
1. Generate platform report
2. Show audit trail
3. Demonstrate analytics views

### Closing (2 min)
- Recap Snowflake features used:
  - Stored Procedures (21)
  - Dynamic Tables
  - Streams & Tasks
  - Streamlit in Snowflake
  - Cortex Analyst (semantic model)

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "No eligible borrowers found" | Complete eKYC and eligibility check first |
| "Loan not found" | Use valid loan ID (LOAN-001 to LOAN-010) |
| "Aadhaar not found" | Use test Aadhaar numbers (see table above) |
| Page not loading | Check warehouse is running |
| Empty tables | Run `setup.sql` to reload sample data |

### Reset Test Data

```sql
-- Truncate and reload sample data
-- (Run relevant INSERT statements from setup.sql)
```

---

## Feature Checklist

Use this checklist to verify all features work:

### Borrower Features
- [ ] eKYC Verification (Aadhaar)
- [ ] eKYC Verification (DigiLocker)
- [ ] Eligibility Check (pass case)
- [ ] Eligibility Check (fail cases)
- [ ] Rate Comparison calculator
- [ ] Loan Application submission
- [ ] My Applications dashboard
- [ ] EMI Schedule generation
- [ ] EMI Payment recording
- [ ] Notifications view
- [ ] Document Upload

### Originator Features
- [ ] Dashboard KPIs
- [ ] Loan Approval
- [ ] Loan Rejection
- [ ] Document Verification
- [ ] All Borrowers view
- [ ] RMBS Dashboard
- [ ] Platform Report generation
- [ ] Audit Log review

### Investor Features
- [ ] Portfolio Dashboard
- [ ] Pool Investment
- [ ] Pool Analytics

### Admin Features
- [ ] Full platform access
- [ ] User Management
- [ ] System overview

---

*Generated with Cortex Code | Last Updated: January 2026*
