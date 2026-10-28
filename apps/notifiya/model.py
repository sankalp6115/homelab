from pydantic import BaseModel

class Notification(BaseModel):
    title: str
    body: str
    priority: int = 5