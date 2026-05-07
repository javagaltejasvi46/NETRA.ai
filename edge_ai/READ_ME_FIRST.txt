================================================================================
                    EDGE AI COPILOT - READ THIS FIRST!
================================================================================

Got "ModuleNotFoundError: No module named 'edge_ai'" error?

HERE'S THE FIX:

--------------------------------------------------------------------------------
OPTION 1: ONE COMMAND TO FIX EVERYTHING (RECOMMENDED)
--------------------------------------------------------------------------------

chmod +x fix_and_run.sh && ./fix_and_run.sh

This will:
- Check everything
- Download model if missing
- Fix Python paths
- Start the system

--------------------------------------------------------------------------------
OPTION 2: JUST START (if already installed)
--------------------------------------------------------------------------------

chmod +x START_HERE.sh && ./START_HERE.sh

--------------------------------------------------------------------------------
OPTION 3: RUN FROM PARENT DIRECTORY
--------------------------------------------------------------------------------

cd ..
python3 -m edge_ai.main

--------------------------------------------------------------------------------
OPTION 4: MANUAL FIX
--------------------------------------------------------------------------------

export PYTHONPATH="/home/pi/NETRA.ai:$PYTHONPATH"
python3 main.py

--------------------------------------------------------------------------------
FIRST TIME SETUP
--------------------------------------------------------------------------------

If this is your first time, run:

chmod +x fix_now.sh && ./fix_now.sh

This installs everything (takes 10-20 minutes).

--------------------------------------------------------------------------------
TESTING
--------------------------------------------------------------------------------

Terminal 1 (start system):
  ./START_HERE.sh

Terminal 2 (send test data):
  mosquitto_pub -t 'battlefield/sensor' -m '{"timestamp":1710000000,"soldier":{"x":120,"y":340,"heart_rate":125},"enemy":{"x":180,"y":360},"hostage":{"x":140,"y":350},"environment":"urban","threat_level":"high"}'

Terminal 3 (watch responses):
  mosquitto_sub -t 'battlefield/ai-response' -v

--------------------------------------------------------------------------------
TROUBLESHOOTING
--------------------------------------------------------------------------------

Run diagnostics:
  chmod +x diagnose.sh && ./diagnose.sh

View detailed guide:
  cat QUICK_START.md

Check logs:
  tail -f logs/edge_ai_*.log

--------------------------------------------------------------------------------
QUICK REFERENCE
--------------------------------------------------------------------------------

All available scripts:
  ./fix_now.sh          - Install everything from scratch
  ./fix_and_run.sh      - Fix paths and run (recommended)
  ./START_HERE.sh       - Just start the system
  ./diagnose.sh         - Check system status
  
Documentation:
  QUICK_START.md        - Quick start guide
  README.md             - Full documentation
  TROUBLESHOOTING.md    - Detailed troubleshooting

--------------------------------------------------------------------------------

Questions? Check QUICK_START.md for detailed instructions!

================================================================================
