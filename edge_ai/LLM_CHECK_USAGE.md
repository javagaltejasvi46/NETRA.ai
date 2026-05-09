# TinyLlama LLM Check & Test Script

## Overview
The `check_llm_and_test.sh` script is an all-in-one tool for setting up and testing TinyLlama on your Raspberry Pi. It automatically installs missing components and provides detailed debugging.

## What It Does

### 1. **Auto-Install Model** 🤖
- Checks if `models/tinyllama.gguf` exists
- If missing, automatically downloads it (~637 MB)
- Verifies file size and integrity
- Fixes file permissions if needed

### 2. **Auto-Install Dependencies** 📦
- Checks for Python3 and pip3
- Installs llama-cpp-python if missing
- Uses optimized build for Raspberry Pi (with OpenBLAS)
- Installs build dependencies automatically

### 3. **System Resource Check** 💻
- Reports RAM availability (needs ~1GB)
- Shows CPU cores and model
- Detects Raspberry Pi model

### 4. **Comprehensive Inference Test** 🧪
- Loads the model and measures load time
- Runs test prompt: "Enemy detected at 50 meters approaching fast. What should I do?"
- Uses proper TinyLlama chat format
- Provides detailed debugging output
- Attempts alternative prompt formats if first attempt fails

## Usage

```bash
cd edge_ai
chmod +x check_llm_and_test.sh
./check_llm_and_test.sh
```

## What's New (Auto-Install Version)

### ✅ Automatic Downloads
- No manual wget commands needed
- Downloads model automatically if missing
- Shows progress bar during download

### ✅ Automatic Installation
- Installs pip3 if missing
- Installs llama-cpp-python with Raspberry Pi optimizations
- Installs build dependencies (cmake, openblas)

### ✅ Enhanced Debugging
The script now provides extensive debug information:

```
DEBUG INFORMATION
==================================================
Python version: 3.x.x
Model path: models/tinyllama.gguf
Model exists: True
Model size: 637.42 MB
Working directory: /path/to/edge_ai
==================================================

RAW OUTPUT DEBUG
==================================================
Output type: <class 'dict'>
Output keys: dict_keys(['choices', 'usage', ...])
Number of choices: 1
Text length: 45
Text repr: 'Take cover and assess the situation'
==================================================
```

### ✅ Fallback Testing
If the first prompt format fails (empty response), the script:
1. Shows detailed debugging info
2. Explains possible causes
3. Automatically tries alternative prompt format
4. Uses higher temperature for better generation

### ✅ Better Error Messages
Instead of just failing, the script now:
- Explains what went wrong
- Suggests specific fixes
- Shows exact commands to run manually if needed

## Debugging Empty Responses

If you get an empty response, the script will show:

1. **Raw output structure** - See exactly what the model returned
2. **Token counts** - How many tokens were generated
3. **Prompt format** - The exact prompt sent to the model
4. **Alternative attempts** - Tries different formats automatically

### Common Causes of Empty Responses:
- ❌ Stop tokens triggered too early
- ❌ Wrong prompt format for the model
- ❌ Temperature too low (model too conservative)
- ❌ Model file corrupted

### The Script's Solutions:
- ✅ Uses proper TinyLlama chat format: `<|system|>...<|user|>...<|assistant|>`
- ✅ Better stop tokens: `["</s>", "<|", "\n\n"]` instead of `["\n", ".", "!"]`
- ✅ Fallback to simpler format: `Q: ... A:`
- ✅ Increases temperature on retry (0.4 → 0.7)

## Expected Output

### Successful Run:
```
========================================
Step 1: Checking Model File
========================================
✓ Model file found: models/tinyllama.gguf
ℹ Model size: 637 MB
✓ Model file is readable

========================================
Step 2: Checking Python Dependencies
========================================
✓ Python3 found: 3.9.2
✓ pip3 found
✓ llama-cpp-python installed (version: 0.3.22)

========================================
Step 3: Checking System Resources
========================================
ℹ Total RAM: 7850 MB
ℹ Available RAM: 4200 MB
✓ Sufficient memory available
ℹ CPU cores: 4
ℹ Device: Raspberry Pi 4 Model B Rev 1.5

========================================
Step 4: Running Inference Test
========================================
✓ Model loaded in 15.84 seconds

User prompt: Enemy detected at 50 meters approaching fast. What should I do?

Generating response...

============================================================
RESPONSE:
Take cover immediately and radio for backup
============================================================

✓ Inference completed in 2.12 seconds
  Tokens generated: 8
  Total tokens: 24

✓ Inference test PASSED

========================================
Test Summary
========================================
✓ All checks passed! TinyLlama is ready to use.
```

## Installation Time Estimates

- **Model download**: 5-15 minutes (depending on internet speed)
- **llama-cpp-python build**: 10-15 minutes (first time only on Raspberry Pi)
- **Total first run**: ~20-30 minutes
- **Subsequent runs**: ~20 seconds (just testing)

## Manual Installation (If Script Fails)

### Download Model:
```bash
mkdir -p models
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf
```

### Install Dependencies:
```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libopenblas-dev python3-pip
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip3 install llama-cpp-python --no-cache-dir
```

## Troubleshooting

### "Model file too small"
- Download was interrupted
- Run script again, it will re-download

### "Failed to load model"
- Insufficient RAM (close other apps)
- Corrupted file (delete and re-download)
- Wrong model format (ensure it's GGUF)

### "llama-cpp-python installation failed"
- Check internet connection
- Ensure sufficient disk space (~2GB needed for build)
- Try manual installation commands above

### "Empty response" even after retry
- Model may need different prompt format
- Try editing the script to use simpler prompts
- Check model file integrity (re-download)

## Next Steps After Success

1. **Configure the system**: Edit `config.py`
2. **Start the copilot**: `python3 main.py`
3. **Test with MQTT**: Send telemetry data
4. **Monitor logs**: `tail -f logs/edge_ai_*.log`

## Support

If issues persist:
1. Check the DEBUG INFORMATION section in output
2. Review RAW OUTPUT DEBUG for model response details
3. Ensure Raspberry Pi has adequate cooling (throttling affects performance)
4. Try running with `sudo` if permission errors occur
