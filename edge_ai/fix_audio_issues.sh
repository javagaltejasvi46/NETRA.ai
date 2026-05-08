#!/bin/bash
# Fix audio recording and playback issues

echo "=========================================="
echo "Fixing Audio Issues"
echo "=========================================="
echo ""

# Step 1: List audio devices
echo "Step 1: Detecting audio devices..."
echo ""

echo "Input devices (microphones):"
arecord -l
echo ""

echo "Output devices (speakers):"
aplay -l
echo ""

# Step 2: Find the correct device
echo "Step 2: Finding correct audio device..."
CARD=$(arecord -l | grep "card" | head -1 | sed 's/card \([0-9]\).*/\1/')
DEVICE=$(arecord -l | grep "card" | head -1 | sed 's/.*device \([0-9]\).*/\1/')

if [ -z "$CARD" ] || [ -z "$DEVICE" ]; then
    echo "✗ No audio input device found!"
    echo ""
    echo "Possible solutions:"
    echo "1. Connect a USB microphone"
    echo "2. Enable built-in microphone in raspi-config"
    echo "3. Check USB connections: lsusb"
    exit 1
fi

echo "✓ Found audio device: card $CARD, device $DEVICE"
echo "  Device string: plughw:$CARD,$DEVICE"
echo ""

# Step 3: Test recording
echo "Step 3: Testing audio recording..."
echo "Recording 3 seconds of audio..."

if arecord -D plughw:$CARD,$DEVICE -d 3 -f S16_LE -r 16000 -c 1 /tmp/test_audio.wav 2>&1; then
    echo "✓ Recording successful"
    
    # Test playback
    echo ""
    echo "Step 4: Testing audio playback..."
    if aplay /tmp/test_audio.wav 2>&1; then
        echo "✓ Playback successful"
    else
        echo "⚠ Playback failed (speakers may not be connected)"
    fi
    
    rm -f /tmp/test_audio.wav
else
    echo "✗ Recording failed"
    echo ""
    echo "Try these fixes:"
    echo "1. Adjust microphone volume: alsamixer"
    echo "2. Check permissions: sudo usermod -a -G audio $USER"
    echo "3. Reboot and try again"
    exit 1
fi

echo ""

# Step 4: Update speech_recognition.py with correct device
echo "Step 5: Updating speech_recognition.py with correct device..."

DEVICE_STRING="plughw:$CARD,$DEVICE"

# Create backup
cp voice/speech_recognition.py voice/speech_recognition.py.backup

# Update the device string in speech_recognition.py
sed -i "s/plughw:1,0/$DEVICE_STRING/g" voice/speech_recognition.py

echo "✓ Updated speech_recognition.py to use: $DEVICE_STRING"
echo ""

# Step 5: Test TTS
echo "Step 6: Testing Text-to-Speech..."

python3 << EOF
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from edge_ai.voice.tts import TTSEngine
    from edge_ai.config import Config
    
    print("Initializing TTS engine...")
    tts = TTSEngine(model_name=Config.TTS_MODEL, timeout=Config.TTS_TIMEOUT)
    
    print("Speaking test message...")
    success = tts.speak("Audio test successful")
    
    if success:
        print("✓ TTS working")
    else:
        print("⚠ TTS initialized but playback may have failed")
except Exception as e:
    print(f"✗ TTS error: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo "✓ TTS test passed"
else
    echo "✗ TTS test failed"
    echo ""
    echo "Install Piper TTS:"
    echo "  pip3 install piper-tts"
fi

echo ""
echo "=========================================="
echo "Audio Configuration Complete"
echo "=========================================="
echo ""
echo "Audio device configured: $DEVICE_STRING"
echo ""
echo "Test commands:"
echo "  Record: arecord -D $DEVICE_STRING -d 5 test.wav"
echo "  Play: aplay test.wav"
echo "  Volume: alsamixer"
echo ""
echo "Now try running the system:"
echo "  ./START_HERE.sh"
echo ""
