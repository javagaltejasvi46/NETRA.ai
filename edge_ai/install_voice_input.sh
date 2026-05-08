#!/bin/bash
# Install voice input dependencies for Edge AI Copilot

set -e

echo "=========================================="
echo "Installing Voice Input Feature"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "config.py" ]; then
    echo "✗ Error: Not in edge_ai directory"
    exit 1
fi

# Install system dependencies for audio
echo "Step 1: Installing system audio dependencies..."
sudo apt-get update
sudo apt-get install -y \
    alsa-utils \
    portaudio19-dev \
    libsndfile1 \
    ffmpeg

echo "✓ System dependencies installed"
echo ""

# Install Python packages
echo "Step 2: Installing Python packages..."

echo "  Installing openai-whisper..."
pip3 install openai-whisper --no-cache-dir
echo "  ✓ Whisper installed"

echo "  Installing noisereduce..."
pip3 install noisereduce --no-cache-dir
echo "  ✓ noisereduce installed"

echo "  Installing soundfile..."
pip3 install soundfile --no-cache-dir
echo "  ✓ soundfile installed"

echo "✓ All Python packages installed"
echo ""

# Download Whisper model
echo "Step 3: Downloading Whisper base model..."
python3 << 'EOF'
import whisper
print("Downloading Whisper base model...")
model = whisper.load_model("base")
print("✓ Model downloaded and cached")
EOF

echo ""

# Test microphone
echo "Step 4: Testing microphone..."
echo "Recording 2-second test..."

if arecord -D plughw:1,0 -d 2 -f S16_LE -r 16000 -c 1 /tmp/test_mic.wav 2>/dev/null; then
    echo "✓ Microphone working"
    rm -f /tmp/test_mic.wav
else
    echo "⚠ Microphone test failed"
    echo "  Check microphone connection"
    echo "  List devices with: arecord -l"
fi

echo ""
echo "=========================================="
echo "Voice Input Installation Complete!"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Edit config.py to customize:"
echo "    VOICE_INPUT_ENABLED = True/False"
echo "    WHISPER_MODEL = 'tiny', 'base', 'small', 'medium'"
echo "    LISTENING_DURATION = 5  # seconds"
echo "    ENABLE_WELCOME_MESSAGE = True/False"
echo ""
echo "Test voice input:"
echo "  python3 -c 'from edge_ai.voice.speech_recognition import SpeechRecognizer; sr = SpeechRecognizer(); print(sr.listen())'"
echo ""
echo "Microphone setup:"
echo "  List devices: arecord -l"
echo "  Test recording: arecord -D plughw:1,0 -d 5 test.wav"
echo "  Adjust volume: alsamixer"
echo ""
