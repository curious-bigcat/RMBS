from dataclasses import dataclass
from datetime import date
from dateutil.relativedelta import relativedelta
from typing import Optional

MHP_MONTHS = 6


@dataclass
class Loan:
    loan_id: str
    borrower_id: str
    amount: float
    disbursement_date: date
    pool_id: Optional[str] = None
    pool_eligible_date: Optional[date] = None


@dataclass
class RMBSPool:
    pool_id: str
    name: str
    aggregation_date: date
    trustee: str


def assign_rmbs_pool(loan: Loan, reference_date: date = None) -> tuple[Loan, Optional[str]]:
    if reference_date is None:
        reference_date = date.today()
    
    eligible_date = calculate_pool_eligible_date(loan.disbursement_date)
    loan.pool_eligible_date = eligible_date
    
    # Check if MHP has been met
    if reference_date >= eligible_date:
        pool = get_pool_for_date(eligible_date)
        loan.pool_id = pool.pool_id
        return loan, pool.name
    
    # Not yet eligible
    return loan, None


def calculate_pool_eligible_date(disbursement_date: date) -> date:
    return disbursement_date + relativedelta(months=MHP_MONTHS)


def get_pool_for_date(eligible_date: date) -> RMBSPool:
    # Generate pool based on quarter
    quarter = (eligible_date.month - 1) // 3 + 1
    pool_id = f"RMBS-{eligible_date.year}-Q{quarter}"
    return RMBSPool(
        pool_id=pool_id,
        name=f"Housing Pool {eligible_date.year} Q{quarter}",
        aggregation_date=eligible_date,
        trustee="India Housing Trust",
    )
