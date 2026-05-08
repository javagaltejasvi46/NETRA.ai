#!/bin/bash
# Complete installation and testing script
# Installs all dependencies (including voice input) and runs comprehensive tests

set -e

echo "=========================================="
echo "Edge AI Copilot - Install & Test"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "config.py" ]; then
    echo "✗ Error: Not in edge_ai directory"
    exit 1
fi

# Step 1: Install core dependencies
echo "Step 1: Installing core dependencies..."
echo ""

if [ ! -f "fix_now.sh" ]; then
    echo "✗ fix_now.sh not found"
    exit 1
fi

chmod +x fix_now.sh
./fix_now.sh

echo ""
echo "✓ Core dependencies installed"
echo ""

# Step 2: Install voice input dependencies
echo "Step 2: Installing voice input dependencies..."
echo ""

if [ ! -f "install_voice_input.sh" ]; then
    echo "✗ install_voice_input.sh not found"
    exit 1
fi

chmod +x install_voice_input.sh
./install_voice_input.sh

echo ""
echo "✓ Voice input dependencies installed"
echo ""

# Step 3: Run comprehensive tests
echo "Step 3: Running comprehensive tests..."
echo ""

if [ ! -f "test_all_features.sh" ]; then
    echo "✗ test_all_features.sh not found"
    exit 1
fi

chmod +x test_all_features.sh
./test_all_features.sh

echo ""
echo "=========================================="
echo "Installation and Testing Complete!"
echo "=========================================="
echo ""
echo "Your system is ready to use."
echo ""
echo "Start the system:"
echo "  ./START_HERE.sh"
echo ""
echo "Or run as service:"
echo "  sudo systemctl start edge-ai-copilot"
echo ""
