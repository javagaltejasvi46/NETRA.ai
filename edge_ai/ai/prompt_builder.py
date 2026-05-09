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
    
    SYSTEM_INSTRUCTION = """Battlefield tactical AI. Analyze and respond in under 15 words.

Rules:
- Military radio style
- Direct and tactical
- No explanations
- Actionable only

Examples:
"Enemy east. Take cover."
"Battery low. RTB soon."
"Heart rate high. Slow down."
"Hostage near. Hold fire."
"""
    
    MAX_CONTEXT_LENGTH = 400  # Keep under 512 token limit
    
    def build_prompt(self, telemetry: 'TelemetryData', 
                     assessment: 'ThreatAssessment',
                     context_store=None) -> str:
        """
        Construct compact prompt from telemetry and threat assessment.
        Optimized to stay under 512 token context window.
        
        Args:
            telemetry: Parsed telemetry data
            assessment: Computed threat assessment
            context_store: Optional context store for historical data
            
        Returns:
            Formatted prompt string for LLM inference
        """
        # Get primary soldier
        primary = telemetry.get_primary_soldier()
        
        # Build compact battlefield state
        prompt_parts = [self.SYSTEM_INSTRUCTION]
        
        # Compact squad info
        squad_info = []
        for s in telemetry.squad:
            battery_warn = " LOW-BAT" if s.battery < 50 else ""
            squad_info.append(f"{s.callsign}: HR{s.heart_rate} B{s.battery}%{battery_warn} {s.status}")
        
        prompt_parts.append(f"\nSquad: {', '.join(squad_info)}")
        
        # Enemy and distances
        prompt_parts.append(
            f"Enemy: {telemetry.enemy.callsign} {assessment.enemy_distance:.0f}m {assessment.threat_level}"
        )
        
        # Hostage
        prompt_parts.append(
            f"Hostage: {assessment.hostage_distance:.0f}m {assessment.hostage_risk}"
        )
        
        # Recent context (only 1 entry to save space)
        if context_store:
            recent = context_store.get_recent_context(count=1)
            if recent:
                prompt_parts.append(f"Last: {recent[0]['decision']}")
        
        # Voice message
        if telemetry.voice_message:
            prompt_parts.append(
                f"\n{telemetry.voice_message.unit}: \"{telemetry.voice_message.message}\""
            )
            prompt_parts.append(f"\nRespond to {telemetry.voice_message.unit}:")
        else:
            prompt_parts.append("\nTactical guidance:")
        
        prompt = "\n".join(prompt_parts)
        
        # Log token estimate (rough: 1 token ≈ 4 characters)
        estimated_tokens = len(prompt) // 4
        logger.debug(f"Prompt: {len(prompt)} chars, ~{estimated_tokens} tokens")
        
        return prompt
