import pytest
from unittest.mock import MagicMock
from src.kyc.aadhaar import (
    validate_aadhaar,
    fetch_digilocker_documents,
    perform_kyc_check,
    AadhaarVerificationResult,
    DigiLockerResult,
    KYCResult,
)


class MockSession:
    """Mock Snowflake session for testing."""
    
    def __init__(self, responses: dict = None):
        self.responses = responses or {}
        self.calls = []
    
    def call(self, procedure: str, *args):
        self.calls.append((procedure, args))
        return self.responses.get(procedure, {})


class TestValidateAadhaar:
    def test_invalid_aadhaar_format_too_short(self):
        session = MockSession()
        result = validate_aadhaar(session, "12345")
        assert result.is_valid is False
        assert "12 digits" in result.error_message

    def test_invalid_aadhaar_format_non_numeric(self):
        session = MockSession()
        result = validate_aadhaar(session, "12345678901a")
        assert result.is_valid is False
        assert "12 digits" in result.error_message

    def test_valid_aadhaar_calls_procedure(self):
        session = MockSession(responses={
            "CORE.VERIFY_AADHAAR": {
                "success": True,
                "aadhaar_id": "123456789012",
                "name": "Priya Sharma",
                "date_of_birth": "1990-05-15",
                "gender": "F",
            }
        })
        result = validate_aadhaar(session, "123456789012")
        
        assert result.is_valid is True
        assert result.name == "Priya Sharma"
        assert result.gender == "F"
        assert ("CORE.VERIFY_AADHAAR", ("123456789012",)) in session.calls

    def test_aadhaar_not_found(self):
        session = MockSession(responses={
            "CORE.VERIFY_AADHAAR": {
                "success": False,
                "error_code": "NOT_FOUND",
                "error_message": "Aadhaar not found in registry",
            }
        })
        result = validate_aadhaar(session, "999888777666")
        
        assert result.is_valid is False
        assert "not found" in result.error_message


class TestFetchDigilockerDocuments:
    def test_fetch_documents_success(self):
        session = MockSession(responses={
            "CORE.FETCH_DIGILOCKER_DOCUMENTS": {
                "success": True,
                "aadhaar_id": "123456789012",
                "holder_name": "Priya Sharma",
                "document_count": 3,
                "documents": [
                    {"doc_type": "AADHAAR", "doc_number": "123456789012", "issuer": "UIDAI", "status": "VERIFIED", "metadata": {}},
                    {"doc_type": "PAN", "doc_number": "ABCDE1234F", "issuer": "Income Tax Dept", "status": "VERIFIED", "metadata": {}},
                    {"doc_type": "FORM_16", "doc_number": "F16-2024", "issuer": "TCS Ltd", "status": "VERIFIED", "metadata": {}},
                ],
            }
        })
        result = fetch_digilocker_documents(session, "123456789012")
        
        assert result.error_message is None
        assert result.holder_name == "Priya Sharma"
        assert len(result.documents) == 3
        assert result.documents[1].doc_type == "PAN"

    def test_fetch_documents_invalid_aadhaar(self):
        session = MockSession(responses={
            "CORE.FETCH_DIGILOCKER_DOCUMENTS": {
                "success": False,
                "error_code": "AADHAAR_INVALID",
                "error_message": "Aadhaar not found in registry",
            }
        })
        result = fetch_digilocker_documents(session, "999888777666")
        
        assert result.error_message is not None
        assert len(result.documents) == 0


class TestPerformKYCCheck:
    def test_kyc_passed_with_all_documents(self):
        session = MockSession(responses={
            "CORE.PERFORM_KYC_CHECK": {
                "kyc_status": "PASSED",
                "aadhaar_verified": True,
                "holder_name": "Priya Sharma",
                "date_of_birth": "1990-05-15",
                "has_pan": True,
                "has_income_proof": True,
                "missing_documents": [],
            }
        })
        result = perform_kyc_check(session, "123456789012")
        
        assert result.kyc_status == "PASSED"
        assert result.aadhaar_verified is True
        assert result.has_pan is True
        assert result.has_income_proof is True
        assert len(result.missing_documents) == 0

    def test_kyc_incomplete_missing_pan(self):
        session = MockSession(responses={
            "CORE.PERFORM_KYC_CHECK": {
                "kyc_status": "INCOMPLETE",
                "aadhaar_verified": True,
                "holder_name": "Test User",
                "date_of_birth": "1990-01-01",
                "has_pan": False,
                "has_income_proof": False,
                "missing_documents": ["PAN", "Income Proof (Form 16 or ITR)"],
            }
        })
        result = perform_kyc_check(session, "567890123456")
        
        assert result.kyc_status == "INCOMPLETE"
        assert result.has_pan is False
        assert "PAN" in result.missing_documents

    def test_kyc_failed_invalid_aadhaar(self):
        session = MockSession(responses={
            "CORE.PERFORM_KYC_CHECK": {
                "kyc_status": "FAILED",
                "stage": "AADHAAR_VERIFICATION",
                "error": "Aadhaar not found in registry",
            }
        })
        result = perform_kyc_check(session, "999888777666")
        
        assert result.kyc_status == "FAILED"
        assert result.aadhaar_verified is False
        assert result.error_message is not None
