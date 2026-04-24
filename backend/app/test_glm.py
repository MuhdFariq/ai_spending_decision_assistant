import requests
from app.config import ZAI_API_KEY

url = "https://api.ilmu.ai/v1/chat/completions"

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {ZAI_API_KEY}",
}

payload = {
    "model": "ilmu-glm-5.1",
    "messages": [
        {
            "role": "user",
            "content": "Hello"
        }
    ]
}

response = requests.post(url, headers=headers, json=payload, timeout=30)

print("STATUS:", response.status_code)
print("RESPONSE:", response.text)