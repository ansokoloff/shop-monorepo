import pytest
from src.worker import process_job

def test_process_job_success():
    result = process_job({"id": "123"})
    assert result["status"] == "processed"

def test_process_job_missing_id():
    with pytest.raises(ValueError):
        process_job({})
