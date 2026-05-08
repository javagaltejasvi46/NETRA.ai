"""
Main orchestrator for Edge AI Copilot pipeline.
"""
import logging
import signal
import sys
import time
from typing import Optional

from edge_ai.config import Config
from edge_ai.mqtt.subscriber import MQTTSubscriber
from edge_ai.mqtt.publisher import MQTTPublisher
from edge_ai.mqtt.models import TelemetryData
from edge_ai.ai.threat_analysis import ThreatAnalyzer
from edge_ai.ai.prompt_builder import PromptBuilder
from edge_ai.ai.inference import InferenceEngine
from edge_ai.ai.failsafe import FailsafeHandler
from edge_ai.ai.decision_validator import TacticalDecisionGenerator
from edge_ai.ai.conversation_manager import ConversationManager
from edge_ai.voice.tts import TTSEngine
from edge_ai.voice.speech_recognition import SpeechRecognizer
from edge_ai.utils.helpers import log_telemetry, log_decision, log_error

logger = logging.getLogger(__name__)


class EdgeAICopilot:
    """
    Main orchestrator that coordinates the entire Edge AI pipeline.
    """
    
    def __init__(self, config: Config):
        """
        Initialize all components of the Edge AI system.
        
        Args:
            config: Configuration instance
        """
        self.config = config
        self.running = False
        
        logger.info("Initializing Edge AI Copilot components...")
        
        # Initialize components
        try:
            # Threat analysis
            self.threat_analyzer = ThreatAnalyzer(
                critical_distance=config.CRITICAL_DISTANCE,
                stress_heart_rate=config.STRESS_HEART_RATE,
                hostage_risk_distance=config.HOSTAGE_RISK_DISTANCE
            )
            logger.info("✓ Threat analyzer initialized")
            
            # Prompt builder
            self.prompt_builder = PromptBuilder()
            logger.info("✓ Prompt builder initialized")
            
            # Failsafe handler
            self.failsafe_handler = FailsafeHandler()
            logger.info("✓ Failsafe handler initialized")
            
            # Inference engine
            self.inference_engine = InferenceEngine(
                model_path=config.MODEL_PATH,
                max_tokens=config.MAX_TOKENS,
                temperature=config.TEMPERATURE,
                threads=config.THREADS,
                timeout=config.INFERENCE_TIMEOUT,
                failsafe_handler=self.failsafe_handler
            )
            logger.info("✓ Inference engine initialized")
            
            # Decision validator
            self.decision_validator = TacticalDecisionGenerator()
            logger.info("✓ Decision validator initialized")
            
            # Conversation manager
            self.conversation_manager = ConversationManager()
            logger.info("✓ Conversation manager initialized")
            
            # TTS engine
            self.tts_engine = TTSEngine(
                model_name=config.TTS_MODEL,
                timeout=config.TTS_TIMEOUT
            )
            logger.info("✓ TTS engine initialized")
            
            # Voice input (optional)
            self.voice_input_enabled = config.VOICE_INPUT_ENABLED
            if self.voice_input_enabled:
                try:
                    self.speech_recognizer = SpeechRecognizer(
                        model_size=config.WHISPER_MODEL,
                        duration=config.LISTENING_DURATION
                    )
                    logger.info("✓ Speech recognizer initialized")
                except Exception as e:
                    logger.warning(f"Speech recognizer failed to initialize: {e}")
                    logger.warning("Voice input disabled")
                    self.voice_input_enabled = False
            else:
                self.speech_recognizer = None
                logger.info("Voice input disabled in config")
            
            # MQTT publisher
            self.mqtt_publisher = MQTTPublisher(
                broker_host=config.MQTT_BROKER_HOST,
                broker_port=config.MQTT_BROKER_PORT,
                topic=config.MQTT_TOPIC_RESPONSE,
                qos=config.MQTT_QOS
            )
            logger.info("✓ MQTT publisher initialized")
            
            # MQTT subscriber (initialized last, uses callback)
            self.mqtt_subscriber = MQTTSubscriber(
                broker_host=config.MQTT_BROKER_HOST,
                broker_port=config.MQTT_BROKER_PORT,
                topic=config.MQTT_TOPIC_SENSOR,
                qos=config.MQTT_QOS,
                on_message_callback=self.on_telemetry_received,
                reconnect_delay=config.MQTT_RECONNECT_DELAY,
                max_reconnect_delay=config.MQTT_MAX_RECONNECT_DELAY
            )
            logger.info("✓ MQTT subscriber initialized")
            
            logger.info("All components initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize components: {e}")
            raise
    
    def on_telemetry_received(self, telemetry: TelemetryData) -> None:
        """
        Pipeline handler for incoming telemetry.
        Processes telemetry through the complete AI pipeline.
        
        Args:
            telemetry: Parsed telemetry data
        """
        start_time = time.time()
        
        try:
            # Log telemetry
            log_telemetry(logger, telemetry)
            
            # Step 1: Analyze threat
            assessment = self.threat_analyzer.analyze(telemetry)
            
            # Store context for conversation
            self.conversation_manager.add_telemetry(telemetry, assessment)
            
            # Step 2: Build prompt
            prompt = self.prompt_builder.build_prompt(telemetry, assessment)
            
            # Step 3: Generate decision (with automatic fallback)
            raw_decision = self.inference_engine.generate(prompt, assessment)
            
            if not raw_decision:
                logger.error("Failed to generate decision")
                return
            
            # Step 4: Validate and format decision
            decision = self.decision_validator.validate_decision(raw_decision)
            
            if not decision:
                logger.error("Decision validation failed")
                return
            
            # Calculate latency
            latency_ms = int((time.time() - start_time) * 1000)
            
            # Step 5: Log decision
            log_decision(logger, decision, assessment.risk_score, latency_ms)
            
            # Store decision in conversation context
            self.conversation_manager.add_decision(decision)
            
            # Step 6: Speak decision (non-blocking, failures don't stop pipeline)
            try:
                self.tts_engine.speak(decision)
            except Exception as e:
                logger.warning(f"TTS failed but continuing: {e}")
            
            # Step 7: Listen for user voice input (if enabled)
            if self.voice_input_enabled and self.speech_recognizer:
                try:
                    self._handle_voice_interaction()
                except Exception as e:
                    logger.warning(f"Voice interaction failed: {e}")
            
            # Step 8: Publish response
            self.mqtt_publisher.publish_response(
                decision=decision,
                risk_score=assessment.risk_score,
                timestamp=telemetry.timestamp,
                latency_ms=latency_ms
            )
            
            logger.info(f"Pipeline completed in {latency_ms}ms")
            
        except Exception as e:
            log_error(logger, "Pipeline", e)
    
    def _handle_voice_interaction(self) -> None:
        """
        Handle voice input from user after tactical decision.
        Opens 5-second listening window for user questions.
        """
        try:
            logger.info("Opening listening window for user input...")
            
            # Listen for user speech
            user_input = self.speech_recognizer.listen()
            
            if not user_input or len(user_input.strip()) < 3:
                logger.info("No valid user input detected")
                return
            
            logger.info(f"User asked: {user_input}")
            
            # Generate response using conversation manager
            response = self.conversation_manager.generate_response(
                user_input,
                self.inference_engine
            )
            
            # Speak response
            if response:
                logger.info(f"Responding: {response}")
                self.tts_engine.speak(response)
            
        except Exception as e:
            logger.error(f"Voice interaction error: {e}")
    
    def _play_welcome_message(self) -> None:
        """
        Play welcome message on system startup.
        """
        try:
            if self.config.ENABLE_WELCOME_MESSAGE:
                welcome = self.conversation_manager.get_welcome_message()
                logger.info(f"Playing welcome message: {welcome}")
                self.tts_engine.speak(welcome)
                
                # Optional: Listen for initial user input
                if self.voice_input_enabled and self.speech_recognizer:
                    logger.info("Listening for initial user input...")
                    self._handle_voice_interaction()
        except Exception as e:
            logger.warning(f"Welcome message failed: {e}")
    
    def start(self) -> None:
        """
        Start the Edge AI Copilot system.
        """
        try:
            logger.info("Starting Edge AI Copilot...")
            
            # Connect MQTT publisher
            self.mqtt_publisher.connect()
            
            # Connect and start MQTT subscriber
            self.mqtt_subscriber.connect()
            self.mqtt_subscriber.start()
            
            self.running = True
            
            # Play welcome message
            self._play_welcome_message()
            
            logger.info("Edge AI Copilot is running. Press Ctrl+C to stop.")
            
            # Keep main thread alive
            while self.running:
                time.sleep(1)
                
        except KeyboardInterrupt:
            logger.info("Keyboard interrupt received")
            self.stop()
        except Exception as e:
            log_error(logger, "Startup", e)
            self.stop()
            raise
    
    def stop(self) -> None:
        """
        Gracefully shutdown all components.
        """
        logger.info("Shutting down Edge AI Copilot...")
        self.running = False
        
        try:
            # Stop MQTT subscriber
            if hasattr(self, 'mqtt_subscriber'):
                self.mqtt_subscriber.stop()
            
            # Disconnect MQTT publisher
            if hasattr(self, 'mqtt_publisher'):
                self.mqtt_publisher.disconnect()
            
            # Cleanup inference engine
            if hasattr(self, 'inference_engine'):
                self.inference_engine.cleanup()
            
            logger.info("Shutdown complete")
            
        except Exception as e:
            logger.error(f"Error during shutdown: {e}")
    
    def setup_signal_handlers(self) -> None:
        """
        Setup signal handlers for graceful shutdown.
        """
        def signal_handler(signum, frame):
            logger.info(f"Received signal {signum}")
            self.stop()
            sys.exit(0)
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
