#!/bin/bash
# Quick diagnostic script for Edge AI Copilot

echo "=========================================="
echo "Edge AI Copilot - System Diagnostics"
echo "=========================================="
echo ""

# System Info
echo "1. System Information:"
echo "   OS: $(uname -s)"
echo "   Kernel: $(uname -r)"
echo "   Architecture: $(uname -m)"
if [ -f /proc/cpuinfo ]; then
    if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        echo "   Device: Raspberry Pi"
    fi
fi
echo ""

# Python
echo "2. Python:"
if command -v python3 &> /dev/null; then
    echo "   ✓ Python: $(python3 --version)"
else
    echo "   ✗ Python not found"
fi
echo ""

# Internet
echo "3. Network Connectivity:"
if ping -c 2 -W 2 8.8.8.8 &> /dev/null; then
    echo "   ✓ Internet connection OK"
else
    echo "   ✗ No internet connection"
fi

if ping -c 2 -W 2 google.com &> /dev/null; then
    echo "   ✓ DNS resolution OK"
else
    echo "   ✗ DNS resolution failed"
fi
echo ""

# Mosquitto
echo "4. MQTT Broker (Mosquitto):"
if command -v mosquitto &> /dev/null; then
    echo "   ✓ Mosquitto installed"
    
    if sudo systemctl is-active --quiet mosquitto; then
        echo "   ✓ Mosquitto running"
    else
        echo "   ✗ Mosquitto not running"
        echo "     Start with: sudo systemctl start mosquitto"
    fi
    
    # Test MQTT
    if timeout 2 mosquitto_sub -t test -C 1 &> /dev/null &
       sleep 1
       mosquitto_pub -t test -m "test" &> /dev/null; then
        echo "   ✓ MQTT pub/sub working"
    else
        echo "   ✗ MQTT pub/sub failed"
    fi
else
    echo "   ✗ Mosquitto not installed"
fi
echo ""

# Python packages
echo "5. Python Packages:"
python3 -c "import paho.mqtt.client; print('   ✓ paho-mqtt')" 2>/dev/null || echo "   ✗ paho-mqtt missing"
python3 -c "import llama_cpp; print('   ✓ llama-cpp-python')" 2>/dev/null || echo "   ✗ llama-cpp-python missing"
python3 -c "import pygame; print('   ✓ pygame')" 2>/dev/null || echo "   ✗ pygame missing"
python3 -c "import piper; print('   ✓ piper-tts')" 2>/dev/null || echo "   ⚠ piper-tts missing (optional)"
echo ""

# Model file
echo "6. AI Model:"
if [ -f "models/tinyllama.gguf" ]; then
    size=$(du -h models/tinyllama.gguf | cut -f1)
    echo "   ✓ Model exists (${size})"
else
    echo "   ✗ Model file missing"
    echo "     Download with: wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf"
fi
echo ""

# Disk space
echo "7. Disk Space:"
df -h . | tail -1 | awk '{print "   Available: " $4 " / " $2}'
echo ""

# Memory
echo "8. Memory:"
free -h | grep "Mem:" | awk '{print "   Total: " $2 ", Available: " $7}'
echo ""

# Audio
echo "9. Audio Devices:"
if command -v aplay &> /dev/null; then
    if aplay -l &> /dev/null; then
        echo "   ✓ Audio devices found"
        aplay -l | grep "card" | head -3 | sed 's/^/   /'
    else
        echo "   ✗ No audio devices"
    fi
else
    echo "   ⚠ aplay not available"
fi
echo ""

# Logs
echo "10. Recent Logs:"
if [ -d "logs" ] && [ "$(ls -A logs)" ]; then
    latest_log=$(ls -t logs/*.log 2>/dev/null | head -1)
    if [ -n "$latest_log" ]; then
        echo "   Latest: $latest_log"
        echo "   Last 3 lines:"
        tail -3 "$latest_log" 2>/dev/null | sed 's/^/     /'
    fi
else
    echo "   No logs yet"
fi
echo ""

echo "=========================================="
echo "Diagnostics Complete"
echo "=========================================="
echo ""

# Summary
errors=0
python3 -c "import paho.mqtt.client" 2>/dev/null || ((errors++))
python3 -c "import llama_cpp" 2>/dev/null || ((errors++))
[ -f "models/tinyllama.gguf" ] || ((errors++))
sudo systemctl is-active --quiet mosquitto || ((errors++))

if [ $errors -eq 0 ]; then
    echo "✓ All critical components OK"
    echo "  Ready to run: python3 main.py"
else
    echo "✗ Found $errors issue(s)"
    echo "  See TROUBLESHOOTING.md for solutions"
fi
echo ""
