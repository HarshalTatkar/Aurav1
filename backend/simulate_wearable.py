import time
import requests
import random
import datetime

# Configuration
API_URL = "http://localhost:8000"
USER_EMAIL = "test@example.com"
USER_PASSWORD = "password123"

# Create a session
session = requests.Session()

print("--- AURA Wearable Simulator ---")

# 1. Register / Login
print(f"Logging in as {USER_EMAIL}...")
try:
    # Try logging in
    resp = session.post(f"{API_URL}/auth/login", json={"email": USER_EMAIL, "password": USER_PASSWORD})
    if resp.status_code != 200:
        # Register if login fails
        print("User not found, registering...")
        session.post(f"{API_URL}/auth/register", json={"email": USER_EMAIL, "password": USER_PASSWORD, "name": "Test User"})
        resp = session.post(f"{API_URL}/auth/login", json={"email": USER_EMAIL, "password": USER_PASSWORD})
    
    token = resp.json().get("access_token")
    session.headers.update({"Authorization": f"Bearer {token}"})
    print("Successfully authenticated!")
except Exception as e:
    print(f"Authentication failed: {e}")
    exit(1)

print("\nStarting live data stream... (Press Ctrl+C to stop)\n")

# 2. Emulate Sensor Readings
base_hr = 70
base_spo2 = 98

try:
    while True:
        # Slight random variations
        hr = base_hr + random.uniform(-2, 3)
        spo2 = base_spo2 + random.uniform(-0.5, 0)
        
        payload = {
            "device_id": "simulated_wearable_1",
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
            "heart_rate": round(hr, 1),
            "spo2": round(spo2, 1),
            "body_temperature": 36.6 + random.uniform(-0.1, 0.1),
            "ambient_temperature": 24.5 + random.uniform(-0.2, 0.2),
            "humidity": 45.0 + random.uniform(-2, 2),
            "pm25": 12.0 + random.uniform(-1, 2),
            "pm10": 20.0 + random.uniform(-2, 3),
            "activity_level": random.uniform(0.1, 0.5),
            "fall_detected": False,
            "battery": 85
        }
        
        res = session.post(f"{API_URL}/sensor/readings", json=payload)
        print(f"[{datetime.datetime.now().strftime('%H:%M:%S')}] Sent Reading: HR={payload['heart_rate']} SpO2={payload['spo2']} | Status: {res.status_code}")
        
        time.sleep(2)  # Update every 2 seconds
        
except KeyboardInterrupt:
    print("\nSimulator stopped.")
