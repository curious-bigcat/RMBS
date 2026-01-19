import pytest
from datetime import date
from src.rules.eligibility import (
    validate_credit_score,
    validate_age,
    calculate_dti,
    issue_eligibility_certificate,
    Borrower,
    MIN_CREDIT_SCORE,
    MIN_AGE,
    MAX_AGE,
    MAX_DTI_RATIO,
)


class TestValidateCreditScore:
    def test_score_above_threshold_passes(self):
        is_valid, reason = validate_credit_score(800)
        assert is_valid is True
        assert reason is None

    def test_score_at_threshold_passes(self):
        is_valid, reason = validate_credit_score(750)
        assert is_valid is True
        assert reason is None

    def test_score_below_threshold_fails(self):
        is_valid, reason = validate_credit_score(700)
        assert is_valid is False
        assert reason is not None


class TestValidateAge:
    def test_age_within_range_passes(self):
        dob = date(1990, 1, 1)
        is_valid, reason = validate_age(dob, reference_date=date(2026, 1, 19))
        assert is_valid is True

    def test_age_below_minimum_fails(self):
        dob = date(2005, 1, 1)  # 21 years old
        is_valid, reason = validate_age(dob, reference_date=date(2026, 1, 19))
        assert is_valid is False

    def test_age_above_maximum_fails(self):
        dob = date(1970, 1, 1)  # 56 years old
        is_valid, reason = validate_age(dob, reference_date=date(2026, 1, 19))
        assert is_valid is False


class TestCalculateDTI:
    def test_dti_below_threshold_passes(self):
        dti, is_valid, reason = calculate_dti(100000, 40000)
        assert dti == 0.40
        assert is_valid is True

    def test_dti_at_threshold_passes(self):
        dti, is_valid, reason = calculate_dti(100000, 50000)
        assert dti == 0.50
        assert is_valid is True

    def test_dti_above_threshold_fails(self):
        dti, is_valid, reason = calculate_dti(100000, 60000)
        assert dti == 0.60
        assert is_valid is False


class TestIssueEligibilityCertificate:
    def test_eligible_borrower_gets_certificate(self):
        borrower = Borrower(
            aadhaar_id="123456789012",
            name="Test User",
            date_of_birth=date(1990, 5, 15),
            monthly_income=100000,
            monthly_liabilities=30000,
            credit_score=800,
        )
        cert = issue_eligibility_certificate(borrower)
        assert cert.is_eligible is True
        assert len(cert.rejection_reasons) == 0

    def test_ineligible_borrower_gets_rejection(self):
        borrower = Borrower(
            aadhaar_id="123456789012",
            name="Test User",
            date_of_birth=date(1990, 5, 15),
            monthly_income=100000,
            monthly_liabilities=30000,
            credit_score=600,  # Below threshold
        )
        cert = issue_eligibility_certificate(borrower)
        assert cert.is_eligible is False
        assert len(cert.rejection_reasons) > 0
