from dotenv import load_dotenv
import os

load_dotenv()

ZAI_API_KEY = os.getenv("ZAI_API_KEY", "")
ZAI_BASE_URL = os.getenv("ZAI_BASE_URL", "")
ZAI_MODEL = os.getenv("ZAI_MODEL", "")