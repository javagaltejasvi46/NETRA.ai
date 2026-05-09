# Changelog - Edge AI Copilot v2.0.0

## 🎯 Major Restructuring - Voice Features Removed

### Overview
Complete project restructuring to remove all voice input/output features and create a streamlined, robust system focused on core MQTT-LLM pipeline.

---

## ✅ What Was Added

### 1. Single Setup Script
- **`setup_and_run.sh`** - Comprehensive all-in-one script
  - Checks system information
  - Installs system dependencies
  - Handles "externally-managed-environment" error
  - Offers virtual environment or system-wide installation
  - Downloads TinyLlama model automatically
  - Runs comprehensive tests (imports, model loading, inference, config)
  - Starts the copilot

### 2. Improved Documentation
- **`README.md`** - Complete project documentation
- **`QUICKSTART.md`** - Quick start guide
- **`CHANGELOG.md`** - This file

### 3. Enhanced Configuration
- Simplified `config.py` with only essential settings
- Removed all voice-related configuration
- Better validation and error messages

### 4. Streamlined Orchestrator
- Removed voice input/output pipeline
- Cleaner console output
- Focused on core MQTT-LLM workflow

---

## ❌ What Was Removed

### Files Deleted
```
voice/                          # Entire voice directory
├── speech_recognition.py
├── tts.py
└── __init__.py

ai/
├── conversation_manager.py     # Voice conversation handling
└── telemetry_store.py          # Voice context storage

# Documentation (outdated/redundant)
AUDIO_TROUBLESHOOTING.md
VOICE_FEATURE_SUMMARY.txt
VOICE_INPUT_GUIDE.md
VOICE_QUICK_REF.txt
RUN_WITHOUT_AUDIO.txt
FIX_AUDIO_NOW.txt
SOLUTION.md
TROUBLESHOOTING.md
TESTING_GUIDE.md
TESTING_COMMANDS.txt
TEST_SUMMARY.txt
README_TESTING.txt
READ_ME_FIRST.txt
QUICK_START.md (old version)
INSTALL_GUIDE.md (old version)
README_INSTALLATION.md (old version)
LLM_CHECK_USAGE.md
QUICK_FIX.txt

# Scripts (replaced by setup_and_run.sh)
check_llm_and_test.sh
install_llm_venv.sh
install_llm_system.sh
START_HERE_INSTALLATION.sh
START_HERE.sh
install_all.sh
install_and_test.sh
install_simple.sh
install_voice_input.sh
setup_voice.sh
setup_bluetooth_audio.sh
check_piper_model.sh
diagnose.sh
disable_voice_features.sh
fix_and_run.sh
fix_audio_issues.sh
fix_import_error.sh
fix_now.sh
fix_welcome_audio.sh
test_all_features.sh
test_interactive.sh
test_voice_input.py
deploy.sh
run_edge_ai.py
```

### Dependencies Removed
```
# From requirements.txt
piper-tts
openai-whisper
noisereduce
soundfile
pygame
```

### Code Removed
- All TTS (text-to-speech) functionality
- All speech recognition functionality
- Voice conversation management
- Welcome message system
- Telemetry context storage for voice
- Audio troubleshooting utilities

---

## 🔄 What Changed

### 1. Pipeline Simplification

**Before:**
```
MQTT → Threat Analysis → Prompt → LLM → Validation → TTS → Voice Input → MQTT
```

**After:**
```
MQTT → Threat Analysis → Prompt → LLM → Validation → MQTT
```

### 2. Configuration

**Before:**
```python
# Voice settings
TTS_MODEL = "en_US-lessac-medium"
TTS_TIMEOUT = 2
VOICE_INPUT_ENABLED = False
WHISPER_MODEL = "base"
LISTENING_DURATION = 5
ENABLE_WELCOME_MESSAGE = False
```

**After:**
```python
# Only core AI settings
MODEL_PATH = "models/tinyllama.gguf"
MAX_TOKENS = 50
TEMPERATURE = 0.5
THREADS = 2
INFERENCE_TIMEOUT = 5
```

### 3. Dependencies

**Before:**
```
paho-mqtt
llama-cpp-python
piper-tts
openai-whisper
noisereduce
soundfile
pygame
```

**After:**
```
paho-mqtt
llama-cpp-python
```

### 4. Installation Process

**Before:**
- Multiple scripts for different scenarios
- Separate voice installation
- Complex troubleshooting guides
- Manual dependency management

**After:**
- Single `setup_and_run.sh` script
- Automatic dependency detection
- Automatic error handling
- Comprehensive testing built-in

---

## 📊 Impact

### Performance Improvements
- ✅ Faster startup (no TTS/Whisper loading)
- ✅ Lower memory usage (~500MB less)
- ✅ Simpler error handling
- ✅ Reduced dependencies

### Code Quality
- ✅ Cleaner architecture
- ✅ Easier to maintain
- ✅ Better error messages
- ✅ Comprehensive testing

### User Experience
- ✅ Single command setup
- ✅ Automatic dependency installation
- ✅ Clear console output
- ✅ Better documentation

---

## 🎯 Core Features Retained

- ✅ MQTT telemetry reception
- ✅ Threat analysis and risk scoring
- ✅ LLM-based tactical decision generation
- ✅ Failsafe rule-based fallback
- ✅ Decision validation
- ✅ MQTT response publishing
- ✅ Comprehensive logging
- ✅ Automatic reconnection
- ✅ Raspberry Pi optimization

---

## 🚀 Migration Guide

### For Existing Users

1. **Pull latest changes:**
   ```bash
   git pull
   ```

2. **Remove old virtual environment (if exists):**
   ```bash
   rm -rf venv
   ```

3. **Run new setup script:**
   ```bash
   chmod +x setup_and_run.sh
   ./setup_and_run.sh
   ```

4. **Update systemd service (if using):**
   ```bash
   sudo systemctl stop edge-ai-copilot
   sudo cp edge-ai-copilot.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl start edge-ai-copilot
   ```

### Configuration Changes

Update `config.py`:
- Remove all voice-related settings
- Keep only MQTT and AI settings
- Update MQTT broker IP if needed

---

## 📝 Testing

The new setup script includes comprehensive tests:

1. **Import Test** - Verifies Python packages
2. **Model Loading Test** - Loads TinyLlama
3. **Inference Test** - Generates tactical decision
4. **Configuration Test** - Validates config.py

All tests run automatically during setup.

---

## 🔮 Future Enhancements

Potential future additions:
- [ ] Multiple model support
- [ ] Advanced threat prediction
- [ ] Historical telemetry analysis
- [ ] Web dashboard integration
- [ ] Multi-agent coordination
- [ ] Enhanced failsafe strategies

---

## 📚 Documentation Structure

```
edge_ai/
├── README.md           # Complete documentation
├── QUICKSTART.md       # Quick start guide
├── CHANGELOG.md        # This file
└── setup_and_run.sh    # All-in-one setup script
```

---

## ✨ Summary

**Version 2.0.0** represents a complete restructuring focused on:
- **Simplicity**: One script does everything
- **Robustness**: Comprehensive error handling
- **Performance**: Removed unnecessary features
- **Maintainability**: Cleaner codebase
- **User Experience**: Clear documentation and setup

The core mission remains: **Autonomous battlefield edge AI with <3s latency on Raspberry Pi.**

---

**Upgrade today:** `./setup_and_run.sh` 🚀
