"""
Main orchestrator for Edge AI Copilot pipeline.
Coordinates MQTT, threat analysis, LLM inference, and response publishing.
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
    Main orchestrator that coordinates the entire Edge AI pipeline.
    
    Pipeline Flow:
    1. Receive telemetry via MQTT
    2. Analyze threat level
    3. Build LLM prompt
    4. Generate tactical decision
    5. Validate decision
    6. Publish response via MQTT
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
        
        try:
            # Initialize threat analyzer
            self.threat_analyzer = ThreatAnalyzer(
                critical_distance=config.CRITICAL_DISTANCE,
                stress_heart_rate=config.STRESS_HEART_RATE,
                hostage_risk_distance=config.HOSTAGE_RISK_DISTANCE
            )
            logger.info("✓ Threat analyzer initialized")
            
            # Initialize prompt builder
            self.prompt_builder = PromptBuilder()
            logger.info("✓ Prompt builder initialized")
            
            # Initialize failsafe handler
            self.failsafe_handler = FailsafeHandler()
            logger.info("✓ Failsafe handler initialized")
            
            # Initialize inference engine
            self.inference_engine = InferenceEngine(
                model_path=config.MODEL_PATH,
                max_tokens=config.MAX_TOKENS,
                temperature=config.TEMPERATURE,
                threads=config.THREADS,
                timeout=config.INFERENCE_TIMEOUT,
                failsafe_handler=self.failsafe_handler
            )
            logger.info("✓ Inference engine initialized")
            
            # Initialize decision validator
            self.decision_validator = TacticalDecisionGenerator()
            logger.info("✓ Decision validator initialized")
            
            # Initialize context store
            self.context_store = ContextStore(
                storage_dir="storage/context",
                max_memory_items=100,
                max_file_items=10000
            )
            logger.info("✓ Context store initialized")
            
            # Initialize MQTT publisher
            self.mqtt_publisher = MQTTPublisher(
                broker_host=config.MQTT_BROKER_HOST,
                broker_port=config.MQTT_BROKER_PORT,
                topic=config.MQTT_TOPIC_RESPONSE,
                qos=config.MQTT_QOS
            )
            logger.info("✓ MQTT publisher initialized")
            
            # Initialize MQTT subscriber (uses callback)
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

            # Console display
            print("\n" + "="*70)
            print("📡 TELEMETRY RECEIVED")
            print("="*70)
            print(f"  Tick        : {telemetry.tick}")
            print(f"  Timestamp   : {telemetry.timestamp}")
            print(f"  Squad Size  : {len(telemetry.squad)} members")
            
            # Display squad members
            for soldier in telemetry.squad:
                status_icon = "🟢" if soldier.status == "nominal" else "🟡" if soldier.status == "warning" else "🔴"
                print(f"    {status_icon} {soldier.callsign}: HR={soldier.heart_rate}bpm, Battery={soldier.battery}%, Status={soldier.status}")
            
            print(f"  Enemy       : {telemetry.enemy.callsign} at ({telemetry.enemy.lat:.4f}, {telemetry.enemy.lng:.4f})")
            print(f"  Hostage     : {telemetry.hostage.callsign} at ({telemetry.hostage.lat:.4f}, {telemetry.hostage.lng:.4f})")
            print("-"*70)

            # Step 1: Analyze threat
            assessment = self.threat_analyzer.analyze(telemetry)

            # Console display
            print(f"🔍 THREAT ANALYSIS")
            print(f"  Primary     : {assessment.primary_soldier_id}")
            print(f"  Distance    : {assessment.enemy_distance:.1f}m")
            print(f"  Threat Level: {assessment.threat_level}")
            print(f"  Risk Score  : {assessment.risk_score:.2f}")
            print(f"  Stress Level: {assessment.soldier_stress}")
            print(f"  Hostage Risk: {assessment.hostage_risk}")
            print(f"  Squad Status: {assessment.squad_status}")
            print("-"*70)

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

            # Console display
            print(f"🤖 AI DECISION")
            print(f"  Decision    : {decision}")
            print(f"  Latency     : {latency_ms}ms")
            print("="*70 + "\n")

            # Step 7: Store context for future predictions
            self.context_store.store_telemetry(
                telemetry=telemetry,
                assessment=assessment,
                decision=decision,
                latency_ms=latency_ms
            )

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
            
            logger.info("="*70)
            logger.info("Edge AI Copilot is running")
            logger.info("Listening for telemetry on: " + self.config.MQTT_TOPIC_SENSOR)
            logger.info("Publishing responses to: " + self.config.MQTT_TOPIC_RESPONSE)
            logger.info("Press Ctrl+C to stop")
            logger.info("="*70)
            
            print("\n" + "="*70)
            print("🚀 EDGE AI COPILOT ONLINE")
            print("="*70)
            print(f"  MQTT Broker : {self.config.MQTT_BROKER_HOST}:{self.config.MQTT_BROKER_PORT}")
            print(f"  Sensor Topic: {self.config.MQTT_TOPIC_SENSOR}")
            print(f"  Response    : {self.config.MQTT_TOPIC_RESPONSE}")
            print(f"  Model       : {self.config.MODEL_PATH}")
            print("="*70)
            print("  Waiting for telemetry...")
            print("="*70 + "\n")
            
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
