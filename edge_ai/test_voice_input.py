#!/usr/bin/env python3
"""
Test script for voice input feature.
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from edge_ai.voice.speech_recognition import SpeechRecognizer
from edge_ai.voice.tts import TTSEngine
from edge_ai.ai.conversation_manager import ConversationManager
from edge_ai.config import Config


def test_speech_recognition():
    """Test speech recognition only."""
    print("=" * 60)
    print("Testing Speech Recognition")
    print("=" * 60)
    print()
    
    try:
        print("Initializing speech recognizer...")
        sr = SpeechRecognizer(model_size="base", duration=5)
        print("✓ Speech recognizer initialized")
        print()
        
        print("Speak now! (5 seconds)")
        print("-" * 60)
        text = sr.listen()
        print("-" * 60)
        print()
        
        if text:
            print(f"✓ Transcribed: {text}")
            return True
        else:
            print("✗ No speech detected")
            return False
            
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def test_tts():
    """Test text-to-speech."""
    print()
    print("=" * 60)
    print("Testing Text-to-Speech")
    print("=" * 60)
    print()
    
    try:
        print("Initializing TTS engine...")
        tts = TTSEngine(model_name=Config.TTS_MODEL, timeout=Config.TTS_TIMEOUT)
        print("✓ TTS engine initialized")
        print()
        
        test_message = "Hello. Welcome to NETRA dot A I."
        print(f"Speaking: {test_message}")
        success = tts.speak(test_message)
        
        if success:
            print("✓ TTS working")
            return True
        else:
            print("✗ TTS failed")
            return False
            
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def test_conversation():
    """Test full conversation flow."""
    print()
    print("=" * 60)
    print("Testing Conversation Flow")
    print("=" * 60)
    print()
    
    try:
        print("Initializing components...")
        sr = SpeechRecognizer(model_size="base", duration=5)
        tts = TTSEngine(model_name=Config.TTS_MODEL, timeout=Config.TTS_TIMEOUT)
        cm = ConversationManager()
        print("✓ All components initialized")
        print()
        
        # Welcome message
        welcome = cm.get_welcome_message()
        print(f"Welcome: {welcome}")
        tts.speak(welcome)
        print()
        
        # Listen for question
        print("Ask a question! (5 seconds)")
        print("-" * 60)
        question = sr.listen()
        print("-" * 60)
        print()
        
        if question:
            print(f"Question: {question}")
            
            # Generate simple response (without LLM for testing)
            response = f"You asked about {question.split()[0] if question.split() else 'something'}. System ready."
            print(f"Response: {response}")
            
            # Speak response
            tts.speak(response)
            print("✓ Conversation flow working")
            return True
        else:
            print("✗ No question detected")
            return False
            
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run all tests."""
    print()
    print("=" * 60)
    print("VOICE INPUT FEATURE TEST SUITE")
    print("=" * 60)
    print()
    
    results = {}
    
    # Test 1: Speech Recognition
    results['speech_recognition'] = test_speech_recognition()
    
    # Test 2: TTS
    results['tts'] = test_tts()
    
    # Test 3: Full conversation
    results['conversation'] = test_conversation()
    
    # Summary
    print()
    print("=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    print()
    
    for test_name, passed in results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{status} - {test_name}")
    
    print()
    
    all_passed = all(results.values())
    if all_passed:
        print("✓ All tests passed!")
        return 0
    else:
        print("✗ Some tests failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
