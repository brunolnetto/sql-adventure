#!/usr/bin/env python3
"""
Main entry point for SQL Adventure AI Evaluator
Refactored for quest-level parallelism and unified workflow
"""

import os
import sys
import asyncio
import argparse
import hashlib
import json
from datetime import datetime
from pathlib import Path

# Add the evaluator directory to the path for module imports
evaluator_dir = Path(__file__).parent.resolve()
sys.path.insert(0, str(evaluator_dir))

# Import and load evaluator environment configuration
from config.env_loader import load_evaluator_env, validate_config

# Load environment before other imports
load_evaluator_env()

class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super(DateTimeEncoder, self).default(obj)
from typing import List, Optional, Dict, Any, Set
from dataclasses import dataclass

from core.evaluators import QuestEvaluator
from config import ProjectFolderConfig, EvaluationConfig


async def evaluate(target: str, config: EvaluationConfig) -> Dict[str, Any]:
    """Unified evaluation function"""
    # Load API key
    openai_api_key = os.getenv("OPENAI_API_KEY")
    if not openai_api_key:
        raise ValueError("OPENAI_API_KEY not found in environment")
    
    # Initialize evaluator
    evaluator = QuestEvaluator()
    
    target_path = Path(target)
    
    is_quests_root = target_path.is_dir() and (target_path == ProjectFolderConfig().quests_dir or target_path.name == "quests")
    is_quest_dir = target_path.is_dir() and "quests/" in str(target_path) and target_path.name.startswith(('1-', '2-', '3-', '4-', '5-'))
    is_subcategory_dir = target_path.is_dir() and "quests/" in str(target_path) and any(sql_file.exists() for sql_file in target_path.rglob("*.sql"))
    is_sql_file = target_path.is_file() and target.endswith(".sql")
    
    if target == "all":
        print("🚀 Starting complete evaluation with quest-level parallelism")
        return await evaluator.evaluate_all()
    
    elif is_quests_root:
        print(f"📁 Evaluating all quests in directory: {target}")
        return await evaluator.evaluate_all_in_directory(target_path)
    
    elif is_quest_dir:
        print(f"📁 Evaluating quest directory: {target}")
        return await evaluator.evaluate_quest(target_path)
    
    elif is_subcategory_dir:
        print(f"📁 Evaluating subcategory directory: {target}")
        return await evaluator.evaluate_quest(target_path)
    
    elif is_sql_file:
        print(f"📄 Evaluating single file: {target}")
        result = await evaluator.evaluate_subcategory(target_path)
        
        # Print results instead of saving for now
        print("\n" + "="*60)
        print("🎯 EVALUATION RESULTS")
        print("="*60)
        if isinstance(result, dict):
            print(json.dumps(result, indent=2, cls=DateTimeEncoder))
        else:
            print(result)
        print("="*60)
        
        return {"files": [result], "total": 1, "success": 1 if result.get("success", True) else 0}
    
    else:
        raise ValueError(f"Invalid target: {target}")

def main():
    """Main function with command line interface"""
    parser = argparse.ArgumentParser(description="SQL Adventure AI Evaluator (Refactored)")
    parser.add_argument("target", nargs="?", help="SQL file, quest directory, or 'all' for everything")
    parser.add_argument("--output-dir", "-o", help="Output directory for results")
    parser.add_argument("--max-concurrent", "-c", type=int, default=3,
                       help="Maximum concurrent files per quest (default: 3)")
    parser.add_argument("--no-cache", action="store_true", help="Disable caching")
    parser.add_argument("--force", action="store_true", help="Force re-evaluation of cached files")
    
    args = parser.parse_args()
    
    if not args.target:
        print("Usage: python3 run_evaluation.py <target> [options]")
        print("  target: SQL file path, quest directory, or 'all'")
        print("\nOptions:")
        print("  --max-concurrent N    Parallel files per quest (default: 3)")
        print("  --no-cache           Disable result caching")
        print("  --force              Re-evaluate cached files")
        print("\nExamples:")
        print("  python3 run_evaluation.py all --max-concurrent 5")
        print("  python3 run_evaluation.py quests/1-data-modeling --no-cache")
        return
    
    # Create configuration
    config = EvaluationConfig()
    
    print(f"⚙️  Configuration:")
    print(f"   Parallel files per quest: {args.max_concurrent}")
    print(f"   Caching: {'disabled' if args.no_cache else 'enabled'}")
    print(f"   Skip unchanged: {'disabled' if args.force else 'enabled'}")
    
    try:
        # Run evaluation
        result = asyncio.run(evaluate(args.target, config))
        
        # Print summary
        if "quests" in result:
            print(f"\n🎉 Complete Evaluation Summary:")
            print(f"   Total files: {result['total_files']}")
            print(f"   Successful: {result['total_success']}")
            print(f"   Success rate: {result['success_rate']:.1f}%")
        else:
            print(f"\n🎉 Evaluation Complete:")
            print(f"   Files processed: {result.get('total', 1)}")
            print(f"   Successful: {result.get('success', 1)}")
        
    except Exception as e:
        print(f"❌ Evaluation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 