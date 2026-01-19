

# `agents.md`: Housing for All Platform

## 1. Project Overview

The **Housing for All Platform** is a digital mortgage marketplace for India. Its primary goals are to standardize loan origination (Aadhaar/DigiLocker based), improve credit quality via automated screening, and enable the creation of securitization-ready Residential Mortgage-Backed Securities (RMBS).

### Stakeholders

* **Borrower**: Individual applicants seeking digital loan certification and competitive offers.
* **Originators (Lenders)**: HFCs, Banks, and NBFCs providing pre-approved digital offers.
* **Trustee Company**: Appointed to oversee finalized RMBS pools.

---

## 2. Technical Requirements

### Borrower Eligibility (Rule Engine)

* **Credit Score**: Minimum 750 required for eligibility.
* **Age Bracket**: 25–50 years.
* **Debt-to-Income (DTI)**: Maximum 50%.
* **KYC**: Aadhaar-based e-KYC and DigiLocker integration.

### Securitization Workflow

* **MHP (Minimum Holding Period)**: 6 months.
* **Aggregation**: Automatic mapping to RMBS pools (e.g., "Pool A – June 2026") based on loan characteristics.

---

## 3. Implementation Pattern: Long-Running Agents

We use a two-agent scaffolding harness to bridge coding sessions and prevent context drift.

### Harness Components

* **`feature_list.json`**: A master list of all functional features (KYC, DTI checks, pooling). All features are initially marked as "failing".
* **`progress.txt`**: A persistent session log where each agent records decisions, implementation notes, and hand-off details for the next run.
* **Git Integration**: Each session concludes with a commit. The commit history acts as the agent's long-term memory.

---

## 4. Local Project Directory Structure

Before execution, the following files will be created in the local root:

```text
/housing-platform
├── agents.md             # This project definition
├── feature_list.json     # Feature checklist (status: failing)
├── progress.txt          # Shared state/session log
├── .env                  # Environment keys (e.g., UIDAI/DigiLocker API stubs)
├── src/
│   ├── rules/            # Eligibility rule engine logic (Credit Score, DTI)
│   ├── kyc/              # Aadhaar/e-KYC integration tools
│   ├── marketplace/      # Discovery and bidding logic
│   └── securitization/   # Pooling and MHP tracking logic
└── tests/                # Unit tests for rule validation

```

---

## 5. Development Steps (Indicative Agent Workflow)

### Turn 1: Initializer Agent

1. **Environment Setup**: Creates the directory structure above.
2. **Scaffolding**: Writes the `feature_list.json` with features like `validate_aadhaar`, `calculate_dti`, and `assign_rmbs_pool`.
3. **Git Init**: Initializes the local repository and makes the first commit.

### Turn 2+: Coding Agent

1. **Bearing Step**: Reads `progress.txt` and `git log` to get up to speed.
2. **Implementation**: Selects exactly **one** failing feature (e.g., `calculate_dti`).
3. **Testing**: Writes and executes unit tests for the rule: `DTI = Total Monthly Liabilities / Monthly Income <= 50%`.
4. **Handoff**: Commits code, marks the feature as "passing" in the JSON file, and updates the progress log.

---

## 6. Indications of Done (DoD)

* [ ] **Eligibility Engine**: Correctly issues certificates for CIBIL 750+, Age 25-50, DTI < 50%.
* [ ] **API Mocking**: Successful simulated Aadhaar e-KYC validation.
* [ ] **RMBS Pool Logic**: Loans disbursed today are correctly flagged for pooling exactly 6 months later.