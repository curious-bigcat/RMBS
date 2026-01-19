from dataclasses import dataclass
from datetime import date
from typing import Optional

MIN_CREDIT_SCORE = 750
MIN_AGE = 25
MAX_AGE = 50
MAX_DTI_RATIO = 0.50


@dataclass
class Borrower:
    aadhaar_id: str
    name: str
    date_of_birth: date
    monthly_income: float
    monthly_liabilities: float
    credit_score: int


@dataclass
class EligibilityCertificate:
    borrower_id: str
    is_eligible: bool
    issued_date: date
    rejection_reasons: list[str]


def validate_credit_score(score: int) -> tuple[bool, Optional[str]]:
    raise NotImplementedError("Feature: validate_credit_score")


def validate_age(dob: date, reference_date: date = None) -> tuple[bool, Optional[str]]:
    raise NotImplementedError("Feature: validate_age")


def calculate_dti(monthly_income: float, monthly_liabilities: float) -> tuple[float, bool, Optional[str]]:
    raise NotImplementedError("Feature: calculate_dti")


def issue_eligibility_certificate(borrower: Borrower) -> EligibilityCertificate:
    raise NotImplementedError("Feature: issue_eligibility_certificate")
