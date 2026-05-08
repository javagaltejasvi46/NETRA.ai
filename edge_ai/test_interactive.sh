#!/bin/bash
# Interactive test script with manual voice input/output testing

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                              ║"
echo "║              EDGE AI COPILOT - INTERACTIVE TEST SUITE                       ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Function to wait for user
wait_for_user() {
    echo ""
    read -p "Press Enter to continue..."
    echo ""
}

# Function to ask yes/no
ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# ============================================================================
# TEST 1: VOICE OUTPUT (TTS)
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 1: VOICE OUTPUT (Text-to-Speech)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "This test will play a voice message through your speakers."
echo "Make sure your speakers/headphones are connected and volume is up."
echo ""

if ask_yes_no "Ready to test voice output?"; then
    echo ""
    echo "Playing test message..."
    python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from edge_ai.voice.tts import TTSEngine
    tts = TTSEngine("en_US-lessac-medium", 2)
    success = tts.speak("Hello. This is a test of the text to speech system. Can you hear me?")
    if success:
        print("\n✓ Voice output test completed")
    else:
        print("\n✗ Voice output failed")
except Exception as e:
    print(f"\n✗ Error: {e}")
EOF
    
    echo ""
    if ask_yes_no "Did you hear the voice message clearly?"; then
        echo -e "${GREEN}✓ PASS${NC} - Voice output working"
    else
        echo -e "${YELLOW}✗ FAIL${NC} - Voice output not working"
        echo "  Troubleshooting:"
        echo "    - Check speaker connection"
        echo "    - Run: speaker-test -t wav -c 2"
        echo "    - Adjust volume: alsamixer"
    fi
else
    echo "Skipping voice output test"
fi

wait_for_user

# ============================================================================
# TEST 2: MICROPHONE INPUT
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 2: MICROPHONE INPUT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "This test will record 3 seconds of audio from your microphone."
echo "Make sure your microphone is connected."
echo ""

if ask_yes_no "Ready to test microphone?"; then
    echo ""
    echo "Recording in 3 seconds..."
    sleep 1
    echo "2..."
    sleep 1
    echo "1..."
    sleep 1
    echo ""
    echo "🎤 RECORDING NOW - Speak into the microphone!"
    
    if arecord -D plughw:1,0 -d 3 -f S16_LE -r 16000 -c 1 /tmp/mic_test.wav 2>/dev/null; then
        echo ""
        echo "Recording complete. Playing back..."
        sleep 1
        aplay /tmp/mic_test.wav 2>/dev/null
        rm -f /tmp/mic_test.wav
        
        echo ""
        if ask_yes_no "Did you hear your voice played back?"; then
            echo -e "${GREEN}✓ PASS${NC} - Microphone working"
        else
            echo -e "${YELLOW}✗ FAIL${NC} - Microphone not working"
            echo "  Troubleshooting:"
            echo "    - Check microphone connection"
            echo "    - List devices: arecord -l"
            echo "    - Adjust input gain: alsamixer"
        fi
    else
        echo -e "${YELLOW}✗ FAIL${NC} - Recording failed"
        echo "  Check microphone connection: arecord -l"
    fi
else
    echo "Skipping microphone test"
fi

wait_for_user

# ============================================================================
# TEST 3: SPEECH RECOGNITION (WHISPER)
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 3: SPEECH RECOGNITION (Whisper AI)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

if python3 -c "import whisper" 2>/dev/null; then
    echo "This test will record your voice and convert it to text."
    echo "You will have 5 seconds to speak."
    echo ""
    echo "Suggested test phrase: 'How far is the enemy?'"
    echo ""
    
    if ask_yes_no "Ready to test speech recognition?"; then
        echo ""
        echo "Initializing Whisper AI (this may take a moment)..."
        
        python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from edge_ai.voice.speech_recognition import SpeechRecognizer
    
    print("\nReady to record!")
    print("Speak clearly into the microphone for 5 seconds...")
    print("\n🎤 RECORDING NOW!\n")
    
    sr = SpeechRecognizer(model_size="base", duration=5)
    text = sr.listen()
    
    print("\n" + "="*80)
    if text:
        print(f"Transcribed text: {text}")
        print("="*80)
        print("\n✓ Speech recognition test completed")
    else:
        print("No speech detected or transcription failed")
        print("="*80)
        print("\n✗ Speech recognition failed")
        
except Exception as e:
    print(f"\n✗ Error: {e}")
    import traceback
    traceback.print_exc()
EOF
        
        echo ""
        if ask_yes_no "Was your speech transcribed correctly?"; then
            echo -e "${GREEN}✓ PASS${NC} - Speech recognition working"
        else
            echo -e "${YELLOW}✗ FAIL${NC} - Speech recognition not accurate"
            echo "  Tips:"
            echo "    - Speak clearly and slowly"
            echo "    - Reduce background noise"
            echo "    - Move microphone closer"
            echo "    - Try larger model: WHISPER_MODEL='small' in config.py"
        fi
    else
        echo "Skipping speech recognition test"
    fi
else
    echo "Whisper AI not installed. Skipping test."
    echo "Install with: ./install_voice_input.sh"
fi

wait_for_user

# ============================================================================
# TEST 4: FULL VOICE CONVERSATION
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 4: FULL VOICE CONVERSATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

if python3 -c "import whisper" 2>/dev/null; then
    echo "This test simulates a complete voice interaction:"
    echo "  1. System speaks a message"
    echo "  2. You ask a question (5 seconds)"
    echo "  3. System responds with voice"
    echo ""
    
    if ask_yes_no "Ready to test full conversation?"; then
        echo ""
        python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from edge_ai.voice.tts import TTSEngine
    from edge_ai.voice.speech_recognition import SpeechRecognizer
    from edge_ai.ai.conversation_manager import ConversationManager
    
    print("Initializing components...")
    tts = TTSEngine("en_US-lessac-medium", 2)
    sr = SpeechRecognizer(model_size="base", duration=5)
    cm = ConversationManager()
    
    # Welcome message
    print("\n" + "="*80)
    print("SYSTEM SPEAKING:")
    welcome = cm.get_welcome_message()
    print(f"  '{welcome}'")
    print("="*80)
    tts.speak(welcome)
    
    # Listen for question
    print("\n🎤 Your turn! Ask a question (5 seconds)...")
    print("Suggested: 'What is your status?'\n")
    
    question = sr.listen()
    
    if question:
        print("\n" + "="*80)
        print(f"YOU ASKED: {question}")
        print("="*80)
        
        # Generate simple response (without full LLM)
        response = f"You asked about {question.split()[0] if question.split() else 'something'}. All systems operational and ready."
        
        # Ensure under 20 words
        words = response.split()
        if len(words) > 20:
            response = ' '.join(words[:20]) + '.'
        
        print("\n" + "="*80)
        print("SYSTEM RESPONDING:")
        print(f"  '{response}'")
        print("="*80)
        
        tts.speak(response)
        
        print("\n✓ Full conversation test completed")
    else:
        print("\n✗ No question detected")
        
except Exception as e:
    print(f"\n✗ Error: {e}")
    import traceback
    traceback.print_exc()
EOF
        
        echo ""
        if ask_yes_no "Did the conversation flow work correctly?"; then
            echo -e "${GREEN}✓ PASS${NC} - Full voice conversation working"
        else
            echo -e "${YELLOW}✗ FAIL${NC} - Conversation had issues"
        fi
    else
        echo "Skipping conversation test"
    fi
else
    echo "Whisper AI not installed. Skipping test."
fi

wait_for_user

# ============================================================================
# TEST 5: MQTT COMMUNICATION
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST 5: MQTT COMMUNICATION${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "This test will send a test message via MQTT."
echo ""

if ask_yes_no "Ready to test MQTT?"; then
    echo ""
    echo "Starting MQTT subscriber..."
    
    # Subscribe in background
    timeout 5 mosquitto_sub -t "test/interactive" -v > /tmp/mqtt_interactive_test.txt 2>&1 &
    SUB_PID=$!
    sleep 2
    
    echo "Publishing test message..."
    mosquitto_pub -t "test/interactive" -m "Hello from Edge AI Copilot"
    
    sleep 2
    
    if grep -q "Hello from Edge AI Copilot" /tmp/mqtt_interactive_test.txt 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC} - MQTT communication working"
    else
        echo -e "${YELLOW}✗ FAIL${NC} - MQTT message not received"
        echo "  Check: sudo systemctl status mosquitto"
    fi
    
    rm -f /tmp/mqtt_interactive_test.txt
else
    echo "Skipping MQTT test"
fi

wait_for_user

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "Interactive testing complete!"
echo ""
echo "Next steps:"
echo "  1. Run full automated tests: ./test_all_features.sh"
echo "  2. Start the system: ./START_HERE.sh"
echo "  3. Send test telemetry and interact with voice"
echo ""
echo "For detailed testing: cat VOICE_INPUT_GUIDE.md"
echo ""
