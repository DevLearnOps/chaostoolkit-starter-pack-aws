import os
import requests
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route


async def make_request(url, timeout):
    try:
        return requests.get(url=url, timeout=timeout)
    except requests.exceptions.RequestException:
        return None


async def http_probe_egress(request):
    """
    Sample body:
        url: str
        timeout: float
        repeat: int
    """
    data = await request.json()

    url = data.get("url")
    timeout = float(data.get("timeout", 5))
    repeat = int(data.get("repeat", 1))

    if repeat > 1:
        report = {}

        duration_sum = 0
        req_count = 0
        err_count = 0
        for idx in range(repeat):
            response = await make_request(url, timeout)
            if response:
                status = response.status_code
                key = f"status_{status}_count"
                report[key] = report.get(key, 0) + 1
                duration_sum = response.elapsed.total_seconds()
                req_count += 1
            else:
                err_count += 1

        if req_count > 0:
            report["avg_duration"] = duration_sum / req_count
        report["error_count"] = err_count

    else:
        response = await make_request(url, timeout)
        report = {
            "status": response.status_code if response else None,
            "duration": response.elapsed.total_seconds() if response else None,
            "error": response is None,
        }

    return JSONResponse(report)


async def health(request):
    return JSONResponse({"status": "healthy"})


app = Starlette(
    debug=os.getenv("DEBUG_ENABLED", False),
    routes=[
        Route("/", health),
        Route("/health", health),
        Route("/http/egress", http_probe_egress, methods=["POST"]),
    ],
)
