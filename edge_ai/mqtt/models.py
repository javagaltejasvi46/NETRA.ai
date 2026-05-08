"""
Data models for telemetry parsing and validation.
"""
import json
import logging
from dataclasses import dataclass
from typing import Optional

logger = logging.getLogger(__name__)


@dataclass
class Position:
    """Represents a 2D position coordinate"""
    x: float
    y: float


@dataclass
class TelemetryData:
    """
    Represents battlefield telemetry data received via MQTT.
    New payload format:
    {
      "timestamp": 1710000000,
      "soldier": {"x": 120, "y": 340, "heart_rate": 125},
      "enemy": {"x": 180, "y": 360, "distance": 90},
      "hostage": {"x": 140, "y": 350}
    }
    """
    timestamp: int
    soldier: dict   # x, y, heart_rate
    enemy: dict     # x, y, distance (pre-computed)
    hostage: dict   # x, y
    environment: str = "unknown"   # optional, defaults to unknown
    threat_level: str = "unknown"  # optional, defaults to unknown

    @staticmethod
    def from_json(payload: str) -> Optional['TelemetryData']:
        try:
            data = json.loads(payload)

            # Required fields only
            for field in ['timestamp', 'soldier', 'enemy', 'hostage']:
                if field not in data:
                    logger.error(f"Missing required field: {field}")
                    return None

            if not all(k in data['soldier'] for k in ['x', 'y', 'heart_rate']):
                logger.error("Missing soldier fields (x, y, heart_rate)")
                return None

            if not all(k in data['enemy'] for k in ['x', 'y']):
                logger.error("Missing enemy fields (x, y)")
                return None

            if not all(k in data['hostage'] for k in ['x', 'y']):
                logger.error("Missing hostage fields (x, y)")
                return None

            return TelemetryData(
                timestamp=int(data['timestamp']),
                soldier=data['soldier'],
                enemy=data['enemy'],
                hostage=data['hostage'],
                environment=data.get('environment', 'unknown'),
                threat_level=data.get('threat_level', 'unknown')
            )

        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}. Payload: {payload[:100]}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error parsing telemetry: {e}")
            return None
