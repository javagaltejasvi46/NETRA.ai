"""
Main entry point for Edge AI Copilot.
"""
import sys
import platform
from pathlib import Path

from edge_ai.config import Config
from edge_ai.orchestrator import EdgeAICopilot
from edge_ai.utils.helpers import setup_logging


def print_banner():
    """Print startup banner."""
    banner = """
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║              EDGE AI COPILOT v1.0.0                       ║
    ║         Autonomous Battlefield Edge AI Unit              ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
    """
    print(banner)


def print_system_info():
    """Print system information."""
    print(f"    Platform: {platform.system()} {platform.release()}")
    print(f"    Python: {platform.python_version()}")
    print(f"    Architecture: {platform.machine()}")
    print()


def validate_environment():
    """
    Validate environment and dependencies.
    
    Returns:
        True if environment is valid, False otherwise
    """
    print("    Validating environment...")
    
    # Check Python version
    if sys.version_info < (3, 8):
        print("    ✗ Python 3.8+ required")
        return False
    print("    ✓ Python version OK")
    
    # Check required packages
    required_packages = [
        ('paho.mqtt', 'paho-mqtt'),
        ('llama_cpp', 'llama-cpp-python')
    ]
    
    missing_packages = []
    for module_name, package_name in required_packages:
        try:
            __import__(module_name)
            print(f"    ✓ {package_name} installed")
        except ImportError:
            print(f"    ✗ {package_name} not installed")
            missing_packages.append(package_name)
    
    if missing_packages:
        print(f"\n    Missing packages: {', '.join(missing_packages)}")
        print(f"    Install with: pip install {' '.join(missing_packages)}")
        return False
    
    print()
    return True


def main():
    """
    Main entry point.
    """
    # Print banner
    print_banner()
    print_system_info()
    
    # Validate environment
    if not validate_environment():
        print("    Environment validation failed. Exiting.")
        sys.exit(1)
    
    try:
        # Setup logging
        logger = setup_logging(
            log_dir=Config.LOG_DIR,
            retention_days=Config.LOG_RETENTION_DAYS
        )
        
        # Log system information
        logger.info(f"Platform: {platform.system()} {platform.release()}")
        logger.info(f"Python: {platform.python_version()}")
        logger.info(f"Architecture: {platform.machine()}")
        
        # Validate configuration
        logger.info("Validating configuration...")
        Config.validate()
        logger.info("Configuration validated successfully")
        
        # Log configuration summary
        logger.info("Configuration Summary:")
        logger.info(f"  MQTT Broker: {Config.MQTT_BROKER_HOST}:{Config.MQTT_BROKER_PORT}")
        logger.info(f"  Sensor Topic: {Config.MQTT_TOPIC_SENSOR}")
        logger.info(f"  Response Topic: {Config.MQTT_TOPIC_RESPONSE}")
        logger.info(f"  Model: {Config.MODEL_PATH}")
        logger.info(f"  Max Tokens: {Config.MAX_TOKENS}")
        logger.info(f"  Temperature: {Config.TEMPERATURE}")
        logger.info(f"  Threads: {Config.THREADS}")
        logger.info(f"  Critical Distance: {Config.CRITICAL_DISTANCE}m")
        logger.info(f"  Stress Heart Rate: {Config.STRESS_HEART_RATE} bpm")
        
        # Initialize and start Edge AI Copilot
        copilot = EdgeAICopilot(Config)
        copilot.setup_signal_handlers()
        copilot.start()
        
    except FileNotFoundError as e:
        print(f"\n    ✗ Error: {e}")
        print(f"    Please ensure the model file exists at: {Config.MODEL_PATH}")
        print(f"    Download with:")
        print(f"    wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O {Config.MODEL_PATH}")
        sys.exit(1)
        
    except ValueError as e:
        print(f"\n    ✗ Configuration error: {e}")
        sys.exit(1)
        
    except KeyboardInterrupt:
        print("\n    Interrupted by user")
        sys.exit(0)
        
    except Exception as e:
        print(f"\n    ✗ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
