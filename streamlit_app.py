import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import json

# Database configuration
DB_SCHEMA = "HOUSING_PLATFORM.CORE"

# Page configuration
st.set_page_config(
    page_title="Housing for All Platform",
    page_icon="🏠",
    layout="wide",
)

# Get Snowflake session
session = get_active_session()

# Role-based navigation
USER_ROLES = {
    "Borrower": ["eKYC Verification", "Eligibility Check", "Apply for Loan", "Rate Comparison", "My Applications", "EMI Payments", "Notifications", "Document Upload"],
    "Originator": ["Originator Dashboard", "Loan Approvals", "Document Verification", "All Borrowers", "RMBS Dashboard", "Platform Report", "Audit Log"],
    "Investor": ["Investor Portal", "RMBS Dashboard", "Pool Analytics"],
    "Admin": ["Admin Dashboard", "Originator Dashboard", "Investor Portal", "RMBS Dashboard", "Platform Report", "Audit Log", "User Management"]
}

# Sidebar - Role Selection
st.sidebar.title("Housing for All")
user_role = st.sidebar.selectbox("Select Role", list(USER_ROLES.keys()), key="user_role")

# Get available pages for the selected role
available_pages = USER_ROLES[user_role]
page = st.sidebar.selectbox("Navigation", available_pages)

# Header
st.title("Housing for All Platform")
st.markdown(f"*{user_role} Portal - Affordable housing marketplace powered by Snowflake*")


def ekyc_verification_page():
    """eKYC verification using mock UIDAI and DigiLocker."""
    st.header("eKYC Verification")
    st.markdown("Verify your identity using Aadhaar and fetch documents from DigiLocker")
    
    aadhaar_id = st.text_input("Enter Aadhaar Number", max_chars=12, placeholder="123456789012")
    
    col1, col2 = st.columns(2)
    
    with col1:
        verify_clicked = st.button("Verify Aadhaar", type="primary")
    with col2:
        full_kyc_clicked = st.button("Complete KYC Check")
    
    if verify_clicked and aadhaar_id:
        with st.spinner("Verifying with UIDAI..."):
            try:
                result = session.sql(f"CALL {DB_SCHEMA}.VERIFY_AADHAAR('{aadhaar_id}')").collect()[0][0]
                import json
                data = json.loads(result) if isinstance(result, str) else result
                
                if data.get("success"):
                    st.success("Aadhaar Verified Successfully")
                    
                    col1, col2, col3 = st.columns(3)
                    col1.metric("Name", data.get("name", "N/A"))
                    col2.metric("Date of Birth", str(data.get("date_of_birth", "N/A")))
                    col3.metric("Gender", data.get("gender", "N/A"))
                    
                    # Store in session state for later use
                    st.session_state["verified_aadhaar"] = data
                else:
                    st.error(f"Verification Failed: {data.get('error_message')}")
            except Exception as e:
                st.error(f"Error: {e}")
    
    if full_kyc_clicked and aadhaar_id:
        with st.spinner("Performing complete KYC check..."):
            try:
                result = session.sql(f"CALL {DB_SCHEMA}.PERFORM_KYC_CHECK('{aadhaar_id}')").collect()[0][0]
                import json
                data = json.loads(result) if isinstance(result, str) else result
                
                kyc_status = data.get("kyc_status")
                
                if kyc_status == "PASSED":
                    st.success("KYC Verification Passed")
                elif kyc_status == "INCOMPLETE":
                    st.warning("KYC Incomplete - Missing Documents")
                else:
                    st.error(f"KYC Failed: {data.get('error')}")
                    return
                
                # Display KYC results
                st.subheader("KYC Summary")
                
                col1, col2 = st.columns(2)
                with col1:
                    st.markdown("**Identity Verification**")
                    st.write(f"- Name: {data.get('holder_name', 'N/A')}")
                    st.write(f"- Date of Birth: {data.get('date_of_birth', 'N/A')}")
                    st.write(f"- Aadhaar Verified: {'Yes' if data.get('aadhaar_verified') else 'No'}")
                
                with col2:
                    st.markdown("**Document Status**")
                    st.write(f"- PAN Card: {'Available' if data.get('has_pan') else 'Missing'}")
                    st.write(f"- Income Proof: {'Available' if data.get('has_income_proof') else 'Missing'}")
                    st.write(f"- Documents Found: {data.get('documents_found', 0)}")
                
                if data.get("missing_documents"):
                    st.warning("Missing Documents:")
                    for doc in data["missing_documents"]:
                        st.write(f"  - {doc}")
                
                # Fetch and display DigiLocker documents
                st.subheader("DigiLocker Documents")
                docs_result = session.sql(f"CALL {DB_SCHEMA}.FETCH_DIGILOCKER_DOCUMENTS('{aadhaar_id}', NULL)").collect()[0][0]
                docs_data = json.loads(docs_result) if isinstance(docs_result, str) else docs_result
                
                if docs_data.get("documents"):
                    docs_df = pd.DataFrame(docs_data["documents"])
                    docs_df = docs_df[["doc_type", "doc_number", "issuer", "status"]]
                    docs_df.columns = ["Document Type", "Number", "Issuer", "Status"]
                    st.dataframe(docs_df, use_container_width=True)
                else:
                    st.info("No documents found in DigiLocker")
                
                # Store KYC result in session
                st.session_state["kyc_result"] = data
                
            except Exception as e:
                st.error(f"Error: {e}")
    
    # Show test data hint
    with st.expander("Test Aadhaar Numbers (MVP Demo)"):
        st.markdown("""
        | Aadhaar | Name | Has PAN | Has Income Proof |
        |---------|------|---------|------------------|
        | 123456789012 | Priya Sharma | Yes | Yes (Form 16) |
        | 234567890123 | Rahul Verma | Yes | Yes (ITR) |
        | 345678901234 | Anita Patel | Yes | No |
        | 567890123456 | Meera Reddy | No | No |
        """)


def eligibility_check_page():
    st.header("Borrower Eligibility Check")
    
    # Pre-fill from KYC if available
    kyc_data = st.session_state.get("kyc_result", {})
    verified_aadhaar = st.session_state.get("verified_aadhaar", {})
    
    col1, col2 = st.columns(2)
    
    with col1:
        default_aadhaar = verified_aadhaar.get("aadhaar_id", "")
        aadhaar_id = st.text_input("Aadhaar Number", value=default_aadhaar, max_chars=12, placeholder="123456789012")
        
        default_name = kyc_data.get("holder_name") or verified_aadhaar.get("name", "")
        name = st.text_input("Full Name", value=default_name)
        
        dob = st.date_input("Date of Birth")
    
    with col2:
        monthly_income = st.number_input("Monthly Income (₹)", min_value=0, step=1000)
        monthly_liabilities = st.number_input("Monthly Liabilities (₹)", min_value=0, step=1000)
        credit_score = st.number_input("CIBIL Score", min_value=300, max_value=900, step=1)
    
    # Show KYC status if available
    if kyc_data:
        kyc_status = kyc_data.get("kyc_status")
        if kyc_status == "PASSED":
            st.success("eKYC Verified")
        elif kyc_status == "INCOMPLETE":
            st.warning("eKYC Incomplete - Some documents missing")
    
    col_check, col_register = st.columns(2)
    
    with col_check:
        check_clicked = st.button("Check Eligibility", type="primary")
    
    with col_register:
        register_clicked = st.button("Register & Get Certificate")
    
    if check_clicked or register_clicked:
        if not aadhaar_id or len(aadhaar_id) != 12 or not aadhaar_id.isdigit():
            st.error("Please enter a valid 12-digit Aadhaar number")
            return
        
        if not name:
            st.error("Please enter your full name")
            return
        
        # Calculate eligibility
        from datetime import date
        from dateutil.relativedelta import relativedelta
        
        age = relativedelta(date.today(), dob).years
        dti = monthly_liabilities / monthly_income if monthly_income > 0 else 1.0
        
        issues = []
        if credit_score < 750:
            issues.append(f"Credit score {credit_score} is below minimum 750")
        if age < 25 or age > 50:
            issues.append(f"Age {age} is outside 25-50 year range")
        if dti > 0.50:
            issues.append(f"DTI ratio {dti:.0%} exceeds 50%")
        
        if not issues:
            st.success("Congratulations! You are eligible for housing finance.")
            
            # Show eligible rates
            st.subheader("Your Eligible Rates")
            rate_data = pd.DataFrame({
                "Product": ["Home Loan", "Home Improvement", "Plot Purchase"],
                "Platform Rate": ["7.5%", "8.0%", "8.5%"],
                "Market Rate": ["9.5%", "10.5%", "11.0%"],
                "Savings": ["2.0%", "2.5%", "2.5%"]
            })
            st.table(rate_data)
            
            if register_clicked:
                # Check if KYC is done
                if not kyc_data or kyc_data.get("kyc_status") != "PASSED":
                    st.warning("Please complete eKYC verification first for full registration")
                
                try:
                    # Use the new registration procedure
                    import json
                    result = session.sql(f"""
                        CALL {DB_SCHEMA}.REGISTER_BORROWER_FROM_KYC(
                            '{aadhaar_id}', 
                            {monthly_income}, 
                            {monthly_liabilities}, 
                            {credit_score}
                        )
                    """).collect()[0][0]
                    
                    reg_data = json.loads(result) if isinstance(result, str) else result
                    
                    if reg_data.get("success"):
                        # Issue certificate
                        session.sql(f"CALL {DB_SCHEMA}.ISSUE_ELIGIBILITY_CERTIFICATE('{aadhaar_id}')").collect()
                        st.success(f"Borrower {reg_data.get('name')} registered successfully!")
                        st.balloons()
                    else:
                        st.error(f"Registration failed: {reg_data.get('error')}")
                except Exception as e:
                    st.error(f"Registration error: {e}")
        else:
            st.error("Not Eligible")
            for issue in issues:
                st.warning(issue)


def rate_comparison_page():
    st.header("Rate Comparison")
    
    loan_amount = st.slider("Loan Amount (₹ Lakhs)", min_value=5, max_value=200, value=50)
    tenure = st.slider("Tenure (Years)", min_value=5, max_value=30, value=20)
    
    st.subheader("Rate Comparison")
    
    comparison_data = pd.DataFrame({
        "Lender": ["Platform Rate", "Bank A", "Bank B", "Bank C", "NBFC D"],
        "Interest Rate": [7.5, 9.5, 9.75, 10.0, 11.5],
        "EMI (₹)": [
            calculate_emi(loan_amount * 100000, 7.5, tenure * 12),
            calculate_emi(loan_amount * 100000, 9.5, tenure * 12),
            calculate_emi(loan_amount * 100000, 9.75, tenure * 12),
            calculate_emi(loan_amount * 100000, 10.0, tenure * 12),
            calculate_emi(loan_amount * 100000, 11.5, tenure * 12),
        ]
    })
    
    comparison_data["Total Interest (₹ L)"] = (
        (comparison_data["EMI (₹)"] * tenure * 12 - loan_amount * 100000) / 100000
    ).round(2)
    
    comparison_data["EMI (₹)"] = comparison_data["EMI (₹)"].apply(lambda x: f"₹{x:,.0f}")
    comparison_data["Interest Rate"] = comparison_data["Interest Rate"].apply(lambda x: f"{x}%")
    
    st.dataframe(comparison_data, use_container_width=True)
    
    # Savings highlight
    platform_emi = calculate_emi(loan_amount * 100000, 7.5, tenure * 12)
    market_emi = calculate_emi(loan_amount * 100000, 9.5, tenure * 12)
    monthly_savings = market_emi - platform_emi
    total_savings = monthly_savings * tenure * 12
    
    col1, col2, col3 = st.columns(3)
    col1.metric("Monthly Savings", f"₹{monthly_savings:,.0f}")
    col2.metric("Total Savings", f"₹{total_savings / 100000:.2f}L")
    col3.metric("Platform Rate Advantage", "2.0%")


def apply_for_loan_page():
    st.header("Apply for Housing Loan")
    
    # Check for eligible borrowers
    try:
        eligible_df = session.sql(f"""
            SELECT AADHAAR_ID, NAME, CREDIT_SCORE 
            FROM {DB_SCHEMA}.BORROWER_ELIGIBILITY_STATUS
            WHERE IS_ELIGIBLE = TRUE
            ORDER BY NAME
        """).to_pandas()
        
        if eligible_df.empty:
            st.warning("No eligible borrowers found. Please complete eligibility check first.")
            return
        
        borrower_options = {f"{row['NAME']} ({row['AADHAAR_ID']})": row['AADHAAR_ID'] 
                          for _, row in eligible_df.iterrows()}
        
        selected = st.selectbox("Select Borrower", options=list(borrower_options.keys()))
        borrower_id = borrower_options[selected]
        
        col1, col2 = st.columns(2)
        
        with col1:
            loan_amount = st.number_input("Loan Amount (₹)", min_value=100000, max_value=50000000, step=100000, value=5000000)
            tenure_years = st.selectbox("Tenure", options=[10, 15, 20, 25, 30], index=2)
        
        with col2:
            interest_rate = st.number_input("Interest Rate (%)", min_value=6.0, max_value=15.0, value=7.5, step=0.25)
            disbursement_date = st.date_input("Expected Disbursement Date")
        
        # Show EMI calculation
        emi = calculate_emi(loan_amount, interest_rate, tenure_years * 12)
        total_payment = emi * tenure_years * 12
        total_interest = total_payment - loan_amount
        
        st.subheader("Loan Summary")
        col1, col2, col3 = st.columns(3)
        col1.metric("Monthly EMI", f"₹{emi:,.0f}")
        col2.metric("Total Interest", f"₹{total_interest/100000:.2f}L")
        col3.metric("Total Payment", f"₹{total_payment/100000:.2f}L")
        
        if st.button("Submit Application", type="primary"):
            import uuid
            loan_id = f"LOAN-{str(uuid.uuid4())[:8].upper()}"
            
            try:
                session.sql(f"""
                    INSERT INTO {DB_SCHEMA}.LOANS 
                        (LOAN_ID, BORROWER_ID, AMOUNT, INTEREST_RATE, TENURE_MONTHS, DISBURSEMENT_DATE, STATUS)
                    VALUES 
                        ('{loan_id}', '{borrower_id}', {loan_amount}, {interest_rate/100}, {tenure_years * 12}, '{disbursement_date}', 'PENDING')
                """).collect()
                
                st.success(f"Loan application submitted! Loan ID: {loan_id}")
                st.balloons()
            except Exception as e:
                st.error(f"Error submitting application: {e}")
                
    except Exception as e:
        st.error(f"Error loading borrowers: {e}")


def calculate_emi(principal, annual_rate, tenure_months):
    r = annual_rate / (12 * 100)
    emi = principal * r * ((1 + r) ** tenure_months) / (((1 + r) ** tenure_months) - 1)
    return round(emi, 0)


def applications_page():
    st.header("My Applications")
    
    # Borrower lookup
    aadhaar_lookup = st.text_input("Enter Aadhaar to view dashboard", max_chars=12, placeholder="123456789012")
    
    if aadhaar_lookup and len(aadhaar_lookup) == 12:
        try:
            import json
            result = session.sql(f"CALL {DB_SCHEMA}.GET_BORROWER_SUMMARY('{aadhaar_lookup}')").collect()[0][0]
            data = json.loads(result) if isinstance(result, str) else result
            
            if data.get("error"):
                st.warning(data["error"])
            else:
                borrower = data.get("borrower", {})
                loans = data.get("loans", {})
                eligibility = data.get("eligibility", {})
                
                # Borrower info cards
                st.subheader(f"Dashboard: {borrower.get('name', 'N/A')}")
                
                col1, col2, col3, col4 = st.columns(4)
                col1.metric("Credit Score", borrower.get("credit_score", "N/A"))
                col2.metric("DTI Ratio", f"{borrower.get('dti_ratio', 0)}%")
                col3.metric("KYC Status", "Verified" if borrower.get("kyc_verified") else "Pending")
                col4.metric("Eligible", "Yes" if eligibility.get("is_eligible") else "No")
                
                # Loan summary
                st.subheader("Loan Summary")
                col1, col2, col3, col4 = st.columns(4)
                col1.metric("Total Loans", loans.get("total_loans", 0))
                col2.metric("Active Loans", loans.get("active_loans", 0))
                col3.metric("Total Amount", f"₹{(loans.get('total_amount') or 0) / 100000:.1f}L")
                col4.metric("RMBS Pooled", loans.get("pooled_loans", 0))
                
        except Exception as e:
            st.error(f"Error: {e}")
    
    st.markdown("---")
    st.subheader("Recent Applications")
    
    # Fetch from Snowflake
    try:
        loans_df = session.sql(f"""
            SELECT 
                L.LOAN_ID,
                B.NAME AS BORROWER,
                L.AMOUNT / 100000 AS "AMOUNT (L)",
                ROUND(L.INTEREST_RATE * 100, 2) AS "RATE %",
                L.TENURE_MONTHS / 12 AS "TENURE (YRS)",
                L.DISBURSEMENT_DATE,
                L.STATUS,
                COALESCE(L.POOL_ID, '-') AS POOL_ID
            FROM {DB_SCHEMA}.LOANS L
            JOIN {DB_SCHEMA}.BORROWERS B ON L.BORROWER_ID = B.AADHAAR_ID
            ORDER BY L.CREATED_AT DESC
            LIMIT 20
        """).to_pandas()
        
        if loans_df.empty:
            st.info("No applications found. Start by checking your eligibility.")
        else:
            st.dataframe(loans_df, use_container_width=True)
    except Exception as e:
        st.warning("Sample data (database not connected)")
        sample_data = pd.DataFrame({
            "Loan ID": ["LOAN-A1B2C3D4", "LOAN-E5F6G7H8"],
            "Borrower": ["Priya Sharma", "Rahul Verma"],
            "Amount (L)": [50.0, 75.0],
            "Rate %": [7.5, 7.25],
            "Status": ["Active", "Active"],
            "Pool": ["RMBS-2025-Q4", "-"]
        })
        st.table(sample_data)


def rmbs_dashboard_page():
    st.header("RMBS Pool Dashboard")
    
    try:
        pools_df = session.sql(f"""
            SELECT 
                POOL_ID,
                NAME,
                AGGREGATION_DATE,
                LOAN_COUNT,
                TOTAL_VALUE,
                STATUS
            FROM {DB_SCHEMA}.RMBS_POOLS
            ORDER BY AGGREGATION_DATE DESC
        """).to_pandas()
        
        if not pools_df.empty:
            col1, col2, col3 = st.columns(3)
            col1.metric("Total Pools", len(pools_df))
            col2.metric("Total Loans", pools_df["LOAN_COUNT"].sum())
            col3.metric("Total Value", f"₹{pools_df['TOTAL_VALUE'].sum() / 10000000:.1f}Cr")
            
            st.subheader("Pool Details")
            st.dataframe(pools_df, use_container_width=True)
    except Exception:
        st.warning("Sample RMBS data (database not connected)")
        
        col1, col2, col3 = st.columns(3)
        col1.metric("Total Pools", "4")
        col2.metric("Total Loans", "1,250")
        col3.metric("Total Value", "₹625Cr")
        
        sample_pools = pd.DataFrame({
            "Pool ID": ["RMBS-2025-Q4", "RMBS-2026-Q1", "RMBS-2026-Q2"],
            "Name": ["Housing Pool 2025 Q4", "Housing Pool 2026 Q1", "Housing Pool 2026 Q2"],
            "Loans": [450, 520, 280],
            "Value (Cr)": [225.5, 260.0, 140.0],
            "Status": ["Closed", "Closed", "Open"]
        })
        st.table(sample_pools)


# ============================================
# NEW FEATURES - Document Upload
# ============================================

def document_upload_page():
    """Document upload for borrowers."""
    st.header("Document Upload")
    st.markdown("Upload additional documents for loan processing")
    
    aadhaar_id = st.text_input("Your Aadhaar Number", max_chars=12, placeholder="123456789012")
    
    if aadhaar_id and len(aadhaar_id) == 12:
        doc_type = st.selectbox("Document Type", [
            "SALARY_SLIP", "BANK_STATEMENT", "PROPERTY_DOCS", 
            "ID_PROOF", "ADDRESS_PROOF", "TAX_RETURNS", "OTHER"
        ])
        
        uploaded_file = st.file_uploader("Choose a file", type=['pdf', 'jpg', 'jpeg', 'png'])
        
        if uploaded_file and st.button("Upload Document", type="primary"):
            try:
                # In production, upload to stage
                result = session.sql(f"""
                    CALL {DB_SCHEMA}.REGISTER_DOCUMENT_UPLOAD(
                        '{aadhaar_id}',
                        '{doc_type}',
                        '{uploaded_file.name}',
                        '@{DB_SCHEMA}.DOCUMENT_UPLOADS/{aadhaar_id}/{uploaded_file.name}',
                        {len(uploaded_file.getvalue()) // 1024},
                        '{uploaded_file.type}'
                    )
                """).collect()[0][0]
                
                data = json.loads(result) if isinstance(result, str) else result
                if data.get("success"):
                    st.success(f"Document uploaded successfully! ID: {data.get('doc_id')}")
                else:
                    st.error(data.get("error"))
            except Exception as e:
                st.error(f"Upload error: {e}")
        
        # Show uploaded documents
        st.subheader("Your Uploaded Documents")
        try:
            docs_df = session.sql(f"""
                SELECT DOC_TYPE, DOC_NAME, UPLOAD_DATE, VERIFICATION_STATUS, REJECTION_REASON
                FROM {DB_SCHEMA}.UPLOADED_DOCUMENTS
                WHERE AADHAAR_ID = '{aadhaar_id}'
                ORDER BY UPLOAD_DATE DESC
            """).to_pandas()
            
            if not docs_df.empty:
                st.dataframe(docs_df, use_container_width=True)
            else:
                st.info("No documents uploaded yet")
        except Exception as e:
            st.info("No documents found")


# ============================================
# ORIGINATOR FEATURES
# ============================================

def originator_dashboard_page():
    """Originator dashboard with KPIs and pending actions."""
    st.header("Originator Dashboard")
    
    try:
        result = session.sql(f"CALL {DB_SCHEMA}.GET_ORIGINATOR_DASHBOARD()").collect()[0][0]
        data = json.loads(result) if isinstance(result, str) else result
        
        # KPI Cards
        st.subheader("Key Metrics")
        col1, col2, col3, col4 = st.columns(4)
        
        loan_stats = data.get("loan_stats", {})
        col1.metric("Total Loans", loan_stats.get("total_loans", 0))
        col2.metric("Pending Approval", loan_stats.get("pending_approval", 0))
        col3.metric("Portfolio Value", f"₹{(loan_stats.get('total_value') or 0) / 10000000:.1f}Cr")
        col4.metric("Avg Rate", f"{loan_stats.get('avg_interest_rate', 0)}%")
        
        borrower_stats = data.get("borrower_stats", {})
        col1, col2, col3, col4 = st.columns(4)
        col1.metric("Total Borrowers", borrower_stats.get("total_borrowers", 0))
        col2.metric("KYC Verified", borrower_stats.get("kyc_verified", 0))
        col3.metric("Avg Credit Score", borrower_stats.get("avg_credit_score", 0))
        
        # Pending Actions
        st.subheader("Pending Actions")
        pending = data.get("pending_actions", {})
        
        col1, col2, col3 = st.columns(3)
        col1.warning(f"**{pending.get('loans_pending_approval', 0)}** Loans awaiting approval")
        col2.warning(f"**{pending.get('documents_pending_verification', 0)}** Documents to verify")
        col3.info(f"**{pending.get('loans_ready_for_pooling', 0)}** Loans ready for RMBS")
        
    except Exception as e:
        st.error(f"Error loading dashboard: {e}")


def loan_approvals_page():
    """Loan approval workflow for originators."""
    st.header("Loan Approvals")
    
    try:
        pending_loans = session.sql(f"""
            SELECT 
                L.LOAN_ID, B.NAME AS BORROWER, B.CREDIT_SCORE,
                L.AMOUNT / 100000 AS "AMOUNT_LAKHS",
                ROUND(L.INTEREST_RATE * 100, 2) AS RATE,
                L.STATUS, L.CREATED_AT
            FROM {DB_SCHEMA}.LOANS L
            JOIN {DB_SCHEMA}.BORROWERS B ON L.BORROWER_ID = B.AADHAAR_ID
            WHERE L.STATUS = 'PENDING'
            ORDER BY L.CREATED_AT
        """).to_pandas()
        
        if pending_loans.empty:
            st.success("No pending loan applications!")
        else:
            st.dataframe(pending_loans, use_container_width=True)
            
            st.subheader("Take Action")
            selected_loan = st.selectbox("Select Loan", pending_loans["LOAN_ID"].tolist())
            
            col1, col2 = st.columns(2)
            with col1:
                if st.button("Approve Loan", type="primary"):
                    result = session.sql(f"""
                        CALL {DB_SCHEMA}.UPDATE_LOAN_STATUS('{selected_loan}', 'APPROVED', 'ORIGINATOR', 'Approved by originator')
                    """).collect()[0][0]
                    data = json.loads(result) if isinstance(result, str) else result
                    if data.get("success"):
                        st.success("Loan approved!")
                        st.rerun()
                    else:
                        st.error(data.get("error"))
            
            with col2:
                rejection_reason = st.text_input("Rejection Reason")
                if st.button("Reject Loan", type="secondary"):
                    if not rejection_reason:
                        st.warning("Please provide a rejection reason")
                    else:
                        result = session.sql(f"""
                            CALL {DB_SCHEMA}.UPDATE_LOAN_STATUS('{selected_loan}', 'REJECTED', 'ORIGINATOR', '{rejection_reason}')
                        """).collect()[0][0]
                        st.success("Loan rejected")
                        st.rerun()
                        
    except Exception as e:
        st.error(f"Error: {e}")


def document_verification_page():
    """Document verification for originators."""
    st.header("Document Verification")
    
    try:
        pending_docs = session.sql(f"""
            SELECT 
                D.DOC_ID, D.AADHAAR_ID, B.NAME AS BORROWER,
                D.DOC_TYPE, D.DOC_NAME, D.UPLOAD_DATE
            FROM {DB_SCHEMA}.UPLOADED_DOCUMENTS D
            JOIN {DB_SCHEMA}.BORROWERS B ON D.AADHAAR_ID = B.AADHAAR_ID
            WHERE D.VERIFICATION_STATUS = 'PENDING'
            ORDER BY D.UPLOAD_DATE
        """).to_pandas()
        
        if pending_docs.empty:
            st.success("No documents pending verification!")
        else:
            st.dataframe(pending_docs, use_container_width=True)
            
            st.subheader("Verify Document")
            selected_doc = st.selectbox("Select Document", pending_docs["DOC_ID"].tolist())
            
            col1, col2 = st.columns(2)
            with col1:
                if st.button("Verify Document", type="primary"):
                    result = session.sql(f"""
                        CALL {DB_SCHEMA}.VERIFY_DOCUMENT('{selected_doc}', 'ORIGINATOR', 'VERIFIED', NULL)
                    """).collect()[0][0]
                    st.success("Document verified!")
                    st.rerun()
            
            with col2:
                reject_reason = st.text_input("Rejection Reason")
                if st.button("Reject Document"):
                    if reject_reason:
                        session.sql(f"""
                            CALL {DB_SCHEMA}.VERIFY_DOCUMENT('{selected_doc}', 'ORIGINATOR', 'REJECTED', '{reject_reason}')
                        """).collect()
                        st.warning("Document rejected")
                        st.rerun()
                        
    except Exception as e:
        st.error(f"Error: {e}")


def all_borrowers_page():
    """View all borrowers for originators."""
    st.header("All Borrowers")
    
    try:
        borrowers_df = session.sql(f"""
            SELECT 
                B.AADHAAR_ID, B.NAME, B.CREDIT_SCORE,
                E.IS_ELIGIBLE, E.DTI_RATIO,
                B.KYC_VERIFIED, B.CREATED_AT
            FROM {DB_SCHEMA}.BORROWERS B
            LEFT JOIN {DB_SCHEMA}.BORROWER_ELIGIBILITY_STATUS E ON B.AADHAAR_ID = E.AADHAAR_ID
            ORDER BY B.CREATED_AT DESC
        """).to_pandas()
        
        # Filters
        col1, col2 = st.columns(2)
        with col1:
            eligibility_filter = st.selectbox("Eligibility", ["All", "Eligible", "Ineligible"])
        with col2:
            kyc_filter = st.selectbox("KYC Status", ["All", "Verified", "Pending"])
        
        # Apply filters
        if eligibility_filter == "Eligible":
            borrowers_df = borrowers_df[borrowers_df["IS_ELIGIBLE"] == True]
        elif eligibility_filter == "Ineligible":
            borrowers_df = borrowers_df[borrowers_df["IS_ELIGIBLE"] == False]
            
        if kyc_filter == "Verified":
            borrowers_df = borrowers_df[borrowers_df["KYC_VERIFIED"] == True]
        elif kyc_filter == "Pending":
            borrowers_df = borrowers_df[borrowers_df["KYC_VERIFIED"] == False]
        
        st.dataframe(borrowers_df, use_container_width=True)
        
    except Exception as e:
        st.error(f"Error: {e}")


def audit_log_page():
    """Audit log viewer for admins."""
    st.header("Audit Log")
    
    try:
        # Filters
        col1, col2, col3 = st.columns(3)
        with col1:
            action_filter = st.selectbox("Action Type", ["All", "KYC_VERIFY", "LOAN_APPLY", "LOAN_STATUS_CHANGE", "DOCUMENT_UPLOAD", "DOCUMENT_VERIFY", "POOL_INVESTMENT"])
        with col2:
            status_filter = st.selectbox("Status", ["All", "SUCCESS", "FAILED"])
        with col3:
            days = st.number_input("Last N Days", min_value=1, max_value=90, value=7)
        
        where_clauses = [f"TIMESTAMP >= DATEADD(DAY, -{days}, CURRENT_TIMESTAMP())"]
        if action_filter != "All":
            where_clauses.append(f"ACTION_TYPE = '{action_filter}'")
        if status_filter != "All":
            where_clauses.append(f"STATUS = '{status_filter}'")
        
        where_sql = " AND ".join(where_clauses)
        
        audit_df = session.sql(f"""
            SELECT 
                TIMESTAMP, USER_ROLE, USER_ID, ACTION_TYPE, 
                ENTITY_TYPE, ENTITY_ID, STATUS, ERROR_MESSAGE
            FROM {DB_SCHEMA}.AUDIT_LOG
            WHERE {where_sql}
            ORDER BY TIMESTAMP DESC
            LIMIT 100
        """).to_pandas()
        
        if audit_df.empty:
            st.info("No audit logs found for the selected criteria")
        else:
            st.dataframe(audit_df, use_container_width=True)
            
    except Exception as e:
        st.error(f"Error loading audit log: {e}")


# ============================================
# INVESTOR FEATURES
# ============================================

def investor_portal_page():
    """Investor portal for RMBS investments."""
    st.header("Investor Portal")
    
    investor_id = st.text_input("Investor ID", placeholder="INV-001")
    
    if investor_id:
        try:
            result = session.sql(f"CALL {DB_SCHEMA}.GET_INVESTOR_DASHBOARD('{investor_id}')").collect()[0][0]
            data = json.loads(result) if isinstance(result, str) else result
            
            # Portfolio Summary
            st.subheader("Portfolio Summary")
            col1, col2, col3, col4 = st.columns(4)
            col1.metric("Total Invested", f"₹{data.get('total_invested', 0) / 100000:.1f}L")
            col2.metric("Current Value", f"₹{data.get('current_value', 0) / 100000:.1f}L")
            col3.metric("Returns", f"₹{data.get('total_returns', 0) / 100000:.1f}L")
            col4.metric("Return %", f"{data.get('return_percentage', 0)}%")
            
            # Portfolio Holdings
            st.subheader("Holdings")
            portfolio = data.get("portfolio", [])
            if portfolio:
                portfolio_df = pd.DataFrame(portfolio)
                st.dataframe(portfolio_df, use_container_width=True)
            else:
                st.info("No investments yet")
                
        except Exception as e:
            st.error(f"Error: {e}")
    
    # New Investment
    st.markdown("---")
    st.subheader("New Investment")
    
    try:
        open_pools = session.sql(f"""
            SELECT POOL_ID, NAME, TOTAL_VALUE / 10000000 AS VALUE_CR, LOAN_COUNT
            FROM {DB_SCHEMA}.RMBS_POOLS
            WHERE STATUS = 'OPEN'
        """).to_pandas()
        
        if not open_pools.empty:
            selected_pool = st.selectbox("Select Pool", open_pools["POOL_ID"].tolist())
            investment_amount = st.number_input("Investment Amount (₹)", min_value=10000, step=10000, value=100000)
            
            if st.button("Invest", type="primary") and investor_id:
                result = session.sql(f"""
                    CALL {DB_SCHEMA}.INVEST_IN_POOL('{investor_id}', '{selected_pool}', {investment_amount})
                """).collect()[0][0]
                data = json.loads(result) if isinstance(result, str) else result
                if data.get("success"):
                    st.success(f"Investment successful! Units: {data.get('units')}")
                    st.balloons()
                else:
                    st.error(data.get("error"))
        else:
            st.info("No pools currently open for investment")
            
    except Exception as e:
        st.error(f"Error: {e}")


def pool_analytics_page():
    """RMBS pool analytics for investors."""
    st.header("Pool Analytics")
    
    try:
        # Pool performance
        pools_df = session.sql(f"""
            SELECT 
                POOL_ID, NAME, LOAN_COUNT, 
                TOTAL_VALUE / 10000000 AS VALUE_CR,
                STATUS
            FROM {DB_SCHEMA}.RMBS_POOLS
            ORDER BY POOL_ID DESC
        """).to_pandas()
        
        st.subheader("Pool Overview")
        st.dataframe(pools_df, use_container_width=True)
        
        # Loan quality in pools
        st.subheader("Loan Quality Analysis")
        quality_df = session.sql(f"""
            SELECT 
                ASSIGNED_POOL_ID AS POOL,
                COUNT(*) AS LOANS,
                ROUND(AVG(CREDIT_SCORE), 0) AS AVG_SCORE,
                SUM(AMOUNT) / 100000 AS TOTAL_LAKHS
            FROM {DB_SCHEMA}.RMBS_ELIGIBLE_LOANS
            WHERE ASSIGNED_POOL_ID IS NOT NULL
            GROUP BY ASSIGNED_POOL_ID
            ORDER BY ASSIGNED_POOL_ID
        """).to_pandas()
        
        if not quality_df.empty:
            st.dataframe(quality_df, use_container_width=True)
            
    except Exception as e:
        st.error(f"Error: {e}")


def admin_dashboard_page():
    """Admin dashboard with system overview."""
    st.header("Admin Dashboard")
    
    # System stats
    col1, col2, col3, col4 = st.columns(4)
    
    try:
        stats = session.sql(f"""
            SELECT 
                (SELECT COUNT(*) FROM {DB_SCHEMA}.BORROWERS) AS borrowers,
                (SELECT COUNT(*) FROM {DB_SCHEMA}.LOANS) AS loans,
                (SELECT COUNT(DISTINCT POOL_ID) FROM {DB_SCHEMA}.RMBS_POOLS) AS pools,
                (SELECT COUNT(*) FROM {DB_SCHEMA}.AUDIT_LOG WHERE TIMESTAMP >= DATEADD(DAY, -1, CURRENT_TIMESTAMP())) AS audit_today
        """).collect()[0]
        
        col1.metric("Total Borrowers", stats[0])
        col2.metric("Total Loans", stats[1])
        col3.metric("RMBS Pools", stats[2])
        col4.metric("Audit Events (24h)", stats[3])
        
    except Exception as e:
        col1.metric("Total Borrowers", "N/A")
    
    # Quick actions
    st.subheader("Quick Actions")
    col1, col2, col3 = st.columns(3)
    
    with col1:
        if st.button("Run Pool Assignment"):
            try:
                session.sql(f"CALL {DB_SCHEMA}.ASSIGN_LOANS_TO_POOLS()").collect()
                st.success("Pool assignment completed!")
            except Exception as e:
                st.error(f"Error: {e}")
    
    with col2:
        if st.button("Refresh Dynamic Tables"):
            try:
                session.sql(f"ALTER DYNAMIC TABLE {DB_SCHEMA}.BORROWER_ELIGIBILITY_STATUS REFRESH").collect()
                session.sql(f"ALTER DYNAMIC TABLE {DB_SCHEMA}.RMBS_ELIGIBLE_LOANS REFRESH").collect()
                st.success("Dynamic tables refreshed!")
            except Exception as e:
                st.error(f"Error: {e}")


def user_management_page():
    """User management for admins."""
    st.header("User Management")
    st.info("User management interface - allows creating and managing user accounts with role-based access")
    
    # Show existing users
    try:
        users_df = session.sql(f"""
            SELECT USER_ID, USER_TYPE, EMAIL, ORGANIZATION, IS_ACTIVE, CREATED_AT
            FROM {DB_SCHEMA}.USER_ROLES
            ORDER BY CREATED_AT DESC
        """).to_pandas()
        
        if not users_df.empty:
            st.dataframe(users_df, use_container_width=True)
        else:
            st.info("No users registered yet")
            
    except Exception as e:
        st.info("User roles table is empty")


# ============================================
# EMI PAYMENT TRACKING
# ============================================

def emi_payments_page():
    """EMI payment tracking for borrowers."""
    st.header("EMI Payments")
    
    aadhaar_id = st.text_input("Your Aadhaar Number", max_chars=12, placeholder="123456789012")
    
    if aadhaar_id and len(aadhaar_id) == 12:
        try:
            # Get loans for this borrower
            loans_df = session.sql(f"""
                SELECT LOAN_ID, AMOUNT / 100000 AS AMOUNT_LAKHS, 
                       ROUND(INTEREST_RATE * 100, 2) AS RATE,
                       TENURE_MONTHS, STATUS
                FROM {DB_SCHEMA}.LOANS
                WHERE BORROWER_ID = '{aadhaar_id}'
                ORDER BY CREATED_AT DESC
            """).to_pandas()
            
            if loans_df.empty:
                st.info("No loans found for this Aadhaar")
                return
            
            st.subheader("Your Loans")
            st.dataframe(loans_df, use_container_width=True)
            
            # Select loan for EMI view
            selected_loan = st.selectbox("Select Loan", loans_df["LOAN_ID"].tolist())
            
            # Generate amortization if not exists
            amort_count = session.sql(f"""
                SELECT COUNT(*) FROM {DB_SCHEMA}.LOAN_AMORTIZATION WHERE LOAN_ID = '{selected_loan}'
            """).collect()[0][0]
            
            if amort_count == 0:
                if st.button("Generate EMI Schedule"):
                    result = session.sql(f"CALL {DB_SCHEMA}.GENERATE_AMORTIZATION_SCHEDULE('{selected_loan}')").collect()[0][0]
                    data = json.loads(result) if isinstance(result, str) else result
                    if data.get("success"):
                        st.success(f"Schedule generated! Monthly EMI: Rs.{data.get('monthly_emi'):,.0f}")
                        st.rerun()
                    else:
                        st.error(data.get("error"))
            else:
                # Show amortization schedule
                st.subheader("EMI Schedule")
                schedule_df = session.sql(f"""
                    SELECT 
                        A.EMI_NUMBER, A.DUE_DATE, 
                        A.OPENING_BALANCE, A.EMI_AMOUNT,
                        A.PRINCIPAL_COMPONENT, A.INTEREST_COMPONENT, A.CLOSING_BALANCE,
                        COALESCE(P.PAYMENT_STATUS, 'PENDING') AS STATUS
                    FROM {DB_SCHEMA}.LOAN_AMORTIZATION A
                    LEFT JOIN {DB_SCHEMA}.EMI_PAYMENTS P 
                        ON A.LOAN_ID = P.LOAN_ID AND A.EMI_NUMBER = P.EMI_NUMBER
                    WHERE A.LOAN_ID = '{selected_loan}'
                    ORDER BY A.EMI_NUMBER
                """).to_pandas()
                
                st.dataframe(schedule_df, use_container_width=True)
                
                # Pay EMI form
                st.subheader("Record EMI Payment")
                pending_emis = schedule_df[schedule_df["STATUS"] == "PENDING"]["EMI_NUMBER"].tolist()
                
                if pending_emis:
                    emi_to_pay = st.selectbox("EMI Number", pending_emis)
                    emi_row = schedule_df[schedule_df["EMI_NUMBER"] == emi_to_pay].iloc[0]
                    
                    st.info(f"EMI Amount Due: Rs.{emi_row['EMI_AMOUNT']:,.2f}")
                    
                    payment_mode = st.selectbox("Payment Mode", ["NACH", "UPI", "NEFT", "CHEQUE"])
                    txn_ref = st.text_input("Transaction Reference")
                    
                    if st.button("Record Payment", type="primary"):
                        result = session.sql(f"""
                            CALL {DB_SCHEMA}.RECORD_EMI_PAYMENT(
                                '{selected_loan}', {emi_to_pay}, {emi_row['EMI_AMOUNT']}, 
                                '{payment_mode}', '{txn_ref}'
                            )
                        """).collect()[0][0]
                        data = json.loads(result) if isinstance(result, str) else result
                        if data.get("success"):
                            st.success("Payment recorded successfully!")
                            st.balloons()
                            st.rerun()
                        else:
                            st.error(data.get("error"))
                else:
                    st.success("All EMIs paid for this schedule period!")
                    
        except Exception as e:
            st.error(f"Error: {e}")


def notifications_page():
    """Notifications for borrowers."""
    st.header("Notifications")
    
    aadhaar_id = st.text_input("Your Aadhaar Number", max_chars=12, placeholder="123456789012", key="notif_aadhaar")
    
    if aadhaar_id and len(aadhaar_id) == 12:
        try:
            result = session.sql(f"CALL {DB_SCHEMA}.GET_USER_NOTIFICATIONS('{aadhaar_id}')").collect()[0][0]
            data = json.loads(result) if isinstance(result, str) else result
            
            unread = data.get("unread_count", 0)
            notifications = data.get("notifications", [])
            
            st.metric("Unread Notifications", unread)
            
            if notifications:
                for notif in notifications:
                    with st.expander(f"{'🔔' if not notif.get('is_read') else '✓'} {notif.get('title')}"):
                        st.write(notif.get("message"))
                        st.caption(f"Type: {notif.get('type')} | {notif.get('created_at')}")
                        
                        if not notif.get("is_read"):
                            if st.button("Mark as Read", key=notif.get("id")):
                                session.sql(f"CALL {DB_SCHEMA}.MARK_NOTIFICATION_READ('{notif.get('id')}')").collect()
                                st.rerun()
            else:
                st.info("No notifications yet")
                
        except Exception as e:
            st.error(f"Error: {e}")


def platform_report_page():
    """Platform report for originators and admins."""
    st.header("Platform Report")
    
    try:
        result = session.sql(f"CALL {DB_SCHEMA}.GENERATE_PLATFORM_REPORT()").collect()[0][0]
        data = json.loads(result) if isinstance(result, str) else result
        
        st.subheader(f"Report Date: {data.get('report_date')}")
        
        # Borrower Stats
        st.markdown("### Borrower Statistics")
        borrower_stats = data.get("borrower_stats", {})
        col1, col2, col3, col4 = st.columns(4)
        col1.metric("Total Borrowers", borrower_stats.get("total", 0))
        col2.metric("KYC Verified", borrower_stats.get("kyc_verified", 0))
        col3.metric("Avg Credit Score", borrower_stats.get("avg_credit_score", 0))
        col4.metric("Prime Borrowers", borrower_stats.get("prime_borrowers", 0))
        
        # Loan Stats
        st.markdown("### Loan Statistics")
        loan_stats = data.get("loan_stats", {})
        col1, col2, col3 = st.columns(3)
        col1.metric("Total Loans", loan_stats.get("total_loans", 0))
        col2.metric("Portfolio Value", f"Rs.{(loan_stats.get('portfolio_value') or 0) / 10000000:.1f}Cr")
        col3.metric("Avg Rate", f"{loan_stats.get('avg_rate', 0)}%")
        
        # Pool Stats
        st.markdown("### RMBS Pool Statistics")
        pool_stats = data.get("pool_stats", {})
        col1, col2, col3 = st.columns(3)
        col1.metric("Total Pools", pool_stats.get("total_pools", 0))
        col2.metric("Securitized Value", f"Rs.{(pool_stats.get('securitized_value') or 0) / 10000000:.1f}Cr")
        col3.metric("Investors", pool_stats.get("investors", 0))
        
    except Exception as e:
        st.error(f"Error generating report: {e}")


# Page routing
if page == "eKYC Verification":
    ekyc_verification_page()
elif page == "Eligibility Check":
    eligibility_check_page()
elif page == "Apply for Loan":
    apply_for_loan_page()
elif page == "Rate Comparison":
    rate_comparison_page()
elif page == "My Applications":
    applications_page()
elif page == "EMI Payments":
    emi_payments_page()
elif page == "Notifications":
    notifications_page()
elif page == "Document Upload":
    document_upload_page()
elif page == "Originator Dashboard":
    originator_dashboard_page()
elif page == "Loan Approvals":
    loan_approvals_page()
elif page == "Document Verification":
    document_verification_page()
elif page == "All Borrowers":
    all_borrowers_page()
elif page == "Audit Log":
    audit_log_page()
elif page == "Platform Report":
    platform_report_page()
elif page == "Investor Portal":
    investor_portal_page()
elif page == "Pool Analytics":
    pool_analytics_page()
elif page == "Admin Dashboard":
    admin_dashboard_page()
elif page == "User Management":
    user_management_page()
elif page == "RMBS Dashboard":
    rmbs_dashboard_page()

# Footer
st.markdown("---")
st.caption(f"Housing for All Platform | {user_role} View | Powered by Snowflake Native Apps")
