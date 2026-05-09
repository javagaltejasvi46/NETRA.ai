#!/bin/bash

################################################################################
# Install llama-cpp-python System-Wide
# WARNING: Uses --break-system-packages flag
# Only use if you understand the risks
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}WARNING: System-Wide Installation${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}This will install packages system-wide using --break-system-packages${NC}"
echo -e "${YELLOW}This may interfere with system package management.${NC}"
echo ""
echo -e "${BLUE}Recommended: Use virtual environment instead (install_llm_venv.sh)${NC}"
echo ""
read -p "Continue anyway? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Installing system dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y python3-pip build-essential cmake libopenblas-dev wget

echo ""
echo -e "${YELLOW}Installing llama-cpp-python (this may take 10-15 minutes)...${NC}"
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip3 install llama-cpp-python --no-cache-dir --break-system-packages

echo ""
echo -e "${YELLOW}Installing other dependencies...${NC}"
pip3 install paho-mqtt --break-system-packages

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}You can now run:${NC}"
echo "  python3 main.py"
echo ""
