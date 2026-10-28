import os
import asyncio
from pathlib import Path
from telethon import TelegramClient, events
from dotenv import load_dotenv

load_dotenv()

BASE_PATH = Path(__file__).parent
DOWNLOAD_FOLDER = BASE_PATH / "downloads"
DOWNLOAD_FOLDER.mkdir(exist_ok=True)

API_ID = int(os.getenv("TELEGRAM_API_ID"))
API_HASH = os.getenv("TELEGRAM_API_HASH")
PHONE = os.getenv("TELEGRAM_PHONE")

TARGET_BOT = "@deezload2bot"
SONG_URL = "https://open.spotify.com/track/3h6Xvd0lISog6GxTk4X6MK"

client = TelegramClient(str(BASE_PATH / "my_session"), API_ID, API_HASH)
done = asyncio.Event()


@client.on(events.NewMessage(incoming=True, from_users=TARGET_BOT))
async def handle_bot_response(event):
    if event.audio or event.document:
        print("🎵 Song received, downloading...")
        path = await event.download_media(file=str(DOWNLOAD_FOLDER))
        print(f"✅ Saved to: {path}")
        done.set()
    elif event.text:
        print(f"🤖 Bot: {event.text}")
        low = event.text.lower()
        if "error" in low or "not found" in low:
            print("❌ Bot couldn't process the link.")
            done.set()


async def main():
    await client.start(phone=PHONE)
    print(f"🚀 Sending URL to {TARGET_BOT}...")
    await client.send_message(TARGET_BOT, SONG_URL)

    try:
        await asyncio.wait_for(done.wait(), timeout=180)
    except asyncio.TimeoutError:
        print("⏰ Timed out waiting for the bot.")
    await client.disconnect()


asyncio.run(main())