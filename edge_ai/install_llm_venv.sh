#!/bin/bash

################################################################################
# Install llama-cpp-python in Virtual Environment
# For Raspberry Pi - Bypasses externally-managed-environment error
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Installing LLM in Virtual Environment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Install system dependencies
echo -e "${YELLOW}Installing system dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip build-essential cmake libopenblas-dev wget

# Create virtual environment
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source venv/bin/activate

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --upgrade pip

# Install llama-cpp-python with optimizations
echo -e "${YELLOW}Installing llama-cpp-python (this may take 10-15 minutes)...${NC}"
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip install llama-cpp-python --no-cache-dir

# Install other dependencies
echo -e "${YELLOW}Installing other dependencies...${NC}"
pip install paho-mqtt

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}To use the virtual environment:${NC}"
echo "  source venv/bin/activate"
echo ""
echo -e "${BLUE}To run the Edge AI Copilot:${NC}"
echo "  source venv/bin/activate"
echo "  python3 main.py"
echo ""
echo -e "${BLUE}To deactivate:${NC}"
echo "  deactivate"
echo ""
