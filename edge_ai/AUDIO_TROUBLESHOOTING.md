# Audio Troubleshooting Guide

## Quick Fixes

### Fix 1: Auto-detect and Configure Audio Devices

```bash
chmod +x fix_audio_issues.sh
./fix_audio_issues.sh
```

This will:
- Detect your audio devices
- Update configuration automatically
- Test recording and playback
- Fix the welcome audio issue

### Fix 2: Fix Welcome Audio Only

```bash
chmod +x fix_welcome_audio.sh
./fix_welcome_audio.sh
```

---

## Common Issues

### Issue 1: "Recording failed: command ['arecord'...] returned non-zero exit status 1"

**Cause:** Wrong audio device or no microphone detected

**Solutions:**

1. **List audio devices:**
   ```bash
   arecord -l
   ```

2. **Find your device:**
   ```
   Output example:
   card 1: Device [USB Audio Device], device 0: USB Audio [USB Audio]
   ```
   Your device is: `plughw:1,0` (card 1, device 0)

3. **Test recording with correct device:**
   ```bash
   arecord -D plughw:1,0 -d 5 -f S16_LE -r 16000 -c 1 test.wav
   aplay test.wav
   ```

4. **If no devices found:**
   - Connect USB microphone
   - Check USB: `lsusb`
   - Enable built-in mic: `sudo raspi-config` → Interface Options → Audio

5. **Update speech_recognition.py manually:**
   ```bash
   nano voice/speech_recognition.py
   ```
   Change `plughw:1,0` to your device (e.g., `plughw:0,0`)

### Issue 2: Welcome Audio Not Playing

**Cause:** Piper TTS not installed or audio output not configured

**Solutions:**

1. **Install Piper TTS:**
   ```bash
   pip3 install piper-tts
   ```

2. **Test Piper:**
   ```bash
   echo "test" | piper --model en_US-lessac-medium --output_file test.wav
   aplay test.wav
   ```

3. **Check audio output devices:**
   ```bash
   aplay -l
   ```

4. **Test speakers:**
   ```bash
   speaker-test -t wav -c 2
   ```

5. **Adjust volume:**
   ```bash
   alsamixer
   ```
   Use arrow keys to increase volume

6. **Check audio output in raspi-config:**
   ```bash
   sudo raspi-config
   ```
   System Options → Audio → Select output (HDMI/Headphones)

### Issue 3: "No audio input device detected"

**Solutions:**

1. **Check USB connections:**
   ```bash
   lsusb
   ```
   Should show your USB microphone

2. **Check ALSA devices:**
   ```bash
   cat /proc/asound/cards
   ```

3. **Add user to audio group:**
   ```bash
   sudo usermod -a -G audio $USER
   ```
   Then logout and login again

4. **Install ALSA utilities:**
   ```bash
   sudo apt-get install alsa-utils
   ```

5. **Reboot:**
   ```bash
   sudo reboot
   ```

### Issue 4: Audio Permissions Error

**Cause:** User doesn't have permission to access audio devices

**Solution:**
```bash
# Add user to audio group
sudo usermod -a -G audio $USER

# Check groups
groups

# Logout and login, or reboot
sudo reboot
```

### Issue 5: "Piper not found"

**Solutions:**

1. **Install Piper:**
   ```bash
   pip3 install piper-tts
   ```

2. **Check installation:**
   ```bash
   pip3 show piper-tts
   which piper
   ```

3. **Install system dependencies:**
   ```bash
   sudo apt-get install ffmpeg
   ```

4. **Try alternative installation:**
   ```bash
   pip3 install --upgrade pip
   pip3 install piper-tts --no-cache-dir
   ```

---

## Diagnostic Commands

### Check Audio Devices

```bash
# List input devices (microphones)
arecord -l

# List output devices (speakers)
aplay -l

# Check ALSA cards
cat /proc/asound/cards

# Check USB devices
lsusb
```

### Test Recording

```bash
# Record 5 seconds (adjust device as needed)
arecord -D plughw:1,0 -d 5 -f S16_LE -r 16000 -c 1 test.wav

# Play back
aplay test.wav

# Check file
file test.wav
```

### Test Playback

```bash
# Test speakers
speaker-test -t wav -c 2

# Play a file
aplay /usr/share/sounds/alsa/Front_Center.wav

# Adjust volume
alsamixer
```

### Test TTS

```bash
# Test Piper directly
echo "Hello world" | piper --model en_US-lessac-medium --output_file test.wav
aplay test.wav

# Test Python TTS
python3 << EOF
from edge_ai.voice.tts import TTSEngine
tts = TTSEngine('en_US-lessac-medium', 2)
tts.speak('Test message')
EOF
```

### Test Speech Recognition

```bash
# Test Whisper
python3 << EOF
import whisper
model = whisper.load_model("base")
print("Whisper OK")
EOF

# Test full pipeline
python3 test_voice_input.py
```

---

## Configuration

### Disable Welcome Message (Temporary Workaround)

If audio isn't working yet, disable welcome message:

```python
# Edit config.py
ENABLE_WELCOME_MESSAGE = False
```

### Change Audio Device

```python
# Edit voice/speech_recognition.py
# Find the line with 'plughw:1,0' and change to your device
# Example: 'plughw:0,0' or 'plughw:2,0'
```

### Use Smaller Whisper Model

If speech recognition is too slow:

```python
# Edit config.py
WHISPER_MODEL = "tiny"  # Instead of "base"
```

---

## Hardware-Specific Issues

### Raspberry Pi Built-in Audio

```bash
# Enable audio
sudo raspi-config
# Navigate to: System Options → Audio → Select output

# Test
speaker-test -t wav -c 2
```

### USB Microphone

```bash
# Check if detected
lsusb
arecord -l

# If not detected, try different USB port
# Some USB 3.0 ports may have issues, try USB 2.0
```

### HDMI Audio

```bash
# Force HDMI audio
sudo raspi-config
# System Options → Audio → HDMI

# Or edit config.txt
sudo nano /boot/config.txt
# Add: hdmi_drive=2
```

### Bluetooth Audio

```bash
# Install Bluetooth audio
sudo apt-get install pulseaudio-module-bluetooth

# Pair device
bluetoothctl
# scan on
# pair XX:XX:XX:XX:XX:XX
# connect XX:XX:XX:XX:XX:XX
```

---

## Advanced Troubleshooting

### Check ALSA Configuration

```bash
# View ALSA config
cat ~/.asoundrc

# System-wide config
cat /etc/asound.conf
```

### Set Default Audio Device

Create `~/.asoundrc`:
```
pcm.!default {
    type hw
    card 1
    device 0
}

ctl.!default {
    type hw
    card 1
}
```

### Enable ALSA Logging

```bash
# Set environment variable
export ALSA_LOG_LEVEL=debug

# Run your command
arecord -D plughw:1,0 -d 5 test.wav
```

### Check System Logs

```bash
# Check for audio errors
dmesg | grep -i audio
dmesg | grep -i sound
dmesg | grep -i alsa

# Check system journal
sudo journalctl -xe | grep -i audio
```

---

## Still Not Working?

1. **Run comprehensive diagnostics:**
   ```bash
   ./diagnose.sh
   ```

2. **Check logs:**
   ```bash
   tail -f logs/edge_ai_*.log
   ```

3. **Try minimal test:**
   ```bash
   # Just test arecord
   arecord -l
   arecord -D plughw:1,0 -d 3 test.wav
   
   # Just test aplay
   aplay -l
   speaker-test -t wav -c 2
   ```

4. **Disable voice features temporarily:**
   ```python
   # Edit config.py
   VOICE_INPUT_ENABLED = False
   ENABLE_WELCOME_MESSAGE = False
   ```

5. **Check hardware:**
   - Try different USB port
   - Try different microphone
   - Check cable connections
   - Test on different computer

---

## Quick Reference

```bash
# Fix everything automatically
./fix_audio_issues.sh

# Fix welcome audio only
./fix_welcome_audio.sh

# List devices
arecord -l && aplay -l

# Test recording
arecord -D plughw:1,0 -d 5 test.wav && aplay test.wav

# Adjust volume
alsamixer

# Check permissions
groups | grep audio

# Add to audio group
sudo usermod -a -G audio $USER

# Reboot
sudo reboot
```

---

## Success Indicators

When audio is working correctly:

✅ `arecord -l` shows your microphone
✅ `aplay -l` shows your speakers
✅ Recording and playback work
✅ Welcome message plays on startup
✅ Voice input captures speech
✅ TTS speaks responses

If all checks pass, your audio system is ready!
