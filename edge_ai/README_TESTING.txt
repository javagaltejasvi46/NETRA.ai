╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                    EDGE AI COPILOT - TESTING SUITE                          ║
║                                                                              ║
║                  Complete Testing with Auto-Install                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

┌──────────────────────────────────────────────────────────────────────────────┐
│ QUICK START (Choose One)                                                    │
└──────────────────────────────────────────────────────────────────────────────┘

  🚀 OPTION 1: Complete Install & Test (Recommended for first time)
  
     chmod +x install_and_test.sh && ./install_and_test.sh
  
  ────────────────────────────────────────────────────────────────────────────
  
  🧪 OPTION 2: Test Only (If already installed)
  
     chmod +x test_all_features.sh && ./test_all_features.sh
  
  ────────────────────────────────────────────────────────────────────────────
  
  ⚡ OPTION 3: Test with Auto-Install (Install missing packages)
  
     ./test_all_features.sh --install

┌──────────────────────────────────────────────────────────────────────────────┐
│ WHAT GETS TESTED (18 Comprehensive Tests)                                   │
└──────────────────────────────────────────────────────────────────────────────┘

  ✓ System dependencies (Python, Mosquitto, audio)
  ✓ Python packages (core + NEW voice packages)
  ✓ File structure
  ✓ AI model (TinyLlama)
  ✓ MQTT broker
  ✓ Audio devices (mic + speakers)
  ✓ Module imports
  ✓ Telemetry parsing
  ✓ Threat analysis
  ✓ Prompt builder
  ✓ Decision validator
  ✓ Failsafe handler
  ✓ Conversation manager (NEW)
  ✓ Text-to-speech (NEW)
  ✓ Speech recognition (NEW)
  ✓ Configuration
  ✓ Logging system
  ✓ System resources

┌──────────────────────────────────────────────────────────────────────────────┐
│ NEW PACKAGES TESTED & AUTO-INSTALLED                                        │
└──────────────────────────────────────────────────────────────────────────────┘

  Voice Input Packages:
    • openai-whisper      - Speech-to-text with Whisper AI
    • noisereduce         - Audio denoising
    • soundfile           - Audio file handling
    • piper-tts           - Text-to-speech output

  System Dependencies:
    • alsa-utils          - Audio recording tools
    • portaudio19-dev     - Audio interface
    • libsndfile1         - Sound file library
    • ffmpeg              - Audio processing

  All installed automatically with --install flag!

┌──────────────────────────────────────────────────────────────────────────────┐
│ TEST OUTPUT                                                                  │
└──────────────────────────────────────────────────────────────────────────────┘

  ✓ Green = Test passed
  ✗ Red = Test failed (needs fixing)
  ⊘ Yellow = Test skipped (optional feature)

  Example:
    ==========================================
    TEST: 15. Speech Recognition
    ==========================================
    
    ✓ Whisper model loaded successfully
    ✓ Speech recognition model ready

  Success Rate: Shows percentage of passed tests
  Log File: logs/test_results_YYYYMMDD_HHMMSS.log

┌──────────────────────────────────────────────────────────────────────────────┐
│ AFTER TESTS PASS                                                             │
└──────────────────────────────────────────────────────────────────────────────┘

  Start the system:
    ./START_HERE.sh

  Test end-to-end:
    # Terminal 1: Start system
    ./START_HERE.sh
    
    # Terminal 2: Monitor responses
    mosquitto_sub -t 'battlefield/ai-response' -v
    
    # Terminal 3: Send telemetry
    mosquitto_pub -t 'battlefield/sensor' -m '{"timestamp":1710000000,"soldier":{"x":120,"y":340,"heart_rate":125},"enemy":{"x":180,"y":360},"hostage":{"x":140,"y":350},"environment":"urban","threat_level":"high"}'

  Expected:
    1. System analyzes threat
    2. Speaks tactical decision
    3. Opens 5-second listening window
    4. You ask a question
    5. System responds with context
    6. Publishes to MQTT

┌──────────────────────────────────────────────────────────────────────────────┐
│ TROUBLESHOOTING                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

  Tests failing?
    ./test_all_features.sh --install    # Auto-install missing

  Check logs:
    cat logs/test_results_*.log

  Run diagnostics:
    ./diagnose.sh

  Test voice only:
    python3 test_voice_input.py

  Test microphone:
    arecord -l                          # List devices
    arecord -D plughw:1,0 -d 5 test.wav # Record
    aplay test.wav                      # Play back

  Full guide:
    cat TESTING_GUIDE.md

┌──────────────────────────────────────────────────────────────────────────────┐
│ DOCUMENTATION                                                                │
└──────────────────────────────────────────────────────────────────────────────┘

  TESTING_GUIDE.md         - Complete testing guide
  TESTING_COMMANDS.txt     - Quick command reference
  TEST_SUMMARY.txt         - Implementation summary
  README_TESTING.txt       - This file

┌──────────────────────────────────────────────────────────────────────────────┐
│ SUCCESS CRITERIA                                                             │
└──────────────────────────────────────────────────────────────────────────────┘

  System ready when:
    ✓ 90%+ tests pass
    ✓ Model file present
    ✓ MQTT running
    ✓ Audio devices detected
    ✓ Voice input working
    ✓ TTS working

╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║  🚀 GET STARTED: ./install_and_test.sh                                      ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
