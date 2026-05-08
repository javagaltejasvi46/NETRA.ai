#!/bin/bash
# Quick fix for welcome audio not playing

echo "=========================================="
echo "Fixing Welcome Audio Issue"
echo "=========================================="
echo ""

# Check if Piper is installed
echo "Checking Piper TTS installation..."
if python3 -c "import piper" 2>/dev/null; then
    echo "✓ Piper TTS installed"
else
    echo "✗ Piper TTS not installed"
    echo ""
    echo "Installing Piper TTS..."
    pip3 install piper-tts
    
    if python3 -c "import piper" 2>/dev/null; then
        echo "✓ Piper TTS installed successfully"
    else
        echo "✗ Piper TTS installation failed"
        echo ""
        echo "Try manual installation:"
        echo "  pip3 install --upgrade pip"
        echo "  pip3 install piper-tts"
        exit 1
    fi
fi

echo ""

# Test TTS
echo "Testing TTS with welcome message..."
python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from edge_ai.voice.tts import TTSEngine
    from edge_ai.ai.conversation_manager import ConversationManager
    from edge_ai.config import Config
    
    print("Initializing components...")
    tts = TTSEngine(model_name=Config.TTS_MODEL, timeout=Config.TTS_TIMEOUT)
    cm = ConversationManager()
    
    welcome = cm.get_welcome_message()
    print(f"Welcome message: {welcome}")
    print("Playing audio...")
    
    success = tts.speak(welcome)
    
    if success:
        print("✓ Welcome audio played successfully!")
    else:
        print("⚠ TTS returned False (audio may not have played)")
        print("Check:")
        print("  - Speakers connected?")
        print("  - Volume up? (alsamixer)")
        print("  - Audio output device: aplay -l")
        
except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Welcome Audio Working!"
    echo "=========================================="
    echo ""
    echo "The system should now play welcome message on startup."
    echo ""
    echo "Start the system:"
    echo "  ./START_HERE.sh"
else
    echo ""
    echo "=========================================="
    echo "✗ Welcome Audio Still Not Working"
    echo "=========================================="
    echo ""
    echo "Troubleshooting steps:"
    echo ""
    echo "1. Check audio output devices:"
    echo "   aplay -l"
    echo ""
    echo "2. Test audio playback:"
    echo "   speaker-test -t wav -c 2"
    echo ""
    echo "3. Adjust volume:"
    echo "   alsamixer"
    echo ""
    echo "4. Check Piper installation:"
    echo "   pip3 show piper-tts"
    echo ""
    echo "5. Try manual TTS test:"
    echo "   echo 'test' | piper --model en_US-lessac-medium --output_file test.wav"
    echo "   aplay test.wav"
    echo ""
    echo "6. Disable welcome message temporarily:"
    echo "   Edit config.py: ENABLE_WELCOME_MESSAGE = False"
    echo ""
fi
