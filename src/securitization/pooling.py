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
    raise NotImplementedError("Feature: assign_rmbs_pool")


def calculate_pool_eligible_date(disbursement_date: date) -> date:
    raise NotImplementedError("Feature: calculate_pool_eligible_date")


def get_pool_for_date(eligible_date: date) -> RMBSPool:
    raise NotImplementedError("Feature: get_pool_for_date")
