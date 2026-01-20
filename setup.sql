-- Housing for All Platform - Setup Script
-- Creates schema, tables, dynamic tables, streams, and tasks

-- Application Schema
CREATE SCHEMA IF NOT EXISTS CORE;

-- ============================================
-- MOCK INTEGRATION TABLES (MVP)
-- Simulates UIDAI Aadhaar and DigiLocker APIs
-- ============================================

CREATE TABLE IF NOT EXISTS CORE.MOCK_UIDAI_REGISTRY (
    AADHAAR_ID VARCHAR(12) PRIMARY KEY,
    NAME VARCHAR(255) NOT NULL,
    DATE_OF_BIRTH DATE NOT NULL,
    GENDER VARCHAR(10),
    ADDRESS VARCHAR(500),
    MOBILE_HASH VARCHAR(64),
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS CORE.MOCK_DIGILOCKER_DOCUMENTS (
    DOC_ID VARCHAR(36) PRIMARY KEY,
    AADHAAR_ID VARCHAR(12) NOT NULL,
    DOC_TYPE VARCHAR(50) NOT NULL,  -- AADHAAR, PAN, DRIVING_LICENSE, VOTER_ID, FORM_16, ITR, PROPERTY_DEED
    DOC_NUMBER VARCHAR(50),
    ISSUER VARCHAR(100),
    ISSUE_DATE DATE,
    EXPIRY_DATE DATE,
    VERIFICATION_STATUS VARCHAR(20) DEFAULT 'VERIFIED',  -- VERIFIED, PENDING, REJECTED
    DOC_METADATA VARIANT,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Seed mock UIDAI data for testing
INSERT INTO CORE.MOCK_UIDAI_REGISTRY (AADHAAR_ID, NAME, DATE_OF_BIRTH, GENDER, ADDRESS, IS_ACTIVE)
SELECT * FROM VALUES
    ('123456789012', 'Priya Sharma', '1990-05-15', 'F', '42 MG Road, Bangalore, Karnataka 560001', TRUE),
    ('234567890123', 'Rahul Verma', '1985-08-22', 'M', '15 Park Street, Kolkata, West Bengal 700016', TRUE),
    ('345678901234', 'Anita Patel', '1992-03-10', 'F', '78 Link Road, Mumbai, Maharashtra 400053', TRUE),
    ('456789012345', 'Vijay Kumar', '1988-11-28', 'M', '23 Anna Salai, Chennai, Tamil Nadu 600002', TRUE),
    ('567890123456', 'Meera Reddy', '1995-07-04', 'F', '56 Jubilee Hills, Hyderabad, Telangana 500033', TRUE),
    ('999999999999', 'Inactive User', '1980-01-01', 'M', 'Unknown', FALSE)
WHERE NOT EXISTS (SELECT 1 FROM CORE.MOCK_UIDAI_REGISTRY LIMIT 1);

-- Seed mock DigiLocker documents
INSERT INTO CORE.MOCK_DIGILOCKER_DOCUMENTS (DOC_ID, AADHAAR_ID, DOC_TYPE, DOC_NUMBER, ISSUER, ISSUE_DATE, VERIFICATION_STATUS, DOC_METADATA)
SELECT * FROM VALUES
    (UUID_STRING(), '123456789012', 'AADHAAR', '123456789012', 'UIDAI', '2015-01-10', 'VERIFIED', PARSE_JSON('{"masked": "XXXX-XXXX-9012"}')),
    (UUID_STRING(), '123456789012', 'PAN', 'ABCDE1234F', 'Income Tax Dept', '2016-03-20', 'VERIFIED', PARSE_JSON('{"name_on_card": "PRIYA SHARMA"}')),
    (UUID_STRING(), '123456789012', 'FORM_16', 'F16-2024-PS', 'TCS Ltd', '2024-06-15', 'VERIFIED', PARSE_JSON('{"fy": "2023-24", "gross_salary": 1200000}')),
    (UUID_STRING(), '234567890123', 'AADHAAR', '234567890123', 'UIDAI', '2014-06-05', 'VERIFIED', PARSE_JSON('{"masked": "XXXX-XXXX-0123"}')),
    (UUID_STRING(), '234567890123', 'PAN', 'FGHIJ5678K', 'Income Tax Dept', '2015-09-12', 'VERIFIED', PARSE_JSON('{"name_on_card": "RAHUL VERMA"}')),
    (UUID_STRING(), '234567890123', 'ITR', 'ITR-2024-RV', 'Income Tax Dept', '2024-07-31', 'VERIFIED', PARSE_JSON('{"ay": "2024-25", "total_income": 1800000}')),
    (UUID_STRING(), '345678901234', 'AADHAAR', '345678901234', 'UIDAI', '2016-02-28', 'VERIFIED', PARSE_JSON('{"masked": "XXXX-XXXX-1234"}')),
    (UUID_STRING(), '345678901234', 'PAN', 'KLMNO9012P', 'Income Tax Dept', '2017-01-15', 'VERIFIED', PARSE_JSON('{"name_on_card": "ANITA PATEL"}')),
    (UUID_STRING(), '345678901234', 'PROPERTY_DEED', 'PD-MH-2023-456', 'Sub-Registrar Mumbai', '2023-04-10', 'VERIFIED', PARSE_JSON('{"property_value": 7500000, "area_sqft": 850}')),
    (UUID_STRING(), '456789012345', 'AADHAAR', '456789012345', 'UIDAI', '2013-11-20', 'VERIFIED', PARSE_JSON('{"masked": "XXXX-XXXX-2345"}')),
    (UUID_STRING(), '456789012345', 'PAN', 'PQRST3456U', 'Income Tax Dept', '2014-05-08', 'VERIFIED', PARSE_JSON('{"name_on_card": "VIJAY KUMAR"}')),
    (UUID_STRING(), '567890123456', 'AADHAAR', '567890123456', 'UIDAI', '2017-09-14', 'VERIFIED', PARSE_JSON('{"masked": "XXXX-XXXX-3456"}')),
    (UUID_STRING(), '567890123456', 'DRIVING_LICENSE', 'TS-1234567890', 'RTO Hyderabad', '2020-02-20', 'VERIFIED', PARSE_JSON('{"valid_until": "2040-02-19", "vehicle_class": "LMV"}'))
WHERE NOT EXISTS (SELECT 1 FROM CORE.MOCK_DIGILOCKER_DOCUMENTS LIMIT 1);

-- ============================================
-- MOCK API PROCEDURES
-- ============================================

-- Simulates UIDAI Aadhaar validation API
CREATE OR REPLACE PROCEDURE CORE.VERIFY_AADHAAR(AADHAAR_ID VARCHAR)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    result OBJECT;
BEGIN
    -- Validate format
    IF (LENGTH(:AADHAAR_ID) != 12 OR TRY_TO_NUMBER(:AADHAAR_ID) IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'success', FALSE,
            'error_code', 'INVALID_FORMAT',
            'error_message', 'Aadhaar must be 12 digits'
        );
    END IF;
    
    -- Look up in mock registry
    SELECT OBJECT_CONSTRUCT(
        'success', TRUE,
        'aadhaar_id', AADHAAR_ID,
        'name', NAME,
        'date_of_birth', DATE_OF_BIRTH,
        'gender', GENDER,
        'is_active', IS_ACTIVE,
        'verification_timestamp', CURRENT_TIMESTAMP()
    ) INTO result
    FROM CORE.MOCK_UIDAI_REGISTRY
    WHERE AADHAAR_ID = :AADHAAR_ID;
    
    IF (result IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'success', FALSE,
            'error_code', 'NOT_FOUND',
            'error_message', 'Aadhaar not found in registry'
        );
    END IF;
    
    IF (result:is_active = FALSE) THEN
        RETURN OBJECT_CONSTRUCT(
            'success', FALSE,
            'error_code', 'INACTIVE',
            'error_message', 'Aadhaar is deactivated'
        );
    END IF;
    
    RETURN result;
END;
$$;

-- Simulates DigiLocker document fetch API
CREATE OR REPLACE PROCEDURE CORE.FETCH_DIGILOCKER_DOCUMENTS(AADHAAR_ID VARCHAR, DOC_TYPE VARCHAR DEFAULT NULL)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    docs ARRAY;
    aadhaar_valid OBJECT;
BEGIN
    -- First verify Aadhaar
    CALL CORE.VERIFY_AADHAAR(:AADHAAR_ID) INTO aadhaar_valid;
    
    IF (aadhaar_valid:success = FALSE) THEN
        RETURN OBJECT_CONSTRUCT(
            'success', FALSE,
            'error_code', 'AADHAAR_INVALID',
            'error_message', aadhaar_valid:error_message
        );
    END IF;
    
    -- Fetch documents
    IF (:DOC_TYPE IS NOT NULL) THEN
        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
            'doc_id', DOC_ID,
            'doc_type', DOC_TYPE,
            'doc_number', DOC_NUMBER,
            'issuer', ISSUER,
            'issue_date', ISSUE_DATE,
            'status', VERIFICATION_STATUS,
            'metadata', DOC_METADATA
        )) INTO docs
        FROM CORE.MOCK_DIGILOCKER_DOCUMENTS
        WHERE AADHAAR_ID = :AADHAAR_ID AND DOC_TYPE = :DOC_TYPE;
    ELSE
        SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
            'doc_id', DOC_ID,
            'doc_type', DOC_TYPE,
            'doc_number', DOC_NUMBER,
            'issuer', ISSUER,
            'issue_date', ISSUE_DATE,
            'status', VERIFICATION_STATUS,
            'metadata', DOC_METADATA
        )) INTO docs
        FROM CORE.MOCK_DIGILOCKER_DOCUMENTS
        WHERE AADHAAR_ID = :AADHAAR_ID;
    END IF;
    
    RETURN OBJECT_CONSTRUCT(
        'success', TRUE,
        'aadhaar_id', :AADHAAR_ID,
        'holder_name', aadhaar_valid:name,
        'document_count', ARRAY_SIZE(COALESCE(docs, ARRAY_CONSTRUCT())),
        'documents', COALESCE(docs, ARRAY_CONSTRUCT())
    );
END;
$$;

-- Combined KYC verification procedure
CREATE OR REPLACE PROCEDURE CORE.PERFORM_KYC_CHECK(AADHAAR_ID VARCHAR)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    aadhaar_result OBJECT;
    digilocker_result OBJECT;
    has_pan BOOLEAN DEFAULT FALSE;
    has_income_proof BOOLEAN DEFAULT FALSE;
BEGIN
    -- Step 1: Verify Aadhaar
    CALL CORE.VERIFY_AADHAAR(:AADHAAR_ID) INTO aadhaar_result;
    
    IF (aadhaar_result:success = FALSE) THEN
        RETURN OBJECT_CONSTRUCT(
            'kyc_status', 'FAILED',
            'stage', 'AADHAAR_VERIFICATION',
            'error', aadhaar_result:error_message
        );
    END IF;
    
    -- Step 2: Fetch DigiLocker documents
    CALL CORE.FETCH_DIGILOCKER_DOCUMENTS(:AADHAAR_ID) INTO digilocker_result;
    
    -- Step 3: Check required documents
    SELECT 
        ARRAY_SIZE(ARRAY_AGG(IFF(d.value:doc_type = 'PAN', 1, NULL))) > 0,
        ARRAY_SIZE(ARRAY_AGG(IFF(d.value:doc_type IN ('FORM_16', 'ITR'), 1, NULL))) > 0
    INTO has_pan, has_income_proof
    FROM TABLE(FLATTEN(digilocker_result:documents)) d;
    
    RETURN OBJECT_CONSTRUCT(
        'kyc_status', IFF(has_pan, 'PASSED', 'INCOMPLETE'),
        'aadhaar_verified', TRUE,
        'holder_name', aadhaar_result:name,
        'date_of_birth', aadhaar_result:date_of_birth,
        'documents_found', digilocker_result:document_count,
        'has_pan', has_pan,
        'has_income_proof', has_income_proof,
        'missing_documents', ARRAY_CONSTRUCT_COMPACT(
            IFF(NOT has_pan, 'PAN', NULL),
            IFF(NOT has_income_proof, 'Income Proof (Form 16 or ITR)', NULL)
        ),
        'verification_timestamp', CURRENT_TIMESTAMP()
    );
END;
$$;

-- ============================================
-- BASE TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS CORE.BORROWERS (
    AADHAAR_ID VARCHAR(12) PRIMARY KEY,
    NAME VARCHAR(255) NOT NULL,
    DATE_OF_BIRTH DATE NOT NULL,
    MONTHLY_INCOME NUMBER(15,2) NOT NULL,
    MONTHLY_LIABILITIES NUMBER(15,2) NOT NULL,
    CREDIT_SCORE INT NOT NULL,
    KYC_VERIFIED BOOLEAN DEFAULT FALSE,
    KYC_VERIFIED_DATE TIMESTAMP_NTZ,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS CORE.LOANS (
    LOAN_ID VARCHAR(36) PRIMARY KEY,
    BORROWER_ID VARCHAR(12) REFERENCES CORE.BORROWERS(AADHAAR_ID),
    AMOUNT NUMBER(15,2) NOT NULL,
    INTEREST_RATE NUMBER(5,4) NOT NULL,
    TENURE_MONTHS INT NOT NULL,
    DISBURSEMENT_DATE DATE NOT NULL,
    POOL_ID VARCHAR(50),
    POOL_ELIGIBLE_DATE DATE,
    STATUS VARCHAR(20) DEFAULT 'ACTIVE',
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS CORE.ELIGIBILITY_CERTIFICATES (
    CERTIFICATE_ID VARCHAR(36) PRIMARY KEY,
    BORROWER_ID VARCHAR(12) REFERENCES CORE.BORROWERS(AADHAAR_ID),
    IS_ELIGIBLE BOOLEAN NOT NULL,
    ISSUED_DATE DATE NOT NULL,
    REJECTION_REASONS ARRAY,
    VALID_UNTIL DATE,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS CORE.RMBS_POOLS (
    POOL_ID VARCHAR(50) PRIMARY KEY,
    NAME VARCHAR(255) NOT NULL,
    AGGREGATION_DATE DATE NOT NULL,
    TRUSTEE VARCHAR(255) NOT NULL,
    TOTAL_VALUE NUMBER(20,2) DEFAULT 0,
    LOAN_COUNT INT DEFAULT 0,
    STATUS VARCHAR(20) DEFAULT 'OPEN',
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================
-- SEED DATA: Sample borrowers and loans for MVP demo
-- ============================================

-- Seed borrowers from mock UIDAI data (with financial details)
INSERT INTO CORE.BORROWERS (AADHAAR_ID, NAME, DATE_OF_BIRTH, MONTHLY_INCOME, MONTHLY_LIABILITIES, CREDIT_SCORE, KYC_VERIFIED, KYC_VERIFIED_DATE)
SELECT * FROM VALUES
    ('123456789012', 'Priya Sharma', '1990-05-15'::DATE, 100000.00, 25000.00, 785, TRUE, CURRENT_TIMESTAMP()),
    ('234567890123', 'Rahul Verma', '1985-08-22'::DATE, 150000.00, 40000.00, 810, TRUE, CURRENT_TIMESTAMP()),
    ('345678901234', 'Anita Patel', '1992-03-10'::DATE, 85000.00, 30000.00, 760, TRUE, CURRENT_TIMESTAMP()),
    ('456789012345', 'Vijay Kumar', '1988-11-28'::DATE, 120000.00, 65000.00, 720, TRUE, CURRENT_TIMESTAMP())
WHERE NOT EXISTS (SELECT 1 FROM CORE.BORROWERS LIMIT 1);

-- Seed sample loans (some eligible for RMBS pooling)
INSERT INTO CORE.LOANS (LOAN_ID, BORROWER_ID, AMOUNT, INTEREST_RATE, TENURE_MONTHS, DISBURSEMENT_DATE, STATUS)
SELECT * FROM VALUES
    ('LOAN-A1B2C3D4', '123456789012', 5000000.00, 0.0750, 240, '2025-03-15'::DATE, 'ACTIVE'),
    ('LOAN-E5F6G7H8', '234567890123', 7500000.00, 0.0725, 300, '2025-02-01'::DATE, 'ACTIVE'),
    ('LOAN-I9J0K1L2', '345678901234', 3500000.00, 0.0775, 180, '2025-04-20'::DATE, 'ACTIVE'),
    ('LOAN-M3N4O5P6', '123456789012', 1500000.00, 0.0800, 120, '2024-06-10'::DATE, 'ACTIVE'),
    ('LOAN-Q7R8S9T0', '234567890123', 4500000.00, 0.0750, 240, '2024-05-01'::DATE, 'ACTIVE')
WHERE NOT EXISTS (SELECT 1 FROM CORE.LOANS LIMIT 1);

-- ============================================
-- PROCEDURE: Register borrower from KYC
-- Auto-populates from UIDAI data after KYC verification
-- ============================================

CREATE OR REPLACE PROCEDURE CORE.REGISTER_BORROWER_FROM_KYC(
    AADHAAR_ID VARCHAR,
    MONTHLY_INCOME NUMBER,
    MONTHLY_LIABILITIES NUMBER,
    CREDIT_SCORE INT
)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    kyc_result OBJECT;
    v_name VARCHAR;
    v_dob DATE;
    existing_count INT;
BEGIN
    -- First perform KYC check
    CALL CORE.PERFORM_KYC_CHECK(:AADHAAR_ID) INTO kyc_result;
    
    IF (kyc_result:kyc_status = 'FAILED') THEN
        RETURN OBJECT_CONSTRUCT(
            'success', FALSE,
            'error', kyc_result:error,
            'stage', 'KYC_VERIFICATION'
        );
    END IF;
    
    -- Extract values from KYC result
    v_name := kyc_result:holder_name::VARCHAR;
    v_dob := kyc_result:date_of_birth::DATE;
    
    -- Check if borrower exists
    SELECT COUNT(*) INTO existing_count 
    FROM CORE.BORROWERS 
    WHERE AADHAAR_ID = :AADHAAR_ID;
    
    IF (existing_count = 0) THEN
        INSERT INTO CORE.BORROWERS 
            (AADHAAR_ID, NAME, DATE_OF_BIRTH, MONTHLY_INCOME, MONTHLY_LIABILITIES, CREDIT_SCORE, KYC_VERIFIED, KYC_VERIFIED_DATE)
        VALUES (
            :AADHAAR_ID, 
            :v_name, 
            :v_dob, 
            :MONTHLY_INCOME, 
            :MONTHLY_LIABILITIES, 
            :CREDIT_SCORE, 
            TRUE, 
            CURRENT_TIMESTAMP()
        );
    ELSE
        UPDATE CORE.BORROWERS SET
            NAME = :v_name,
            DATE_OF_BIRTH = :v_dob,
            MONTHLY_INCOME = :MONTHLY_INCOME,
            MONTHLY_LIABILITIES = :MONTHLY_LIABILITIES,
            CREDIT_SCORE = :CREDIT_SCORE,
            KYC_VERIFIED = TRUE,
            KYC_VERIFIED_DATE = CURRENT_TIMESTAMP(),
            UPDATED_AT = CURRENT_TIMESTAMP()
        WHERE AADHAAR_ID = :AADHAAR_ID;
    END IF;
    
    RETURN OBJECT_CONSTRUCT(
        'success', TRUE,
        'aadhaar_id', :AADHAAR_ID,
        'name', :v_name,
        'kyc_status', kyc_result:kyc_status,
        'has_pan', kyc_result:has_pan,
        'has_income_proof', kyc_result:has_income_proof,
        'registered_at', CURRENT_TIMESTAMP()
    );
END;
$$;

-- ============================================
-- PROCEDURE: Get borrower dashboard summary
-- ============================================

CREATE OR REPLACE PROCEDURE CORE.GET_BORROWER_SUMMARY(AADHAAR_ID VARCHAR)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    borrower_info OBJECT;
    loan_summary OBJECT;
    eligibility OBJECT;
BEGIN
    -- Get borrower info
    SELECT OBJECT_CONSTRUCT(
        'name', NAME,
        'credit_score', CREDIT_SCORE,
        'kyc_verified', KYC_VERIFIED,
        'monthly_income', MONTHLY_INCOME,
        'dti_ratio', ROUND(MONTHLY_LIABILITIES / NULLIF(MONTHLY_INCOME, 0) * 100, 1)
    ) INTO borrower_info
    FROM CORE.BORROWERS
    WHERE AADHAAR_ID = :AADHAAR_ID;
    
    IF (borrower_info IS NULL) THEN
        RETURN OBJECT_CONSTRUCT('error', 'Borrower not found');
    END IF;
    
    -- Get loan summary
    SELECT OBJECT_CONSTRUCT(
        'total_loans', COUNT(*),
        'total_amount', SUM(AMOUNT),
        'active_loans', SUM(IFF(STATUS = 'ACTIVE', 1, 0)),
        'pooled_loans', SUM(IFF(POOL_ID IS NOT NULL, 1, 0)),
        'avg_interest_rate', ROUND(AVG(INTEREST_RATE) * 100, 2)
    ) INTO loan_summary
    FROM CORE.LOANS
    WHERE BORROWER_ID = :AADHAAR_ID;
    
    -- Get eligibility status
    SELECT OBJECT_CONSTRUCT(
        'is_eligible', IS_ELIGIBLE,
        'rejection_reasons', REJECTION_REASONS
    ) INTO eligibility
    FROM CORE.BORROWER_ELIGIBILITY_STATUS
    WHERE AADHAAR_ID = :AADHAAR_ID;
    
    RETURN OBJECT_CONSTRUCT(
        'borrower', borrower_info,
        'loans', loan_summary,
        'eligibility', eligibility
    );
END;
$$;

-- ============================================
-- DYNAMIC TABLE: RMBS Pool Aggregation
-- Automatically aggregates loans meeting MHP criteria
-- ============================================

CREATE OR REPLACE DYNAMIC TABLE CORE.RMBS_ELIGIBLE_LOANS
    TARGET_LAG = '1 hour'
    WAREHOUSE = COMPUTE_WH
AS
SELECT
    L.LOAN_ID,
    L.BORROWER_ID,
    L.AMOUNT,
    L.INTEREST_RATE,
    L.DISBURSEMENT_DATE,
    DATEADD(MONTH, 6, L.DISBURSEMENT_DATE) AS POOL_ELIGIBLE_DATE,
    CONCAT('RMBS-', YEAR(DATEADD(MONTH, 6, L.DISBURSEMENT_DATE)), '-Q',
           CEIL(MONTH(DATEADD(MONTH, 6, L.DISBURSEMENT_DATE)) / 3)) AS ASSIGNED_POOL_ID,
    B.CREDIT_SCORE,
    B.NAME AS BORROWER_NAME
FROM CORE.LOANS L
JOIN CORE.BORROWERS B ON L.BORROWER_ID = B.AADHAAR_ID
WHERE 
    L.STATUS = 'ACTIVE'
    AND B.CREDIT_SCORE >= 750
    AND DATEADD(MONTH, 6, L.DISBURSEMENT_DATE) <= CURRENT_DATE()
    AND L.POOL_ID IS NULL;

-- ============================================
-- DYNAMIC TABLE: Borrower Eligibility Status
-- Real-time eligibility calculation
-- ============================================

CREATE OR REPLACE DYNAMIC TABLE CORE.BORROWER_ELIGIBILITY_STATUS
    TARGET_LAG = '1 hour'
    WAREHOUSE = COMPUTE_WH
AS
SELECT
    AADHAAR_ID,
    NAME,
    CREDIT_SCORE,
    DATEDIFF(YEAR, DATE_OF_BIRTH, CURRENT_DATE()) AS AGE,
    MONTHLY_LIABILITIES / NULLIF(MONTHLY_INCOME, 0) AS DTI_RATIO,
    CASE
        WHEN CREDIT_SCORE >= 750
             AND DATEDIFF(YEAR, DATE_OF_BIRTH, CURRENT_DATE()) BETWEEN 25 AND 50
             AND (MONTHLY_LIABILITIES / NULLIF(MONTHLY_INCOME, 0)) <= 0.50
        THEN TRUE
        ELSE FALSE
    END AS IS_ELIGIBLE,
    ARRAY_CONSTRUCT_COMPACT(
        IFF(CREDIT_SCORE < 750, CONCAT('Credit score ', CREDIT_SCORE, ' below 750'), NULL),
        IFF(DATEDIFF(YEAR, DATE_OF_BIRTH, CURRENT_DATE()) < 25, 'Age below 25 years', NULL),
        IFF(DATEDIFF(YEAR, DATE_OF_BIRTH, CURRENT_DATE()) > 50, 'Age above 50 years', NULL),
        IFF((MONTHLY_LIABILITIES / NULLIF(MONTHLY_INCOME, 0)) > 0.50, CONCAT('DTI ratio ', ROUND((MONTHLY_LIABILITIES / NULLIF(MONTHLY_INCOME, 0)) * 100, 1), '% exceeds 50%'), NULL)
    ) AS REJECTION_REASONS
FROM CORE.BORROWERS;

-- ============================================
-- STREAM: Track loan changes for pool assignment
-- ============================================

CREATE OR REPLACE STREAM CORE.LOANS_STREAM ON TABLE CORE.LOANS
    APPEND_ONLY = FALSE
    SHOW_INITIAL_ROWS = FALSE;

-- ============================================
-- STORED PROCEDURES
-- ============================================

CREATE OR REPLACE PROCEDURE CORE.ASSIGN_LOANS_TO_POOLS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    assigned_count INT DEFAULT 0;
BEGIN
    -- Update loans that are now eligible for RMBS pools
    UPDATE CORE.LOANS L
    SET 
        POOL_ID = E.ASSIGNED_POOL_ID,
        POOL_ELIGIBLE_DATE = E.POOL_ELIGIBLE_DATE,
        UPDATED_AT = CURRENT_TIMESTAMP()
    FROM CORE.RMBS_ELIGIBLE_LOANS E
    WHERE L.LOAN_ID = E.LOAN_ID
      AND L.POOL_ID IS NULL;
    
    assigned_count := SQLROWCOUNT;
    
    -- Ensure pools exist
    INSERT INTO CORE.RMBS_POOLS (POOL_ID, NAME, AGGREGATION_DATE, TRUSTEE)
    SELECT DISTINCT 
        ASSIGNED_POOL_ID,
        CONCAT('Housing Pool ', YEAR(POOL_ELIGIBLE_DATE), ' Q', CEIL(MONTH(POOL_ELIGIBLE_DATE) / 3)),
        POOL_ELIGIBLE_DATE,
        'India Housing Trust'
    FROM CORE.RMBS_ELIGIBLE_LOANS
    WHERE ASSIGNED_POOL_ID NOT IN (SELECT POOL_ID FROM CORE.RMBS_POOLS);
    
    -- Update pool statistics
    MERGE INTO CORE.RMBS_POOLS P
    USING (
        SELECT POOL_ID, COUNT(*) AS LOAN_COUNT, SUM(AMOUNT) AS TOTAL_VALUE
        FROM CORE.LOANS
        WHERE POOL_ID IS NOT NULL
        GROUP BY POOL_ID
    ) S
    ON P.POOL_ID = S.POOL_ID
    WHEN MATCHED THEN UPDATE SET
        P.LOAN_COUNT = S.LOAN_COUNT,
        P.TOTAL_VALUE = S.TOTAL_VALUE;
    
    RETURN 'Assigned ' || assigned_count || ' loans to RMBS pools';
END;
$$;

CREATE OR REPLACE PROCEDURE CORE.ISSUE_ELIGIBILITY_CERTIFICATE(BORROWER_AADHAAR VARCHAR)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_is_eligible BOOLEAN;
    v_rejection_reasons VARIANT;
    v_cert_id VARCHAR;
BEGIN
    -- Get eligibility data
    SELECT IS_ELIGIBLE, REJECTION_REASONS 
    INTO v_is_eligible, v_rejection_reasons
    FROM CORE.BORROWER_ELIGIBILITY_STATUS
    WHERE AADHAAR_ID = :BORROWER_AADHAAR;
    
    IF (v_is_eligible IS NULL) THEN
        RETURN OBJECT_CONSTRUCT('error', 'Borrower not found in eligibility table');
    END IF;
    
    v_cert_id := UUID_STRING();
    
    INSERT INTO CORE.ELIGIBILITY_CERTIFICATES 
        (CERTIFICATE_ID, BORROWER_ID, IS_ELIGIBLE, ISSUED_DATE, REJECTION_REASONS, VALID_UNTIL)
    SELECT 
        :v_cert_id,
        :BORROWER_AADHAAR,
        :v_is_eligible,
        CURRENT_DATE(),
        :v_rejection_reasons,
        DATEADD(DAY, 90, CURRENT_DATE());
    
    RETURN OBJECT_CONSTRUCT(
        'certificate_id', :v_cert_id,
        'borrower_id', :BORROWER_AADHAAR,
        'is_eligible', :v_is_eligible,
        'valid_until', DATEADD(DAY, 90, CURRENT_DATE()),
        'rejection_reasons', :v_rejection_reasons
    );
END;
$$;

-- ============================================
-- TASK: Automated pool assignment (daily)
-- ============================================

CREATE OR REPLACE TASK CORE.DAILY_POOL_ASSIGNMENT
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 0 2 * * * UTC'
AS
    CALL CORE.ASSIGN_LOANS_TO_POOLS();

-- Enable the task
ALTER TASK CORE.DAILY_POOL_ASSIGNMENT RESUME;

-- ============================================
-- GRANTS for application roles
-- ============================================

CREATE APPLICATION ROLE IF NOT EXISTS APP_USER;
CREATE APPLICATION ROLE IF NOT EXISTS APP_ADMIN;

GRANT USAGE ON SCHEMA CORE TO APPLICATION ROLE APP_USER;
GRANT SELECT ON ALL TABLES IN SCHEMA CORE TO APPLICATION ROLE APP_USER;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA CORE TO APPLICATION ROLE APP_USER;

GRANT USAGE ON SCHEMA CORE TO APPLICATION ROLE APP_ADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA CORE TO APPLICATION ROLE APP_ADMIN;
GRANT ALL PRIVILEGES ON ALL DYNAMIC TABLES IN SCHEMA CORE TO APPLICATION ROLE APP_ADMIN;
GRANT USAGE ON PROCEDURE CORE.ASSIGN_LOANS_TO_POOLS() TO APPLICATION ROLE APP_ADMIN;
GRANT USAGE ON PROCEDURE CORE.ISSUE_ELIGIBILITY_CERTIFICATE(VARCHAR) TO APPLICATION ROLE APP_ADMIN;
GRANT USAGE ON PROCEDURE CORE.VERIFY_AADHAAR(VARCHAR) TO APPLICATION ROLE APP_USER;
GRANT USAGE ON PROCEDURE CORE.FETCH_DIGILOCKER_DOCUMENTS(VARCHAR, VARCHAR) TO APPLICATION ROLE APP_USER;
GRANT USAGE ON PROCEDURE CORE.PERFORM_KYC_CHECK(VARCHAR) TO APPLICATION ROLE APP_USER;
GRANT USAGE ON PROCEDURE CORE.REGISTER_BORROWER_FROM_KYC(VARCHAR, NUMBER, NUMBER, INT) TO APPLICATION ROLE APP_USER;
GRANT USAGE ON PROCEDURE CORE.GET_BORROWER_SUMMARY(VARCHAR) TO APPLICATION ROLE APP_USER;

-- ============================================
-- PHASE 2: ADDITIONAL TABLES
-- ============================================

-- Audit Trail
CREATE TABLE IF NOT EXISTS CORE.AUDIT_LOG (
    LOG_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    USER_ROLE VARCHAR(50),
    USER_ID VARCHAR(50),
    ACTION_TYPE VARCHAR(50) NOT NULL,
    ENTITY_TYPE VARCHAR(50),
    ENTITY_ID VARCHAR(50),
    ACTION_DETAILS VARIANT,
    IP_ADDRESS VARCHAR(50),
    STATUS VARCHAR(20) DEFAULT 'SUCCESS',
    ERROR_MESSAGE VARCHAR(500)
);

-- User Roles
CREATE TABLE IF NOT EXISTS CORE.USER_ROLES (
    USER_ID VARCHAR(50) PRIMARY KEY,
    USER_TYPE VARCHAR(20) NOT NULL,
    EMAIL VARCHAR(255),
    PHONE VARCHAR(15),
    ORGANIZATION VARCHAR(100),
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    PERMISSIONS VARIANT,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    LAST_LOGIN TIMESTAMP_NTZ
);

-- Permissions
CREATE TABLE IF NOT EXISTS CORE.PERMISSIONS (
    PERMISSION_ID VARCHAR(50) PRIMARY KEY,
    PERMISSION_NAME VARCHAR(100),
    DESCRIPTION VARCHAR(255),
    APPLICABLE_ROLES ARRAY
);

-- Document Uploads
CREATE TABLE IF NOT EXISTS CORE.UPLOADED_DOCUMENTS (
    DOC_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    AADHAAR_ID VARCHAR(12) NOT NULL,
    DOC_TYPE VARCHAR(50) NOT NULL,
    DOC_NAME VARCHAR(255),
    FILE_PATH VARCHAR(500),
    FILE_SIZE_KB NUMBER,
    MIME_TYPE VARCHAR(100),
    UPLOAD_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    VERIFICATION_STATUS VARCHAR(20) DEFAULT 'PENDING',
    VERIFIED_BY VARCHAR(50),
    VERIFIED_DATE TIMESTAMP_NTZ,
    REJECTION_REASON VARCHAR(500),
    METADATA VARIANT
);

-- Loan Status History
CREATE TABLE IF NOT EXISTS CORE.LOAN_STATUS_HISTORY (
    HISTORY_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    LOAN_ID VARCHAR(36) NOT NULL,
    OLD_STATUS VARCHAR(20),
    NEW_STATUS VARCHAR(20) NOT NULL,
    CHANGED_BY VARCHAR(50),
    CHANGED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    COMMENTS VARCHAR(500)
);

-- Loan Prepayments
CREATE TABLE IF NOT EXISTS CORE.LOAN_PREPAYMENTS (
    PREPAYMENT_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    LOAN_ID VARCHAR(36) NOT NULL,
    PREPAYMENT_DATE DATE NOT NULL,
    AMOUNT NUMBER(15,2) NOT NULL,
    PREPAYMENT_TYPE VARCHAR(20),
    OUTSTANDING_BEFORE NUMBER(15,2),
    OUTSTANDING_AFTER NUMBER(15,2),
    INTEREST_SAVED NUMBER(15,2),
    PROCESSED_BY VARCHAR(50),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Investor Portfolio
CREATE TABLE IF NOT EXISTS CORE.INVESTOR_PORTFOLIO (
    INVESTMENT_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    INVESTOR_ID VARCHAR(50) NOT NULL,
    POOL_ID VARCHAR(36) NOT NULL,
    UNITS_HELD NUMBER(10,4),
    INVESTMENT_AMOUNT NUMBER(15,2),
    INVESTMENT_DATE DATE,
    CURRENT_VALUE NUMBER(15,2),
    RETURNS_EARNED NUMBER(15,2) DEFAULT 0,
    STATUS VARCHAR(20) DEFAULT 'ACTIVE',
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Document Upload Stage
CREATE STAGE IF NOT EXISTS CORE.DOCUMENT_UPLOADS
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for borrower document uploads';

-- ============================================
-- PHASE 2: ADDITIONAL PROCEDURES
-- ============================================

-- Log Audit Event
CREATE OR REPLACE PROCEDURE CORE.LOG_AUDIT_EVENT(
    P_USER_ROLE VARCHAR, P_USER_ID VARCHAR, P_ACTION_TYPE VARCHAR,
    P_ENTITY_TYPE VARCHAR, P_ENTITY_ID VARCHAR, P_ACTION_DETAILS VARIANT,
    P_STATUS VARCHAR, P_ERROR_MESSAGE VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO CORE.AUDIT_LOG (USER_ROLE, USER_ID, ACTION_TYPE, ENTITY_TYPE, ENTITY_ID, ACTION_DETAILS, STATUS, ERROR_MESSAGE)
    VALUES (:P_USER_ROLE, :P_USER_ID, :P_ACTION_TYPE, :P_ENTITY_TYPE, :P_ENTITY_ID, :P_ACTION_DETAILS, :P_STATUS, :P_ERROR_MESSAGE);
    RETURN 'LOGGED';
END;
$$;

-- Register Document Upload
CREATE OR REPLACE PROCEDURE CORE.REGISTER_DOCUMENT_UPLOAD(
    P_AADHAAR_ID VARCHAR, P_DOC_TYPE VARCHAR, P_DOC_NAME VARCHAR,
    P_FILE_PATH VARCHAR, P_FILE_SIZE_KB NUMBER, P_MIME_TYPE VARCHAR
)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_doc_id VARCHAR;
BEGIN
    v_doc_id := UUID_STRING();
    INSERT INTO CORE.UPLOADED_DOCUMENTS (DOC_ID, AADHAAR_ID, DOC_TYPE, DOC_NAME, FILE_PATH, FILE_SIZE_KB, MIME_TYPE)
    VALUES (:v_doc_id, :P_AADHAAR_ID, :P_DOC_TYPE, :P_DOC_NAME, :P_FILE_PATH, :P_FILE_SIZE_KB, :P_MIME_TYPE);
    CALL CORE.LOG_AUDIT_EVENT('BORROWER', :P_AADHAAR_ID, 'DOCUMENT_UPLOAD', 'DOCUMENT', :v_doc_id,
        OBJECT_CONSTRUCT('doc_type', :P_DOC_TYPE, 'doc_name', :P_DOC_NAME), 'SUCCESS', NULL);
    RETURN OBJECT_CONSTRUCT('success', TRUE, 'doc_id', :v_doc_id, 'message', 'Document uploaded successfully');
END;
$$;

-- Verify Document
CREATE OR REPLACE PROCEDURE CORE.VERIFY_DOCUMENT(
    P_DOC_ID VARCHAR, P_VERIFIER_ID VARCHAR, P_STATUS VARCHAR, P_REJECTION_REASON VARCHAR
)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_aadhaar_id VARCHAR;
BEGIN
    SELECT AADHAAR_ID INTO v_aadhaar_id FROM CORE.UPLOADED_DOCUMENTS WHERE DOC_ID = :P_DOC_ID;
    IF (v_aadhaar_id IS NULL) THEN
        RETURN OBJECT_CONSTRUCT('success', FALSE, 'error', 'Document not found');
    END IF;
    UPDATE CORE.UPLOADED_DOCUMENTS SET VERIFICATION_STATUS = :P_STATUS, VERIFIED_BY = :P_VERIFIER_ID,
        VERIFIED_DATE = CURRENT_TIMESTAMP(), REJECTION_REASON = CASE WHEN :P_STATUS = 'REJECTED' THEN :P_REJECTION_REASON ELSE NULL END
    WHERE DOC_ID = :P_DOC_ID;
    CALL CORE.LOG_AUDIT_EVENT('ORIGINATOR', :P_VERIFIER_ID, 'DOCUMENT_VERIFY', 'DOCUMENT', :P_DOC_ID,
        OBJECT_CONSTRUCT('status', :P_STATUS, 'rejection_reason', :P_REJECTION_REASON), 'SUCCESS', NULL);
    RETURN OBJECT_CONSTRUCT('success', TRUE, 'doc_id', :P_DOC_ID, 'status', :P_STATUS);
END;
$$;

-- Update Loan Status
CREATE OR REPLACE PROCEDURE CORE.UPDATE_LOAN_STATUS(
    P_LOAN_ID VARCHAR, P_NEW_STATUS VARCHAR, P_CHANGED_BY VARCHAR, P_COMMENTS VARCHAR
)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_old_status VARCHAR;
    v_borrower_id VARCHAR;
BEGIN
    SELECT STATUS, BORROWER_ID INTO v_old_status, v_borrower_id FROM CORE.LOANS WHERE LOAN_ID = :P_LOAN_ID;
    IF (v_old_status IS NULL) THEN
        RETURN OBJECT_CONSTRUCT('success', FALSE, 'error', 'Loan not found');
    END IF;
    UPDATE CORE.LOANS SET STATUS = :P_NEW_STATUS, UPDATED_AT = CURRENT_TIMESTAMP() WHERE LOAN_ID = :P_LOAN_ID;
    INSERT INTO CORE.LOAN_STATUS_HISTORY (LOAN_ID, OLD_STATUS, NEW_STATUS, CHANGED_BY, COMMENTS)
    VALUES (:P_LOAN_ID, v_old_status, :P_NEW_STATUS, :P_CHANGED_BY, :P_COMMENTS);
    CALL CORE.LOG_AUDIT_EVENT('ORIGINATOR', :P_CHANGED_BY, 'LOAN_STATUS_CHANGE', 'LOAN', :P_LOAN_ID,
        OBJECT_CONSTRUCT('old_status', v_old_status, 'new_status', :P_NEW_STATUS), 'SUCCESS', NULL);
    RETURN OBJECT_CONSTRUCT('success', TRUE, 'loan_id', :P_LOAN_ID, 'old_status', v_old_status, 'new_status', :P_NEW_STATUS);
END;
$$;

-- Get Originator Dashboard
CREATE OR REPLACE PROCEDURE CORE.GET_ORIGINATOR_DASHBOARD()
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_total_loans NUMBER; v_pending NUMBER; v_approved NUMBER; v_active NUMBER;
    v_total_value NUMBER; v_avg_rate NUMBER; v_total_borrowers NUMBER;
    v_kyc_verified NUMBER; v_avg_score NUMBER; v_docs_pending NUMBER; v_loans_pooling NUMBER;
BEGIN
    SELECT COUNT(*), COUNT_IF(STATUS = 'PENDING'), COUNT_IF(STATUS = 'APPROVED'),
        COUNT_IF(STATUS = 'ACTIVE'), SUM(AMOUNT), ROUND(AVG(INTEREST_RATE) * 100, 2)
    INTO v_total_loans, v_pending, v_approved, v_active, v_total_value, v_avg_rate FROM CORE.LOANS;
    SELECT COUNT(*), COUNT_IF(KYC_VERIFIED), ROUND(AVG(CREDIT_SCORE), 0)
    INTO v_total_borrowers, v_kyc_verified, v_avg_score FROM CORE.BORROWERS;
    SELECT COUNT(*) INTO v_docs_pending FROM CORE.UPLOADED_DOCUMENTS WHERE VERIFICATION_STATUS = 'PENDING';
    SELECT COUNT(*) INTO v_loans_pooling FROM CORE.RMBS_ELIGIBLE_LOANS;
    RETURN OBJECT_CONSTRUCT(
        'loan_stats', OBJECT_CONSTRUCT('total_loans', v_total_loans, 'pending_approval', v_pending,
            'approved', v_approved, 'active', v_active, 'total_value', v_total_value, 'avg_interest_rate', v_avg_rate),
        'borrower_stats', OBJECT_CONSTRUCT('total_borrowers', v_total_borrowers, 'kyc_verified', v_kyc_verified, 'avg_credit_score', v_avg_score),
        'pending_actions', OBJECT_CONSTRUCT('loans_pending_approval', v_pending, 'documents_pending_verification', v_docs_pending, 'loans_ready_for_pooling', v_loans_pooling),
        'generated_at', CURRENT_TIMESTAMP()
    );
END;
$$;

-- Get Investor Dashboard
CREATE OR REPLACE PROCEDURE CORE.GET_INVESTOR_DASHBOARD(P_INVESTOR_ID VARCHAR)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_portfolio ARRAY; v_total_invested NUMBER DEFAULT 0; v_total_current NUMBER DEFAULT 0; v_total_returns NUMBER DEFAULT 0;
BEGIN
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('pool_id', ip.POOL_ID, 'pool_name', rp.NAME, 'units', ip.UNITS_HELD,
        'invested', ip.INVESTMENT_AMOUNT, 'current_value', ip.CURRENT_VALUE, 'returns', ip.RETURNS_EARNED, 'status', ip.STATUS)),
        SUM(ip.INVESTMENT_AMOUNT), SUM(ip.CURRENT_VALUE), SUM(ip.RETURNS_EARNED)
    INTO v_portfolio, v_total_invested, v_total_current, v_total_returns
    FROM CORE.INVESTOR_PORTFOLIO ip JOIN CORE.RMBS_POOLS rp ON ip.POOL_ID = rp.POOL_ID
    WHERE ip.INVESTOR_ID = :P_INVESTOR_ID AND ip.STATUS = 'ACTIVE';
    RETURN OBJECT_CONSTRUCT('investor_id', :P_INVESTOR_ID, 'total_invested', COALESCE(v_total_invested, 0),
        'current_value', COALESCE(v_total_current, 0), 'total_returns', COALESCE(v_total_returns, 0),
        'return_percentage', CASE WHEN v_total_invested > 0 THEN ROUND((v_total_current - v_total_invested) / v_total_invested * 100, 2) ELSE 0 END,
        'portfolio', COALESCE(v_portfolio, ARRAY_CONSTRUCT()));
END;
$$;

-- Invest in Pool
CREATE OR REPLACE PROCEDURE CORE.INVEST_IN_POOL(P_INVESTOR_ID VARCHAR, P_POOL_ID VARCHAR, P_INVESTMENT_AMOUNT NUMBER)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_pool_value NUMBER; v_pool_status VARCHAR; v_units NUMBER; v_investment_id VARCHAR;
BEGIN
    SELECT TOTAL_VALUE, STATUS INTO v_pool_value, v_pool_status FROM CORE.RMBS_POOLS WHERE POOL_ID = :P_POOL_ID;
    IF (v_pool_value IS NULL) THEN RETURN OBJECT_CONSTRUCT('success', FALSE, 'error', 'Pool not found'); END IF;
    IF (v_pool_status != 'OPEN') THEN RETURN OBJECT_CONSTRUCT('success', FALSE, 'error', 'Pool is not open'); END IF;
    v_units := :P_INVESTMENT_AMOUNT / 10000;
    v_investment_id := UUID_STRING();
    INSERT INTO CORE.INVESTOR_PORTFOLIO (INVESTMENT_ID, INVESTOR_ID, POOL_ID, UNITS_HELD, INVESTMENT_AMOUNT, INVESTMENT_DATE, CURRENT_VALUE, STATUS)
    VALUES (v_investment_id, :P_INVESTOR_ID, :P_POOL_ID, v_units, :P_INVESTMENT_AMOUNT, CURRENT_DATE(), :P_INVESTMENT_AMOUNT, 'ACTIVE');
    CALL CORE.LOG_AUDIT_EVENT('INVESTOR', :P_INVESTOR_ID, 'POOL_INVESTMENT', 'POOL', :P_POOL_ID,
        OBJECT_CONSTRUCT('amount', :P_INVESTMENT_AMOUNT, 'units', v_units), 'SUCCESS', NULL);
    RETURN OBJECT_CONSTRUCT('success', TRUE, 'investment_id', v_investment_id, 'pool_id', :P_POOL_ID, 'units', v_units, 'amount', :P_INVESTMENT_AMOUNT);
END;
$$;

-- ============================================
-- PHASE 3: EMI TRACKING & NOTIFICATIONS
-- ============================================

-- EMI Payment Tracking Table
CREATE TABLE IF NOT EXISTS CORE.EMI_PAYMENTS (
    PAYMENT_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    LOAN_ID VARCHAR(36) NOT NULL,
    EMI_NUMBER INT NOT NULL,
    DUE_DATE DATE NOT NULL,
    PRINCIPAL_COMPONENT NUMBER(15,2),
    INTEREST_COMPONENT NUMBER(15,2),
    TOTAL_EMI NUMBER(15,2),
    PAID_AMOUNT NUMBER(15,2),
    PAID_DATE DATE,
    PAYMENT_STATUS VARCHAR(20) DEFAULT 'PENDING',
    PAYMENT_MODE VARCHAR(20),
    TRANSACTION_REF VARCHAR(50),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS CORE.NOTIFICATIONS (
    NOTIFICATION_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    USER_ID VARCHAR(50) NOT NULL,
    USER_TYPE VARCHAR(20),
    NOTIFICATION_TYPE VARCHAR(50),
    TITLE VARCHAR(200),
    MESSAGE VARCHAR(1000),
    RELATED_ENTITY_TYPE VARCHAR(50),
    RELATED_ENTITY_ID VARCHAR(50),
    IS_READ BOOLEAN DEFAULT FALSE,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    READ_AT TIMESTAMP_NTZ
);

-- Loan Amortization Schedule Table
CREATE TABLE IF NOT EXISTS CORE.LOAN_AMORTIZATION (
    SCHEDULE_ID VARCHAR(36) DEFAULT UUID_STRING() PRIMARY KEY,
    LOAN_ID VARCHAR(36) NOT NULL,
    EMI_NUMBER INT NOT NULL,
    DUE_DATE DATE NOT NULL,
    OPENING_BALANCE NUMBER(15,2),
    EMI_AMOUNT NUMBER(15,2),
    PRINCIPAL_COMPONENT NUMBER(15,2),
    INTEREST_COMPONENT NUMBER(15,2),
    CLOSING_BALANCE NUMBER(15,2),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Generate Amortization Schedule
CREATE OR REPLACE PROCEDURE CORE.GENERATE_AMORTIZATION_SCHEDULE(P_LOAN_ID VARCHAR)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_emi NUMBER;
    v_tenure INT;
BEGIN
    DELETE FROM CORE.LOAN_AMORTIZATION WHERE LOAN_ID = :P_LOAN_ID;
    
    INSERT INTO CORE.LOAN_AMORTIZATION 
        (LOAN_ID, EMI_NUMBER, DUE_DATE, OPENING_BALANCE, EMI_AMOUNT, PRINCIPAL_COMPONENT, INTEREST_COMPONENT, CLOSING_BALANCE)
    WITH loan_data AS (
        SELECT 
            AMOUNT as principal,
            INTEREST_RATE / 12 as monthly_rate,
            TENURE_MONTHS as tenure,
            DISBURSEMENT_DATE as start_date,
            AMOUNT * (INTEREST_RATE / 12) * POWER(1 + INTEREST_RATE / 12, TENURE_MONTHS) / 
                (POWER(1 + INTEREST_RATE / 12, TENURE_MONTHS) - 1) as emi
        FROM CORE.LOANS WHERE LOAN_ID = :P_LOAN_ID
    ),
    numbers AS (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n FROM TABLE(GENERATOR(ROWCOUNT => 24)))
    SELECT :P_LOAN_ID, n.n AS emi_number, DATEADD(MONTH, n.n, ld.start_date) AS due_date,
        ROUND(ld.principal * POWER(1 + ld.monthly_rate, n.n - 1) - ld.emi * (POWER(1 + ld.monthly_rate, n.n - 1) - 1) / ld.monthly_rate, 2),
        ROUND(ld.emi, 2),
        ROUND(ld.emi - (ld.principal * POWER(1 + ld.monthly_rate, n.n - 1) - ld.emi * (POWER(1 + ld.monthly_rate, n.n - 1) - 1) / ld.monthly_rate) * ld.monthly_rate, 2),
        ROUND((ld.principal * POWER(1 + ld.monthly_rate, n.n - 1) - ld.emi * (POWER(1 + ld.monthly_rate, n.n - 1) - 1) / ld.monthly_rate) * ld.monthly_rate, 2),
        ROUND(ld.principal * POWER(1 + ld.monthly_rate, n.n) - ld.emi * (POWER(1 + ld.monthly_rate, n.n) - 1) / ld.monthly_rate, 2)
    FROM loan_data ld CROSS JOIN numbers n WHERE n.n <= LEAST(ld.tenure, 24);
    
    SELECT emi, tenure INTO v_emi, v_tenure FROM (
        SELECT AMOUNT * (INTEREST_RATE / 12) * POWER(1 + INTEREST_RATE / 12, TENURE_MONTHS) / 
            (POWER(1 + INTEREST_RATE / 12, TENURE_MONTHS) - 1) as emi, TENURE_MONTHS as tenure
        FROM CORE.LOANS WHERE LOAN_ID = :P_LOAN_ID);
    
    RETURN OBJECT_CONSTRUCT('success', TRUE, 'loan_id', :P_LOAN_ID, 'monthly_emi', ROUND(v_emi, 2), 
        'total_tenure', v_tenure, 'emis_generated', LEAST(v_tenure, 24));
END;
$$;

-- Record EMI Payment
CREATE OR REPLACE PROCEDURE CORE.RECORD_EMI_PAYMENT(
    P_LOAN_ID VARCHAR, P_EMI_NUMBER INT, P_PAID_AMOUNT NUMBER, P_PAYMENT_MODE VARCHAR, P_TRANSACTION_REF VARCHAR
)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_payment_id VARCHAR; v_schedule_exists INT; v_due_date DATE;
    v_emi_amount NUMBER; v_principal NUMBER; v_interest NUMBER; v_status VARCHAR; v_borrower_id VARCHAR;
BEGIN
    SELECT COUNT(*) INTO v_schedule_exists FROM CORE.LOAN_AMORTIZATION WHERE LOAN_ID = :P_LOAN_ID AND EMI_NUMBER = :P_EMI_NUMBER;
    IF (v_schedule_exists = 0) THEN RETURN OBJECT_CONSTRUCT('success', FALSE, 'error', 'EMI schedule not found'); END IF;
    
    SELECT DUE_DATE, EMI_AMOUNT, PRINCIPAL_COMPONENT, INTEREST_COMPONENT
    INTO v_due_date, v_emi_amount, v_principal, v_interest FROM CORE.LOAN_AMORTIZATION WHERE LOAN_ID = :P_LOAN_ID AND EMI_NUMBER = :P_EMI_NUMBER;
    
    IF (:P_PAID_AMOUNT >= v_emi_amount) THEN v_status := 'PAID';
    ELSEIF (:P_PAID_AMOUNT > 0) THEN v_status := 'PARTIAL'; ELSE v_status := 'PENDING'; END IF;
    
    v_payment_id := UUID_STRING();
    INSERT INTO CORE.EMI_PAYMENTS (PAYMENT_ID, LOAN_ID, EMI_NUMBER, DUE_DATE, PRINCIPAL_COMPONENT, INTEREST_COMPONENT, 
        TOTAL_EMI, PAID_AMOUNT, PAID_DATE, PAYMENT_STATUS, PAYMENT_MODE, TRANSACTION_REF)
    VALUES (:v_payment_id, :P_LOAN_ID, :P_EMI_NUMBER, :v_due_date, :v_principal, :v_interest,
        :v_emi_amount, :P_PAID_AMOUNT, CURRENT_DATE(), :v_status, :P_PAYMENT_MODE, :P_TRANSACTION_REF);
    
    SELECT BORROWER_ID INTO v_borrower_id FROM CORE.LOANS WHERE LOAN_ID = :P_LOAN_ID;
    CALL CORE.SEND_NOTIFICATION(:v_borrower_id, 'BORROWER', 'EMI_PAID', 'EMI Payment Recorded',
        'Your EMI #' || :P_EMI_NUMBER || ' payment of Rs.' || :P_PAID_AMOUNT || ' has been recorded.', 'LOAN', :P_LOAN_ID);
    
    RETURN OBJECT_CONSTRUCT('success', TRUE, 'payment_id', v_payment_id, 'loan_id', :P_LOAN_ID, 
        'emi_number', :P_EMI_NUMBER, 'paid_amount', :P_PAID_AMOUNT, 'status', v_status);
END;
$$;

-- Send Notification
CREATE OR REPLACE PROCEDURE CORE.SEND_NOTIFICATION(
    P_USER_ID VARCHAR, P_USER_TYPE VARCHAR, P_NOTIFICATION_TYPE VARCHAR, P_TITLE VARCHAR, P_MESSAGE VARCHAR, P_ENTITY_TYPE VARCHAR, P_ENTITY_ID VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO CORE.NOTIFICATIONS (USER_ID, USER_TYPE, NOTIFICATION_TYPE, TITLE, MESSAGE, RELATED_ENTITY_TYPE, RELATED_ENTITY_ID)
    VALUES (:P_USER_ID, :P_USER_TYPE, :P_NOTIFICATION_TYPE, :P_TITLE, :P_MESSAGE, :P_ENTITY_TYPE, :P_ENTITY_ID);
    RETURN 'SENT';
END;
$$;

-- Get User Notifications
CREATE OR REPLACE PROCEDURE CORE.GET_USER_NOTIFICATIONS(P_USER_ID VARCHAR)
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_notifications ARRAY; v_unread_count INT;
BEGIN
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT('id', NOTIFICATION_ID, 'type', NOTIFICATION_TYPE, 'title', TITLE,
        'message', MESSAGE, 'is_read', IS_READ, 'created_at', CREATED_AT)) INTO v_notifications
    FROM CORE.NOTIFICATIONS WHERE USER_ID = :P_USER_ID ORDER BY CREATED_AT DESC LIMIT 50;
    SELECT COUNT(*) INTO v_unread_count FROM CORE.NOTIFICATIONS WHERE USER_ID = :P_USER_ID AND IS_READ = FALSE;
    RETURN OBJECT_CONSTRUCT('user_id', :P_USER_ID, 'unread_count', v_unread_count, 'notifications', COALESCE(v_notifications, ARRAY_CONSTRUCT()));
END;
$$;

-- Mark Notification Read
CREATE OR REPLACE PROCEDURE CORE.MARK_NOTIFICATION_READ(P_NOTIFICATION_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    UPDATE CORE.NOTIFICATIONS SET IS_READ = TRUE, READ_AT = CURRENT_TIMESTAMP() WHERE NOTIFICATION_ID = :P_NOTIFICATION_ID;
    RETURN 'OK';
END;
$$;

-- Generate Platform Report
CREATE OR REPLACE PROCEDURE CORE.GENERATE_PLATFORM_REPORT()
RETURNS OBJECT
LANGUAGE SQL
AS
$$
DECLARE
    v_total_borrowers INT; v_kyc_verified INT; v_avg_score INT; v_prime INT;
    v_total_loans INT; v_total_portfolio NUMBER; v_avg_rate NUMBER;
    v_total_pools INT; v_total_securitized NUMBER; v_total_investors INT;
BEGIN
    SELECT COUNT(*), COUNT_IF(KYC_VERIFIED), ROUND(AVG(CREDIT_SCORE), 0), COUNT_IF(CREDIT_SCORE >= 800)
    INTO v_total_borrowers, v_kyc_verified, v_avg_score, v_prime FROM CORE.BORROWERS;
    SELECT COUNT(*), SUM(AMOUNT), ROUND(AVG(INTEREST_RATE) * 100, 2)
    INTO v_total_loans, v_total_portfolio, v_avg_rate FROM CORE.LOANS;
    SELECT COUNT(DISTINCT POOL_ID), SUM(TOTAL_VALUE) INTO v_total_pools, v_total_securitized FROM CORE.RMBS_POOLS;
    SELECT COUNT(DISTINCT INVESTOR_ID) INTO v_total_investors FROM CORE.INVESTOR_PORTFOLIO;
    RETURN OBJECT_CONSTRUCT('report_date', CURRENT_DATE(),
        'borrower_stats', OBJECT_CONSTRUCT('total', v_total_borrowers, 'kyc_verified', v_kyc_verified, 'avg_credit_score', v_avg_score, 'prime_borrowers', v_prime),
        'loan_stats', OBJECT_CONSTRUCT('total_loans', v_total_loans, 'portfolio_value', v_total_portfolio, 'avg_rate', v_avg_rate),
        'pool_stats', OBJECT_CONSTRUCT('total_pools', v_total_pools, 'securitized_value', v_total_securitized, 'investors', v_total_investors));
END;
$$;

-- Analytics Views
CREATE OR REPLACE VIEW CORE.V_PORTFOLIO_ANALYTICS AS
SELECT DATE_TRUNC('MONTH', L.DISBURSEMENT_DATE) AS MONTH, COUNT(DISTINCT L.LOAN_ID) AS LOANS_ORIGINATED,
    SUM(L.AMOUNT) AS TOTAL_DISBURSED, AVG(L.INTEREST_RATE) * 100 AS AVG_RATE, AVG(B.CREDIT_SCORE) AS AVG_CREDIT_SCORE
FROM CORE.LOANS L JOIN CORE.BORROWERS B ON L.BORROWER_ID = B.AADHAAR_ID
GROUP BY DATE_TRUNC('MONTH', L.DISBURSEMENT_DATE);

CREATE OR REPLACE VIEW CORE.V_RISK_DISTRIBUTION AS
SELECT CASE WHEN CREDIT_SCORE >= 800 THEN 'Prime (800+)' WHEN CREDIT_SCORE >= 750 THEN 'Near-Prime (750-799)'
    WHEN CREDIT_SCORE >= 700 THEN 'Standard (700-749)' ELSE 'Sub-Prime (<700)' END AS RISK_CATEGORY,
    COUNT(*) AS BORROWER_COUNT, SUM(MONTHLY_INCOME) AS TOTAL_INCOME
FROM CORE.BORROWERS GROUP BY RISK_CATEGORY;

CREATE OR REPLACE VIEW CORE.V_POOL_PERFORMANCE AS
SELECT P.POOL_ID, P.NAME AS POOL_NAME, P.TOTAL_VALUE, P.LOAN_COUNT, COUNT(DISTINCT I.INVESTOR_ID) AS INVESTOR_COUNT,
    SUM(I.INVESTMENT_AMOUNT) AS TOTAL_INVESTED, P.STATUS
FROM CORE.RMBS_POOLS P LEFT JOIN CORE.INVESTOR_PORTFOLIO I ON P.POOL_ID = I.POOL_ID
GROUP BY P.POOL_ID, P.NAME, P.TOTAL_VALUE, P.LOAN_COUNT, P.STATUS;

CREATE OR REPLACE VIEW CORE.V_EMI_COLLECTION AS
SELECT DATE_TRUNC('MONTH', DUE_DATE) AS MONTH, COUNT(*) AS TOTAL_EMIS,
    SUM(CASE WHEN PAYMENT_STATUS = 'PAID' THEN 1 ELSE 0 END) AS PAID_COUNT,
    SUM(TOTAL_EMI) AS TOTAL_DUE, SUM(PAID_AMOUNT) AS TOTAL_COLLECTED,
    ROUND(SUM(PAID_AMOUNT) / NULLIF(SUM(TOTAL_EMI), 0) * 100, 2) AS COLLECTION_RATE
FROM CORE.EMI_PAYMENTS GROUP BY DATE_TRUNC('MONTH', DUE_DATE);

-- Calculate Prepayment Benefits
CREATE OR REPLACE PROCEDURE CORE.CALCULATE_PREPAYMENT(P_LOAN_ID VARCHAR, P_PREPAY_AMOUNT NUMBER)
RETURNS OBJECT
LANGUAGE SQL
AS
$
BEGIN
    LET v_result OBJECT;
    
    WITH loan_data AS (
        SELECT 
            LOAN_ID,
            AMOUNT,
            INTEREST_RATE,
            TENURE_MONTHS,
            INTEREST_RATE / 12 as monthly_rate,
            AMOUNT * (INTEREST_RATE / 12) * POWER(1 + INTEREST_RATE / 12, TENURE_MONTHS) / 
                NULLIF(POWER(1 + INTEREST_RATE / 12, TENURE_MONTHS) - 1, 0) as current_emi,
            AMOUNT - :P_PREPAY_AMOUNT as new_balance
        FROM CORE.LOANS 
        WHERE LOAN_ID = :P_LOAN_ID
    ),
    calculations AS (
        SELECT 
            *,
            current_emi - new_balance * monthly_rate as emi_diff
        FROM loan_data
    )
    SELECT OBJECT_CONSTRUCT(
        'success', TRUE,
        'loan_id', LOAN_ID,
        'prepay_amount', :P_PREPAY_AMOUNT,
        'original_balance', AMOUNT,
        'new_balance', new_balance,
        'original_tenure_months', TENURE_MONTHS,
        'new_tenure_months', CASE 
            WHEN emi_diff <= 0 THEN CEIL(new_balance / current_emi)
            ELSE CEIL(LN(current_emi / NULLIF(emi_diff, 0)) / NULLIF(LN(1 + monthly_rate), 0))
        END,
        'months_saved', TENURE_MONTHS - CASE 
            WHEN emi_diff <= 0 THEN CEIL(new_balance / current_emi)
            ELSE CEIL(LN(current_emi / NULLIF(emi_diff, 0)) / NULLIF(LN(1 + monthly_rate), 0))
        END,
        'interest_saved', ROUND(GREATEST(
            (current_emi * TENURE_MONTHS) - 
            (current_emi * CASE 
                WHEN emi_diff <= 0 THEN CEIL(new_balance / current_emi)
                ELSE CEIL(LN(current_emi / NULLIF(emi_diff, 0)) / NULLIF(LN(1 + monthly_rate), 0))
            END) - :P_PREPAY_AMOUNT
        , 0), 2),
        'monthly_emi', ROUND(current_emi, 2)
    ) INTO v_result
    FROM calculations;
    
    IF (v_result IS NULL) THEN
        RETURN OBJECT_CONSTRUCT('success', FALSE, 'error', 'Loan not found');
    END IF;
    
    RETURN v_result;
END;
$;

