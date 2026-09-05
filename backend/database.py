"""
AURA Backend — Database Models & Configuration
PostgreSQL with SQLAlchemy async
"""
import os
from datetime import datetime
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, ForeignKey,
    Text, JSON, Index, Enum as SAEnum, UniqueConstraint
)
from sqlalchemy.orm import relationship, DeclarativeBase
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://aura:aura_pass@localhost:5432/aura_db")

if DATABASE_URL.startswith("sqlite"):
    engine = create_async_engine(DATABASE_URL, echo=False)
else:
    engine = create_async_engine(DATABASE_URL, echo=False, pool_size=10, max_overflow=20)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


# ─── Users ────────────────────────────────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    profile = relationship("Profile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    devices = relationship("Device", back_populates="user", cascade="all, delete-orphan")
    sensor_readings = relationship("SensorReading", back_populates="user", cascade="all, delete-orphan")
    alerts = relationship("Alert", back_populates="user", cascade="all, delete-orphan")
    emergency_events = relationship("EmergencyEvent", back_populates="user", cascade="all, delete-orphan")
    preferences = relationship("UserPreference", back_populates="user", uselist=False, cascade="all, delete-orphan")


# ─── Profile ─────────────────────────────────────────────────────────────────
class Profile(Base):
    __tablename__ = "profiles"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    age = Column(Integer)
    weight = Column(Float)
    height = Column(Float)
    baseline_hr_low = Column(Float, default=62)
    baseline_hr_high = Column(Float, default=82)
    baseline_hr_avg = Column(Float, default=72)
    baseline_spo2_low = Column(Float, default=96)
    baseline_spo2_avg = Column(Float, default=98)
    baseline_body_temp_low = Column(Float, default=36.2)
    baseline_body_temp_high = Column(Float, default=36.9)
    baseline_body_temp_avg = Column(Float, default=36.6)
    baseline_calibrated_at = Column(DateTime)
    baseline_readings_count = Column(Integer, default=0)

    user = relationship("User", back_populates="profile")


# ─── Devices ──────────────────────────────────────────────────────────────────
class Device(Base):
    __tablename__ = "devices"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)
    device_type = Column(String(20), nullable=False)  # sensor, wearable
    ble_address = Column(String(50))
    firmware_version = Column(String(50))
    registered_at = Column(DateTime, default=datetime.utcnow)
    last_connected = Column(DateTime)
    is_active = Column(Boolean, default=True)

    user = relationship("User", back_populates="devices")

    __table_args__ = (Index("idx_devices_user", "user_id"),)


# ─── Sensor Readings ─────────────────────────────────────────────────────────
class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_id = Column(String(36))
    timestamp = Column(DateTime, nullable=False, index=True)
    heart_rate = Column(Float)
    spo2 = Column(Float)
    body_temperature = Column(Float)
    ambient_temperature = Column(Float)
    humidity = Column(Float)
    pm25 = Column(Float)
    pm10 = Column(Float)
    activity_level = Column(Float)
    fall_detected = Column(Boolean, default=False)
    battery = Column(Integer)

    user = relationship("User", back_populates="sensor_readings")

    __table_args__ = (
        Index("idx_readings_user_ts", "user_id", "timestamp"),
    )


# ─── Risk Assessments ────────────────────────────────────────────────────────
class RiskAssessment(Base):
    __tablename__ = "risk_assessments"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    timestamp = Column(DateTime, nullable=False, index=True)
    score = Column(Integer, nullable=False)
    level = Column(String(20), nullable=False)
    pattern = Column(Text)
    factors = Column(JSON)
    recommendations = Column(JSON)
    confidence = Column(Float)
    disaster_context = Column(String(50))

    __table_args__ = (Index("idx_risk_user_ts", "user_id", "timestamp"),)


# ─── Alerts ───────────────────────────────────────────────────────────────────
class Alert(Base):
    __tablename__ = "alerts"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    alert_type = Column(String(30), nullable=False)
    severity = Column(String(20), nullable=False)
    timestamp = Column(DateTime, nullable=False, index=True)
    reason = Column(Text, nullable=False)
    recommendation = Column(Text)
    sensor_values = Column(JSON)
    status = Column(String(20), default="active")
    wearable_notified = Column(Boolean, default=False)
    wearable_acknowledged = Column(Boolean, default=False)
    acknowledged_at = Column(DateTime)
    resolved_at = Column(DateTime)

    user = relationship("User", back_populates="alerts")

    __table_args__ = (Index("idx_alerts_user_ts", "user_id", "timestamp"),)


# ─── Emergency Events ────────────────────────────────────────────────────────
class EmergencyEvent(Base):
    __tablename__ = "emergency_events"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    timestamp = Column(DateTime, nullable=False)
    event_type = Column(String(30), nullable=False)
    latitude = Column(Float)
    longitude = Column(Float)
    health_snapshot = Column(JSON)
    status = Column(String(20), default="ACTIVE")
    resolved_at = Column(DateTime)

    user = relationship("User", back_populates="emergency_events")


# ─── Emergency Contacts ──────────────────────────────────────────────────────
class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=False)
    relationship_type = Column(String(50))
    is_primary = Column(Boolean, default=False)

    __table_args__ = (Index("idx_contacts_user", "user_id"),)


# ─── User Preferences ────────────────────────────────────────────────────────
class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    continuous_monitoring = Column(Boolean, default=True)
    health_alerts = Column(Boolean, default=True)
    heat_alerts = Column(Boolean, default=True)
    air_quality_alerts = Column(Boolean, default=True)
    wearable_alerts = Column(Boolean, default=True)
    data_sharing = Column(Boolean, default=False)
    location_enabled = Column(Boolean, default=False)
    theme_mode = Column(String(10), default="dark")

    user = relationship("User", back_populates="preferences")


# ─── Sync Queue ───────────────────────────────────────────────────────────────
class SyncQueue(Base):
    __tablename__ = "sync_queue"

    id = Column(String(36), primary_key=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    entity_type = Column(String(50), nullable=False)
    entity_id = Column(String(36), nullable=False)
    action = Column(String(20), nullable=False)
    payload = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
    synced_at = Column(DateTime)
    status = Column(String(20), default="pending")

    __table_args__ = (Index("idx_sync_user_status", "user_id", "status"),)


# ─── Helper ──────────────────────────────────────────────────────────────────
async def get_db():
    async with async_session() as session:
        yield session
