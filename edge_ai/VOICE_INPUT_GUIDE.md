## Voice Input Feature Guide

## Overview

The voice input feature enables conversational interaction with NETRA.AI. After each tactical decision, the system opens a 5-second listening window where users can ask questions about the battlefield situation.

### Key Features

- ✅ **Welcome Message**: System greets user on startup
- ✅ **Automatic Listening**: Opens after each tactical decision
- ✅ **Noise Reduction**: Cleans audio before processing
- ✅ **Whisper AI**: Converts speech to text
- ✅ **Context Memory**: Remembers recent telemetry and decisions
- ✅ **Brief Responses**: Answers in under 20 words
- ✅ **Voice Output**: Speaks responses using Piper TTS

---

## Installation

### Quick Install

```bash
cd edge_ai
chmod +x install_voice_input.sh
./install_voice_input.sh
```

### Manual Install

```bash
# System dependencies
sudo apt-get install -y alsa-utils portaudio19-dev libsndfile1 ffmpeg

# Python packages
pip3 install openai-whisper noisereduce soundfile

# Download Whisper model
python3 -c "import whisper; whisper.load_model('base')"
```

---

## Configuration

Edit `config.py`:

```python
# Voice Input Settings
VOICE_INPUT_ENABLED = True          # Enable/disable voice input
WHISPER_MODEL = "base"              # Model size: tiny, base, small, medium, large
LISTENING_DURATION = 5              # Listening window in seconds
ENABLE_WELCOME_MESSAGE = True       # Play welcome on startup
```

### Model Size Recommendations

| Model | Size | Speed | Accuracy | Raspberry Pi |
|-------|------|-------|----------|--------------|
| tiny  | 39MB | Fast  | Good     | ✅ Recommended for Pi 3 |
| base  | 74MB | Medium| Better   | ✅ Recommended for Pi 4 |
| small | 244MB| Slow  | Best     | ⚠️ Pi 4 only |
| medium| 769MB| Very Slow | Excellent | ❌ Too slow |

---

## Usage Flow

### 1. System Startup

```
System: "Hello. Welcome to NETRA dot A I. Battlefield copilot ready."
[5-second listening window opens]
User: "What is your status?"
System: "All systems operational. Ready for telemetry."
```

### 2. After Tactical Decision

```
[Telemetry received]
System: "Take cover immediately."
[5-second listening window opens]
User: "How far is the enemy?"
System: "Enemy is 72 meters away. Threat level critical."
```

### 3. Context-Aware Responses

The system remembers:
- Last 5 telemetry updates
- Last 5 tactical decisions
- Last 10 conversation exchanges

Example:
```
User: "What was the last decision?"
System: "Take cover immediately. Enemy approaching from east."

User: "What is the soldier's heart rate?"
System: "Heart rate is 125 beats per minute. Stress level high."
```

---

## Microphone Setup

### Check Available Devices

```bash
arecord -l
```

Output example:
```
card 1: Device [USB Audio Device], device 0: USB Audio [USB Audio]
```

### Test Recording

```bash
# Record 5 seconds
arecord -D plughw:1,0 -d 5 -f S16_LE -r 16000 -c 1 test.wav

# Play back
aplay test.wav
```

### Adjust Volume

```bash
alsamixer
```

Use arrow keys to adjust microphone gain.

### Set Default Device

If using USB microphone, update `speech_recognition.py`:

```python
# Change device in record_audio method
subprocess.run(
    ['arecord', '-D', 'plughw:1,0',  # Change card:device numbers
     '-d', str(duration), '-f', 'S16_LE', '-r', '16000', '-c', '1', temp_path],
    ...
)
```

---

## Testing

### Test Individual Components

```bash
# Test speech recognition only
python3 test_voice_input.py

# Test microphone
arecord -D plughw:1,0 -d 5 test.wav && aplay test.wav

# Test TTS
python3 -c "from edge_ai.voice.tts import TTSEngine; tts = TTSEngine('en_US-lessac-medium', 2); tts.speak('Test message')"

# Test Whisper
python3 -c "import whisper; model = whisper.load_model('base'); print('Whisper OK')"
```

### Full System Test

```bash
# Start system
./START_HERE.sh

# In another terminal, send telemetry
mosquitto_pub -t 'battlefield/sensor' -m '{"timestamp":1710000000,"soldier":{"x":120,"y":340,"heart_rate":125},"enemy":{"x":180,"y":360},"hostage":{"x":140,"y":350},"environment":"urban","threat_level":"high"}'

# System will:
# 1. Analyze threat
# 2. Generate decision
# 3. Speak decision
# 4. Open listening window
# 5. Wait for your question
# 6. Respond to your question
```

---

## Example Questions

### Situation Awareness
- "How far is the enemy?"
- "What is the threat level?"
- "Where is the hostage?"
- "What is my heart rate?"

### Decision Clarification
- "What was the last decision?"
- "Why should I take cover?"
- "Is it safe to move?"

### System Status
- "What is your status?"
- "Are you ready?"
- "Can you hear me?"

---

## Troubleshooting

### No Audio Input Detected

```bash
# Check microphone connection
arecord -l

# Test recording
arecord -D plughw:1,0 -d 5 test.wav

# Check volume
alsamixer
```

### Whisper Model Not Loading

```bash
# Check installation
pip3 show openai-whisper

# Reinstall
pip3 install --upgrade openai-whisper

# Download model manually
python3 -c "import whisper; whisper.load_model('base')"
```

### Poor Transcription Quality

1. **Reduce background noise**
   - Move to quieter environment
   - Use directional microphone
   - Increase `noisereduce` strength

2. **Improve microphone quality**
   - Use USB microphone instead of built-in
   - Adjust gain in `alsamixer`
   - Position microphone closer

3. **Use larger Whisper model**
   ```python
   WHISPER_MODEL = "small"  # Better accuracy, slower
   ```

### Slow Response Time

1. **Use smaller Whisper model**
   ```python
   WHISPER_MODEL = "tiny"  # Faster, less accurate
   ```

2. **Reduce listening duration**
   ```python
   LISTENING_DURATION = 3  # Shorter window
   ```

3. **Disable noise reduction**
   - Comment out denoising in `speech_recognition.py`

### Voice Input Not Triggering

Check configuration:
```python
# In config.py
VOICE_INPUT_ENABLED = True  # Must be True
```

Check logs:
```bash
tail -f logs/edge_ai_*.log | grep -i voice
```

---

## Performance Optimization

### Raspberry Pi 3

```python
WHISPER_MODEL = "tiny"
LISTENING_DURATION = 3
# Disable noise reduction for speed
```

### Raspberry Pi 4

```python
WHISPER_MODEL = "base"  # Good balance
LISTENING_DURATION = 5
# Keep noise reduction enabled
```

### Raspberry Pi 5

```python
WHISPER_MODEL = "small"  # Best quality
LISTENING_DURATION = 5
# Enable all features
```

---

## Advanced Configuration

### Custom Wake Word (Future Enhancement)

Currently, listening window opens automatically after decisions. To add wake word detection, integrate Porcupine or Snowboy.

### Multi-Language Support

Change Whisper language:
```python
# In speech_recognition.py, transcribe method
result = self.model.transcribe(
    audio_path,
    language="es",  # Spanish, French, etc.
    ...
)
```

### Continuous Listening Mode

Modify orchestrator to keep listening window open:
```python
# In orchestrator.py
while self.running:
    self._handle_voice_interaction()
```

---

## API Reference

### SpeechRecognizer

```python
from edge_ai.voice.speech_recognition import SpeechRecognizer

sr = SpeechRecognizer(model_size="base", duration=5)
text = sr.listen()  # Record, denoise, transcribe
```

### ConversationManager

```python
from edge_ai.ai.conversation_manager import ConversationManager

cm = ConversationManager(max_history=10)
cm.add_telemetry(telemetry, assessment)
cm.add_decision(decision)
response = cm.generate_response(question, inference_engine)
```

---

## Security Considerations

- Audio is processed locally (no cloud services)
- Temporary audio files are deleted after processing
- Conversation history stored in memory only
- No audio recordings are saved permanently

---

## Known Limitations

1. **5-second window**: Fixed duration, may cut off long questions
2. **English only**: Default configuration (can be changed)
3. **Single speaker**: Not optimized for multiple speakers
4. **No wake word**: Listening window opens automatically
5. **Context limit**: Remembers last 10 exchanges only

---

## Future Enhancements

- [ ] Wake word detection
- [ ] Continuous listening mode
- [ ] Multi-language support
- [ ] Speaker identification
- [ ] Emotion detection
- [ ] Voice authentication
- [ ] Offline voice commands

---

## Support

For issues:
1. Run diagnostics: `./diagnose.sh`
2. Check logs: `tail -f logs/edge_ai_*.log`
3. Test components: `python3 test_voice_input.py`
4. Review: `TROUBLESHOOTING.md`
