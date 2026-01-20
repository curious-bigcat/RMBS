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
    if score >= MIN_CREDIT_SCORE:
        return True, None
    return False, f"Credit score {score} is below minimum threshold of {MIN_CREDIT_SCORE}"


def validate_age(dob: date, reference_date: date = None) -> tuple[bool, Optional[str]]:
    from dateutil.relativedelta import relativedelta
    if reference_date is None:
        reference_date = date.today()
    age = relativedelta(reference_date, dob).years
    if age < MIN_AGE:
        return False, f"Borrower age {age} is below minimum of {MIN_AGE} years"
    if age > MAX_AGE:
        return False, f"Borrower age {age} exceeds maximum of {MAX_AGE} years"
    return True, None


def calculate_dti(monthly_income: float, monthly_liabilities: float) -> tuple[float, bool, Optional[str]]:
    if monthly_income <= 0:
        return 0.0, False, "Monthly income must be positive"
    dti = monthly_liabilities / monthly_income
    if dti <= MAX_DTI_RATIO:
        return dti, True, None
    return dti, False, f"DTI ratio {dti:.0%} exceeds maximum of {MAX_DTI_RATIO:.0%}"


def issue_eligibility_certificate(borrower: Borrower) -> EligibilityCertificate:
    rejection_reasons = []
    
    credit_valid, credit_reason = validate_credit_score(borrower.credit_score)
    if not credit_valid:
        rejection_reasons.append(credit_reason)
    
    age_valid, age_reason = validate_age(borrower.date_of_birth)
    if not age_valid:
        rejection_reasons.append(age_reason)
    
    _, dti_valid, dti_reason = calculate_dti(borrower.monthly_income, borrower.monthly_liabilities)
    if not dti_valid:
        rejection_reasons.append(dti_reason)
    
    is_eligible = len(rejection_reasons) == 0
    
    return EligibilityCertificate(
        borrower_id=borrower.aadhaar_id,
        is_eligible=is_eligible,
        issued_date=date.today(),
        rejection_reasons=rejection_reasons,
    )
