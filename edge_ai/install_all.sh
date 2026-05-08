#!/bin/bash
# Install ALL dependencies for Edge AI Copilot including voice features
# Checks if already installed before installing
set -e

echo "=========================================="
echo "Edge AI Copilot - Full Dependency Install"
echo "=========================================="

# Helper functions
pkg_installed() { dpkg -s "$1" &>/dev/null; }
py_installed()  { python3 -c "import $1" &>/dev/null; }
cmd_exists()    { command -v "$1" &>/dev/null; }

# System packages
echo ""
echo "[1/6] System packages..."
SYSPKGS=(mosquitto mosquitto-clients python3-pip python3-dev
         pulseaudio pulseaudio-module-bluetooth
         alsa-utils portaudio19-dev libsndfile1 ffmpeg
         cmake build-essential libopenblas-dev)

MISSING_SYS=()
for pkg in "${SYSPKGS[@]}"; do
    if pkg_installed "$pkg"; then
        echo "  ✓ $pkg"
    else
        echo "  ✗ $pkg (will install)"
        MISSING_SYS+=("$pkg")
    fi
done

if [ ${#MISSING_SYS[@]} -gt 0 ]; then
    sudo apt-get update -qq
    sudo apt-get install -y "${MISSING_SYS[@]}"
    echo "✓ System packages installed"
else
    echo "✓ All system packages already installed"
fi

# Python packages
echo ""
echo "[2/6] Python packages..."
PYPKGS=(paho.mqtt pygame soundfile noisereduce whisper piper)
PYNAMES=(paho-mqtt pygame soundfile noisereduce openai-whisper piper-tts)

MISSING_PY=()
for i in "${!PYPKGS[@]}"; do
    mod="${PYPKGS[$i]}"
    pkg="${PYNAMES[$i]}"
    if py_installed "$mod"; then
        echo "  ✓ $pkg"
    else
        echo "  ✗ $pkg (will install)"
        MISSING_PY+=("$pkg")
    fi
done

if [ ${#MISSING_PY[@]} -gt 0 ]; then
    pip3 install "${MISSING_PY[@]}"
    echo "✓ Python packages installed"
else
    echo "✓ All Python packages already installed"
fi

# llama-cpp-python
echo ""
echo "[3/6] llama-cpp-python..."
if py_installed "llama_cpp"; then
    echo "✓ llama-cpp-python already installed"
else
    echo "  Installing llama-cpp-python (takes 5-10 min)..."
    CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" \
        pip3 install llama-cpp-python --no-cache-dir
    echo "✓ llama-cpp-python installed"
fi

# AI model
echo ""
echo "[4/6] AI model (TinyLlama)..."
mkdir -p models
if [ -f "models/tinyllama.gguf" ]; then
    SIZE=$(du -h models/tinyllama.gguf | cut -f1)
    echo "✓ Model already exists ($SIZE)"
else
    echo "  Downloading TinyLlama (~600MB)..."
    wget -q --show-progress --continue \
        https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
        -O models/tinyllama.gguf
    echo "✓ AI model downloaded"
fi

# Piper voice model
echo ""
echo "[5/6] Piper voice model..."
VOICE="en_US-lessac-medium"
PIPER_DIR="$HOME/.local/share/piper-tts"
MODEL=$(find "$HOME/.local/share/piper"* /usr/share/piper* . 2>/dev/null -name "${VOICE}.onnx" | head -1)

if [ -n "$MODEL" ]; then
    echo "✓ Voice model already at: $MODEL"
else
    echo "  Downloading Piper voice model..."
    mkdir -p "$PIPER_DIR"
    python3 -c "
from piper.download import ensure_voice_exists
ensure_voice_exists('$VOICE', data_dirs=[], download_dir='$PIPER_DIR')
"
    echo "✓ Piper voice model downloaded"
fi

# PulseAudio + Bluetooth
echo ""
echo "[6/6] Bluetooth audio (PulseAudio)..."
if ! pulseaudio --check 2>/dev/null; then
    pulseaudio --start
    sleep 2
fi

BT_SINK=$(pactl list short sinks 2>/dev/null | grep -i "bluez\|oneplus\|bullets" | head -1 | awk '{print $2}')
BT_SOURCE=$(pactl list short sources 2>/dev/null | grep -i "bluez\|oneplus\|bullets" | head -1 | awk '{print $2}')

if [ -n "$BT_SINK" ]; then
    pactl set-default-sink "$BT_SINK"
    echo "✓ Bluetooth output: $BT_SINK"
else
    echo "⚠ Bluetooth output not found (connect headphones first)"
fi

if [ -n "$BT_SOURCE" ]; then
    pactl set-default-source "$BT_SOURCE"
    echo "✓ Bluetooth mic: $BT_SOURCE"
else
    echo "⚠ Bluetooth mic not found"
fi

# Enable voice in config
python3 -c "
content = open('config.py').read()
content = content.replace('VOICE_INPUT_ENABLED: bool = False', 'VOICE_INPUT_ENABLED: bool = True')
content = content.replace('ENABLE_WELCOME_MESSAGE: bool = False', 'ENABLE_WELCOME_MESSAGE: bool = True')
open('config.py', 'w').write(content)
"
echo "✓ Voice enabled in config.py"

mkdir -p logs

echo ""
echo "=========================================="
echo "✓ ALL DEPENDENCIES READY"
echo "=========================================="
echo ""
echo "Test voice:   python3 test_voice_input.py"
echo "Start system: ./START_HERE.sh"
echo ""
