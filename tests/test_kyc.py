import pytest
from src.kyc.aadhaar import validate_aadhaar, AadhaarVerificationResult


class TestValidateAadhaar:
    def test_valid_aadhaar_passes(self):
        result = validate_aadhaar("123456789012")
        assert result.is_valid is True
        assert result.aadhaar_id == "123456789012"

    def test_invalid_aadhaar_format_fails(self):
        result = validate_aadhaar("12345")  # Too short
        assert result.is_valid is False
        assert result.error_message is not None

    def test_mock_aadhaar_returns_name_and_dob(self):
        result = validate_aadhaar("123456789012")
        assert result.name is not None
        assert result.date_of_birth is not None
