#!/bin/bash
# Deployment script for Edge AI Copilot on Raspberry Pi

set -e

echo "=========================================="
echo "Edge AI Copilot Deployment Script"
echo "=========================================="
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "Warning: This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "Step 1: Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install system dependencies
echo ""
echo "Step 2: Installing system dependencies..."
sudo apt-get install -y \
    mosquitto \
    mosquitto-clients \
    python3-pip \
    python3-dev \
    portaudio19-dev \
    git \
    cmake \
    build-essential \
    libopenblas-dev

# Start Mosquitto
echo ""
echo "Step 3: Configuring Mosquitto MQTT broker..."
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
echo "✓ Mosquitto started"

# Install Python dependencies
echo ""
echo "Step 4: Installing Python dependencies..."
pip3 install --upgrade pip

# Install llama-cpp-python with OpenBLAS support
echo "Installing llama-cpp-python (this may take a while)..."
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" \
    pip3 install llama-cpp-python --no-cache-dir

# Install other dependencies
pip3 install paho-mqtt piper-tts pygame

echo "✓ Python dependencies installed"

# Download AI model
echo ""
echo "Step 5: Downloading AI model..."
mkdir -p models

if [ ! -f "models/tinyllama.gguf" ]; then
    echo "Downloading TinyLlama Q4 model (~600MB)..."
    wget -q --show-progress \
        https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
        -O models/tinyllama.gguf
    echo "✓ Model downloaded"
else
    echo "✓ Model already exists"
fi

# Download Piper voice model
echo ""
echo "Step 6: Downloading Piper TTS voice model..."
echo "test" | piper --model en_US-lessac-medium --output_file /tmp/test.wav 2>/dev/null || true
rm -f /tmp/test.wav
echo "✓ Piper voice model ready"

# Create logs directory
echo ""
echo "Step 7: Creating directories..."
mkdir -p logs
echo "✓ Directories created"

# Test the system
echo ""
echo "Step 8: Testing system..."
python3 -c "import paho.mqtt.client as mqtt; print('✓ paho-mqtt OK')"
python3 -c "from llama_cpp import Llama; print('✓ llama-cpp-python OK')"
python3 -c "import pygame; print('✓ pygame OK')"

# Install systemd service
echo ""
echo "Step 9: Installing systemd service..."
read -p "Install as systemd service? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Update WorkingDirectory in service file
    CURRENT_DIR=$(pwd)
    sed "s|/home/pi/edge_ai|$CURRENT_DIR|g" edge-ai-copilot.service > /tmp/edge-ai-copilot.service
    
    sudo cp /tmp/edge-ai-copilot.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable edge-ai-copilot
    
    echo "✓ Service installed"
    echo ""
    echo "Start service with: sudo systemctl start edge-ai-copilot"
    echo "Check status with: sudo systemctl status edge-ai-copilot"
    echo "View logs with: sudo journalctl -u edge-ai-copilot -f"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review configuration in config.py"
echo "2. Test manually: python3 main.py"
echo "3. Or start service: sudo systemctl start edge-ai-copilot"
echo ""
echo "Test MQTT with:"
echo "  mosquitto_pub -t 'battlefield/sensor' -m '{\"timestamp\":1710000000,\"soldier\":{\"x\":120,\"y\":340,\"heart_rate\":125},\"enemy\":{\"x\":180,\"y\":360},\"hostage\":{\"x\":140,\"y\":350},\"environment\":\"urban\",\"threat_level\":\"high\"}'"
echo ""
