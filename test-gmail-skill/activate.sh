#!/bin/bash
# Helper script to activate virtual environment
# Usage: source activate.sh

if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✓ Virtual environment activated"
    echo "  Python: $(which python3)"
    echo "  Pip: $(which pip)"
    echo ""
    echo "Run commands now, for example:"
    echo "  python3 skills/gmail/scripts/gmail_search.py setup"
else
    echo "Error: venv directory not found"
    echo "Run: python3 -m venv venv"
fi
