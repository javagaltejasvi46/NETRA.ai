# Edge AI Copilot - Installation Summary

## 🚨 The "externally-managed-environment" Error

You're seeing this error because **Raspberry Pi OS (Debian Bookworm)** now prevents direct `pip install` to protect system packages.

```
error: externally-managed-environment
```

This is **NORMAL** and **EXPECTED** on modern Raspberry Pi OS.

---

## ✅ Quick Solutions

### 🎯 Recommended: Virtual Environment

```bash
cd edge_ai
chmod +x install_llm_venv.sh
./install_llm_venv.sh
```

**Usage:**
```bash
source venv/bin/activate  # Always run this first
python3 main.py
```

---

### ⚡ Alternative: System-Wide Install

```bash
cd edge_ai
chmod +x install_llm_system.sh
./install_llm_system.sh
```

**Usage:**
```bash
python3 main.py  # No activation needed
```

---

## 📋 What Gets Installed

1. **System packages** (via apt):
   - build-essential
   - cmake
   - libopenblas-dev
   - python3-venv (for venv option)

2. **Python packages** (via pip):
   - llama-cpp-python (with OpenBLAS optimization)
   - paho-mqtt

3. **Model file** (via wget):
   - TinyLlama 1.1B Q4_K_M (~637 MB)

---

## ⏱️ Installation Time

- **System dependencies**: 2-5 minutes
- **llama-cpp-python build**: 10-15 minutes (Raspberry Pi compiles from source)
- **Model download**: 5-15 minutes (depends on internet speed)
- **Total**: ~20-35 minutes

---

## 🧪 Testing Your Installation

### Automated Test:
```bash
./check_llm_and_test.sh
```

This will:
- ✅ Check if model exists (download if missing)
- ✅ Verify llama-cpp-python installation
- ✅ Run inference test with debugging
- ✅ Show detailed output

### Manual Test:
```bash
# If using venv:
source venv/bin/activate

# Test import:
python3 -c "import llama_cpp; print('Success!')"

# Test model:
python3 -c "from llama_cpp import Llama; llm = Llama('models/tinyllama.gguf'); print('Model loaded!')"
```

---

## 📁 Files Created

```
edge_ai/
├── venv/                          # Virtual environment (if using venv)
├── models/
│   └── tinyllama.gguf            # LLM model (~637 MB)
├── install_llm_venv.sh           # Venv installer
├── install_llm_system.sh         # System-wide installer
├── check_llm_and_test.sh         # Test script
├── INSTALL_GUIDE.md              # Detailed guide
├── QUICK_FIX.txt                 # Quick reference
└── README_INSTALLATION.md        # This file
```

---

## 🔧 Common Issues

### Issue: "No module named 'llama_cpp'"

**If using venv:**
```bash
source venv/bin/activate  # You forgot this!
```

**If system-wide:**
```bash
# Reinstall with correct flag
pip3 install llama-cpp-python --break-system-packages
```

---

### Issue: Build fails with "No space left on device"

```bash
# Check space
df -h

# Clean up
sudo apt-get clean
sudo apt-get autoremove
rm -rf ~/.cache/pip

# Need at least 2GB free for build
```

---

### Issue: "Model file not found"

```bash
# Download manually
mkdir -p models
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf
```

---

### Issue: Empty response from model

This is a **prompt formatting issue**, not an installation issue.

The updated `check_llm_and_test.sh` includes:
- ✅ Proper TinyLlama chat format
- ✅ Better stop tokens
- ✅ Detailed debugging output
- ✅ Alternative prompt formats

Run the test script to see detailed debugging:
```bash
./check_llm_and_test.sh
```

---

## 🎯 Next Steps After Installation

1. **Test the installation:**
   ```bash
   ./check_llm_and_test.sh
   ```

2. **Configure the system:**
   ```bash
   nano config.py  # Adjust MQTT broker, etc.
   ```

3. **Run the copilot:**
   ```bash
   # If using venv:
   source venv/bin/activate
   
   python3 main.py
   ```

4. **Set up as service** (optional):
   ```bash
   sudo cp edge-ai-copilot.service /etc/systemd/system/
   sudo systemctl enable edge-ai-copilot
   sudo systemctl start edge-ai-copilot
   ```

---

## 📚 Documentation Files

- **QUICK_FIX.txt** - One-page quick reference
- **INSTALL_GUIDE.md** - Detailed installation guide with all options
- **LLM_CHECK_USAGE.md** - How to use the test script
- **README_INSTALLATION.md** - This file (overview)

---

## 🆘 Still Having Issues?

1. **Read the detailed guide:**
   ```bash
   cat INSTALL_GUIDE.md
   ```

2. **Check the quick fix:**
   ```bash
   cat QUICK_FIX.txt
   ```

3. **Run the test script with debugging:**
   ```bash
   ./check_llm_and_test.sh
   ```

4. **Check system logs:**
   ```bash
   tail -f logs/edge_ai_*.log
   ```

---

## 💡 Pro Tips

1. **Virtual environment is safer** - Use it for development
2. **System-wide is simpler** - Use it for production
3. **Be patient during build** - 10-15 minutes is normal on Raspberry Pi
4. **Check available RAM** - Need ~1GB free to load model
5. **Use Q4 quantized model** - Q8 is too slow for Raspberry Pi

---

## ✨ Summary

| Method | Command | Pros | Cons |
|--------|---------|------|------|
| Virtual Env | `./install_llm_venv.sh` | Safe, isolated | Need to activate |
| System-Wide | `./install_llm_system.sh` | Simple, direct | May conflict |

**Recommendation**: Use virtual environment for development, system-wide for production.

---

**Installation complete? Run the test:**
```bash
./check_llm_and_test.sh
```
