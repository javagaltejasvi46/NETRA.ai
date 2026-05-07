# Troubleshooting Guide

## Connection Failed Errors

### Error: "Connection failed [IP: 2a00:1098:88:26::1:1 80]"

This error occurs during package installation, not MQTT connection. It's trying to download dependencies.

#### Solution 1: Check Internet Connection

```bash
# Test internet connectivity
ping -c 4 8.8.8.8

# Test DNS resolution
ping -c 4 google.com

# If IPv6 is causing issues, prefer IPv4
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
```

#### Solution 2: Install Dependencies Manually

```bash
# Update package lists
sudo apt-get update

# Install system dependencies one by one
sudo apt-get install -y mosquitto
sudo apt-get install -y mosquitto-clients
sudo apt-get install -y python3-pip
sudo apt-get install -y portaudio19-dev

# Install Python packages
pip3 install paho-mqtt
pip3 install pygame

# For llama-cpp-python, try without OpenBLAS first
pip3 install llama-cpp-python

# If that fails, install build dependencies
sudo apt-get install -y cmake build-essential
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip3 install llama-cpp-python --no-cache-dir
```

#### Solution 3: Skip Piper TTS Initially

If Piper installation fails, you can run the system without TTS:

1. Comment out TTS in orchestrator.py temporarily
2. Or install Piper separately later:

```bash
pip3 install piper-tts
```

### Error: "Model file not found"

```bash
# Download model manually
cd edge_ai
mkdir -p models

# Download TinyLlama (recommended)
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf

# Or use curl if wget fails
curl -L https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -o models/tinyllama.gguf
```

### Error: "MQTT Broker connection failed"

#### Check Mosquitto Status

```bash
# Check if Mosquitto is running
sudo systemctl status mosquitto

# If not running, start it
sudo systemctl start mosquitto

# Enable on boot
sudo systemctl enable mosquitto

# Test MQTT locally
mosquitto_pub -t test -m "hello"
mosquitto_sub -t test -v
```

#### Check Mosquitto Configuration

```bash
# View Mosquitto config
cat /etc/mosquitto/mosquitto.conf

# If empty or misconfigured, create basic config
sudo nano /etc/mosquitto/mosquitto.conf
```

Add:
```
listener 1883
allow_anonymous true
```

Then restart:
```bash
sudo systemctl restart mosquitto
```

### Error: "llama-cpp-python installation failed"

#### Option 1: Install Pre-built Wheel

```bash
# For Raspberry Pi OS 64-bit
pip3 install llama-cpp-python --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu
```

#### Option 2: Build from Source (Slower but More Compatible)

```bash
# Install build dependencies
sudo apt-get install -y cmake build-essential libopenblas-dev

# Build with OpenBLAS support
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" \
  pip3 install llama-cpp-python --no-cache-dir --verbose
```

#### Option 3: Use Subprocess Method Instead

If llama-cpp-python won't install, modify `edge_ai/ai/inference.py` to use subprocess:

```python
# Instead of importing Llama from llama_cpp
# Use subprocess to call llama.cpp CLI directly
import subprocess

def _load_model(self):
    # Skip model loading, use CLI instead
    pass

def generate(self, prompt, assessment=None):
    try:
        # Call llama.cpp CLI
        result = subprocess.run(
            ['./llama.cpp/main', '-m', self.model_path, 
             '-p', prompt, '-n', str(self.max_tokens),
             '--temp', str(self.temperature)],
            capture_output=True,
            text=True,
            timeout=self.timeout
        )
        return result.stdout.strip()
    except Exception as e:
        if self.failsafe_handler and assessment:
            return self.failsafe_handler.generate_fallback(assessment)
        return None
```

## Network Issues

### Slow Download Speeds

```bash
# Use a different mirror
sudo nano /etc/apt/sources.list
# Change to a closer mirror

# Or use IPv4 only
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
```

### Firewall Blocking MQTT

```bash
# Check firewall status
sudo ufw status

# Allow MQTT port
sudo ufw allow 1883/tcp

# Or disable firewall temporarily for testing
sudo ufw disable
```

## Memory Issues

### Out of Memory During Model Loading

```bash
# Check available memory
free -h

# Increase swap space
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### Reduce Memory Usage

Edit `config.py`:
```python
MAX_TOKENS = 30  # Reduce from 40
THREADS = 1      # Reduce from 2 if needed
```

## Audio Issues

### No Audio Output

```bash
# Test audio
speaker-test -t wav -c 2

# Check audio devices
aplay -l

# Set default audio device
sudo raspi-config
# Navigate to: System Options > Audio

# Test with simple playback
aplay /usr/share/sounds/alsa/Front_Center.wav
```

### Piper TTS Not Working

```bash
# Test Piper directly
echo "test" | piper --model en_US-lessac-medium --output_file /tmp/test.wav
aplay /tmp/test.wav

# If model download fails, download manually
mkdir -p ~/.local/share/piper-tts
cd ~/.local/share/piper-tts
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json
```

## Quick Diagnostic Script

Save as `diagnose.sh`:

```bash
#!/bin/bash

echo "=== Edge AI Copilot Diagnostics ==="
echo ""

echo "1. System Info:"
uname -a
echo ""

echo "2. Python Version:"
python3 --version
echo ""

echo "3. Internet Connectivity:"
ping -c 2 8.8.8.8 && echo "✓ Internet OK" || echo "✗ No Internet"
echo ""

echo "4. Mosquitto Status:"
sudo systemctl is-active mosquitto && echo "✓ Mosquitto running" || echo "✗ Mosquitto not running"
echo ""

echo "5. MQTT Test:"
timeout 2 mosquitto_sub -t test -C 1 &
sleep 1
mosquitto_pub -t test -m "test"
wait
echo ""

echo "6. Python Packages:"
python3 -c "import paho.mqtt.client; print('✓ paho-mqtt')" 2>/dev/null || echo "✗ paho-mqtt missing"
python3 -c "import llama_cpp; print('✓ llama-cpp-python')" 2>/dev/null || echo "✗ llama-cpp-python missing"
python3 -c "import pygame; print('✓ pygame')" 2>/dev/null || echo "✗ pygame missing"
echo ""

echo "7. Model File:"
[ -f "models/tinyllama.gguf" ] && echo "✓ Model exists" || echo "✗ Model missing"
echo ""

echo "8. Disk Space:"
df -h | grep -E "Filesystem|/$"
echo ""

echo "9. Memory:"
free -h
echo ""

echo "=== End Diagnostics ==="
```

Run with:
```bash
chmod +x diagnose.sh
./diagnose.sh
```

## Minimal Test Without Dependencies

Create `test_minimal.py`:

```python
#!/usr/bin/env python3
"""Minimal test without heavy dependencies"""

import json
import time

# Test 1: MQTT
try:
    import paho.mqtt.client as mqtt
    print("✓ MQTT library OK")
    
    client = mqtt.Client()
    client.connect("localhost", 1883, 60)
    print("✓ MQTT broker connection OK")
    client.disconnect()
except Exception as e:
    print(f"✗ MQTT failed: {e}")

# Test 2: Telemetry parsing
try:
    payload = json.dumps({
        "timestamp": int(time.time()),
        "soldier": {"x": 120, "y": 340, "heart_rate": 125},
        "enemy": {"x": 180, "y": 360},
        "hostage": {"x": 140, "y": 350},
        "environment": "urban",
        "threat_level": "high"
    })
    data = json.loads(payload)
    print("✓ JSON parsing OK")
except Exception as e:
    print(f"✗ JSON parsing failed: {e}")

# Test 3: Threat analysis (no dependencies)
try:
    import math
    distance = math.sqrt((180-120)**2 + (360-340)**2)
    print(f"✓ Threat analysis OK (distance: {distance:.1f}m)")
except Exception as e:
    print(f"✗ Threat analysis failed: {e}")

print("\nMinimal tests complete!")
```

Run with:
```bash
python3 test_minimal.py
```

## Getting Help

If issues persist:

1. Check logs: `tail -f logs/edge_ai_*.log`
2. Run diagnostics: `./diagnose.sh`
3. Test minimal: `python3 test_minimal.py`
4. Check system journal: `sudo journalctl -xe`
