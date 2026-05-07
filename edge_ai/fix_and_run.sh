#!/bin/bash
# ONE SCRIPT TO FIX EVERYTHING AND RUN
# This is the ultimate solution - just run this!

echo "=========================================="
echo "Edge AI Copilot - Fix & Run"
echo "=========================================="
echo ""

# Get directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Step 1: Check if we're in the right place
if [ ! -f "main.py" ]; then
    echo "✗ Error: Not in edge_ai directory!"
    echo "  Current directory: $(pwd)"
    echo "  Please cd to edge_ai first"
    exit 1
fi

echo "✓ In correct directory: $SCRIPT_DIR"
echo ""

# Step 2: Check Mosquitto
echo "Checking Mosquitto..."
if sudo systemctl is-active --quiet mosquitto; then
    echo "✓ Mosquitto running"
else
    echo "⚠ Starting Mosquitto..."
    sudo systemctl start mosquitto
    sleep 2
    echo "✓ Mosquitto started"
fi
echo ""

# Step 3: Check model
echo "Checking AI model..."
if [ -f "models/tinyllama.gguf" ]; then
    size=$(du -h models/tinyllama.gguf | cut -f1)
    echo "✓ Model exists (${size})"
else
    echo "✗ Model missing!"
    echo ""
    echo "Downloading model now (this will take 5-15 minutes)..."
    mkdir -p models
    
    if wget --tries=3 --timeout=60 --continue \
        https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
        -O models/tinyllama.gguf; then
        echo "✓ Model downloaded"
    else
        echo "✗ Download failed!"
        echo "  Try running: ./fix_now.sh"
        exit 1
    fi
fi
echo ""

# Step 4: Check Python packages
echo "Checking Python packages..."
missing=0

if ! python3 -c "import paho.mqtt.client" 2>/dev/null; then
    echo "✗ paho-mqtt missing"
    missing=1
fi

if ! python3 -c "from llama_cpp import Llama" 2>/dev/null; then
    echo "✗ llama-cpp-python missing"
    missing=1
fi

if ! python3 -c "import pygame" 2>/dev/null; then
    echo "✗ pygame missing"
    missing=1
fi

if [ $missing -eq 1 ]; then
    echo ""
    echo "Missing packages detected!"
    echo "Run installation first: ./fix_now.sh"
    exit 1
else
    echo "✓ All packages installed"
fi
echo ""

# Step 5: Fix Python path
echo "Setting up Python environment..."
export PYTHONPATH="$(dirname "$SCRIPT_DIR"):$PYTHONPATH"
echo "✓ PYTHONPATH configured"
echo ""

# Step 6: Create logs directory
mkdir -p logs

echo "=========================================="
echo "✓ All checks passed!"
echo "=========================================="
echo ""
echo "Starting Edge AI Copilot..."
echo ""
echo "To test, open another terminal and run:"
echo "  mosquitto_pub -t 'battlefield/sensor' -m '{\"timestamp\":1710000000,\"soldier\":{\"x\":120,\"y\":340,\"heart_rate\":125},\"enemy\":{\"x\":180,\"y\":360},\"hostage\":{\"x\":140,\"y\":350},\"environment\":\"urban\",\"threat_level\":\"high\"}'"
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "=========================================="
echo ""

# Run the system
python3 main.py
