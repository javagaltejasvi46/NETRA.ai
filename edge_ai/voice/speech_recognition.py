"""
Speech recognition using Whisper AI with noise reduction.
"""
import logging
import os
import tempfile
import subprocess
import numpy as np
from pathlib import Path

logger = logging.getLogger(__name__)


class SpeechRecognizer:
    """
    Captures audio, applies noise reduction, and converts speech to text using Whisper.
    """
    
    def __init__(self, model_size: str = "base", duration: int = 5):
        """
        Initialize speech recognizer.
        
        Args:
            model_size: Whisper model size (tiny, base, small, medium, large)
            duration: Recording duration in seconds
        """
        self.model_size = model_size
        self.duration = duration
        self.model = None
        
        # Load Whisper model
        self._load_model()
    
    def _load_model(self) -> None:
        """Load Whisper model."""
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
        """
        Record audio from microphone.
        
        Args:
            duration: Recording duration in seconds (uses default if None)
            
        Returns:
            Path to recorded audio file
        """
        if duration is None:
            duration = self.duration
        
        try:
            # Create temporary file
            temp_fd, temp_path = tempfile.mkstemp(suffix='.wav', prefix='voice_input_')
            os.close(temp_fd)
            
            logger.info(f"Recording audio for {duration} seconds...")
            
            # Record using arecord (available on Raspberry Pi)
            subprocess.run(
                ['arecord', '-D', 'plughw:1,0', '-d', str(duration), 
                 '-f', 'S16_LE', '-r', '16000', '-c', '1', temp_path],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            
            logger.info(f"Audio recorded to {temp_path}")
            return temp_path
            
        except FileNotFoundError:
            logger.error("arecord not found. Install with: sudo apt-get install alsa-utils")
            raise
        except subprocess.CalledProcessError as e:
            logger.error(f"Recording failed: {e}")
            raise
        except Exception as e:
            logger.error(f"Audio recording error: {e}")
            raise
    
    def denoise_audio(self, audio_path: str) -> str:
        """
        Apply noise reduction to audio file.
        
        Args:
            audio_path: Path to input audio file
            
        Returns:
            Path to denoised audio file
        """
        try:
            import noisereduce as nr
            import soundfile as sf
            
            # Read audio
            data, rate = sf.read(audio_path)
            
            # Apply noise reduction
            logger.debug("Applying noise reduction...")
            reduced_noise = nr.reduce_noise(y=data, sr=rate, stationary=True)
            
            # Save denoised audio
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
        """
        Convert speech to text using Whisper.
        
        Args:
            audio_path: Path to audio file
            
        Returns:
            Transcribed text
        """
        if self.model is None:
            raise RuntimeError("Whisper model not loaded")
        
        try:
            logger.info("Transcribing audio...")
            
            # Transcribe with Whisper
            result = self.model.transcribe(
                audio_path,
                language="en",
                fp16=False,  # Use FP32 for Raspberry Pi compatibility
                verbose=False
            )
            
            text = result["text"].strip()
            logger.info(f"Transcribed: {text}")
            
            return text
            
        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            return ""
    
    def listen(self) -> str:
        """
        Complete listening pipeline: record, denoise, transcribe.
        
        Returns:
            Transcribed text from user speech
        """
        audio_path = None
        denoised_path = None
        
        try:
            # Record audio
            audio_path = self.record_audio()
            
            # Denoise
            denoised_path = self.denoise_audio(audio_path)
            
            # Transcribe
            text = self.transcribe(denoised_path)
            
            return text
            
        except Exception as e:
            logger.error(f"Listen failed: {e}")
            return ""
            
        finally:
            # Cleanup temporary files
            for path in [audio_path, denoised_path]:
                if path and os.path.exists(path):
                    try:
                        os.remove(path)
                    except Exception as e:
                        logger.warning(f"Failed to cleanup {path}: {e}")
