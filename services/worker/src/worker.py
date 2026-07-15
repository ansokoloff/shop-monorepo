def process_job(job: dict) -> dict:
    if "id" not in job:
        raise ValueError("Job must have an id")
    return {"job_id": job["id"], "status": "processed"}
