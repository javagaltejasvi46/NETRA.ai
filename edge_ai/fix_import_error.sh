#!/bin/bash
# Fix for ModuleNotFoundError: No module named 'edge_ai'

echo "=========================================="
echo "Fixing Import Error"
echo "=========================================="
echo ""

# Get the current directory
CURRENT_DIR=$(pwd)

echo "Current directory: $CURRENT_DIR"
echo ""

# Check if we're in the right place
if [ ! -f "main.py" ]; then
    echo "✗ Error: main.py not found!"
    echo "  Make sure you're in the edge_ai directory"
    echo "  Run: cd edge_ai"
    exit 1
fi

# Fix 1: Add __init__.py if missing
echo "Step 1: Ensuring __init__.py exists..."
touch __init__.py
echo "✓ __init__.py created"
echo ""

# Fix 2: Set PYTHONPATH
echo "Step 2: Setting PYTHONPATH..."
export PYTHONPATH="${CURRENT_DIR}:${PYTHONPATH}"
echo "✓ PYTHONPATH set to: $PYTHONPATH"
echo ""

# Fix 3: Update main.py to use relative imports
echo "Step 3: Checking Python path..."
python3 -c "import sys; print('Python path:'); [print('  ' + p) for p in sys.path]"
echo ""

# Fix 4: Create a wrapper script
echo "Step 4: Creating run script..."
cat > run.sh << 'EOF'
#!/bin/bash
# Wrapper script to run Edge AI Copilot with correct Python path

# Get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Set Python path to parent directory
export PYTHONPATH="$(dirname "$DIR"):$PYTHONPATH"

# Run main.py
python3 main.py "$@"
EOF

chmod +x run.sh
echo "✓ Created run.sh wrapper"
echo ""

echo "=========================================="
echo "Fix Applied!"
echo "=========================================="
echo ""
echo "Now run the system using ONE of these methods:"
echo ""
echo "Method 1 (Recommended): Use the wrapper script"
echo "  ./run.sh"
echo ""
echo "Method 2: Set PYTHONPATH and run"
echo "  export PYTHONPATH=\"$(dirname $CURRENT_DIR):\$PYTHONPATH\""
echo "  python3 main.py"
echo ""
echo "Method 3: Run from parent directory"
echo "  cd .."
echo "  python3 -m edge_ai.main"
echo ""
