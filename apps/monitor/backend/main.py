import os
import argparse
import uvicorn
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

try:
    from apps.apps.gotify import Gotify
    GOTIFY_TOKEN = os.getenv("GOTIFY_TOKEN")
    GOTIFY_SERVER = os.getenv("GOTIFY_SERVER")
    gotify = Gotify(GOTIFY_SERVER, GOTIFY_TOKEN) if (GOTIFY_SERVER and GOTIFY_TOKEN) else None
except Exception:
    gotify = None

from router import router

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)

FRONTEND_FOLDER = Path(__file__).parent.parent / "frontend" / "dist"

app.mount("/assets", StaticFiles(directory=FRONTEND_FOLDER / "assets"), name="assets")

@app.get("/favicon.png")
async def favicon():
    return FileResponse(FRONTEND_FOLDER / "favicon.png")

@app.get("/{full_path:path}")
async def serve_spa(full_path: str):
    return FileResponse(FRONTEND_FOLDER / "index.html")

# if __name__ == "__main__":
#     parser = argparse.ArgumentParser(description="Backend Server")
#     parser.add_argument("--port", type=int, default=8000, help="Port to bind the server to")
#     args = parser.parse_args()

#     if gotify:
#         try:
#             gotify.info("Monitor Server Up", f"Monitor Server started on port {args.port}")
#         except Exception:
#             pass

#     uvicorn.run("main:app", port=args.port, host="0.0.0.0")

def main():
    global RUNNING_MODE, PORT
    parser = argparse.ArgumentParser(description="Homelab System Monitor Agent & Central Dashboard Server")
    parser.add_argument("--mode", type=str, choices=["agent", "central"], default="central",
                        help="Run mode: 'agent' to just expose API metrics, 'central' to run dashboard server & scanner")
    parser.add_argument("--port", type=int, default=18000,
                        help="Port to run the service on (default: 18000)")
    parser.add_argument("--host", type=str, default="0.0.0.0",
                        help="Host IP to bind the service (default: 0.0.0.0)")
    args = parser.parse_args()

    RUNNING_MODE = args.mode
    PORT = args.port

    logger.info(f"Starting homelab-monitor in {RUNNING_MODE} mode on port {PORT}...")
    uvicorn.run(app, host=args.host, port=args.port)

