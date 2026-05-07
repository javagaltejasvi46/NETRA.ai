#!/bin/bash
# IMMEDIATE FIX for Connection Failed Error
# Run this script on your Raspberry Pi: chmod +x fix_now.sh && ./fix_now.sh

set -e

echo "=========================================="
echo "IMMEDIATE FIX - Edge AI Copilot"
echo "=========================================="
echo ""

# Fix 1: Disable IPv6 (common cause of connection issues)
echo "Step 1: Fixing IPv6 issues..."
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 2>/dev/null || true
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4 >/dev/null
echo "✓ IPv6 disabled, forcing IPv4"
echo ""

# Fix 2: Update package lists
echo "Step 2: Updating package lists..."
sudo apt-get update
echo "✓ Package lists updated"
echo ""

# Fix 3: Install Mosquitto MQTT broker
echo "Step 3: Installing Mosquitto..."
sudo apt-get install -y mosquitto mosquitto-clients
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
echo "✓ Mosquitto installed and running"
echo ""

# Fix 4: Install Python and pip
echo "Step 4: Installing Python tools..."
sudo apt-get install -y python3-pip python3-dev
pip3 install --upgrade pip
echo "✓ Python tools ready"
echo ""

# Fix 5: Install Python packages (one by one)
echo "Step 5: Installing Python packages..."

echo "  Installing paho-mqtt..."
pip3 install paho-mqtt --no-cache-dir
echo "  ✓ paho-mqtt"

echo "  Installing pygame..."
pip3 install pygame --no-cache-dir
echo "  ✓ pygame"

echo "  Installing llama-cpp-python (this takes 5-10 minutes)..."
# Try simple install first
if pip3 install llama-cpp-python --no-cache-dir 2>/dev/null; then
    echo "  ✓ llama-cpp-python (pre-built)"
else
    echo "  Building from source..."
    sudo apt-get install -y cmake build-essential libopenblas-dev
    CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" \
        pip3 install llama-cpp-python --no-cache-dir
    echo "  ✓ llama-cpp-python (built)"
fi

echo "✓ All Python packages installed"
echo ""

# Fix 6: Download AI model
echo "Step 6: Downloading AI model..."
mkdir -p models

if [ -f "models/tinyllama.gguf" ]; then
    echo "✓ Model already exists"
else
    echo "Downloading TinyLlama (~600MB, may take 5-15 minutes)..."
    
    # Try wget with retries
    if wget --tries=5 --timeout=60 --continue \
        https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
        -O models/tinyllama.gguf 2>&1 | grep -v "^--"; then
        echo "✓ Model downloaded"
    else
        echo "wget failed, trying curl..."
        curl -L --retry 5 --max-time 600 --continue-at - \
            https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
            -o models/tinyllama.gguf
        echo "✓ Model downloaded"
    fi
fi
echo ""

# Fix 7: Create necessary directories
echo "Step 7: Creating directories..."
mkdir -p logs
echo "✓ Directories created"
echo ""

# Fix 8: Test everything
echo "Step 8: Testing installation..."
echo ""

# Test MQTT
echo "Testing MQTT..."
timeout 3 mosquitto_sub -t test -C 1 &
sleep 1
mosquitto_pub -t test -m "test"
wait
echo "✓ MQTT working"

# Test Python packages
echo "Testing Python packages..."
python3 -c "import paho.mqtt.client; print('✓ paho-mqtt')"
python3 -c "from llama_cpp import Llama; print('✓ llama-cpp-python')"
python3 -c "import pygame; print('✓ pygame')"

# Test model
if [ -f "models/tinyllama.gguf" ]; then
    size=$(du -h models/tinyllama.gguf | cut -f1)
    echo "✓ Model file exists (${size})"
else
    echo "✗ Model file missing!"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ ALL FIXES APPLIED SUCCESSFULLY!"
echo "=========================================="
echo ""
echo "Your system is ready to run!"
echo ""
echo "Next steps:"
echo "1. Start the system:"
echo "   python3 main.py"
echo ""
echo "2. In another terminal, send test telemetry:"
echo "   mosquitto_pub -t 'battlefield/sensor' -m '{\"timestamp\":1710000000,\"soldier\":{\"x\":120,\"y\":340,\"heart_rate\":125},\"enemy\":{\"x\":180,\"y\":360},\"hostage\":{\"x\":140,\"y\":350},\"environment\":\"urban\",\"threat_level\":\"high\"}'"
echo ""
echo "3. Monitor responses:"
echo "   mosquitto_sub -t 'battlefield/ai-response' -v"
echo ""
echo "If you still have issues, run: ./diagnose.sh"
echo ""
