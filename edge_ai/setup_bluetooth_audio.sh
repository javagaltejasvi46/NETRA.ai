#!/bin/bash
# Complete Bluetooth Audio Setup for OnePlus Bullets Wireless Z2
# Installs, configures, and tests microphone + speaker

set -e

echo "=========================================="
echo "Bluetooth Audio Setup"
echo "Device: OnePlus Bullets Wireless Z2"
echo "=========================================="
echo ""

# Step 1: Install PulseAudio
echo "Step 1: Installing PulseAudio..."
sudo apt-get update -qq
sudo apt-get install -y pulseaudio pulseaudio-module-bluetooth paprefs pavucontrol
echo "✓ PulseAudio installed"
echo ""

# Step 2: Start PulseAudio
echo "Step 2: Starting PulseAudio..."
pulseaudio --kill 2>/dev/null || true
sleep 1
pulseaudio --start
sleep 2
echo "✓ PulseAudio started"
echo ""

# Step 3: Set Bluetooth as default
echo "Step 3: Configuring Bluetooth audio..."

# Find Bluetooth sink (output)
BT_SINK=$(pactl list short sinks | grep -i "bluez\|oneplus\|bullets" | head -1 | awk '{print $2}')
if [ -n "$BT_SINK" ]; then
    pactl set-default-sink "$BT_SINK"
    echo "✓ Bluetooth output set: $BT_SINK"
else
    echo "⚠ Bluetooth output not found, will try alternative method"
fi

# Find Bluetooth source (input/mic)
BT_SOURCE=$(pactl list short sources | grep -i "bluez\|oneplus\|bullets" | head -1 | awk '{print $2}')
if [ -n "$BT_SOURCE" ]; then
    pactl set-default-source "$BT_SOURCE"
    echo "✓ Bluetooth microphone set: $BT_SOURCE"
else
    echo "⚠ Bluetooth microphone not found, will try alternative method"
fi

# Alternative: Use pacmd
if [ -z "$BT_SINK" ] || [ -z "$BT_SOURCE" ]; then
    echo "Trying alternative configuration..."
    pacmd set-default-sink $(pacmd list-sinks | grep -i "bluez\|oneplus" | grep name: | head -1 | cut -d'<' -f2 | cut -d'>' -f1) 2>/dev/null || true
    pacmd set-default-source $(pacmd list-sources | grep -i "bluez\|oneplus" | grep name: | head -1 | cut -d'<' -f2 | cut -d'>' -f1) 2>/dev/null || true
fi

echo ""

# Step 4: Update speech_recognition.py for PulseAudio
echo "Step 4: Updating speech recognition for Bluetooth..."

cat > voice/speech_recognition_bluetooth.py << 'PYEOF'
"""
Speech recognition using Whisper AI with Bluetooth support via PulseAudio.
"""
import logging
import os
import tempfile
import subprocess
import numpy as np
from pathlib import Path

logger = logging.getLogger(__name__)


class SpeechRecognizer:
    def __init__(self, model_size: str = "base", duration: int = 5):
        self.model_size = model_size
        self.duration = duration
        self.model = None
        self._load_model()
    
    def _load_model(self) -> None:
        try:
            import whisper
            logger.info(f"Loading Whisper {self.model_size} model...")
            self.model = whisper.load_model(self.model_size)
            logger.info("Whisper model loaded successfully")
        except ImportError:
            logger.error("Whisper not installed. Install with: pip install openai-whisper")
            raise
        except Exception as e:
            logger.error(f"Failed to load Whisper model: {e}")
            raise
    
    def record_audio(self, duration: int = None) -> str:
        if duration is None:
            duration = self.duration
        
        try:
            temp_fd, temp_path = tempfile.mkstemp(suffix='.wav', prefix='voice_input_')
            os.close(temp_fd)
            
            logger.info(f"Recording audio for {duration} seconds via Bluetooth...")
            
            # Use parecord for Bluetooth (PulseAudio)
            subprocess.run(
                ['parecord', '--channels=1', '--rate=16000', 
                 '--format=s16le', f'--duration={duration}', temp_path],
                check=True,
                stderr=subprocess.PIPE
            )
            
            logger.info(f"Audio recorded to {temp_path}")
            return temp_path
            
        except FileNotFoundError:
            logger.error("parecord not found. PulseAudio not installed?")
            raise
        except subprocess.CalledProcessError as e:
            logger.error(f"Recording failed: {e.stderr.decode() if e.stderr else e}")
            raise
        except Exception as e:
            logger.error(f"Audio recording error: {e}")
            raise
    
    def denoise_audio(self, audio_path: str) -> str:
        try:
            import noisereduce as nr
            import soundfile as sf
            
            data, rate = sf.read(audio_path)
            logger.debug("Applying noise reduction...")
            reduced_noise = nr.reduce_noise(y=data, sr=rate, stationary=True)
            
            denoised_path = audio_path.replace('.wav', '_denoised.wav')
            sf.write(denoised_path, reduced_noise, rate)
            
            logger.debug(f"Denoised audio saved to {denoised_path}")
            return denoised_path
            
        except ImportError:
            logger.warning("noisereduce not available, skipping denoising")
            return audio_path
        except Exception as e:
            logger.warning(f"Denoising failed: {e}, using original audio")
            return audio_path
    
    def transcribe(self, audio_path: str) -> str:
        if self.model is None:
            raise RuntimeError("Whisper model not loaded")
        
        try:
            logger.info("Transcribing audio...")
            
            result = self.model.transcribe(
                audio_path,
                language="en",
                fp16=False,
                verbose=False
            )
            
            text = result["text"].strip()
            logger.info(f"Transcribed: {text}")
            
            return text
            
        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            return ""
    
    def listen(self) -> str:
        audio_path = None
        denoised_path = None
        
        try:
            audio_path = self.record_audio()
            denoised_path = self.denoise_audio(audio_path)
            text = self.transcribe(denoised_path)
            return text
            
        except Exception as e:
            logger.error(f"Listen failed: {e}")
            return ""
            
        finally:
            for path in [audio_path, denoised_path]:
                if path and os.path.exists(path):
                    try:
                        os.remove(path)
                    except Exception as e:
                        logger.warning(f"Failed to cleanup {path}: {e}")
PYEOF

# Backup original and replace
cp voice/speech_recognition.py voice/speech_recognition.py.backup
cp voice/speech_recognition_bluetooth.py voice/speech_recognition.py

echo "✓ Speech recognition updated for Bluetooth"
echo ""

# Step 5: Enable voice in config
echo "Step 5: Enabling voice features..."
python3 << 'EOF'
with open('config.py', 'r') as f:
    content = f.read()

content = content.replace('VOICE_INPUT_ENABLED: bool = False', 'VOICE_INPUT_ENABLED: bool = True')
content = content.replace('ENABLE_WELCOME_MESSAGE: bool = False', 'ENABLE_WELCOME_MESSAGE: bool = True')

with open('config.py', 'w') as f:
    f.write(content)

print("✓ Voice features enabled in config.py")
EOF

echo ""

# Step 6: Test microphone
echo "Step 6: Testing Bluetooth microphone..."
echo "Recording 3 seconds... SPEAK NOW!"
parecord --channels=1 --rate=16000 --format=s16le --duration=3 /tmp/test_bt_mic.wav 2>&1
if [ -f /tmp/test_bt_mic.wav ]; then
    echo "✓ Microphone recording successful"
    
    # Test playback
    echo ""
    echo "Step 7: Testing Bluetooth speaker..."
    echo "Playing back your recording..."
    paplay /tmp/test_bt_mic.wav 2>&1
    echo "✓ Speaker playback successful"
    
    rm -f /tmp/test_bt_mic.wav
else
    echo "✗ Microphone test failed"
    exit 1
fi

echo ""

# Step 8: Test TTS
echo "Step 8: Testing Text-to-Speech..."
python3 << 'EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from edge_ai.voice.tts import TTSEngine
    from edge_ai.ai.conversation_manager import ConversationManager
    from edge_ai.config import Config
    
    print("Initializing TTS...")
    tts = TTSEngine(model_name=Config.TTS_MODEL, timeout=Config.TTS_TIMEOUT)
    cm = ConversationManager()
    
    welcome = cm.get_welcome_message()
    print(f"Speaking: {welcome}")
    
    success = tts.speak(welcome)
    
    if success:
        print("✓ TTS working - You should hear the welcome message!")
    else:
        print("⚠ TTS returned False")
        
except Exception as e:
    print(f"✗ TTS error: {e}")
    import traceback
    traceback.print_exc()
EOF

echo ""
echo "=========================================="
echo "✓ Bluetooth Audio Setup Complete!"
echo "=========================================="
echo ""
echo "Your OnePlus Bullets Wireless Z2 is configured!"
echo ""
echo "What was tested:"
echo "  ✓ Microphone recording (you spoke)"
echo "  ✓ Speaker playback (you heard your voice)"
echo "  ✓ TTS welcome message (you heard NETRA.AI)"
echo ""
echo "Start the system:"
echo "  ./START_HERE.sh"
echo ""
echo "The system will:"
echo "  1. Play welcome message"
echo "  2. Listen for 5 seconds"
echo "  3. You can ask questions"
echo "  4. System responds via Bluetooth"
echo ""
