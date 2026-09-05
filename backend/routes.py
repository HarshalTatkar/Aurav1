"""
AURA Backend — API Routes
All REST API endpoints for the health companion
"""
from datetime import datetime
from typing import List, Optional
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from database import (
    get_db, User, Device, SensorReading as SensorReadingDB,
    RiskAssessment as RiskAssessmentDB, Alert as AlertDB,
    EmergencyEvent as EmergencyEventDB, Profile,
)
from auth import get_current_user
from websocket_hub import manager

router = APIRouter()


# ─── Schemas ──────────────────────────────────────────────────────────────────
class DeviceCreate(BaseModel):
    name: str
    device_type: str  # sensor, wearable
    ble_address: Optional[str] = None

class DeviceResponse(BaseModel):
    id: str
    name: str
    device_type: str
    ble_address: Optional[str]
    registered_at: Optional[datetime]
    last_connected: Optional[datetime]

class SensorReadingCreate(BaseModel):
    device_id: str
    timestamp: datetime
    heart_rate: Optional[float] = None
    spo2: Optional[float] = None
    body_temperature: Optional[float] = None
    ambient_temperature: Optional[float] = None
    humidity: Optional[float] = None
    pm25: Optional[float] = None
    pm10: Optional[float] = None
    activity_level: Optional[float] = None
    fall_detected: bool = False
    battery: Optional[int] = None

class SensorReadingResponse(BaseModel):
    id: str
    timestamp: datetime
    heart_rate: Optional[float]
    spo2: Optional[float]
    body_temperature: Optional[float]
    ambient_temperature: Optional[float]
    humidity: Optional[float]
    pm25: Optional[float]
    pm10: Optional[float]
    activity_level: Optional[float]
    fall_detected: bool
    battery: Optional[int]

class AlertResponse(BaseModel):
    id: str
    alert_type: str
    severity: str
    timestamp: datetime
    reason: str
    recommendation: Optional[str]
    status: str

class SOSRequest(BaseModel):
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    health_snapshot: Optional[dict] = None

class EmergencyResponse(BaseModel):
    id: str
    timestamp: datetime
    event_type: str
    latitude: Optional[float]
    longitude: Optional[float]
    status: str


# ─── Device Endpoints ─────────────────────────────────────────────────────────
@router.get("/devices", response_model=List[DeviceResponse])
async def list_devices(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Device).where(Device.user_id == user.id, Device.is_active == True)
    )
    return [DeviceResponse(
        id=d.id, name=d.name, device_type=d.device_type,
        ble_address=d.ble_address, registered_at=d.registered_at,
        last_connected=d.last_connected,
    ) for d in result.scalars().all()]


@router.post("/devices", response_model=DeviceResponse)
async def register_device(
    req: DeviceCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    device = Device(
        id=str(uuid4()),
        user_id=user.id,
        name=req.name,
        device_type=req.device_type,
        ble_address=req.ble_address,
    )
    db.add(device)
    await db.commit()
    return DeviceResponse(
        id=device.id, name=device.name, device_type=device.device_type,
        ble_address=device.ble_address, registered_at=device.registered_at,
        last_connected=device.last_connected,
    )


@router.delete("/devices/{device_id}")
async def remove_device(
    device_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Device).where(Device.id == device_id, Device.user_id == user.id)
    )
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
    device.is_active = False
    await db.commit()
    return {"status": "removed"}


# ─── Sensor Reading Endpoints ────────────────────────────────────────────────
@router.post("/sensor/readings")
async def create_sensor_reading(
    req: SensorReadingCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reading = SensorReadingDB(
        id=str(uuid4()),
        user_id=user.id,
        device_id=req.device_id,
        timestamp=req.timestamp,
        heart_rate=req.heart_rate,
        spo2=req.spo2,
        body_temperature=req.body_temperature,
        ambient_temperature=req.ambient_temperature,
        humidity=req.humidity,
        pm25=req.pm25,
        pm10=req.pm10,
        activity_level=req.activity_level,
        fall_detected=req.fall_detected,
        battery=req.battery,
    )
    db.add(reading)
    await db.commit()
    
    # Broadcast to dashboard via websocket
    await manager.send_to_user(user.id, {
        "type": "user_sensor_update",
        "data": {
            "device_id": req.device_id,
            "timestamp": req.timestamp.isoformat(),
            "heart_rate": req.heart_rate,
            "spo2": req.spo2,
            "body_temperature": req.body_temperature,
            "ambient_temperature": req.ambient_temperature,
            "humidity": req.humidity,
            "pm25": req.pm25,
            "pm10": req.pm10,
            "activity_level": req.activity_level,
            "fall_detected": req.fall_detected,
            "battery": req.battery,
        }
    })
    
    return {"status": "created", "id": reading.id}


@router.get("/sensor/readings", response_model=List[SensorReadingResponse])
async def get_sensor_readings(
    limit: int = Query(100, le=1000),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SensorReadingDB)
        .where(SensorReadingDB.user_id == user.id)
        .order_by(desc(SensorReadingDB.timestamp))
        .limit(limit)
    )
    readings = result.scalars().all()
    return [SensorReadingResponse(
        id=r.id, timestamp=r.timestamp, heart_rate=r.heart_rate,
        spo2=r.spo2, body_temperature=r.body_temperature,
        ambient_temperature=r.ambient_temperature, humidity=r.humidity,
        pm25=r.pm25, pm10=r.pm10, activity_level=r.activity_level,
        fall_detected=r.fall_detected, battery=r.battery,
    ) for r in readings]


# ─── Health Endpoints ─────────────────────────────────────────────────────────
@router.get("/health/current")
async def get_current_health(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SensorReadingDB)
        .where(SensorReadingDB.user_id == user.id)
        .order_by(desc(SensorReadingDB.timestamp))
        .limit(1)
    )
    reading = result.scalar_one_or_none()
    if not reading:
        return {"status": "no_data"}
    return SensorReadingResponse(
        id=reading.id, timestamp=reading.timestamp,
        heart_rate=reading.heart_rate, spo2=reading.spo2,
        body_temperature=reading.body_temperature,
        ambient_temperature=reading.ambient_temperature,
        humidity=reading.humidity, pm25=reading.pm25, pm10=reading.pm10,
        activity_level=reading.activity_level,
        fall_detected=reading.fall_detected, battery=reading.battery,
    )


# ─── Risk Endpoints ──────────────────────────────────────────────────────────
@router.get("/risk/current")
async def get_current_risk(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(RiskAssessmentDB)
        .where(RiskAssessmentDB.user_id == user.id)
        .order_by(desc(RiskAssessmentDB.timestamp))
        .limit(1)
    )
    risk = result.scalar_one_or_none()
    if not risk:
        return {"score": 0, "level": "LOW", "pattern": "No data yet"}
    return {
        "id": risk.id, "score": risk.score, "level": risk.level,
        "pattern": risk.pattern, "factors": risk.factors,
        "recommendations": risk.recommendations, "confidence": risk.confidence,
    }

@router.post("/risk/analyze")
async def analyze_risk(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Simulate an AI cloud-based risk assessment
    # In a real environment, this would call Gemini API with the last 24h of telemetry
    result = await db.execute(
        select(SensorReadingDB)
        .where(SensorReadingDB.user_id == user.id)
        .order_by(desc(SensorReadingDB.timestamp))
        .limit(10)
    )
    readings = result.scalars().all()
    
    if not readings:
        return {"recommendation": "Not enough data for AI analysis. Please connect your wearable."}
    
    hr_avg = sum(r.heart_rate for r in readings if r.heart_rate) / len(readings) if readings else 0
    
    rec = "Your vitals are stable. Continue your current routine."
    if hr_avg > 100:
        rec = "AI Alert: Elevated resting heart rate detected over the last hour. Recommend taking a 15-minute rest and hydrating."
    elif hr_avg > 0 and hr_avg < 50:
        rec = "AI Alert: Unusually low heart rate detected. Please ensure you are not experiencing dizziness."

    return {
        "ai_recommendation": rec,
        "confidence_score": 0.89,
        "analyzed_datapoints": len(readings)
    }

# ─── Alert Endpoints ─────────────────────────────────────────────────────────
@router.get("/alerts", response_model=List[AlertResponse])
async def list_alerts(
    limit: int = Query(50, le=200),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(AlertDB)
        .where(AlertDB.user_id == user.id)
        .order_by(desc(AlertDB.timestamp))
        .limit(limit)
    )
    return [AlertResponse(
        id=a.id, alert_type=a.alert_type, severity=a.severity,
        timestamp=a.timestamp, reason=a.reason,
        recommendation=a.recommendation, status=a.status,
    ) for a in result.scalars().all()]


@router.post("/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(
    alert_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(AlertDB).where(AlertDB.id == alert_id, AlertDB.user_id == user.id)
    )
    alert = result.scalar_one_or_none()
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    alert.status = "acknowledged"
    alert.acknowledged_at = datetime.utcnow()
    await db.commit()
    return {"status": "acknowledged"}


# ─── Emergency Endpoints ─────────────────────────────────────────────────────
@router.post("/emergency/sos", response_model=EmergencyResponse)
async def create_sos(
    req: SOSRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event = EmergencyEventDB(
        id=str(uuid4()),
        user_id=user.id,
        timestamp=datetime.utcnow(),
        event_type="SOS",
        latitude=req.latitude,
        longitude=req.longitude,
        health_snapshot=req.health_snapshot,
    )
    db.add(event)
    await db.commit()
    return EmergencyResponse(
        id=event.id, timestamp=event.timestamp, event_type=event.event_type,
        latitude=event.latitude, longitude=event.longitude, status=event.status,
    )


@router.get("/emergency/history", response_model=List[EmergencyResponse])
async def emergency_history(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(EmergencyEventDB)
        .where(EmergencyEventDB.user_id == user.id)
        .order_by(desc(EmergencyEventDB.timestamp))
        .limit(20)
    )
    return [EmergencyResponse(
        id=e.id, timestamp=e.timestamp, event_type=e.event_type,
        latitude=e.latitude, longitude=e.longitude, status=e.status,
    ) for e in result.scalars().all()]


# ─── User Profile ────────────────────────────────────────────────────────────
@router.get("/users/me/profile")
async def get_profile(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Profile).where(Profile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        return {"status": "no_profile"}
    return {
        "age": profile.age, "weight": profile.weight, "height": profile.height,
        "baseline": {
            "hr_low": profile.baseline_hr_low, "hr_high": profile.baseline_hr_high,
            "hr_avg": profile.baseline_hr_avg, "spo2_low": profile.baseline_spo2_low,
            "body_temp_low": profile.baseline_body_temp_low,
            "body_temp_high": profile.baseline_body_temp_high,
            "calibrated_at": profile.baseline_calibrated_at,
            "readings_count": profile.baseline_readings_count,
        },
    }
