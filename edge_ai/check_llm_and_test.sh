#!/bin/bash

################################################################################
# TinyLlama GGUF Model Checker and Test Script
# For Raspberry Pi Edge AI Copilot Project
#
# This script:
# 1. Checks if TinyLlama GGUF model exists
# 2. Verifies llama-cpp-python installation
# 3. Runs a basic inference test with a simple prompt
# 4. Reports results without installing anything
################################################################################

set -e  # Exit on error

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
            return 1
        fi
        
        # Check file permissions
        if [ -r "$MODEL_PATH" ]; then
            print_success "Model file is readable"
        else
            print_error "Model file exists but is not readable"
            print_info "Try: chmod 644 $MODEL_PATH"
            return 1
        fi
        
        return 0
    else
        print_error "Model file not found: $MODEL_PATH"
        echo ""
        print_info "To download TinyLlama model, run:"
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
        return 1
    fi
    
    # Check llama-cpp-python
    if python3 -c "import llama_cpp" 2>/dev/null; then
        LLAMA_VERSION=$(python3 -c "import llama_cpp; print(llama_cpp.__version__)" 2>/dev/null || echo "unknown")
        print_success "llama-cpp-python installed (version: $LLAMA_VERSION)"
    else
        print_error "llama-cpp-python not installed"
        echo ""
        print_info "To install llama-cpp-python, run:"
        echo "  pip3 install llama-cpp-python"
        echo ""
        print_info "For Raspberry Pi with optimizations:"
        echo "  CMAKE_ARGS=\"-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS\" pip3 install llama-cpp-python --no-cache-dir"
        return 1
    fi
    
    return 0
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
from llama_cpp import Llama

def test_inference(model_path, prompt, max_tokens=40, temperature=0.4, threads=2):
    """Run a simple inference test"""
    try:
        print(f"Loading model: {model_path}")
        start_load = time.time()
        
        # Load model
        llm = Llama(
            model_path=model_path,
            n_threads=threads,
            n_ctx=512,
            verbose=False
        )
        
        load_time = time.time() - start_load
        print(f"✓ Model loaded in {load_time:.2f} seconds")
        print()
        
        # Format prompt for TinyLlama chat format
        formatted_prompt = f"<|system|>\nYou are a tactical military AI assistant.</s>\n<|user|>\n{prompt}</s>\n<|assistant|>\n"
        
        # Run inference
        print(f"Prompt: {prompt}")
        print()
        print("Generating response...")
        start_inference = time.time()
        
        output = llm(
            formatted_prompt,
            max_tokens=max_tokens,
            temperature=temperature,
            top_p=0.9,
            repeat_penalty=1.1,
            stop=["</s>", "<|", "\n\n"],  # Better stop tokens for chat format
            echo=False
        )
        
        inference_time = time.time() - start_inference
        
        # Extract response
        if output and 'choices' in output and len(output['choices']) > 0:
            response = output['choices'][0]['text'].strip()
            
            # Check if response is empty or too short
            if not response or len(response) < 3:
                print()
                print("=" * 60)
                print("RESPONSE: (empty or too short)")
                print(f"Raw output: '{response}'")
                print("=" * 60)
                print()
                print(f"⚠ Inference completed in {inference_time:.2f} seconds but response is empty")
                print("  This may indicate:")
                print("  - Stop tokens triggered too early")
                print("  - Model needs different prompt format")
                print("  - Temperature too low")
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
            return False
            
    except Exception as e:
        print(f"✗ Error during inference: {e}")
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
    echo ""
    
    # Track overall success
    OVERALL_SUCCESS=0
    
    # Step 1: Check model file
    if ! check_model_exists; then
        print_error "Cannot proceed without model file"
        exit 1
    fi
    echo ""
    
    # Step 2: Check dependencies
    if ! check_python_dependencies; then
        print_error "Cannot proceed without required dependencies"
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
        print_error "Some checks failed. Please review the output above."
        echo ""
        print_info "Common issues:"
        echo "  - Model file corrupted: Re-download the model"
        echo "  - Low memory: Close other applications"
        echo "  - Missing dependencies: Install llama-cpp-python"
    fi
    
    echo ""
    exit $OVERALL_SUCCESS
}

# Run main function
main
