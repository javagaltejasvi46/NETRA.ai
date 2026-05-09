"""
Prompt builder for LLM inference.
"""
import logging
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from edge_ai.mqtt.models import TelemetryData
    from edge_ai.ai.threat_analysis import ThreatAssessment

logger = logging.getLogger(__name__)


class PromptBuilder:
    """
    Constructs compact prompts for LLM inference from telemetry and threat assessment.
    """
    
    SYSTEM_INSTRUCTION = "You are a battlefield tactical AI. Generate one short tactical recommendation."
    MAX_CONTEXT_LENGTH = 200  # characters, excluding system instruction
    
    def build_prompt(self, telemetry: 'TelemetryData', 
                     assessment: 'ThreatAssessment') -> str:
        """
        Construct prompt from telemetry and threat assessment.
        
        Args:
            telemetry: Parsed telemetry data
            assessment: Computed threat assessment
            
        Returns:
            Formatted prompt string for LLM inference
        """
        # Get primary soldier info
        primary_soldier = telemetry.get_primary_soldier()
        
        # Build context string with proper formatting
        context_parts = [
            f"Squad: {len(telemetry.squad)} members, status {assessment.squad_status.lower()}.",
            f"Primary: {assessment.primary_soldier_id}, HR {primary_soldier.heart_rate}bpm.",
            f"Enemy: {assessment.enemy_distance:.0f}m away, threat {assessment.threat_level.lower()}.",
            f"Hostage: {assessment.hostage_risk.lower()} risk.",
        ]
        
        context = " ".join(context_parts)
        
        # Enforce length limit
        if len(context) > self.MAX_CONTEXT_LENGTH:
            logger.warning(f"Context length {len(context)} exceeds limit, truncating")
            context = context[:self.MAX_CONTEXT_LENGTH]
        
        # Combine system instruction with context
        prompt = f"{self.SYSTEM_INSTRUCTION}\n{context}"
        
        logger.debug(f"Built prompt: {prompt}")
        
        return prompt
