#!/bin/bash
# Simplified installation script with better error handling

set -e

echo "=========================================="
echo "Edge AI Copilot - Simple Installation"
echo "=========================================="
echo ""

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo "✓ $1"
    else
        echo "✗ $1 failed"
        exit 1
    fi
}

# Step 1: Update system
echo "Step 1: Updating system..."
sudo apt-get update
check_success "System update"

# Step 2: Install Mosquitto
echo ""
echo "Step 2: Installing Mosquitto MQTT broker..."
sudo apt-get install -y mosquitto mosquitto-clients
check_success "Mosquitto installation"

sudo systemctl enable mosquitto
sudo systemctl start mosquitto
check_success "Mosquitto start"

# Test MQTT
timeout 2 mosquitto_sub -t test -C 1 &
sleep 1
mosquitto_pub -t test -m "test" 2>/dev/null
check_success "MQTT test"

# Step 3: Install Python basics
echo ""
echo "Step 3: Installing Python dependencies..."
sudo apt-get install -y python3-pip
check_success "pip installation"

pip3 install --upgrade pip
check_success "pip upgrade"

# Step 4: Install Python packages (one by one for better error handling)
echo ""
echo "Step 4: Installing Python packages..."

echo "Installing paho-mqtt..."
pip3 install paho-mqtt
check_success "paho-mqtt"

echo "Installing pygame..."
pip3 install pygame
check_success "pygame"

# Step 5: Install llama-cpp-python (with fallback)
echo ""
echo "Step 5: Installing llama-cpp-python..."
echo "This may take 5-10 minutes on Raspberry Pi..."

# Try pre-built wheel first
if pip3 install llama-cpp-python 2>/dev/null; then
    echo "✓ llama-cpp-python (pre-built)"
else
    echo "Pre-built wheel failed, building from source..."
    sudo apt-get install -y cmake build-essential libopenblas-dev
    
    CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" \
        pip3 install llama-cpp-python --no-cache-dir
    check_success "llama-cpp-python (built from source)"
fi

# Step 6: Install Piper TTS (optional, can fail)
echo ""
echo "Step 6: Installing Piper TTS (optional)..."
if pip3 install piper-tts 2>/dev/null; then
    echo "✓ Piper TTS installed"
    
    # Try to download voice model
    echo "Downloading voice model..."
    echo "test" | piper --model en_US-lessac-medium --output_file /tmp/test.wav 2>/dev/null && rm -f /tmp/test.wav
    echo "✓ Voice model ready"
else
    echo "⚠ Piper TTS installation failed (optional, can install later)"
    echo "  Install manually with: pip3 install piper-tts"
fi

# Step 7: Download AI model
echo ""
echo "Step 7: Downloading AI model..."
mkdir -p models

if [ ! -f "models/tinyllama.gguf" ]; then
    echo "Downloading TinyLlama Q4 model (~600MB)..."
    echo "This may take several minutes depending on your connection..."
    
    # Try wget first
    if command -v wget &> /dev/null; then
        wget --tries=3 --timeout=30 \
            https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
            -O models/tinyllama.gguf
    # Fallback to curl
    elif command -v curl &> /dev/null; then
        curl -L --retry 3 --max-time 300 \
            https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
            -o models/tinyllama.gguf
    else
        echo "✗ Neither wget nor curl available"
        echo "  Download manually from:"
        echo "  https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF"
        exit 1
    fi
    
    check_success "Model download"
else
    echo "✓ Model already exists"
fi

# Step 8: Create directories
echo ""
echo "Step 8: Creating directories..."
mkdir -p logs
check_success "Directory creation"

# Step 9: Test installation
echo ""
echo "Step 9: Testing installation..."

python3 -c "import paho.mqtt.client as mqtt; print('✓ paho-mqtt')"
python3 -c "from llama_cpp import Llama; print('✓ llama-cpp-python')"
python3 -c "import pygame; print('✓ pygame')"

# Test model file
if [ -f "models/tinyllama.gguf" ]; then
    echo "✓ Model file exists"
else
    echo "✗ Model file missing"
    exit 1
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test the system: python3 main.py"
echo "2. Send test telemetry:"
echo "   mosquitto_pub -t 'battlefield/sensor' -m '{\"timestamp\":1710000000,\"soldier\":{\"x\":120,\"y\":340,\"heart_rate\":125},\"enemy\":{\"x\":180,\"y\":360},\"hostage\":{\"x\":140,\"y\":350},\"environment\":\"urban\",\"threat_level\":\"high\"}'"
echo ""
echo "If you encounter issues, see TROUBLESHOOTING.md"
echo ""
