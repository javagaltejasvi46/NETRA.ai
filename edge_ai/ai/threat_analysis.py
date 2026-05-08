"""
Threat analysis engine for battlefield telemetry.
"""
import logging
import math
from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from edge_ai.mqtt.models import TelemetryData

logger = logging.getLogger(__name__)


@dataclass
class ThreatAssessment:
    """
    Represents the result of threat analysis.
    
    Attributes:
        risk_score: Normalized risk score (0.0 to 1.0)
        threat_level: Classification (CRITICAL, HIGH, MEDIUM, LOW)
        enemy_distance: Distance from soldier to enemy in meters
        soldier_stress: Soldier stress state (HIGH, NORMAL)
        hostage_risk: Hostage risk level (ELEVATED, NORMAL)
    """
    risk_score: float
    threat_level: str
    enemy_distance: float
    soldier_stress: str
    hostage_risk: str


class ThreatAnalyzer:
    """
    Analyzes battlefield telemetry to compute threat levels and risk scores.
    """
    
    def __init__(self, critical_distance: int, stress_heart_rate: int, 
                 hostage_risk_distance: int):
        """
        Initialize threat analyzer with configurable thresholds.
        
        Args:
            critical_distance: Distance threshold for CRITICAL threat (meters)
            stress_heart_rate: Heart rate threshold for HIGH stress (bpm)
            hostage_risk_distance: Distance threshold for ELEVATED hostage risk (meters)
        """
        self.critical_distance = critical_distance
        self.stress_heart_rate = stress_heart_rate
        self.hostage_risk_distance = hostage_risk_distance
    
    def analyze(self, telemetry: 'TelemetryData') -> ThreatAssessment:
        """
        Compute threat assessment from telemetry data.
        
        Args:
            telemetry: Parsed telemetry data
            
        Returns:
            ThreatAssessment with computed metrics
        """
        # Extract positions
        soldier_x = telemetry.soldier['x']
        soldier_y = telemetry.soldier['y']
        soldier_hr = telemetry.soldier['heart_rate']
        
        enemy_x = telemetry.enemy['x']
        enemy_y = telemetry.enemy['y']
        
        hostage_x = telemetry.hostage['x']
        hostage_y = telemetry.hostage['y']
        
        # Compute enemy distance - use pre-computed if available, else Euclidean
        if 'distance' in telemetry.enemy and telemetry.enemy['distance'] is not None:
            enemy_distance = float(telemetry.enemy['distance'])
        else:
            enemy_distance = self._calculate_distance(
                soldier_x, soldier_y, enemy_x, enemy_y
            )
        
        # Compute hostage distance from enemy
        hostage_enemy_distance = self._calculate_distance(
            hostage_x, hostage_y, enemy_x, enemy_y
        )
        
        # Classify threat level based on enemy distance
        if enemy_distance < self.critical_distance:
            threat_level = "CRITICAL"
        elif enemy_distance < self.critical_distance * 1.5:
            threat_level = "HIGH"
        elif enemy_distance < self.critical_distance * 2:
            threat_level = "MEDIUM"
        else:
            threat_level = "LOW"
        
        # Determine soldier stress state
        soldier_stress = "HIGH" if soldier_hr > self.stress_heart_rate else "NORMAL"
        
        # Determine hostage risk
        hostage_risk = "ELEVATED" if hostage_enemy_distance < self.hostage_risk_distance else "NORMAL"
        
        # Compute normalized risk score (0.0 to 1.0)
        # Formula: distance_factor (60%) + stress_factor (20%) + hostage_factor (20%)
        distance_factor = max(0.0, 1.0 - (enemy_distance / 200.0))
        stress_factor = 1.0 if soldier_hr > self.stress_heart_rate else 0.0
        hostage_factor = 1.0 if hostage_enemy_distance < self.hostage_risk_distance else 0.0
        
        risk_score = (distance_factor * 0.6) + (stress_factor * 0.2) + (hostage_factor * 0.2)
        risk_score = min(1.0, max(0.0, risk_score))  # Clamp to [0, 1]
        
        logger.info(
            f"Threat Analysis: distance={enemy_distance:.1f}m, "
            f"threat={threat_level}, stress={soldier_stress}, "
            f"hostage_risk={hostage_risk}, risk_score={risk_score:.2f}"
        )
        
        return ThreatAssessment(
            risk_score=risk_score,
            threat_level=threat_level,
            enemy_distance=enemy_distance,
            soldier_stress=soldier_stress,
            hostage_risk=hostage_risk
        )
    
    @staticmethod
    def _calculate_distance(x1: float, y1: float, x2: float, y2: float) -> float:
        """
        Calculate Euclidean distance between two points.
        
        Args:
            x1, y1: First point coordinates
            x2, y2: Second point coordinates
            
        Returns:
            Distance in same units as input coordinates
        """
        return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
