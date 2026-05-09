#!/bin/bash

################################################################################
# TinyLlama GGUF Model Checker and Test Script
# For Raspberry Pi Edge AI Copilot Project
#
# This script:
# 1. Checks if TinyLlama GGUF model exists (downloads if missing)
# 2. Verifies llama-cpp-python installation (installs if missing)
# 3. Runs a basic inference test with a simple prompt
# 4. Provides detailed debugging information
################################################################################

# Don't exit on error - we want to handle errors gracefully
set +e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MODEL_PATH="models/tinyllama.gguf"
EXPECTED_MODEL_SIZE_MIN=600000000  # ~600MB minimum for Q4 quantized model
TEST_PROMPT="Enemy detected at 50 meters approaching fast. What should I do?"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

################################################################################
# Check Functions
################################################################################

check_model_exists() {
    print_header "Step 1: Checking Model File"
    
    if [ -f "$MODEL_PATH" ]; then
        print_success "Model file found: $MODEL_PATH"
        
        # Get file size
        MODEL_SIZE=$(stat -c%s "$MODEL_PATH" 2>/dev/null || stat -f%z "$MODEL_PATH" 2>/dev/null)
        MODEL_SIZE_MB=$((MODEL_SIZE / 1024 / 1024))
        
        print_info "Model size: ${MODEL_SIZE_MB} MB"
        
        # Verify size is reasonable
        if [ "$MODEL_SIZE" -lt "$EXPECTED_MODEL_SIZE_MIN" ]; then
            print_warning "Model file seems too small (expected ~600MB+)"
            print_warning "The file might be corrupted or incomplete"
            print_info "Removing corrupted file and re-downloading..."
            rm -f "$MODEL_PATH"
            download_model
            return $?
        fi
        
        # Check file permissions
        if [ -r "$MODEL_PATH" ]; then
            print_success "Model file is readable"
        else
            print_error "Model file exists but is not readable"
            print_info "Fixing permissions..."
            chmod 644 "$MODEL_PATH"
            if [ -r "$MODEL_PATH" ]; then
                print_success "Permissions fixed"
            else
                print_error "Failed to fix permissions"
                return 1
            fi
        fi
        
        return 0
    else
        print_error "Model file not found: $MODEL_PATH"
        download_model
        return $?
    fi
}

download_model() {
    print_info "Attempting to download TinyLlama model..."
    echo ""
    
    # Check if wget is available
    if ! command -v wget &> /dev/null; then
        print_error "wget not found. Please install it first:"
        echo "  sudo apt-get install wget"
        return 1
    fi
    
    # Create models directory
    mkdir -p models
    
    print_info "Downloading TinyLlama 1.1B Q4_K_M model (~637 MB)..."
    print_warning "This may take several minutes depending on your connection..."
    echo ""
    
    # Download with progress bar
    if wget --show-progress \
            "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf" \
            -O "$MODEL_PATH"; then
        echo ""
        print_success "Model downloaded successfully"
        
        # Verify download
        if [ -f "$MODEL_PATH" ]; then
            MODEL_SIZE=$(stat -c%s "$MODEL_PATH" 2>/dev/null || stat -f%z "$MODEL_PATH" 2>/dev/null)
            MODEL_SIZE_MB=$((MODEL_SIZE / 1024 / 1024))
            print_info "Downloaded size: ${MODEL_SIZE_MB} MB"
            
            if [ "$MODEL_SIZE" -lt "$EXPECTED_MODEL_SIZE_MIN" ]; then
                print_error "Downloaded file is too small. Download may have failed."
                return 1
            fi
            
            return 0
        else
            print_error "Download completed but file not found"
            return 1
        fi
    else
        echo ""
        print_error "Failed to download model"
        print_info "You can manually download it with:"
        echo "  mkdir -p models"
        echo "  wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf"
        return 1
    fi
}

check_python_dependencies() {
    print_header "Step 2: Checking Python Dependencies"
    
    # Check Python version
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        print_success "Python3 found: $PYTHON_VERSION"
    else
        print_error "Python3 not found"
        print_info "Install with: sudo apt-get install python3 python3-pip"
        return 1
    fi
    
    # Check pip
    if command -v pip3 &> /dev/null; then
        print_success "pip3 found"
    else
        print_warning "pip3 not found, attempting to install..."
        sudo apt-get update
        sudo apt-get install -y python3-pip
        if command -v pip3 &> /dev/null; then
            print_success "pip3 installed successfully"
        else
            print_error "Failed to install pip3"
            return 1
        fi
    fi
    
    # Check llama-cpp-python
    if python3 -c "import llama_cpp" 2>/dev/null; then
        LLAMA_VERSION=$(python3 -c "import llama_cpp; print(llama_cpp.__version__)" 2>/dev/null || echo "unknown")
        print_success "llama-cpp-python installed (version: $LLAMA_VERSION)"
    else
        print_warning "llama-cpp-python not installed"
        install_llama_cpp_python
        return $?
    fi
    
    return 0
}

install_llama_cpp_python() {
    print_info "Installing llama-cpp-python..."
    echo ""
    
    # Check if we're on Raspberry Pi
    IS_RPI=0
    if [ -f /proc/device-tree/model ]; then
        if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
            IS_RPI=1
            print_info "Raspberry Pi detected - using optimized build"
        fi
    fi
    
    # Install build dependencies
    print_info "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential cmake libopenblas-dev
    
    # Install llama-cpp-python
    if [ $IS_RPI -eq 1 ]; then
        print_info "Building with OpenBLAS optimization (this may take 10-15 minutes)..."
        CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip3 install llama-cpp-python --no-cache-dir
    else
        print_info "Installing llama-cpp-python..."
        pip3 install llama-cpp-python
    fi
    
    # Verify installation
    if python3 -c "import llama_cpp" 2>/dev/null; then
        echo ""
        print_success "llama-cpp-python installed successfully"
        return 0
    else
        echo ""
        print_error "Failed to install llama-cpp-python"
        print_info "Try manual installation:"
        echo "  pip3 install llama-cpp-python"
        return 1
    fi
}

check_system_resources() {
    print_header "Step 3: Checking System Resources"
    
    # Check available memory
    if command -v free &> /dev/null; then
        TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
        AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')
        
        print_info "Total RAM: ${TOTAL_MEM} MB"
        print_info "Available RAM: ${AVAIL_MEM} MB"
        
        if [ "$AVAIL_MEM" -lt 1000 ]; then
            print_warning "Low available memory (< 1GB). Model loading may fail."
            print_info "Consider closing other applications"
        else
            print_success "Sufficient memory available"
        fi
    fi
    
    # Check CPU info
    if [ -f /proc/cpuinfo ]; then
        CPU_COUNT=$(grep -c ^processor /proc/cpuinfo)
        CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        
        print_info "CPU cores: $CPU_COUNT"
        print_info "CPU model: ${CPU_MODEL:-Unknown}"
    fi
    
    # Check if running on Raspberry Pi
    if [ -f /proc/device-tree/model ]; then
        PI_MODEL=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
        print_info "Device: $PI_MODEL"
    fi
    
    return 0
}

run_inference_test() {
    print_header "Step 4: Running Inference Test"
    
    print_info "Creating test script..."
    
    # Create temporary Python test script
    TEST_SCRIPT=$(mktemp /tmp/llm_test_XXXXXX.py)
    
    cat > "$TEST_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
"""
Simple LLM inference test for TinyLlama GGUF model
"""
import sys
import time
import os

def test_inference(model_path, prompt, max_tokens=40, temperature=0.4, threads=2):
    """Run a simple inference test"""
    
    # Debug: Print environment info
    print("=" * 60)
    print("DEBUG INFORMATION")
    print("=" * 60)
    print(f"Python version: {sys.version}")
    print(f"Model path: {model_path}")
    print(f"Model exists: {os.path.exists(model_path)}")
    if os.path.exists(model_path):
        model_size = os.path.getsize(model_path)
        print(f"Model size: {model_size / (1024*1024):.2f} MB")
    print(f"Working directory: {os.getcwd()}")
    print("=" * 60)
    print()
    
    try:
        # Import llama_cpp
        print("Importing llama_cpp...")
        try:
            from llama_cpp import Llama
            import llama_cpp
            print(f"✓ llama_cpp version: {llama_cpp.__version__}")
        except ImportError as e:
            print(f"✗ Failed to import llama_cpp: {e}")
            print("  Install with: pip3 install llama-cpp-python")
            return False
        print()
        
        # Check model file
        if not os.path.exists(model_path):
            print(f"✗ Model file not found: {model_path}")
            return False
        
        print(f"Loading model: {model_path}")
        start_load = time.time()
        
        # Load model with error handling
        try:
            llm = Llama(
                model_path=model_path,
                n_threads=threads,
                n_ctx=512,
                verbose=False
            )
        except Exception as e:
            print(f"✗ Failed to load model: {e}")
            print()
            print("Common causes:")
            print("  - Corrupted model file (try re-downloading)")
            print("  - Insufficient memory (need ~1GB free)")
            print("  - Incompatible model format")
            return False
        
        load_time = time.time() - start_load
        print(f"✓ Model loaded in {load_time:.2f} seconds")
        print()
        
        # Format prompt for TinyLlama chat format
        formatted_prompt = f"<|system|>\nYou are a tactical military AI assistant.</s>\n<|user|>\n{prompt}</s>\n<|assistant|>\n"
        
        # Run inference
        print(f"User prompt: {prompt}")
        print()
        print(f"Formatted prompt length: {len(formatted_prompt)} chars")
        print("Generating response...")
        start_inference = time.time()
        
        try:
            output = llm(
                formatted_prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                top_p=0.9,
                repeat_penalty=1.1,
                stop=["</s>", "<|", "\n\n"],  # Better stop tokens for chat format
                echo=False
            )
        except Exception as e:
            print(f"✗ Inference failed: {e}")
            import traceback
            traceback.print_exc()
            return False
        
        inference_time = time.time() - start_inference
        
        # Debug: Print raw output structure
        print()
        print("=" * 60)
        print("RAW OUTPUT DEBUG")
        print("=" * 60)
        print(f"Output type: {type(output)}")
        print(f"Output keys: {output.keys() if isinstance(output, dict) else 'N/A'}")
        if 'choices' in output:
            print(f"Number of choices: {len(output['choices'])}")
            if len(output['choices']) > 0:
                choice = output['choices'][0]
                print(f"Choice keys: {choice.keys()}")
                print(f"Text length: {len(choice.get('text', ''))}")
                print(f"Text repr: {repr(choice.get('text', ''))}")
        print("=" * 60)
        print()
        
        # Extract response
        if output and 'choices' in output and len(output['choices']) > 0:
            response = output['choices'][0]['text'].strip()
            
            # Check if response is empty or too short
            if not response or len(response) < 3:
                print()
                print("=" * 60)
                print("RESPONSE: (empty or too short)")
                print(f"Raw output: {repr(response)}")
                print("=" * 60)
                print()
                print(f"⚠ Inference completed in {inference_time:.2f} seconds but response is empty")
                print()
                print("DEBUGGING TIPS:")
                print("  1. The model may have generated only whitespace or stop tokens")
                print("  2. Try increasing max_tokens (current: {})".format(max_tokens))
                print("  3. Try increasing temperature (current: {})".format(temperature))
                print("  4. The prompt format may not match the model's training")
                print()
                print("Attempting alternative prompt format...")
                
                # Try simpler prompt
                simple_prompt = f"Q: {prompt}\nA:"
                print(f"Trying: {simple_prompt}")
                
                try:
                    output2 = llm(
                        simple_prompt,
                        max_tokens=max_tokens,
                        temperature=0.7,  # Higher temperature
                        top_p=0.9,
                        repeat_penalty=1.1,
                        stop=["\n", "Q:"],
                        echo=False
                    )
                    
                    if output2 and 'choices' in output2 and len(output2['choices']) > 0:
                        response2 = output2['choices'][0]['text'].strip()
                        if response2 and len(response2) >= 3:
                            print()
                            print("=" * 60)
                            print("ALTERNATIVE FORMAT RESPONSE:")
                            print(response2)
                            print("=" * 60)
                            return True
                except:
                    pass
                
                return False
            else:
                print()
                print("=" * 60)
                print("RESPONSE:")
                print(response)
                print("=" * 60)
                print()
                print(f"✓ Inference completed in {inference_time:.2f} seconds")
            
            # Token statistics
            if 'usage' in output:
                usage = output['usage']
                print(f"  Tokens generated: {usage.get('completion_tokens', 'N/A')}")
                print(f"  Total tokens: {usage.get('total_tokens', 'N/A')}")
            
            # Consider it successful if we got any response
            return True
        else:
            print("✗ No output generated")
            print("Output structure:", output)
            return False
            
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 test_script.py <model_path> <prompt>")
        sys.exit(1)
    
    model_path = sys.argv[1]
    prompt = sys.argv[2]
    
    success = test_inference(model_path, prompt)
    sys.exit(0 if success else 1)
PYTHON_EOF
    
    chmod +x "$TEST_SCRIPT"
    
    # Run the test
    print_info "Running inference with prompt: '$TEST_PROMPT'"
    echo ""
    
    if python3 "$TEST_SCRIPT" "$MODEL_PATH" "$TEST_PROMPT"; then
        echo ""
        print_success "Inference test PASSED"
        TEST_RESULT=0
    else
        echo ""
        print_error "Inference test FAILED"
        TEST_RESULT=1
    fi
    
    # Cleanup
    rm -f "$TEST_SCRIPT"
    
    return $TEST_RESULT
}

################################################################################
# Main Execution
################################################################################

main() {
    echo ""
    print_header "TinyLlama GGUF Model Check & Test"
    echo ""
    print_info "Project: Edge AI Copilot for Raspberry Pi"
    print_info "Date: $(date)"
    print_info "Mode: Auto-install missing components"
    echo ""
    
    # Track overall success
    OVERALL_SUCCESS=0
    
    # Step 1: Check model file
    if ! check_model_exists; then
        print_error "Model check/download failed"
        exit 1
    fi
    echo ""
    
    # Step 2: Check dependencies
    if ! check_python_dependencies; then
        print_error "Dependency check/installation failed"
        exit 1
    fi
    echo ""
    
    # Step 3: Check system resources
    check_system_resources
    echo ""
    
    # Step 4: Run inference test
    if ! run_inference_test; then
        OVERALL_SUCCESS=1
    fi
    echo ""
    
    # Final summary
    print_header "Test Summary"
    
    if [ $OVERALL_SUCCESS -eq 0 ]; then
        print_success "All checks passed! TinyLlama is ready to use."
        echo ""
        print_info "Next steps:"
        echo "  1. Review config.py for system settings"
        echo "  2. Start the Edge AI Copilot: python3 main.py"
        echo "  3. Send test telemetry via MQTT"
    else
        print_error "Inference test failed. Review debug output above."
        echo ""
        print_info "Troubleshooting:"
        echo "  1. Check if model file is corrupted (re-download if needed)"
        echo "  2. Ensure sufficient RAM (need ~1GB free)"
        echo "  3. Try different prompt formats"
        echo "  4. Check llama-cpp-python installation"
        echo ""
        print_info "For detailed logs, scroll up to see DEBUG INFORMATION section"
    fi
    
    echo ""
    exit $OVERALL_SUCCESS
}

# Run main function
main
