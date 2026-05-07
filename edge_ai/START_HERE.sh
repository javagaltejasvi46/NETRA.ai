#!/bin/bash
# ULTIMATE FIX - Start Edge AI Copilot
# This script fixes all import issues and starts the system

echo "=========================================="
echo "Edge AI Copilot - Starting System"
echo "=========================================="
echo ""

# Get absolute path
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Working directory: $SCRIPT_DIR"
echo ""

# Check if main.py exists
if [ ! -f "main.py" ]; then
    echo "✗ Error: main.py not found!"
    echo "  Make sure you're in the edge_ai directory"
    exit 1
fi

# Check if model exists
if [ ! -f "models/tinyllama.gguf" ]; then
    echo "✗ Error: Model file not found!"
    echo "  Run ./fix_now.sh first to download the model"
    exit 1
fi

# Check if Mosquitto is running
if ! sudo systemctl is-active --quiet mosquitto; then
    echo "⚠ Mosquitto not running, starting it..."
    sudo systemctl start mosquitto
    sleep 2
fi

# Set Python path to parent directory
export PYTHONPATH="$(dirname "$SCRIPT_DIR"):$PYTHONPATH"

echo "✓ Environment configured"
echo "✓ Starting Edge AI Copilot..."
echo ""
echo "=========================================="
echo ""

# Run the system
python3 main.py

# If that fails, try alternative method
if [ $? -ne 0 ]; then
    echo ""
    echo "Trying alternative startup method..."
    cd ..
    python3 -m edge_ai.main
fi
