from dataclasses import dataclass
from typing import Optional
import os

UIDAI_API_URL = os.getenv("UIDAI_API_URL", "https://mock-uidai.example.com/api/v1")


@dataclass
class AadhaarVerificationResult:
    aadhaar_id: str
    is_valid: bool
    name: Optional[str]
    date_of_birth: Optional[str]
    error_message: Optional[str]


def validate_aadhaar(aadhaar_id: str) -> AadhaarVerificationResult:
    raise NotImplementedError("Feature: validate_aadhaar")


def fetch_digilocker_documents(aadhaar_id: str) -> dict:
    raise NotImplementedError("Feature: fetch_digilocker_documents")
