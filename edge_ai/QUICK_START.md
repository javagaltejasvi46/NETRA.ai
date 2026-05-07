# Quick Start Guide

## Error: "ModuleNotFoundError: No module named 'edge_ai'"

This is a Python import path issue. Here are **3 simple solutions**:

---

## ✅ Solution 1: Use START_HERE.sh (EASIEST)

```bash
cd edge_ai
chmod +x START_HERE.sh
./START_HERE.sh
```

This script automatically fixes the import path and starts the system.

---

## ✅ Solution 2: Run from Parent Directory

```bash
# Go to parent directory (NETRA.ai)
cd ..

# Run as a Python module
python3 -m edge_ai.main
```

---

## ✅ Solution 3: Set PYTHONPATH

```bash
cd edge_ai

# Set Python path
export PYTHONPATH="/home/pi/NETRA.ai:$PYTHONPATH"

# Run normally
python3 main.py
```

---

## Testing the System

Once running, test with MQTT:

### Terminal 1: Subscribe to responses
```bash
mosquitto_sub -t 'battlefield/ai-response' -v
```

### Terminal 2: Send test telemetry
```bash
mosquitto_pub -t 'battlefield/sensor' -m '{
  "timestamp": 1710000000,
  "soldier": {"x": 120, "y": 340, "heart_rate": 125},
  "enemy": {"x": 180, "y": 360},
  "hostage": {"x": 140, "y": 350},
  "environment": "urban",
  "threat_level": "high"
}'
```

You should see:
1. Console output showing threat analysis
2. AI-generated tactical decision
3. Audio output (if speakers connected)
4. MQTT response published

---

## Common Issues

### Issue: "Model file not found"
```bash
cd edge_ai
./fix_now.sh  # Downloads model automatically
```

### Issue: "Mosquitto not running"
```bash
sudo systemctl start mosquitto
sudo systemctl enable mosquitto
```

### Issue: "No audio output"
```bash
# Test audio
speaker-test -t wav -c 2

# Check volume
alsamixer
```

### Issue: Still getting import errors
```bash
# Make sure you're in the right directory
pwd  # Should show: /home/pi/NETRA.ai/edge_ai

# Check Python can find modules
python3 -c "import sys; print(sys.path)"

# Use absolute path method
cd /home/pi/NETRA.ai
python3 -m edge_ai.main
```

---

## File Structure

Your directory should look like this:

```
NETRA.ai/
├── edge_ai/              ← You are here
│   ├── main.py
│   ├── config.py
│   ├── orchestrator.py
│   ├── START_HERE.sh    ← Use this to start
│   ├── fix_now.sh       ← Use this to install
│   ├── models/
│   │   └── tinyllama.gguf
│   ├── mqtt/
│   ├── ai/
│   ├── voice/
│   └── utils/
└── dashboard/
```

---

## Quick Commands Reference

```bash
# Install everything
./fix_now.sh

# Start the system
./START_HERE.sh

# Check system status
./diagnose.sh

# View logs
tail -f logs/edge_ai_*.log

# Stop the system
Ctrl+C

# Run as service
sudo systemctl start edge-ai-copilot
sudo systemctl status edge-ai-copilot
```

---

## Still Having Issues?

1. Run diagnostics:
   ```bash
   ./diagnose.sh
   ```

2. Check the full troubleshooting guide:
   ```bash
   cat TROUBLESHOOTING.md
   ```

3. Check logs:
   ```bash
   ls -la logs/
   tail -50 logs/edge_ai_*.log
   ```

---

## Success Indicators

When working correctly, you'll see:

```
✓ Connected to MQTT broker successfully
✓ Subscribed to topic: battlefield/sensor
✓ Threat analyzer initialized
✓ Inference engine initialized
✓ TTS engine initialized
Edge AI Copilot is running. Press Ctrl+C to stop.
```

Then when telemetry arrives:
```
Telemetry received - timestamp: 1710000000, soldier: (120.0, 340.0), ...
Threat Analysis: distance=72.1m, threat=CRITICAL, risk_score=0.87
Decision generated - text: 'Take cover immediately.', risk_score: 0.87
```
