"""
Text-to-speech engine using Piper TTS.
"""
import logging
import os
import subprocess
import tempfile
from pathlib import Path

logger = logging.getLogger(__name__)


class TTSEngine:
    """
    Converts text to speech using Piper TTS and plays audio output.
    """
    
    def __init__(self, model_name: str, timeout: int):
        """
        Initialize TTS engine.
        
        Args:
            model_name: Piper voice model name
            timeout: Timeout for TTS generation in seconds
        """
        self.model_name = model_name
        self.timeout = timeout
    
    def speak(self, text: str) -> bool:
        """
        Convert text to speech and play audio.
        
        Args:
            text: Text to convert to speech
            
        Returns:
            True if successful, False otherwise
        """
        if not text:
            logger.warning("Empty text provided for TTS")
            return False
        
        temp_file = None
        
        try:
            # Generate temporary WAV file
            temp_file = self._generate_audio(text)
            
            if temp_file is None:
                logger.warning("TTS generation failed, skipping audio output")
                return False
            
            # Play audio
            self._play_audio(temp_file)
            
            logger.info(f"Successfully played TTS audio: {text[:50]}...")
            return True
            
        except Exception as e:
            logger.error(f"TTS failed: {e}")
            logger.warning("Continuing without audio output")
            return False
            
        finally:
            # Cleanup temporary file
            if temp_file and os.path.exists(temp_file):
                try:
                    os.remove(temp_file)
                    logger.debug(f"Cleaned up temp file: {temp_file}")
                except Exception as e:
                    logger.warning(f"Failed to cleanup temp file: {e}")
    
    def _generate_audio(self, text: str) -> str:
        """
        Call Piper CLI to generate WAV file.
        Downloads voice model automatically if missing.
        """
        try:
            temp_fd, temp_path = tempfile.mkstemp(suffix='.wav', prefix='tts_')
            os.close(temp_fd)
            
            logger.debug(f"Generating audio to {temp_path}")
            
            # Resolve model path - try name as-is, then check piper voices dir
            model_path = self._resolve_model_path()
            if model_path is None:
                logger.error("Piper voice model not found. Run: python3 -c \"from piper import download; download.ensure_voice_exists('en_US-lessac-medium', data_dirs=[], download_dir='.')\"")
                return None
            
            process = subprocess.Popen(
                ['piper', '--model', model_path, '--output_file', temp_path],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            stdout, stderr = process.communicate(input=text, timeout=self.timeout)
            
            if process.returncode != 0:
                logger.error(f"Piper failed: {stderr}")
                return None
            
            return temp_path
            
        except subprocess.TimeoutExpired:
            logger.error(f"TTS generation timed out after {self.timeout}s")
            process.kill()
            return None
        except FileNotFoundError:
            logger.error("Piper not found. Install with: pip install piper-tts")
            return None
        except Exception as e:
            logger.error(f"Audio generation failed: {e}")
            return None
    
    def _resolve_model_path(self) -> str:
        """
        Find the Piper voice model file on disk.
        Searches common locations and downloads if needed.
        """
        import glob
        
        # Search common piper model locations
        search_dirs = [
            os.path.expanduser("~/.local/share/piper-tts"),
            os.path.expanduser("~/.local/share/piper"),
            "/usr/share/piper-tts",
            "/usr/local/share/piper-tts",
            ".",
        ]
        
        model_name = self.model_name  # e.g. en_US-lessac-medium
        
        for d in search_dirs:
            # Look for .onnx file matching model name
            pattern = os.path.join(d, "**", f"{model_name}.onnx")
            matches = glob.glob(pattern, recursive=True)
            if matches:
                logger.info(f"Found voice model: {matches[0]}")
                return matches[0]
            
            # Also try direct path
            direct = os.path.join(d, f"{model_name}.onnx")
            if os.path.exists(direct):
                return direct
        
        # Try to download automatically
        logger.info(f"Voice model not found, downloading {model_name}...")
        try:
            result = subprocess.run(
                ['python3', '-c',
                 f"from piper.download import ensure_voice_exists; "
                 f"ensure_voice_exists('{model_name}', data_dirs=[], "
                 f"download_dir='{os.path.expanduser('~/.local/share/piper-tts')}')"],
                capture_output=True, text=True, timeout=120
            )
            if result.returncode == 0:
                # Search again after download
                for d in search_dirs:
                    pattern = os.path.join(d, "**", f"{model_name}.onnx")
                    matches = glob.glob(pattern, recursive=True)
                    if matches:
                        logger.info(f"Downloaded and found: {matches[0]}")
                        return matches[0]
        except Exception as e:
            logger.error(f"Auto-download failed: {e}")
        
        return None
    
    def _play_audio(self, audio_path: str) -> None:
        """
        Play audio - tries paplay (Bluetooth/PulseAudio) first, then fallbacks.
        """
        try:
            # Try paplay first (PulseAudio - works with Bluetooth)
            try:
                subprocess.run(
                    ['paplay', audio_path],
                    check=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                logger.debug("Audio played via paplay (PulseAudio/Bluetooth)")
                return
            except (FileNotFoundError, subprocess.CalledProcessError):
                pass
            
            # Try pygame
            try:
                import pygame
                pygame.mixer.init()
                pygame.mixer.music.load(audio_path)
                pygame.mixer.music.play()
                while pygame.mixer.music.get_busy():
                    pygame.time.Clock().tick(10)
                pygame.mixer.quit()
                logger.debug("Audio played via pygame")
                return
            except ImportError:
                pass
            
            # Try aplay (ALSA fallback)
            try:
                subprocess.run(
                    ['aplay', audio_path],
                    check=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                logger.debug("Audio played via aplay")
                return
            except (FileNotFoundError, subprocess.CalledProcessError):
                pass
            
            logger.warning("No audio playback method available")
            
        except Exception as e:
            logger.error(f"Audio playback failed: {e}")
