To implement the **Housing for All Platform** using **Snowflake native components**, you can leverage the **Snowflake Native App Framework**, **Cortex AI**, **Dynamic Tables**, and **Streamlit**. This approach ensures all data processing, credit scoring, and RMBS pooling occur securely within Snowflake's governed environment.

### Snowflake Native Architecture

The platform can be built as a **Snowflake Native App**, which bundles business logic (Python/SQL) and UI (Streamlit) into a deployable package.

* **Borrower Eligibility (Cortex AI & External Functions):**
* Use **Cortex AI** (Data Science Agent) to build and validate credit risk models for "soft" credit checks.
* Implement **External Functions** with **External Network Access** to securely validate **Aadhaar** identities and fetch **DigiLocker** documents via third-party APIs.


* **Loan Origination (Streamlit):**
* Build an interactive **Streamlit** dashboard for borrowers to compare "Market Rates" vs. "Platform Rates" and track application milestones.


* **Securitization & RMBS (Dynamic Tables & Streams):**
* Use **Dynamic Tables** to declaratively define **RMBS pools**. These tables can automatically aggregate loans that meet specific criteria (e.g., Credit Score > 750) as soon as the **6-month MHP** is met.
* **Snowflake Streams and Tasks** can trigger automated notifications or update "RMBS Eligible" certificates when borrower data changes.



### Implementation Plan (Long-Running Agent Pattern)

The `agents.md` file will guide the development process using a state-managed harness to maintain progress across sessions.

#### `agents.md`: Housing for All (Native Implementation)

* **Initialization (Turn 1):**
* Create `feature_list.json` with features like `Setup_Native_App_Package`, `Aadhaar_API_Integration`, and `RMBS_Dynamic_Pool_Logic`.
* Generate `init.sh` to provision the Snowflake database, application package, and stages.


* **Development (Turns 2+):**
* **Bearing Protocol:** The agent reads `progress.txt` to resume the specific task, such as coding the **Cortex Analyst** semantic model for borrower inquiries.
* **Deployment:** Use the **Snowflake CLI** (`snow native-app deploy`) to sync local code to Snowflake stages and upgrade the application version.



### Project Structure

| File/Directory | Description |
| --- | --- |
| **`snowflake.yml`** | Project definition for Snowflake CLI to manage the Native App. |
| **`manifest.yml`** | Metadata and permission requirements (e.g., `EXTERNAL_ACCESS`). |
| **`setup.sql`** | Script to create procedures, functions, and dynamic tables upon installation. |
| **`streamlit_app.py`** | The front-end marketplace for borrowers and originators. |
