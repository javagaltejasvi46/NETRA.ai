#!/bin/bash
# Disable voice features to run system without audio

echo "=========================================="
echo "Disabling Voice Features"
echo "=========================================="
echo ""

echo "This will disable:"
echo "  - Voice input (speech recognition)"
echo "  - Voice output (TTS)"
echo "  - Welcome message"
echo ""
echo "The system will still work for:"
echo "  - MQTT telemetry processing"
echo "  - Threat analysis"
echo "  - Tactical decision generation"
echo "  - MQTT response publishing"
echo ""

# Backup config
cp config.py config.py.backup
echo "✓ Backed up config.py to config.py.backup"

# Update config to disable voice
python3 << 'EOF'
with open('config.py', 'r') as f:
    content = f.read()

# Disable voice features
content = content.replace('VOICE_INPUT_ENABLED: bool = True', 'VOICE_INPUT_ENABLED: bool = False')
content = content.replace('ENABLE_WELCOME_MESSAGE: bool = True', 'ENABLE_WELCOME_MESSAGE: bool = False')

with open('config.py', 'w') as f:
    f.write(content)

print("✓ Updated config.py")
print("  VOICE_INPUT_ENABLED = False")
print("  ENABLE_WELCOME_MESSAGE = False")
EOF

echo ""
echo "=========================================="
echo "✓ Voice Features Disabled"
echo "=========================================="
echo ""
echo "The system will now run WITHOUT voice features."
echo ""
echo "Start the system:"
echo "  ./START_HERE.sh"
echo ""
echo "To re-enable voice features later:"
echo "  1. Fix audio issues (connect microphone/speakers)"
echo "  2. Run: ./fix_audio_issues.sh"
echo "  3. Restore config: cp config.py.backup config.py"
echo ""
echo "The core AI functionality will work perfectly!"
echo ""
