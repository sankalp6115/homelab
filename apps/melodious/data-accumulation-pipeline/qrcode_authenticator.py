# pip install qrcode
import os, asyncio
import qrcode
from pathlib import Path
from telethon import TelegramClient
from telethon.errors import SessionPasswordNeededError
from dotenv import load_dotenv

load_dotenv()
BASE_PATH = Path(__file__).parent

API_ID = int(os.getenv("TELEGRAM_API_ID"))
API_HASH = os.getenv("TELEGRAM_API_HASH")

client = TelegramClient(str(BASE_PATH / "my_session"), API_ID, API_HASH)


async def login():
    await client.connect()
    if await client.is_user_authorized():
        print("Already logged in.")
        return

    qr = await client.qr_login()
    while True:
        q = qrcode.QRCode()
        q.add_data(qr.url)
        q.print_ascii(invert=True)
        print("Scan: Telegram app → Settings → Devices → Link Desktop Device")
        try:
            await qr.wait(timeout=30)
            break
        except asyncio.TimeoutError:
            await qr.recreate()  # QR expires every ~30s
        except SessionPasswordNeededError:
            await client.sign_in(password=input("2FA password: "))
            break
    print("✅ Logged in, session saved.")


asyncio.run(login())