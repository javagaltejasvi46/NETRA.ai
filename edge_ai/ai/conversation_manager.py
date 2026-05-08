"""
Conversation manager with context memory for voice interactions.
"""
import logging
from typing import List, Dict, Optional
from collections import deque

logger = logging.getLogger(__name__)


class ConversationManager:
    """
    Manages conversation context and generates responses to user questions.
    """
    
    def __init__(self, max_history: int = 10):
        """
        Initialize conversation manager.
        
        Args:
            max_history: Maximum number of conversation turns to remember
        """
        self.max_history = max_history
        self.conversation_history = deque(maxlen=max_history)
        self.telemetry_history = deque(maxlen=5)
        self.decision_history = deque(maxlen=5)
    
    def add_telemetry(self, telemetry, assessment) -> None:
        """
        Store telemetry and threat assessment for context.
        
        Args:
            telemetry: TelemetryData instance
            assessment: ThreatAssessment instance
        """
        self.telemetry_history.append({
            'soldier_pos': (telemetry.soldier['x'], telemetry.soldier['y']),
            'enemy_pos': (telemetry.enemy['x'], telemetry.enemy['y']),
            'hostage_pos': (telemetry.hostage['x'], telemetry.hostage['y']),
            'heart_rate': telemetry.soldier['heart_rate'],
            'environment': telemetry.environment,
            'threat_level': assessment.threat_level,
            'enemy_distance': assessment.enemy_distance,
            'risk_score': assessment.risk_score
        })
    
    def add_decision(self, decision: str) -> None:
        """
        Store tactical decision for context.
        
        Args:
            decision: Tactical decision text
        """
        self.decision_history.append(decision)
    
    def add_exchange(self, user_input: str, response: str) -> None:
        """
        Store conversation exchange.
        
        Args:
            user_input: User's question
            response: System's response
        """
        self.conversation_history.append({
            'user': user_input,
            'assistant': response
        })
    
    def build_context_prompt(self, user_question: str) -> str:
        """
        Build prompt with conversation context for LLM.
        
        Args:
            user_question: User's current question
            
        Returns:
            Formatted prompt with context
        """
        prompt_parts = [
            "You are NETRA.AI, a battlefield tactical AI assistant.",
            "Answer questions briefly in under 20 words.",
            "Be direct and tactical."
        ]
        
        # Add recent telemetry context
        if self.telemetry_history:
            latest = self.telemetry_history[-1]
            prompt_parts.append(
                f"\nCurrent situation: Enemy {latest['enemy_distance']:.0f}m away, "
                f"threat level {latest['threat_level']}, "
                f"soldier heart rate {latest['heart_rate']} bpm."
            )
        
        # Add recent decision
        if self.decision_history:
            prompt_parts.append(f"Last decision: {self.decision_history[-1]}")
        
        # Add conversation history (last 3 exchanges)
        if self.conversation_history:
            prompt_parts.append("\nRecent conversation:")
            for exchange in list(self.conversation_history)[-3:]:
                prompt_parts.append(f"User: {exchange['user']}")
                prompt_parts.append(f"Assistant: {exchange['assistant']}")
        
        # Add current question
        prompt_parts.append(f"\nUser: {user_question}")
        prompt_parts.append("Assistant:")
        
        return "\n".join(prompt_parts)
    
    def generate_response(self, user_question: str, inference_engine) -> str:
        """
        Generate response to user question using LLM.
        
        Args:
            user_question: User's question
            inference_engine: InferenceEngine instance
            
        Returns:
            Generated response (max 20 words)
        """
        try:
            # Build prompt with context
            prompt = self.build_context_prompt(user_question)
            
            logger.debug(f"Conversation prompt: {prompt[:200]}...")
            
            # Generate response using inference engine
            response = inference_engine.generate(prompt, assessment=None)
            
            if not response:
                response = "I cannot answer that right now."
            
            # Ensure response is under 20 words
            words = response.split()
            if len(words) > 20:
                response = ' '.join(words[:20]) + '.'
            
            # Store exchange
            self.add_exchange(user_question, response)
            
            logger.info(f"Q: {user_question} | A: {response}")
            
            return response
            
        except Exception as e:
            logger.error(f"Response generation failed: {e}")
            return "Error processing your question."
    
    def get_welcome_message(self) -> str:
        """
        Get welcome message for system startup.
        
        Returns:
            Welcome message
        """
        return "Hello. Welcome to NETRA dot A I. Battlefield copilot ready."
    
    def clear_history(self) -> None:
        """Clear all conversation history."""
        self.conversation_history.clear()
        self.telemetry_history.clear()
        self.decision_history.clear()
        logger.info("Conversation history cleared")
