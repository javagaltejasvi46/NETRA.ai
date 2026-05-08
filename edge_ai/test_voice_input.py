#!/usr/bin/env python3
"""
Test script for voice input and output features.
"""
import sys
import os
import time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.voice.speech_recognition import SpeechRecognizer
from edge_ai.voice.tts import TTSEngine
from edge_ai.ai.conversation_manager import ConversationManager
from edge_ai.config import Config


def test_tts():
    """Test TTS - play a sample message."""
    print("=" * 60)
    print("TEST 1: Text-to-Speech")
    print("=" * 60)
    print()

    try:
        print("Initializing TTS engine...")
        tts = TTSEngine(model_name=Config.TTS_MODEL, timeout=10)
        print("✓ TTS engine initialized")
        print()

        msg = "Hello. This is NETRA dot A I. Audio test successful."
        print(f"Speaking: \"{msg}\"")
        print(">>> LISTEN TO YOUR HEADPHONES <<<")
        print()

        success = tts.speak(msg)

        # Wait for audio to finish
        time.sleep(1)

        if success:
            print("✓ TTS PASSED - Did you hear the message?")
            return True, tts
        else:
            print("✗ TTS FAILED")
            return False, tts

    except Exception as e:
        print(f"✗ TTS Error: {e}")
        import traceback
        traceback.print_exc()
        return False, None


def test_speech_recognition():
    """Test microphone recording and Whisper transcription."""
    print()
    print("=" * 60)
    print("TEST 2: Speech Recognition (Voice-to-Text)")
    print("=" * 60)
    print()

    try:
        print("Initializing speech recognizer...")
        sr = SpeechRecognizer(model_size=Config.WHISPER_MODEL, duration=Config.LISTENING_DURATION)
        print("✓ Speech recognizer initialized")
        print()

        print(">>> SPEAK NOW - You have 5 seconds <<<")
        print("Say something like: 'Hello NETRA, what is the threat level?'")
        print("-" * 60)

        text = sr.listen()

        print("-" * 60)
        print()

        if text and len(text.strip()) > 2:
            print(f"✓ SPEECH RECOGNITION PASSED")
            print(f"  You said: \"{text}\"")
            return True, text
        else:
            print("✗ No speech detected or transcription empty")
            return False, ""

    except Exception as e:
        print(f"✗ Speech Recognition Error: {e}")
        import traceback
        traceback.print_exc()
        return False, ""


def test_full_loop(tts, question):
    """Test full loop: speak a response to the user's question."""
    print()
    print("=" * 60)
    print("TEST 3: Full Voice Loop (TTS response to your question)")
    print("=" * 60)
    print()

    if not tts or not question:
        print("⊘ Skipped (TTS or speech recognition failed)")
        return False

    try:
        cm = ConversationManager()

        # Simple response without LLM
        words = question.lower().split()
        if any(w in words for w in ["threat", "enemy", "danger"]):
            response = "Threat level is critical. Enemy approaching fast."
        elif any(w in words for w in ["status", "ready", "hello"]):
            response = "All systems operational. Ready for battle."
        elif any(w in words for w in ["distance", "far", "close"]):
            response = "Enemy is approximately 72 meters away."
        else:
            response = "Understood. Monitoring battlefield conditions."

        print(f"Your question: \"{question}\"")
        print(f"Response: \"{response}\"")
        print()
        print(">>> LISTEN TO YOUR HEADPHONES <<<")

        success = tts.speak(response)
        time.sleep(1)

        if success:
            print("✓ FULL LOOP PASSED")
            return True
        else:
            print("✗ Response playback failed")
            return False

    except Exception as e:
        print(f"✗ Full loop error: {e}")
        return False


def main():
    print()
    print("=" * 60)
    print("NETRA.AI - VOICE FEATURE TEST")
    print("Device: OnePlus Bullets Wireless Z2")
    print("=" * 60)
    print()

    results = {}

    # Test 1: TTS
    tts_ok, tts = test_tts()
    results["TTS (audio output)"] = tts_ok

    # Wait between tests
    time.sleep(2)

    # Test 2: Speech Recognition
    sr_ok, question = test_speech_recognition()
    results["Speech Recognition (mic input)"] = sr_ok

    # Wait between tests
    time.sleep(1)

    # Test 3: Full loop
    loop_ok = test_full_loop(tts, question)
    results["Full Voice Loop"] = loop_ok

    # Summary
    print()
    print("=" * 60)
    print("RESULTS")
    print("=" * 60)
    print()
    for name, passed in results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"  {status}  {name}")

    print()
    all_passed = all(results.values())
    if all_passed:
        print("✓ All voice tests passed! System is ready.")
    else:
        print("✗ Some tests failed.")
        if not results.get("TTS (audio output)"):
            print("  → TTS fix: run ./setup_bluetooth_audio.sh")
        if not results.get("Speech Recognition (mic input)"):
            print("  → Mic fix: check parecord works: parecord --channels=1 --rate=16000 --format=s16le test.wav")
            print("             then Ctrl+C after 3 seconds, play with: paplay test.wav")
    print()


if __name__ == "__main__":
    main()
