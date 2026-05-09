# Installation Guide - Fixing "externally-managed-environment" Error

## The Problem

Newer versions of Raspberry Pi OS (Debian Bookworm) prevent direct `pip install` to protect system packages. You'll see this error:

```
error: externally-managed-environment
This environment is externally managed
To install Python packages system-wide, try apt install
```

## Solutions (Choose One)

---

## ✅ Solution 1: Virtual Environment (RECOMMENDED)

This is the **safest and recommended** approach. It creates an isolated Python environment.

### Quick Install:

```bash
cd edge_ai
chmod +x install_llm_venv.sh
./install_llm_venv.sh
```

### Manual Steps:

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip build-essential cmake libopenblas-dev

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install packages
pip install --upgrade pip
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip install llama-cpp-python --no-cache-dir
pip install paho-mqtt
```

### Usage:

```bash
# Always activate before running
source venv/bin/activate

# Run your application
python3 main.py

# When done
deactivate
```

### Pros:
- ✅ Safe - doesn't affect system packages
- ✅ Clean - easy to delete and recreate
- ✅ Recommended by Python developers

### Cons:
- ⚠️ Must activate venv each time
- ⚠️ Systemd service needs adjustment

---

## ⚠️ Solution 2: System-Wide with --break-system-packages

Install packages system-wide by overriding the protection.

### Quick Install:

```bash
cd edge_ai
chmod +x install_llm_system.sh
./install_llm_system.sh
```

### Manual Steps:

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y python3-pip build-essential cmake libopenblas-dev

# Install with override flag
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" \
  pip3 install llama-cpp-python --no-cache-dir --break-system-packages

pip3 install paho-mqtt --break-system-packages
```

### Usage:

```bash
# Just run directly
python3 main.py
```

### Pros:
- ✅ Simple - no activation needed
- ✅ Works with systemd service as-is

### Cons:
- ⚠️ May conflict with system packages
- ⚠️ Not recommended by Python developers

---

## 🔧 Solution 3: Use apt packages (Limited)

Some packages are available via apt, but llama-cpp-python is not.

```bash
sudo apt-get install python3-paho-mqtt
# llama-cpp-python NOT available via apt
```

**Not viable for this project** - llama-cpp-python must be installed via pip.

---

## 📦 Solution 4: Modify pip.conf (Permanent Override)

Make pip always use `--break-system-packages`.

```bash
# Create config file
mkdir -p ~/.config/pip
cat > ~/.config/pip/pip.conf << EOF
[global]
break-system-packages = true
EOF
```

Then install normally:
```bash
pip3 install llama-cpp-python
```

### Pros:
- ✅ Don't need to type --break-system-packages each time

### Cons:
- ⚠️ Affects ALL pip installs permanently
- ⚠️ Easy to forget it's enabled

---

## 🎯 Recommended Approach

### For Development/Testing:
**Use Virtual Environment (Solution 1)**

```bash
./install_llm_venv.sh
source venv/bin/activate
python3 main.py
```

### For Production/Systemd Service:
**Use --break-system-packages (Solution 2)**

```bash
./install_llm_system.sh
python3 main.py
```

Then update systemd service to use system Python.

---

## Updating Systemd Service for Virtual Environment

If you use virtual environment, update the service file:

```bash
sudo nano /etc/systemd/system/edge-ai-copilot.service
```

Change:
```ini
[Service]
ExecStart=/usr/bin/python3 main.py
```

To:
```ini
[Service]
ExecStart=/home/pi/edge_ai/venv/bin/python3 main.py
```

Then reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart edge-ai-copilot
```

---

## Download Model

Regardless of which solution you choose, download the model:

```bash
mkdir -p models
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf
```

---

## Testing Installation

### With Virtual Environment:
```bash
source venv/bin/activate
python3 -c "import llama_cpp; print('Success!')"
```

### System-Wide:
```bash
python3 -c "import llama_cpp; print('Success!')"
```

---

## Quick Start Commands

### Option A: Virtual Environment
```bash
cd edge_ai
./install_llm_venv.sh
source venv/bin/activate
./check_llm_and_test.sh
```

### Option B: System-Wide
```bash
cd edge_ai
./install_llm_system.sh
./check_llm_and_test.sh
```

---

## Troubleshooting

### "command not found: venv"
```bash
sudo apt-get install python3-venv
```

### "No module named 'llama_cpp'" (with venv)
```bash
# Make sure venv is activated
source venv/bin/activate
# Check which python
which python3  # Should show: /path/to/edge_ai/venv/bin/python3
```

### Build fails during llama-cpp-python installation
```bash
# Install build dependencies
sudo apt-get install -y build-essential cmake libopenblas-dev

# Try again
pip install llama-cpp-python --no-cache-dir
```

### Out of disk space during build
```bash
# Check space
df -h

# Clean up
sudo apt-get clean
sudo apt-get autoremove
```

---

## Summary

| Method | Safety | Ease of Use | Systemd Compatible |
|--------|--------|-------------|-------------------|
| Virtual Env | ✅ Safe | ⚠️ Need activation | ⚠️ Needs config |
| --break-system-packages | ⚠️ Risky | ✅ Simple | ✅ Works as-is |
| pip.conf | ⚠️ Risky | ✅ Simple | ✅ Works as-is |

**Recommendation**: Use virtual environment for development, system-wide for production deployment.
