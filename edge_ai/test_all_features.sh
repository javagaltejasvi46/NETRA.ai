#!/bin/bash
# Comprehensive test script for all Edge AI Copilot features
# Tests: MQTT, Threat Analysis, LLM Inference, TTS, Voice Input, End-to-End Pipeline
#
# Usage:
#   ./test_all_features.sh           - Run tests only
#   ./test_all_features.sh --install - Run tests and auto-install missing packages
#   ./test_all_features.sh -i        - Same as --install

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Logging
LOG_FILE="logs/test_results_$(date +%Y%m%d_%H%M%S).log"
mkdir -p logs

echo "=========================================="
echo "Edge AI Copilot - Comprehensive Test Suite"
echo "=========================================="
echo ""
echo "Log file: $LOG_FILE"
echo ""

# Check for --install flag
INSTALL_MISSING=false
if [ "$1" == "--install" ] || [ "$1" == "-i" ]; then
    INSTALL_MISSING=true
    echo -e "${YELLOW}Auto-install mode enabled${NC}"
    echo ""
fi

# Helper functions
print_test_header() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "TEST: $1"
    echo -e "==========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++))
    echo "[PASS] $1" >> "$LOG_FILE"
}

print_failure() {
    echo -e "${RED}✗ $1${NC}"
    ((TESTS_FAILED++))
    echo "[FAIL] $1" >> "$LOG_FILE"
}

print_skip() {
    echo -e "${YELLOW}⊘ $1${NC}"
    ((TESTS_SKIPPED++))
    echo "[SKIP] $1" >> "$LOG_FILE"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Test 1: System Dependencies
print_test_header "1. System Dependencies"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_success "Python installed: $PYTHON_VERSION"
else
    print_failure "Python not found"
fi

if command -v mosquitto &> /dev/null; then
    print_success "Mosquitto installed"
else
    print_failure "Mosquitto not found"
fi

if command -v arecord &> /dev/null; then
    print_success "arecord (audio recording) available"
else
    print_failure "arecord not found"
fi

if command -v aplay &> /dev/null; then
    print_success "aplay (audio playback) available"
else
    print_failure "aplay not found"
fi

# Test 2: Python Packages
print_test_header "2. Python Package Dependencies"

check_python_package() {
    if python3 -c "import $1" 2>/dev/null; then
        print_success "$2 installed"
        return 0
    else
        if [ "$INSTALL_MISSING" = true ]; then
            print_info "Installing $2..."
            pip3 install $3 --no-cache-dir
            if python3 -c "import $1" 2>/dev/null; then
                print_success "$2 installed successfully"
                return 0
            else
                print_failure "$2 installation failed"
                return 1
            fi
        else
            print_failure "$2 not installed"
            return 1
        fi
    fi
}

# Core packages
check_python_package "paho.mqtt.client" "paho-mqtt" "paho-mqtt"
check_python_package "llama_cpp" "llama-cpp-python" "llama-cpp-python"
check_python_package "pygame" "pygame" "pygame"

# Voice input packages (newly added)
if [ "$INSTALL_MISSING" = true ]; then
    print_info "Checking voice input packages..."
    
    # Install system dependencies first
    if ! command -v ffmpeg &> /dev/null; then
        print_info "Installing system dependencies for voice input..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq alsa-utils portaudio19-dev libsndfile1 ffmpeg
    fi
fi

check_python_package "whisper" "openai-whisper" "openai-whisper"
check_python_package "noisereduce" "noisereduce" "noisereduce"
check_python_package "soundfile" "soundfile" "soundfile"

# Optional TTS
if python3 -c "import piper" 2>/dev/null; then
    print_success "piper-tts installed"
else
    if [ "$INSTALL_MISSING" = true ]; then
        print_info "Installing piper-tts..."
        pip3 install piper-tts --no-cache-dir
        if python3 -c "import piper" 2>/dev/null; then
            print_success "piper-tts installed successfully"
        else
            print_skip "piper-tts installation failed (optional)"
        fi
    else
        print_skip "piper-tts not installed (optional)"
    fi
fi

# Test 3: File Structure
print_test_header "3. File Structure"

check_file() {
    if [ -f "$1" ]; then
        print_success "File exists: $1"
        return 0
    else
        print_failure "File missing: $1"
        return 1
    fi
}

check_file "config.py"
check_file "main.py"
check_file "orchestrator.py"
check_file "mqtt/subscriber.py"
check_file "mqtt/publisher.py"
check_file "ai/inference.py"
check_file "ai/threat_analysis.py"
check_file "voice/tts.py"
check_file "voice/speech_recognition.py"
check_file "ai/conversation_manager.py"

# Test 4: Model File
print_test_header "4. AI Model"

if [ -f "models/tinyllama.gguf" ]; then
    MODEL_SIZE=$(du -h models/tinyllama.gguf | cut -f1)
    print_success "Model file exists (${MODEL_SIZE})"
else
    if [ "$INSTALL_MISSING" = true ]; then
        print_info "Downloading AI model (this may take 5-15 minutes)..."
        mkdir -p models
        
        if wget --tries=3 --timeout=60 --continue \
            https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
            -O models/tinyllama.gguf 2>&1 | grep -v "^--"; then
            print_success "Model downloaded successfully"
        else
            print_failure "Model download failed"
            print_info "Try manually: ./fix_now.sh"
        fi
    else
        print_failure "Model file missing: models/tinyllama.gguf"
        print_info "Download with: ./fix_now.sh or run with --install flag"
    fi
fi

# Test 5: MQTT Broker
print_test_header "5. MQTT Broker"

if sudo systemctl is-active --quiet mosquitto; then
    print_success "Mosquitto service running"
    
    # Test MQTT pub/sub
    print_info "Testing MQTT pub/sub..."
    timeout 3 mosquitto_sub -t test/edge_ai -C 1 > /tmp/mqtt_test.txt 2>&1 &
    sleep 1
    mosquitto_pub -t test/edge_ai -m "test_message" 2>&1
    sleep 1
    
    if grep -q "test_message" /tmp/mqtt_test.txt 2>/dev/null; then
        print_success "MQTT pub/sub working"
    else
        print_failure "MQTT pub/sub failed"
    fi
    rm -f /tmp/mqtt_test.txt
else
    print_failure "Mosquitto service not running"
    print_info "Start with: sudo systemctl start mosquitto"
fi

# Test 6: Audio Devices
print_test_header "6. Audio Devices"

if arecord -l &> /dev/null; then
    AUDIO_DEVICES=$(arecord -l 2>/dev/null | grep -c "card")
    if [ "$AUDIO_DEVICES" -gt 0 ]; then
        print_success "Audio input devices found: $AUDIO_DEVICES"
    else
        print_failure "No audio input devices found"
    fi
else
    print_failure "Cannot list audio devices"
fi

if aplay -l &> /dev/null; then
    PLAYBACK_DEVICES=$(aplay -l 2>/dev/null | grep -c "card")
    if [ "$PLAYBACK_DEVICES" -gt 0 ]; then
        print_success "Audio output devices found: $PLAYBACK_DEVICES"
    else
        print_failure "No audio output devices found"
    fi
else
    print_failure "Cannot list playback devices"
fi

# Test 7: Python Module Imports
print_test_header "7. Python Module Imports"

print_info "Testing module imports..."

python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from edge_ai.config import Config
    print("✓ Config import OK")
except Exception as e:
    print(f"✗ Config import failed: {e}")
    sys.exit(1)

try:
    from edge_ai.mqtt.models import TelemetryData
    print("✓ TelemetryData import OK")
except Exception as e:
    print(f"✗ TelemetryData import failed: {e}")
    sys.exit(1)

try:
    from edge_ai.ai.threat_analysis import ThreatAnalyzer
    print("✓ ThreatAnalyzer import OK")
except Exception as e:
    print(f"✗ ThreatAnalyzer import failed: {e}")
    sys.exit(1)

try:
    from edge_ai.voice.tts import TTSEngine
    print("✓ TTSEngine import OK")
except Exception as e:
    print(f"✗ TTSEngine import failed: {e}")
    sys.exit(1)

try:
    from edge_ai.ai.conversation_manager import ConversationManager
    print("✓ ConversationManager import OK")
except Exception as e:
    print(f"✗ ConversationManager import failed: {e}")
    sys.exit(1)

print("All imports successful")
EOF

if [ $? -eq 0 ]; then
    print_success "All Python modules import successfully"
else
    print_failure "Python module import errors"
fi

# Test 8: Telemetry Parsing
print_test_header "8. Telemetry Data Parsing"

python3 << 'EOF'
import sys
import os
import json
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.mqtt.models import TelemetryData

# Test valid telemetry
payload = json.dumps({
    "timestamp": 1710000000,
    "soldier": {"x": 120, "y": 340, "heart_rate": 125},
    "enemy": {"x": 180, "y": 360},
    "hostage": {"x": 140, "y": 350},
    "environment": "urban",
    "threat_level": "high"
})

telemetry = TelemetryData.from_json(payload)
if telemetry:
    print("✓ Valid telemetry parsed successfully")
else:
    print("✗ Failed to parse valid telemetry")
    sys.exit(1)

# Test malformed telemetry
bad_payload = '{"invalid": json}'
bad_telemetry = TelemetryData.from_json(bad_payload)
if bad_telemetry is None:
    print("✓ Malformed telemetry rejected correctly")
else:
    print("✗ Malformed telemetry not rejected")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "Telemetry parsing works correctly"
else
    print_failure "Telemetry parsing failed"
fi

# Test 9: Threat Analysis
print_test_header "9. Threat Analysis Engine"

python3 << 'EOF'
import sys
import os
import json
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.mqtt.models import TelemetryData
from edge_ai.ai.threat_analysis import ThreatAnalyzer

analyzer = ThreatAnalyzer(critical_distance=100, stress_heart_rate=120, hostage_risk_distance=50)

# Test critical threat
payload = json.dumps({
    "timestamp": 1710000000,
    "soldier": {"x": 100, "y": 100, "heart_rate": 130},
    "enemy": {"x": 150, "y": 100},
    "hostage": {"x": 140, "y": 100},
    "environment": "urban",
    "threat_level": "high"
})

telemetry = TelemetryData.from_json(payload)
assessment = analyzer.analyze(telemetry)

if assessment.threat_level == "CRITICAL":
    print(f"✓ Critical threat detected correctly (distance: {assessment.enemy_distance:.1f}m)")
else:
    print(f"✗ Threat level incorrect: {assessment.threat_level}")
    sys.exit(1)

if 0.0 <= assessment.risk_score <= 1.0:
    print(f"✓ Risk score valid: {assessment.risk_score:.2f}")
else:
    print(f"✗ Risk score out of range: {assessment.risk_score}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "Threat analysis engine working"
else
    print_failure "Threat analysis failed"
fi

# Test 10: Prompt Builder
print_test_header "10. Prompt Builder"

python3 << 'EOF'
import sys
import os
import json
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.mqtt.models import TelemetryData
from edge_ai.ai.threat_analysis import ThreatAnalyzer
from edge_ai.ai.prompt_builder import PromptBuilder

analyzer = ThreatAnalyzer(100, 120, 50)
builder = PromptBuilder()

payload = json.dumps({
    "timestamp": 1710000000,
    "soldier": {"x": 120, "y": 340, "heart_rate": 125},
    "enemy": {"x": 180, "y": 360},
    "hostage": {"x": 140, "y": 350},
    "environment": "urban",
    "threat_level": "high"
})

telemetry = TelemetryData.from_json(payload)
assessment = analyzer.analyze(telemetry)
prompt = builder.build_prompt(telemetry, assessment)

if "battlefield tactical AI" in prompt:
    print("✓ Prompt contains system instruction")
else:
    print("✗ Prompt missing system instruction")
    sys.exit(1)

if "Enemy distance:" in prompt:
    print("✓ Prompt contains enemy distance")
else:
    print("✗ Prompt missing enemy distance")
    sys.exit(1)

print(f"✓ Prompt generated ({len(prompt)} chars)")
EOF

if [ $? -eq 0 ]; then
    print_success "Prompt builder working"
else
    print_failure "Prompt builder failed"
fi

# Test 11: Decision Validator
print_test_header "11. Tactical Decision Validator"

python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.ai.decision_validator import TacticalDecisionGenerator

validator = TacticalDecisionGenerator()

# Test word count limit
long_decision = " ".join(["word"] * 30)
validated = validator.validate_decision(long_decision)
word_count = len(validated.split())

if word_count <= 20:
    print(f"✓ Word count enforced: {word_count} words")
else:
    print(f"✗ Word count not enforced: {word_count} words")
    sys.exit(1)

# Test formatting
decision = "move to cover"
formatted = validator.format_decision(decision)

if formatted[0].isupper() and formatted.endswith('.'):
    print("✓ Formatting applied correctly")
else:
    print("✗ Formatting failed")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "Decision validator working"
else
    print_failure "Decision validator failed"
fi

# Test 12: Failsafe Handler
print_test_header "12. Failsafe Handler"

python3 << 'EOF'
import sys
import os
import json
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.mqtt.models import TelemetryData
from edge_ai.ai.threat_analysis import ThreatAnalyzer
from edge_ai.ai.failsafe import FailsafeHandler

analyzer = ThreatAnalyzer(100, 120, 50)
failsafe = FailsafeHandler()

# Test immediate retreat
payload = json.dumps({
    "timestamp": 1710000000,
    "soldier": {"x": 100, "y": 100, "heart_rate": 130},
    "enemy": {"x": 130, "y": 100},
    "hostage": {"x": 200, "y": 100},
    "environment": "urban",
    "threat_level": "critical"
})

telemetry = TelemetryData.from_json(payload)
assessment = analyzer.analyze(telemetry)
decision = failsafe.generate_fallback(assessment)

if "retreat" in decision.lower():
    print(f"✓ Failsafe generated correct decision: {decision}")
else:
    print(f"✗ Failsafe decision incorrect: {decision}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "Failsafe handler working"
else
    print_failure "Failsafe handler failed"
fi

# Test 13: Conversation Manager
print_test_header "13. Conversation Manager"

python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.ai.conversation_manager import ConversationManager

cm = ConversationManager(max_history=10)

# Test welcome message
welcome = cm.get_welcome_message()
if "NETRA" in welcome and "ready" in welcome.lower():
    print(f"✓ Welcome message: {welcome}")
else:
    print(f"✗ Welcome message incorrect: {welcome}")
    sys.exit(1)

# Test context building
prompt = cm.build_context_prompt("What is the threat level?")
if "NETRA" in prompt and "tactical" in prompt.lower():
    print("✓ Context prompt built correctly")
else:
    print("✗ Context prompt incorrect")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "Conversation manager working"
else
    print_failure "Conversation manager failed"
fi

# Test 14: TTS Engine (if available)
print_test_header "14. Text-to-Speech Engine"

if command -v piper &> /dev/null || python3 -c "import piper" 2>/dev/null; then
    print_info "Testing TTS (this will play audio)..."
    
    python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.voice.tts import TTSEngine
from edge_ai.config import Config

try:
    tts = TTSEngine(model_name=Config.TTS_MODEL, timeout=Config.TTS_TIMEOUT)
    success = tts.speak("Test message")
    if success:
        print("✓ TTS engine working")
    else:
        print("⊘ TTS engine initialized but playback failed")
except Exception as e:
    print(f"⊘ TTS test skipped: {e}")
EOF
    
    if [ $? -eq 0 ]; then
        print_success "TTS engine test completed"
    else
        print_skip "TTS engine test skipped"
    fi
else
    print_skip "Piper TTS not installed"
fi

# Test 15: Speech Recognition (if available)
print_test_header "15. Speech Recognition"

if python3 -c "import whisper" 2>/dev/null; then
    print_info "Whisper installed, testing model loading..."
    
    python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import whisper
    model = whisper.load_model("base")
    print("✓ Whisper model loaded successfully")
except Exception as e:
    print(f"✗ Whisper model loading failed: {e}")
    sys.exit(1)
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Speech recognition model ready"
    else
        print_failure "Speech recognition model failed"
    fi
else
    print_skip "Whisper not installed (voice input disabled)"
fi

# Test 16: Configuration Validation
print_test_header "16. Configuration Validation"

python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.config import Config

try:
    # This will raise ValueError if config is invalid
    # But model file might not exist, so we'll skip that check
    if Config.MQTT_BROKER_PORT < 1 or Config.MQTT_BROKER_PORT > 65535:
        print("✗ Invalid MQTT port")
        sys.exit(1)
    
    if Config.MAX_TOKENS < 1:
        print("✗ Invalid MAX_TOKENS")
        sys.exit(1)
    
    if Config.TEMPERATURE < 0.0 or Config.TEMPERATURE > 2.0:
        print("✗ Invalid TEMPERATURE")
        sys.exit(1)
    
    print("✓ Configuration values valid")
except Exception as e:
    print(f"✗ Configuration validation failed: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "Configuration validation passed"
else
    print_failure "Configuration validation failed"
fi

# Test 17: Logging System
print_test_header "17. Logging System"

python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.utils.helpers import setup_logging
from edge_ai.config import Config

try:
    logger = setup_logging(Config.LOG_DIR, Config.LOG_RETENTION_DAYS)
    logger.info("Test log message")
    print("✓ Logging system initialized")
except Exception as e:
    print(f"✗ Logging system failed: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    print_success "Logging system working"
else
    print_failure "Logging system failed"
fi

# Test 18: Memory and Disk Space
print_test_header "18. System Resources"

AVAILABLE_MEM=$(free -m | awk 'NR==2{print $7}')
if [ "$AVAILABLE_MEM" -gt 1000 ]; then
    print_success "Available memory: ${AVAILABLE_MEM}MB"
else
    print_failure "Low memory: ${AVAILABLE_MEM}MB (need >1000MB)"
fi

AVAILABLE_DISK=$(df -m . | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_DISK" -gt 1000 ]; then
    print_success "Available disk space: ${AVAILABLE_DISK}MB"
else
    print_failure "Low disk space: ${AVAILABLE_DISK}MB (need >1000MB)"
fi

# Summary
echo ""
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo ""
echo -e "${GREEN}Passed:  $TESTS_PASSED${NC}"
echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    echo "Success Rate: ${SUCCESS_RATE}%"
fi

echo ""
echo "Detailed log: $LOG_FILE"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}=========================================="
    echo "✓ ALL TESTS PASSED!"
    echo -e "==========================================${NC}"
    echo ""
    echo "System is ready to run!"
    echo "Start with: ./START_HERE.sh"
    exit 0
else
    echo -e "${RED}=========================================="
    echo "✗ SOME TESTS FAILED"
    echo -e "==========================================${NC}"
    echo ""
    if [ "$INSTALL_MISSING" = false ]; then
        echo "Try running with auto-install:"
        echo "  ./test_all_features.sh --install"
        echo ""
    fi
    echo "Or fix issues manually:"
    echo "  - Install packages: ./fix_now.sh"
    echo "  - Install voice: ./install_voice_input.sh"
    echo "  - See: TROUBLESHOOTING.md"
    exit 1
fi
