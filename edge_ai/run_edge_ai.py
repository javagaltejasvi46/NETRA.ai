#!/usr/bin/env python3
"""
Standalone runner for Edge AI Copilot that handles import paths correctly.
"""
import sys
import os

# Add the parent directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

# Now import and run main
if __name__ == "__main__":
    from edge_ai.main import main
    main()
