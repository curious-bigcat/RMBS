#!/bin/bash
# Housing for All Platform - Deployment Script
# 
# Prerequisites:
# 1. Snowflake CLI (snow) installed
# 2. A Snowflake connection configured with CREATE DATABASE privileges
# 3. A warehouse named COMPUTE_WH (or update setup.sql)
#
# Usage:
#   ./deploy.sh [connection_name]
#
# Example:
#   ./deploy.sh default

set -e

CONNECTION=${1:-"default"}

echo "=== Housing for All Platform - MVP Deployment ==="
echo ""
echo "Connection: $CONNECTION"
echo ""

# Create database
echo "Creating database HOUSING_PLATFORM..."
snow sql -c "$CONNECTION" -q "CREATE DATABASE IF NOT EXISTS HOUSING_PLATFORM"
snow sql -c "$CONNECTION" -q "CREATE SCHEMA IF NOT EXISTS HOUSING_PLATFORM.CORE"

# Run setup script
echo "Running setup.sql..."
snow sql -c "$CONNECTION" -f setup.sql

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Database: HOUSING_PLATFORM.CORE"
echo ""
echo "Mock Integration Tables:"
echo "  - MOCK_UIDAI_REGISTRY (Aadhaar simulation)"
echo "  - MOCK_DIGILOCKER_DOCUMENTS (Document store simulation)"
echo ""
echo "Stored Procedures:"
echo "  - VERIFY_AADHAAR(aadhaar_id)"
echo "  - FETCH_DIGILOCKER_DOCUMENTS(aadhaar_id, doc_type)"
echo "  - PERFORM_KYC_CHECK(aadhaar_id)"
echo "  - REGISTER_BORROWER_FROM_KYC(aadhaar_id, income, liabilities, score)"
echo "  - GET_BORROWER_SUMMARY(aadhaar_id)"
echo "  - ISSUE_ELIGIBILITY_CERTIFICATE(aadhaar_id)"
echo "  - ASSIGN_LOANS_TO_POOLS()"
echo ""
echo "Dynamic Tables:"
echo "  - BORROWER_ELIGIBILITY_STATUS (real-time eligibility)"
echo "  - RMBS_ELIGIBLE_LOANS (6-month MHP tracking)"
echo ""
echo "Test Aadhaar Numbers:"
echo "  - 123456789012 (Priya Sharma) - Full KYC"
echo "  - 234567890123 (Rahul Verma) - Full KYC"
echo "  - 345678901234 (Anita Patel) - Partial KYC"
echo "  - 567890123456 (Meera Reddy) - Minimal docs"
echo ""
echo "To deploy Streamlit app:"
echo "  snow streamlit deploy --connection $CONNECTION"
