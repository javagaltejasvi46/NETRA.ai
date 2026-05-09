#!/bin/bash

################################################################################
# Edge AI Copilot - Interactive Installation Wizard
# Handles "externally-managed-environment" error automatically
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           EDGE AI COPILOT - INSTALLATION WIZARD              ║
║                                                               ║
║              Raspberry Pi LLM Setup Assistant                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${YELLOW}This wizard will help you install TinyLlama LLM on your Raspberry Pi${NC}"
echo -e "${YELLOW}and fix the 'externally-managed-environment' error.${NC}"
echo ""

# Check if already installed
if python3 -c "import llama_cpp" 2>/dev/null && [ -f "models/tinyllama.gguf" ]; then
    echo -e "${GREEN}✓ llama-cpp-python is already installed${NC}"
    echo -e "${GREEN}✓ Model file exists${NC}"
    echo ""
    echo -e "${BLUE}Everything looks good! Run the test:${NC}"
    echo "  ./check_llm_and_test.sh"
    echo ""
    exit 0
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 1: Choose Installation Method${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "The 'externally-managed-environment' error prevents direct pip install."
echo "You need to choose an installation method:"
echo ""
echo -e "${GREEN}1) Virtual Environment (RECOMMENDED)${NC}"
echo "   ✓ Safe - doesn't affect system packages"
echo "   ✓ Clean - easy to delete and recreate"
echo "   ✓ Best practice"
echo "   ✗ Must activate before each use: source venv/bin/activate"
echo ""
echo -e "${YELLOW}2) System-Wide Installation${NC}"
echo "   ✓ Simple - no activation needed"
echo "   ✓ Works with systemd service as-is"
echo "   ✗ Uses --break-system-packages flag"
echo "   ✗ May interfere with system packages"
echo ""
echo -e "${CYAN}3) Show me the manual commands${NC}"
echo "   I'll show you the commands to run yourself"
echo ""
echo -e "${RED}4) Exit${NC}"
echo "   I'll install it myself later"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}Installing with Virtual Environment${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        if [ -f "install_llm_venv.sh" ]; then
            chmod +x install_llm_venv.sh
            ./install_llm_venv.sh
            
            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}✓ Installation complete!${NC}"
                echo ""
                echo -e "${YELLOW}IMPORTANT: Always activate the virtual environment before running:${NC}"
                echo -e "${CYAN}  source venv/bin/activate${NC}"
                echo ""
                echo -e "${BLUE}Next steps:${NC}"
                echo "  1. source venv/bin/activate"
                echo "  2. ./check_llm_and_test.sh"
            fi
        else
            echo -e "${RED}Error: install_llm_venv.sh not found${NC}"
        fi
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}Installing System-Wide${NC}"
        echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        
        if [ -f "install_llm_system.sh" ]; then
            chmod +x install_llm_system.sh
            ./install_llm_system.sh
            
            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}✓ Installation complete!${NC}"
                echo ""
                echo -e "${BLUE}Next steps:${NC}"
                echo "  ./check_llm_and_test.sh"
            fi
        else
            echo -e "${RED}Error: install_llm_system.sh not found${NC}"
        fi
        ;;
        
    3)
        echo ""
        echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}Manual Installation Commands${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${GREEN}Option A: Virtual Environment${NC}"
        echo ""
        echo "# Install dependencies"
        echo "sudo apt-get update"
        echo "sudo apt-get install -y python3-venv build-essential cmake libopenblas-dev"
        echo ""
        echo "# Create and activate virtual environment"
        echo "python3 -m venv venv"
        echo "source venv/bin/activate"
        echo ""
        echo "# Install llama-cpp-python"
        echo "pip install --upgrade pip"
        echo "CMAKE_ARGS=\"-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS\" \\"
        echo "  pip install llama-cpp-python --no-cache-dir"
        echo ""
        echo "# Download model"
        echo "mkdir -p models"
        echo "wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf"
        echo ""
        echo -e "${YELLOW}────────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "${YELLOW}Option B: System-Wide${NC}"
        echo ""
        echo "# Install dependencies"
        echo "sudo apt-get update"
        echo "sudo apt-get install -y build-essential cmake libopenblas-dev"
        echo ""
        echo "# Install llama-cpp-python"
        echo "CMAKE_ARGS=\"-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS\" \\"
        echo "  pip3 install llama-cpp-python --no-cache-dir --break-system-packages"
        echo ""
        echo "# Download model"
        echo "mkdir -p models"
        echo "wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf"
        echo ""
        ;;
        
    4)
        echo ""
        echo -e "${BLUE}No problem! When you're ready, run:${NC}"
        echo "  ./START_HERE_INSTALLATION.sh"
        echo ""
        echo -e "${BLUE}Or read the guides:${NC}"
        echo "  cat QUICK_FIX.txt"
        echo "  cat INSTALL_GUIDE.md"
        echo ""
        exit 0
        ;;
        
    *)
        echo ""
        echo -e "${RED}Invalid choice. Please run again and choose 1-4.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Installation Complete!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "  QUICK_FIX.txt           - Quick reference"
echo "  INSTALL_GUIDE.md        - Detailed guide"
echo "  LLM_CHECK_USAGE.md      - Test script usage"
echo "  README_INSTALLATION.md  - Installation overview"
echo ""
echo -e "${BLUE}🧪 Test your installation:${NC}"
echo "  ./check_llm_and_test.sh"
echo ""
echo -e "${BLUE}🚀 Run the copilot:${NC}"
if [ "$choice" = "1" ]; then
    echo "  source venv/bin/activate  # Don't forget this!"
fi
echo "  python3 main.py"
echo ""
