#!/bin/bash
# Quick setup script for voice input feature

echo "=========================================="
echo "Voice Input Feature - Quick Setup"
echo "=========================================="
echo ""

# Install dependencies
echo "Installing dependencies..."
chmod +x install_voice_input.sh
./install_voice_input.sh

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Test voice input:"
echo "   python3 test_voice_input.py"
echo ""
echo "2. Configure (optional):"
echo "   nano config.py"
echo "   # Adjust WHISPER_MODEL, LISTENING_DURATION, etc."
echo ""
echo "3. Start system with voice input:"
echo "   ./START_HERE.sh"
echo ""
echo "4. Read full guide:"
echo "   cat VOICE_INPUT_GUIDE.md"
echo ""
echo "Microphone tips:"
echo "  - List devices: arecord -l"
echo "  - Test mic: arecord -D plughw:1,0 -d 5 test.wav"
echo "  - Adjust volume: alsamixer"
echo ""
