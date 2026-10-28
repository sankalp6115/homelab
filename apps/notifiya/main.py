from pathlib import Path
import os
from fastapi import FastAPI
import uvicorn
from dotenv import load_dotenv
import sys
from model import Notification

sys.path.append(str(Path(__file__).resolve().parent.parent))
from gotify import Gotify

DOT_ENV = Path(__file__).parent.parent.parent / ".env"
print(DOT_ENV)

load_dotenv(DOT_ENV)


GOTIFY_TOKEN = os.getenv("GOTIFY_TOKEN")
GOTIFY_SERVER = os.getenv("GOTIFY_SERVER")

gotify = Gotify(GOTIFY_SERVER, GOTIFY_TOKEN)
app = FastAPI()

@app.get("/")
def root():
    return {
        "status": "Hi i am healthy, and i send notifications"
    }

@app.post("/")
def send(payload: Notification):
    gotify.send(payload.title, payload.body, payload.priority)
    return {
        "status": f"I have sent a notification with title: {payload.title} and body: {payload.body} with {payload.priority}"
    }

if __name__ == "__main__":
    gotify.send("App up", "Notifiya upped on port 3010")
    uvicorn.run("main:app", host="0.0.0.0", port=3010)