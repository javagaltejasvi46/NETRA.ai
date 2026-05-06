# Edge AI Copilot

Autonomous battlefield edge AI unit running on Raspberry Pi 4. Processes telemetry data locally using lightweight LLM (llama.cpp with TinyLlama), generates tactical recommendations, converts them to speech using Piper TTS, and publishes responses via MQTT.

## Features

- **Real-time Telemetry Processing**: Receives battlefield sensor data via MQTT
- **Local AI Inference**: Uses llama.cpp for low-latency tactical decision generation
- **Threat Analysis**: Computes risk scores and threat levels from telemetry
- **Voice Output**: Converts decisions to speech using Piper TTS
- **Automatic Reconnection**: Robust MQTT handling with exponential backoff
- **Failsafe Logic**: Rule-based fallback when AI inference fails
- **Comprehensive Logging**: Daily log rotation with configurable retention

## System Requirements

### Hardware
- Raspberry Pi 4 (8GB recommended, 4GB minimum)
- MicroSD card (32GB+)
- Audio output (HDMI, 3.5mm jack, or USB audio)
- Network connection (Ethernet or WiFi)

### Software
- Raspberry Pi OS (64-bit recommended)
- Python 3.8+
- MQTT Broker (Mosquitto)

## Installation

### 1. System Dependencies

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install system packages
sudo apt-get install -y mosquitto mosquitto-clients python3-pip portaudio19-dev git

# Start Mosquitto broker
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
```

### 2. Python Dependencies

```bash
# Navigate to project directory
cd edge_ai

# Install Python packages
pip3 install paho-mqtt llama-cpp-python piper-tts pygame

# For Raspberry Pi, you may need to build llama-cpp-python from source:
CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" pip3 install llama-cpp-python --no-cache-dir
```

### 3. Download AI Model

```bash
# Create models directory
mkdir -p models

# Download TinyLlama Q4 model (recommended)
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf -O models/tinyllama.gguf

# Alternative: Qwen 1.5B Q4 (better quality, slightly slower)
# wget https://huggingface.co/Qwen/Qwen-1_8B-Chat-GGUF/resolve/main/qwen-1_8b-chat-q4_k_m.gguf -O models/qwen.gguf
```

### 4. Install Piper TTS

```bash
# Install Piper
pip3 install piper-tts

# Download voice model (automatic on first use)
echo "test" | piper --model en_US-lessac-medium --output_file /tmp/test.wav
```

## Configuration

Edit `config.py` to customize settings:

### MQTT Settings
```python
MQTT_BROKER_HOST = "localhost"  # MQTT broker address
MQTT_BROKER_PORT = 1883         # MQTT broker port
MQTT_TOPIC_SENSOR = "battlefield/sensor"      # Incoming telemetry topic
MQTT_TOPIC_RESPONSE = "battlefield/ai-response"  # Outgoing response topic
MQTT_QOS = 1                    # Quality of Service (0, 1, or 2)
```

### AI Settings
```python
MODEL_PATH = "models/tinyllama.gguf"  # Path to GGUF model
MAX_TOKENS = 40                       # Maximum tokens to generate
TEMPERATURE = 0.4                     # Sampling temperature (0.0-2.0)
THREADS = 2                           # CPU threads for inference
INFERENCE_TIMEOUT = 3                 # Timeout in seconds
```

### Threat Analysis Thresholds
```python
CRITICAL_DISTANCE = 100      # Enemy distance for CRITICAL threat (meters)
STRESS_HEART_RATE = 120      # Heart rate threshold for HIGH stress (bpm)
HOSTAGE_RISK_DISTANCE = 50   # Hostage proximity for ELEVATED risk (meters)
```

### TTS Settings
```python
TTS_MODEL = "en_US-lessac-medium"  # Piper voice model
TTS_TIMEOUT = 2                    # TTS generation timeout (seconds)
```

## Usage

### Running Manually

```bash
# From edge_ai directory
python3 main.py
```

### Running as Systemd Service

1. Create service file:

```bash
sudo nano /etc/systemd/system/edge-ai-copilot.service
```

2. Add the following content:

```ini
[Unit]
Description=Edge AI Copilot
After=network.target mosquitto.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/edge_ai
ExecStart=/usr/bin/python3 main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

3. Enable and start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable edge-ai-copilot
sudo systemctl start edge-ai-copilot
```

4. Check status:

```bash
sudo systemctl status edge-ai-copilot
sudo journalctl -u edge-ai-copilot -f
```

## MQTT Topics and Payloads

### Incoming Telemetry (`battlefield/sensor`)

```json
{
  "timestamp": 1710000000,
  "soldier": {
    "x": 120,
    "y": 340,
    "heart_rate": 125
  },
  "enemy": {
    "x": 180,
    "y": 360
  },
  "hostage": {
    "x": 140,
    "y": 350
  },
  "environment": "urban",
  "threat_level": "high"
}
```

### Outgoing AI Response (`battlefield/ai-response`)

```json
{
  "decision": "Move to cover immediately",
  "risk_score": 0.87,
  "timestamp": 1710000000,
  "latency_ms": 245
}
```

## Testing

### Run Unit Tests

```bash
python3 -m unittest discover edge_ai/tests
```

### Test MQTT Connection

```bash
# Subscribe to response topic
mosquitto_sub -t "battlefield/ai-response" -v

# Publish test telemetry (in another terminal)
mosquitto_pub -t "battlefield/sensor" -m '{
  "timestamp": 1710000000,
  "soldier": {"x": 120, "y": 340, "heart_rate": 125},
  "enemy": {"x": 180, "y": 360},
  "hostage": {"x": 140, "y": 350},
  "environment": "urban",
  "threat_level": "high"
}'
```

## Architecture

```
Dashboard/Backend
    ↓ MQTT publish (battlefield/sensor)
Raspberry Pi MQTT Subscriber
    ↓
Telemetry Parser
    ↓
Threat Analyzer (compute risk scores)
    ↓
Prompt Builder (generate LLM prompt)
    ↓
llama.cpp Inference (generate decision)
    ↓
Decision Validator (format & validate)
    ↓
Piper TTS (voice output)
    ↓
MQTT Publisher (battlefield/ai-response)
    ↓
Dashboard receives AI feedback
```

## Directory Structure

```
edge_ai/
├── main.py                 # Entry point
├── config.py              # Configuration
├── orchestrator.py        # Main pipeline coordinator
├── mqtt/
│   ├── subscriber.py      # MQTT subscriber
│   ├── publisher.py       # MQTT publisher
│   └── models.py          # Telemetry data models
├── ai/
│   ├── threat_analysis.py # Threat analyzer
│   ├── prompt_builder.py  # Prompt generator
│   ├── inference.py       # LLM inference engine
│   ├── failsafe.py        # Fallback logic
│   └── decision_validator.py  # Decision validator
├── voice/
│   └── tts.py            # Text-to-speech engine
├── utils/
│   └── helpers.py        # Logging and utilities
├── models/               # AI models (GGUF files)
├── logs/                 # Log files
└── tests/               # Integration tests
```

## Troubleshooting

### Model Loading Fails
- Verify model file exists: `ls -lh models/tinyllama.gguf`
- Check file permissions: `chmod 644 models/tinyllama.gguf`
- Ensure sufficient RAM (model requires ~1GB)

### MQTT Connection Issues
- Check Mosquitto is running: `sudo systemctl status mosquitto`
- Test broker: `mosquitto_pub -t test -m "hello"`
- Verify firewall allows port 1883

### Audio Not Playing
- Test audio output: `speaker-test -t wav -c 2`
- Check volume: `alsamixer`
- Verify audio device: `aplay -l`

### High CPU Usage
- Reduce `THREADS` in config.py
- Use smaller model (TinyLlama Q4 instead of Q8)
- Increase `INFERENCE_TIMEOUT` to reduce retries

### Inference Too Slow
- Ensure using Q4 quantized model (not Q8 or F16)
- Set `THREADS=2` (optimal for Raspberry Pi 4)
- Reduce `MAX_TOKENS` to 30-40

## Performance Optimization

### Recommended Settings for Raspberry Pi 4

```python
# config.py
MAX_TOKENS = 40          # Keep responses short
TEMPERATURE = 0.4        # More deterministic
THREADS = 2              # Optimal for quad-core
INFERENCE_TIMEOUT = 3    # Allow time for inference
```

### Model Selection
- **TinyLlama 1.1B Q4**: Best balance (recommended)
- **Qwen 1.5B Q4**: Better quality, slightly slower
- Avoid Q8 quantization (too slow for Raspberry Pi)

## Security Considerations

### MQTT Security
```bash
# Enable authentication in Mosquitto
sudo mosquitto_passwd -c /etc/mosquitto/passwd edge_ai
sudo nano /etc/mosquitto/mosquitto.conf
```

Add to config:
```
allow_anonymous false
password_file /etc/mosquitto/passwd
```

### TLS Encryption
Generate certificates and update config.py:
```python
MQTT_USE_TLS = True
MQTT_CA_CERTS = "/path/to/ca.crt"
```

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- Check logs: `tail -f logs/edge_ai_*.log`
- Review systemd journal: `sudo journalctl -u edge-ai-copilot -n 100`
- Test components individually using unit tests
