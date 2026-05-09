"""
Main orchestrator for Edge AI Copilot pipeline.
Simplified and robust: Receive → Analyze → Generate → Respond
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
from edge_ai.storage.context_store import ContextStore
from edge_ai.utils.helpers import log_telemetry, log_decision, log_error

logger = logging.getLogger(__name__)


class EdgeAICopilot:
    """
    Main orchestrator for Edge AI Copilot.
    
    Simple pipeline:
    1. Receive telemetry via MQTT
    2. Analyze threat
    3. Generate LLM decision
    4. Send response via MQTT
    5. Print to console
    """
    
    def __init__(self, config: Config):
        """Initialize all components."""
        self.config = config
        self.running = False
        
        logger.info("Initializing Edge AI Copilot...")
        
        try:
            # Threat analyzer
            self.threat_analyzer = ThreatAnalyzer(
                critical_distance=config.CRITICAL_DISTANCE,
                stress_heart_rate=config.STRESS_HEART_RATE,
                hostage_risk_distance=config.HOSTAGE_RISK_DISTANCE
            )
            logger.info("✓ Threat analyzer ready")
            
            # Prompt builder
            self.prompt_builder = PromptBuilder()
            logger.info("✓ Prompt builder ready")
            
            # Failsafe handler
            self.failsafe_handler = FailsafeHandler()
            logger.info("✓ Failsafe handler ready")
            
            # LLM inference engine
            self.inference_engine = InferenceEngine(
                model_path=config.MODEL_PATH,
                max_tokens=config.MAX_TOKENS,
                temperature=config.TEMPERATURE,
                threads=config.THREADS,
                timeout=config.INFERENCE_TIMEOUT,
                failsafe_handler=self.failsafe_handler
            )
            logger.info("✓ LLM inference engine ready")
            
            # Decision validator
            self.decision_validator = TacticalDecisionGenerator()
            logger.info("✓ Decision validator ready")
            
            # Context store
            self.context_store = ContextStore(
                storage_dir="storage/context",
                max_memory_items=100,
                max_file_items=10000
            )
            logger.info("✓ Context store ready")
            
            # MQTT publisher
            self.mqtt_publisher = MQTTPublisher(
                broker_host=config.MQTT_BROKER_HOST,
                broker_port=config.MQTT_BROKER_PORT,
                topic=config.MQTT_TOPIC_RESPONSE,
                qos=config.MQTT_QOS
            )
            logger.info("✓ MQTT publisher ready")
            
            # MQTT subscriber
            self.mqtt_subscriber = MQTTSubscriber(
                broker_host=config.MQTT_BROKER_HOST,
                broker_port=config.MQTT_BROKER_PORT,
                topic=config.MQTT_TOPIC_SENSOR,
                qos=config.MQTT_QOS,
                on_message_callback=self.process_telemetry,
                reconnect_delay=config.MQTT_RECONNECT_DELAY,
                max_reconnect_delay=config.MQTT_MAX_RECONNECT_DELAY
            )
            logger.info("✓ MQTT subscriber ready")
            
            logger.info("All components initialized successfully")
            
        except Exception as e:
            logger.error(f"Initialization failed: {e}")
            raise
    
    def process_telemetry(self, telemetry: TelemetryData) -> None:
        """
        Main processing pipeline.
        Guaranteed to send a response.
        
        Args:
            telemetry: Incoming telemetry data
        """
        start_time = time.time()
        response_sent = False
        
        print("\n" + "="*80)
        print("📡 TELEMETRY RECEIVED")
        print("="*80)
        
        try:
            # Display received data with complete formatting
            print(f"📊 TELEMETRY DATA")
            print(f"Tick      : {telemetry.tick}")
            print(f"Timestamp : {telemetry.timestamp}")
            print(f"Environment: {telemetry.environment}")
            print()
            
            print(f"👥 SQUAD ({len(telemetry.squad)} members)")
            for i, soldier in enumerate(telemetry.squad, 1):
                icon = "🟢" if soldier.status == "nominal" else "🟡" if soldier.status == "warning" else "🔴"
                print(f"  {i}. {icon} {soldier.callsign} (ID: {soldier.id})")
                print(f"     Status   : {soldier.status}")
                print(f"     Position : ({soldier.lat:.6f}, {soldier.lng:.6f})")
                print(f"     Heart Rate: {soldier.heart_rate} bpm")
                print(f"     Battery  : {soldier.battery}%")
                if i < len(telemetry.squad):
                    print()
            
            print()
            print(f"⚠️  ENEMY")
            print(f"  Callsign : {telemetry.enemy.callsign}")
            print(f"  Position : ({telemetry.enemy.lat:.6f}, {telemetry.enemy.lng:.6f})")
            
            print()
            print(f"🆘 HOSTAGE")
            print(f"  Callsign : {telemetry.hostage.callsign}")
            print(f"  Position : ({telemetry.hostage.lat:.6f}, {telemetry.hostage.lng:.6f})")
            if hasattr(telemetry.hostage, 'status'):
                print(f"  Status   : {telemetry.hostage.status}")
            
            # Display voice message if present
            if telemetry.voice_message is not None:
                print()
                print(f"🎤 VOICE MESSAGE")
                print(f"  From     : {telemetry.voice_message.unit}")
                print(f"  Message  : \"{telemetry.voice_message.message}\"")
                print(f"  Source   : {telemetry.voice_message.source}")
                print(f"  Timestamp: {telemetry.voice_message.timestamp}")
            else:
                logger.debug("No voice message in telemetry")
            
            print("-"*80)
            
            # Step 1: Analyze threat
            print("🔍 THREAT ANALYSIS")
            assessment = self.threat_analyzer.analyze(telemetry)
            
            print(f"Primary Soldier    : {assessment.primary_soldier_id}")
            print(f"Enemy Distance     : {assessment.enemy_distance:.1f}m")
            print(f"Hostage Distance   : {assessment.hostage_distance:.1f}m (from primary)")
            print(f"Threat Level       : {assessment.threat_level}")
            print(f"Risk Score         : {assessment.risk_score:.2f}")
            print(f"Squad Status       : {assessment.squad_status}")
            print(f"Hostage Risk       : {assessment.hostage_risk}")
            print(f"Stress Level       : {'HIGH' if assessment.high_stress else 'NORMAL'}")
            print("-"*80)
            
            # Step 2: Build prompt
            if telemetry.voice_message:
                print(f"🤖 PROCESSING VOICE COMMAND")
                print(f"Command from {telemetry.voice_message.unit}: \"{telemetry.voice_message.message}\"")
            else:
                print(f"🤖 GENERATING TACTICAL GUIDANCE")
            
            prompt = self.prompt_builder.build_prompt(telemetry, assessment)
            logger.debug(f"Prompt: {prompt}")
            
            # Step 3: Generate LLM decision
            raw_decision = self.inference_engine.generate(prompt, assessment)
            
            if raw_decision and len(raw_decision.strip()) > 0:
                # Validate and clean
                decision = self.decision_validator.validate_decision(raw_decision)
                logger.info(f"✅ LLM generated: {decision}")
            else:
                # Fallback
                if telemetry.voice_message:
                    decision = f"Roger {telemetry.voice_message.unit}, message received."
                else:
                    decision = "Maintain current position and monitor."
                logger.warning("⚠️  LLM returned empty, using acknowledgment")
            
            # Ensure we have a valid decision
            if not decision or len(decision.strip()) < 3:
                if telemetry.voice_message:
                    decision = f"Roger {telemetry.voice_message.unit}, message received."
                else:
                    decision = "Maintain current position and monitor."
                logger.warning("⚠️  Decision validation failed, using acknowledgment")
            
            # Calculate latency
            latency_ms = int((time.time() - start_time) * 1000)
            
            # Step 4: Print decision
            print()
            print("✅ AI RESPONSE")
            if telemetry.voice_message:
                print(f"To       : {telemetry.voice_message.unit}")
            print(f"Decision : {decision}")
            print(f"Latency  : {latency_ms}ms")
            print("-"*80)
            
            # Step 5: Send response via MQTT
            print("📤 Sending response to broker...")
            
            # Prepare voice message context if present
            replying_to_unit = None
            replying_to_message = None
            original_timestamp = None
            
            if telemetry.voice_message:
                replying_to_unit = telemetry.voice_message.unit
                replying_to_message = telemetry.voice_message.message
                original_timestamp = telemetry.voice_message.timestamp
            
            self.mqtt_publisher.publish_response(
                decision=decision,
                risk_score=assessment.risk_score,
                timestamp=telemetry.timestamp,
                latency_ms=latency_ms,
                replying_to_unit=replying_to_unit,
                replying_to_message=replying_to_message,
                original_timestamp=original_timestamp,
                threat_level=assessment.threat_level
            )
            response_sent = True
            print("✅ Response sent successfully")
            
            # Display response details
            if replying_to_unit:
                print(f"   Replying to: {replying_to_unit}")
                print(f"   Original msg: \"{replying_to_message}\"")
            
            print("="*80 + "\n")
            
            # Step 6: Store context (non-critical)
            try:
                self.context_store.store_telemetry(
                    telemetry=telemetry,
                    assessment=assessment,
                    decision=decision,
                    latency_ms=latency_ms
                )
            except Exception as e:
                logger.warning(f"Context storage failed: {e}")
            
            logger.info(f"Pipeline completed successfully in {latency_ms}ms")
            
        except Exception as e:
            # Error handling
            logger.error(f"Pipeline error: {e}", exc_info=True)
            print(f"❌ Error: {e}")
            print("-"*80)
            
            # Always send acknowledgment if we haven't sent response yet
            if not response_sent:
                try:
                    latency_ms = int((time.time() - start_time) * 1000)
                    print("📤 Sending acknowledgment...")
                    
                    # Prepare voice message context if present
                    replying_to_unit = None
                    replying_to_message = None
                    original_timestamp = None
                    
                    if telemetry.voice_message:
                        replying_to_unit = telemetry.voice_message.unit
                        replying_to_message = telemetry.voice_message.message
                        original_timestamp = telemetry.voice_message.timestamp
                    
                    self.mqtt_publisher.publish_response(
                        decision="OK, I received your message.",
                        risk_score=0.0,
                        timestamp=telemetry.timestamp,
                        latency_ms=latency_ms,
                        replying_to_unit=replying_to_unit,
                        replying_to_message=replying_to_message,
                        original_timestamp=original_timestamp,
                        threat_level="unknown"
                    )
                    print("✅ Acknowledgment sent")
                    print("="*80 + "\n")
                except Exception as e2:
                    logger.error(f"Failed to send acknowledgment: {e2}")
                    print(f"❌ Failed to send acknowledgment: {e2}")
                    print("="*80 + "\n")
    
    def start(self) -> None:
        """Start the Edge AI Copilot system."""
        try:
            logger.info("Starting Edge AI Copilot...")
            
            # Connect MQTT publisher
            self.mqtt_publisher.connect()
            logger.info("MQTT publisher connected")
            
            # Connect and start MQTT subscriber
            self.mqtt_subscriber.connect()
            self.mqtt_subscriber.start()
            logger.info("MQTT subscriber connected and listening")
            
            self.running = True
            
            # Print startup message
            print("\n" + "="*80)
            print("🚀 EDGE AI COPILOT ONLINE")
            print("="*80)
            print(f"MQTT Broker    : {self.config.MQTT_BROKER_HOST}:{self.config.MQTT_BROKER_PORT}")
            print(f"Listening on   : {self.config.MQTT_TOPIC_SENSOR}")
            print(f"Publishing to  : {self.config.MQTT_TOPIC_RESPONSE}")
            print(f"LLM Model      : {self.config.MODEL_PATH}")
            print(f"Max Tokens     : {self.config.MAX_TOKENS}")
            print(f"Temperature    : {self.config.TEMPERATURE}")
            print("="*80)
            print("Waiting for telemetry... (Press Ctrl+C to stop)")
            print("="*80 + "\n")
            
            logger.info("System ready and waiting for telemetry")
            
            # Keep main thread alive
            while self.running:
                time.sleep(1)
                
        except KeyboardInterrupt:
            logger.info("Keyboard interrupt received")
            self.stop()
        except Exception as e:
            logger.error(f"Startup error: {e}", exc_info=True)
            self.stop()
            raise
    
    def stop(self) -> None:
        """Gracefully shutdown all components."""
        logger.info("Shutting down Edge AI Copilot...")
        self.running = False
        
        print("\n" + "="*80)
        print("🛑 SHUTTING DOWN")
        print("="*80)
        
        try:
            # Stop MQTT subscriber
            if hasattr(self, 'mqtt_subscriber'):
                self.mqtt_subscriber.stop()
                print("✓ MQTT subscriber stopped")
            
            # Disconnect MQTT publisher
            if hasattr(self, 'mqtt_publisher'):
                self.mqtt_publisher.disconnect()
                print("✓ MQTT publisher disconnected")
            
            # Cleanup inference engine
            if hasattr(self, 'inference_engine'):
                self.inference_engine.cleanup()
                print("✓ LLM engine cleaned up")
            
            print("="*80)
            print("Shutdown complete")
            print("="*80 + "\n")
            
            logger.info("Shutdown complete")
            
        except Exception as e:
            logger.error(f"Error during shutdown: {e}")
    
    def setup_signal_handlers(self) -> None:
        """Setup signal handlers for graceful shutdown."""
        def signal_handler(signum, frame):
            logger.info(f"Received signal {signum}")
            self.stop()
            sys.exit(0)
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
