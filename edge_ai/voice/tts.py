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
        
        Args:
            text: Text to convert
            
        Returns:
            Path to generated WAV file or None if failed
        """
        try:
            # Create temporary file
            temp_fd, temp_path = tempfile.mkstemp(suffix='.wav', prefix='tts_')
            os.close(temp_fd)
            
            logger.debug(f"Generating audio to {temp_path}")
            
            # Call Piper CLI
            # Note: This assumes piper is installed and in PATH
            # Command: echo "text" | piper --model <model> --output_file <file>
            process = subprocess.Popen(
                ['piper', '--model', self.model_name, '--output_file', temp_path],
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
            logger.error(
                "Piper not found. Install with: pip install piper-tts "
                "or ensure piper is in PATH"
            )
            return None
        except Exception as e:
            logger.error(f"Audio generation failed: {e}")
            return None
    
    def _play_audio(self, audio_path: str) -> None:
        """
        Play audio using system command or pygame.
        
        Args:
            audio_path: Path to WAV file
        """
        try:
            # Try pygame first (cross-platform)
            try:
                import pygame
                pygame.mixer.init()
                pygame.mixer.music.load(audio_path)
                pygame.mixer.music.play()
                
                # Wait for playback to complete
                while pygame.mixer.music.get_busy():
                    pygame.time.Clock().tick(10)
                
                pygame.mixer.quit()
                logger.debug("Audio played via pygame")
                return
                
            except ImportError:
                logger.debug("pygame not available, trying system command")
            
            # Fallback to system commands
            if os.name == 'posix':  # Linux/Mac
                # Try aplay (common on Raspberry Pi)
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
                
                # Try afplay (macOS)
                try:
                    subprocess.run(
                        ['afplay', audio_path],
                        check=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
                    logger.debug("Audio played via afplay")
                    return
                except (FileNotFoundError, subprocess.CalledProcessError):
                    pass
            
            elif os.name == 'nt':  # Windows
                import winsound
                winsound.PlaySound(audio_path, winsound.SND_FILENAME)
                logger.debug("Audio played via winsound")
                return
            
            logger.warning("No audio playback method available")
            
        except Exception as e:
            logger.error(f"Audio playback failed: {e}")
