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
    
    SYSTEM_INSTRUCTION = """You are an autonomous battlefield tactical AI assistant running on an edge device.
Your task is to analyze battlefield telemetry and provide concise tactical guidance to soldiers in real time.

You must:
- Analyze squad positions
- Detect nearby enemies
- Consider hostage safety
- Monitor soldier stress using heart rate
- Consider unit status and battery
- Respond to voice questions intelligently
- Prioritize soldier and hostage survival

Rules:
- Keep responses under 20 words
- Respond like military radio communication
- Be direct and tactical
- Avoid explanations
- Avoid conversational filler
- Avoid hallucinations
- Focus only on actionable guidance

Examples:
"Enemy east. Move behind cover."
"Hostage proximity critical. Hold fire."
"Heart rate elevated. Slow movement advised."
"Advance through western corridor."
"Battery low. Return to base soon."

Never produce long paragraphs."""
    
    MAX_CONTEXT_LENGTH = 500  # Increased for detailed context
    
    def build_prompt(self, telemetry: 'TelemetryData', 
                     assessment: 'ThreatAssessment',
                     context_store=None) -> str:
        """
        Construct prompt from telemetry and threat assessment.
        
        Args:
            telemetry: Parsed telemetry data
            assessment: Computed threat assessment
            context_store: Optional context store for historical data
            
        Returns:
            Formatted prompt string for LLM inference
        """
        # Build detailed battlefield state
        prompt_parts = [self.SYSTEM_INSTRUCTION, "\n\nCurrent Battlefield State:"]
        
        # Squad Units with full details
        prompt_parts.append("\nSquad Units:")
        for soldier in telemetry.squad:
            battery_status = ""
            if soldier.battery < 30:
                battery_status = " (CRITICAL BATTERY)"
            elif soldier.battery < 50:
                battery_status = " (LOW BATTERY)"
            
            prompt_parts.append(
                f"- {soldier.callsign} at coordinates ({soldier.lat:.4f}, {soldier.lng:.4f})\n"
                f"  Heart Rate: {soldier.heart_rate}\n"
                f"  Battery: {soldier.battery}%{battery_status}\n"
                f"  Status: {soldier.status}"
            )
        
        # Enemy Position
        prompt_parts.append(
            f"\nEnemy Position:\n"
            f"- {telemetry.enemy.callsign} at ({telemetry.enemy.lat:.4f}, {telemetry.enemy.lng:.4f})\n"
            f"  Distance from primary: {assessment.enemy_distance:.0f}m"
        )
        
        # Hostage Position
        prompt_parts.append(
            f"\nHostage Position:\n"
            f"- {telemetry.hostage.callsign} at ({telemetry.hostage.lat:.4f}, {telemetry.hostage.lng:.4f})\n"
            f"  Distance from primary: {assessment.hostage_distance:.0f}m\n"
            f"  Risk Level: {assessment.hostage_risk}"
        )
        
        # Add recent context if available
        if context_store:
            recent = context_store.get_recent_context(count=2)
            if recent:
                prompt_parts.append("\nRecent Actions:")
                for i, entry in enumerate(recent, 1):
                    prompt_parts.append(
                        f"{i}. Tick {entry['tick']}: {entry['decision']}"
                    )
        
        # Voice Transmission (if present)
        if telemetry.voice_message:
            prompt_parts.append(
                f"\nVoice Transmission:\n"
                f"Unit: {telemetry.voice_message.unit}\n"
                f"Message: \"{telemetry.voice_message.message}\""
            )
        
        # Analysis prompt
        prompt_parts.append(
            f"\nAnalyze:\n"
            f"- Enemy proximity: {assessment.threat_level}\n"
            f"- Squad safety: {assessment.squad_status}\n"
            f"- Hostage risk: {assessment.hostage_risk}\n"
            f"- Soldier stress: {assessment.soldier_stress}"
        )
        
        # Add tactical movement safety if voice message mentions movement
        if telemetry.voice_message and any(word in telemetry.voice_message.message.lower() 
                                           for word in ['move', 'moving', 'advance', 'retreat']):
            prompt_parts.append("- Tactical movement safety")
        
        # Final instruction
        if telemetry.voice_message:
            prompt_parts.append(f"\nGenerate one short tactical response to {telemetry.voice_message.unit}:")
        else:
            prompt_parts.append("\nGenerate one short tactical guidance:")
        
        prompt = "\n".join(prompt_parts)
        
        logger.debug(f"Built prompt: {prompt}")
        
        return prompt
