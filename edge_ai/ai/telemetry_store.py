"""
Persistent storage for incoming telemetry payloads.
Stores all JSON payloads to disk and provides context for the LLM.
"""
import json
import logging
import os
from collections import deque
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)

STORE_FILE = "logs/telemetry_history.jsonl"  # one JSON per line


class TelemetryStore:
    """
    Stores all incoming telemetry payloads to disk and memory.
    Provides a summarized context string for the LLM.
    """

    def __init__(self, max_memory: int = 20):
        """
        Args:
            max_memory: How many recent payloads to keep in memory for context
        """
        self.max_memory = max_memory
        self._memory: deque = deque(maxlen=max_memory)
        Path(STORE_FILE).parent.mkdir(parents=True, exist_ok=True)
        logger.info(f"TelemetryStore initialized. Persisting to {STORE_FILE}")

    def save(self, telemetry, assessment) -> None:
        """
        Save a telemetry payload + assessment to disk and memory.
        """
        record = {
            "ts": datetime.utcnow().isoformat(),
            "timestamp": telemetry.timestamp,
            "soldier": telemetry.soldier,
            "enemy": telemetry.enemy,
            "hostage": telemetry.hostage,
            "environment": telemetry.environment,
            "threat_level": assessment.threat_level,
            "enemy_distance": round(assessment.enemy_distance, 1),
            "risk_score": round(assessment.risk_score, 2),
            "soldier_stress": assessment.soldier_stress,
            "hostage_risk": assessment.hostage_risk,
        }

        # Persist to disk (append)
        try:
            with open(STORE_FILE, "a") as f:
                f.write(json.dumps(record) + "\n")
        except Exception as e:
            logger.warning(f"Failed to persist telemetry: {e}")

        # Keep in memory
        self._memory.append(record)

    def get_context_summary(self, last_n: int = 5) -> str:
        """
        Return a compact summary of the last N telemetry records
        to inject into the LLM prompt as context.
        """
        records = list(self._memory)[-last_n:]
        if not records:
            return "No telemetry history available."

        lines = ["Recent battlefield telemetry:"]
        for i, r in enumerate(records, 1):
            lines.append(
                f"  [{i}] dist={r['enemy_distance']}m "
                f"threat={r['threat_level']} "
                f"risk={r['risk_score']} "
                f"stress={r['soldier_stress']} "
                f"hostage={r['hostage_risk']} "
                f"env={r['environment']}"
            )
        return "\n".join(lines)

    def latest(self) -> dict:
        """Return the most recent record or empty dict."""
        return self._memory[-1] if self._memory else {}
