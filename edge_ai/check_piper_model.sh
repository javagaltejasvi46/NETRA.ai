#!/bin/bash
# Check if Piper voice model is downloaded, download if missing

VOICE="en_US-lessac-medium"
DOWNLOAD_DIR="$HOME/.local/share/piper-tts"

echo "Checking for Piper voice model: $VOICE"
echo ""

# Search for model
MODEL=$(find "$HOME/.local/share/piper"* /usr/share/piper* . 2>/dev/null -name "${VOICE}.onnx" | head -1)

if [ -n "$MODEL" ]; then
    echo "✓ Model found: $MODEL"
    echo ""
    echo "Testing TTS..."
    echo "Hello. NETRA AI is ready." | piper --model "$MODEL" --output_file /tmp/piper_test.wav
    paplay /tmp/piper_test.wav
    rm -f /tmp/piper_test.wav
    echo "✓ TTS working"
else
    echo "✗ Model not found. Downloading..."
    mkdir -p "$DOWNLOAD_DIR"
    python3 -c "
from piper.download import ensure_voice_exists
ensure_voice_exists('$VOICE', data_dirs=[], download_dir='$DOWNLOAD_DIR')
print('Download complete')
"
    echo ""
    echo "✓ Model downloaded to $DOWNLOAD_DIR"
    echo "Run this script again to test."
fi
