import pytest
from datetime import date
from src.securitization.pooling import (
    assign_rmbs_pool,
    calculate_pool_eligible_date,
    Loan,
    MHP_MONTHS,
)


class TestCalculatePoolEligibleDate:
    def test_mhp_adds_six_months(self):
        disbursement = date(2026, 1, 19)
        eligible_date = calculate_pool_eligible_date(disbursement)
        assert eligible_date == date(2026, 7, 19)

    def test_mhp_handles_month_overflow(self):
        disbursement = date(2026, 8, 31)
        eligible_date = calculate_pool_eligible_date(disbursement)
        assert eligible_date.year == 2027
        assert eligible_date.month == 2


class TestAssignRMBSPool:
    def test_loan_after_mhp_gets_pool(self):
        loan = Loan(
            loan_id="LOAN001",
            borrower_id="BORR001",
            amount=5000000,
            disbursement_date=date(2025, 6, 1),
        )
        updated_loan, pool_name = assign_rmbs_pool(loan, reference_date=date(2026, 1, 19))
        assert updated_loan.pool_id is not None
        assert pool_name is not None

    def test_loan_before_mhp_not_assigned(self):
        loan = Loan(
            loan_id="LOAN002",
            borrower_id="BORR002",
            amount=5000000,
            disbursement_date=date(2025, 12, 1),  # Less than 6 months ago
        )
        updated_loan, pool_name = assign_rmbs_pool(loan, reference_date=date(2026, 1, 19))
        assert updated_loan.pool_id is None
