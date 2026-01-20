from dataclasses import dataclass
from typing import Optional, List
import json


@dataclass
class AadhaarVerificationResult:
    aadhaar_id: str
    is_valid: bool
    name: Optional[str]
    date_of_birth: Optional[str]
    gender: Optional[str]
    error_message: Optional[str]


@dataclass 
class Document:
    doc_type: str
    doc_number: Optional[str]
    issuer: Optional[str]
    status: str
    metadata: Optional[dict]


@dataclass
class DigiLockerResult:
    aadhaar_id: str
    holder_name: Optional[str]
    documents: List[Document]
    error_message: Optional[str]


@dataclass
class KYCResult:
    kyc_status: str  # PASSED, FAILED, INCOMPLETE
    aadhaar_verified: bool
    holder_name: Optional[str]
    date_of_birth: Optional[str]
    has_pan: bool
    has_income_proof: bool
    missing_documents: List[str]
    error_message: Optional[str]


def validate_aadhaar(session, aadhaar_id: str) -> AadhaarVerificationResult:
    """
    Validate Aadhaar ID against mock UIDAI registry in Snowflake.
    
    Args:
        session: Snowflake session/connection
        aadhaar_id: 12-digit Aadhaar number
    
    Returns:
        AadhaarVerificationResult with validation status and details
    """
    # Client-side format validation
    if not aadhaar_id or len(aadhaar_id) != 12 or not aadhaar_id.isdigit():
        return AadhaarVerificationResult(
            aadhaar_id=aadhaar_id,
            is_valid=False,
            name=None,
            date_of_birth=None,
            gender=None,
            error_message="Invalid Aadhaar format: must be 12 digits",
        )
    
    # Call Snowflake stored procedure
    result = session.call("CORE.VERIFY_AADHAAR", aadhaar_id)
    
    if isinstance(result, str):
        result = json.loads(result)
    
    if not result.get("success"):
        return AadhaarVerificationResult(
            aadhaar_id=aadhaar_id,
            is_valid=False,
            name=None,
            date_of_birth=None,
            gender=None,
            error_message=result.get("error_message", "Verification failed"),
        )
    
    return AadhaarVerificationResult(
        aadhaar_id=aadhaar_id,
        is_valid=True,
        name=result.get("name"),
        date_of_birth=str(result.get("date_of_birth")),
        gender=result.get("gender"),
        error_message=None,
    )


def fetch_digilocker_documents(session, aadhaar_id: str, doc_type: str = None) -> DigiLockerResult:
    """
    Fetch documents from mock DigiLocker registry in Snowflake.
    
    Args:
        session: Snowflake session/connection
        aadhaar_id: 12-digit Aadhaar number
        doc_type: Optional filter for specific document type
    
    Returns:
        DigiLockerResult with documents list
    """
    # Call Snowflake stored procedure
    if doc_type:
        result = session.call("CORE.FETCH_DIGILOCKER_DOCUMENTS", aadhaar_id, doc_type)
    else:
        result = session.call("CORE.FETCH_DIGILOCKER_DOCUMENTS", aadhaar_id)
    
    if isinstance(result, str):
        result = json.loads(result)
    
    if not result.get("success"):
        return DigiLockerResult(
            aadhaar_id=aadhaar_id,
            holder_name=None,
            documents=[],
            error_message=result.get("error_message", "Failed to fetch documents"),
        )
    
    documents = []
    for doc in result.get("documents", []):
        documents.append(Document(
            doc_type=doc.get("doc_type"),
            doc_number=doc.get("doc_number"),
            issuer=doc.get("issuer"),
            status=doc.get("status"),
            metadata=doc.get("metadata"),
        ))
    
    return DigiLockerResult(
        aadhaar_id=aadhaar_id,
        holder_name=result.get("holder_name"),
        documents=documents,
        error_message=None,
    )


def perform_kyc_check(session, aadhaar_id: str) -> KYCResult:
    """
    Perform complete KYC verification using mock UIDAI and DigiLocker.
    
    Args:
        session: Snowflake session/connection
        aadhaar_id: 12-digit Aadhaar number
    
    Returns:
        KYCResult with complete verification status
    """
    # Call combined KYC procedure
    result = session.call("CORE.PERFORM_KYC_CHECK", aadhaar_id)
    
    if isinstance(result, str):
        result = json.loads(result)
    
    if result.get("kyc_status") == "FAILED":
        return KYCResult(
            kyc_status="FAILED",
            aadhaar_verified=False,
            holder_name=None,
            date_of_birth=None,
            has_pan=False,
            has_income_proof=False,
            missing_documents=[],
            error_message=result.get("error"),
        )
    
    return KYCResult(
        kyc_status=result.get("kyc_status"),
        aadhaar_verified=result.get("aadhaar_verified", False),
        holder_name=result.get("holder_name"),
        date_of_birth=str(result.get("date_of_birth")) if result.get("date_of_birth") else None,
        has_pan=result.get("has_pan", False),
        has_income_proof=result.get("has_income_proof", False),
        missing_documents=result.get("missing_documents", []),
        error_message=None,
    )
