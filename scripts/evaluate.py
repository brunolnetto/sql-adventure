#!/usr/bin/env python3
"""
SQL Adventure Evaluator - Drop-in replacement for shell scripts
This script provides a simple interface to migrate from shell scripts to Python
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    """Main entry point that mimics shell script behavior"""
    
    # Add the evaluator directory to the path
    evaluator_dir = Path(__file__).parent / "evaluator"
    sys.path.insert(0, str(evaluator_dir))
    
    # Import the main CLI
    try:
        from evaluator.main import main as evaluator_main
    except ImportError as e:
        print(f"❌ Failed to import evaluator: {e}")
        print("Please ensure the evaluator module is properly installed")
        sys.exit(1)
    
    # Map shell script arguments to Python CLI arguments
    args = sys.argv[1:]
    
    if not args:
        print("SQL Adventure Evaluator - Python Edition")
        print("Usage: python evaluate.py <mode> [target] [options]")
        print("")
        print("Modes:")
        print("  validate <file|quest>     - Validate SQL files")
        print("  evaluate <file|quest>     - Run AI evaluation")
        print("  examples <file|quest>     - Run SQL examples")
        print("  report <format> [quest]   - Generate reports")
        print("  consistency               - Check file consistency")
        print("  performance               - Performance optimization test")
        print("")
        print("Examples:")
        print("  python evaluate.py validate quests/1-data-modeling")
        print("  python evaluate.py evaluate quests/1-data-modeling --batch-size 5")
        print("  python evaluate.py examples quests/1-data-modeling --verbose")
        print("  python evaluate.py report json quests/1-data-modeling")
        sys.exit(0)
    
    # Convert shell-style arguments to Python CLI arguments
    python_args = ["evaluator.main"]
    
    # Handle mode
    mode = args[0]
    python_args.append(mode)
    
    # Handle target
    if len(args) > 1 and not args[1].startswith('-'):
        python_args.append(args[1])
        args = args[2:]
    else:
        args = args[1:]
    
    # Convert shell-style options to Python CLI options
    for arg in args:
        if arg.startswith('--'):
            python_args.append(arg)
        elif arg.startswith('-'):
            # Convert short options to long options
            if arg == '-v':
                python_args.append('--verbose')
            elif arg == '-q':
                python_args.append('--quiet')
            elif arg == '-f':
                python_args.append('--force')
            else:
                python_args.append(arg)
        else:
            python_args.append(arg)
    
    # Set up environment
    os.environ['PYTHONPATH'] = str(evaluator_dir) + os.pathsep + os.environ.get('PYTHONPATH', '')
    
    # Run the evaluator
    try:
        # Create a new sys.argv for the evaluator
        sys.argv = python_args
        evaluator_main()
    except Exception as e:
        print(f"❌ Error running evaluator: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 