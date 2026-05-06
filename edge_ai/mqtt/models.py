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
    
    Attributes:
        timestamp: Unix timestamp of the telemetry
        soldier: Soldier position and heart rate
        enemy: Enemy position
        hostage: Hostage position
        environment: Environment type (urban, rural, forest, etc.)
        threat_level: Threat level indicator (high, medium, low)
    """
    timestamp: int
    soldier: dict  # Contains x, y, heart_rate
    enemy: dict    # Contains x, y, distance (optional)
    hostage: dict  # Contains x, y
    environment: str
    threat_level: str
    
    @staticmethod
    def from_json(payload: str) -> Optional['TelemetryData']:
        """
        Parse and validate JSON payload into TelemetryData.
        
        Args:
            payload: JSON string containing telemetry data
            
        Returns:
            TelemetryData instance if valid, None if malformed
        """
        try:
            data = json.loads(payload)
            
            # Validate required top-level fields
            required_fields = ['timestamp', 'soldier', 'enemy', 'hostage', 
                             'environment', 'threat_level']
            for field in required_fields:
                if field not in data:
                    logger.error(f"Missing required field: {field}")
                    return None
            
            # Validate soldier data
            if not isinstance(data['soldier'], dict):
                logger.error("Invalid soldier data: must be a dictionary")
                return None
            if not all(k in data['soldier'] for k in ['x', 'y', 'heart_rate']):
                logger.error("Missing soldier fields (x, y, heart_rate)")
                return None
            
            # Validate enemy data
            if not isinstance(data['enemy'], dict):
                logger.error("Invalid enemy data: must be a dictionary")
                return None
            if not all(k in data['enemy'] for k in ['x', 'y']):
                logger.error("Missing enemy fields (x, y)")
                return None
            
            # Validate hostage data
            if not isinstance(data['hostage'], dict):
                logger.error("Invalid hostage data: must be a dictionary")
                return None
            if not all(k in data['hostage'] for k in ['x', 'y']):
                logger.error("Missing hostage fields (x, y)")
                return None
            
            # Validate types
            if not isinstance(data['timestamp'], int):
                logger.error("Invalid timestamp: must be an integer")
                return None
            
            if not isinstance(data['environment'], str):
                logger.error("Invalid environment: must be a string")
                return None
            
            if not isinstance(data['threat_level'], str):
                logger.error("Invalid threat_level: must be a string")
                return None
            
            # Create TelemetryData instance
            return TelemetryData(
                timestamp=data['timestamp'],
                soldier=data['soldier'],
                enemy=data['enemy'],
                hostage=data['hostage'],
                environment=data['environment'],
                threat_level=data['threat_level']
            )
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}. Payload: {payload[:100]}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error parsing telemetry: {e}")
            return None
