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
from pathlib import Path
from typing import List, Optional, Dict, Any, Set
from dataclasses import dataclass

from sql_evaluator import SQLEvaluator

@dataclass
class EvaluationConfig:
    """Configuration for evaluation runs"""
    max_concurrent_files: int = 3  # Parallel files per quest
    cache_enabled: bool = True
    skip_unchanged: bool = True
    output_dir: Optional[str] = None
    mode: str = "fast"

class QuestEvaluator:
    """Unified evaluator with quest-level parallelism and caching"""
    
    def __init__(self, api_key: str, config: EvaluationConfig):
        self.evaluator = SQLEvaluator(api_key)
        self.config = config
        self.cache_dir = Path("evaluation-cache")
        self.cache_dir.mkdir(exist_ok=True)
    
    def _get_file_hash(self, file_path: Path) -> str:
        """Generate hash for file change detection"""
        content = file_path.read_text()
        return hashlib.md5(content.encode()).hexdigest()
    
    def _get_cache_path(self, file_path: Path) -> Path:
        """Get cache file path for a SQL file"""
        return self.cache_dir / f"{file_path.stem}_{self._get_file_hash(file_path)[:8]}.json"
    
    def _is_cached_valid(self, file_path: Path) -> bool:
        """Return True if cache exists and is newer than the SQL file."""
        if not self.config.cache_enabled or not self.config.skip_unchanged:
            return False

        cache_path = self._get_cache_path(file_path)
        if not cache_path.exists():
            return False

        return cache_path.stat().st_mtime >= file_path.stat().st_mtime
    
    def _load_cached_result(self, file_path: Path) -> Optional[Dict[str, Any]]:
        """Load cached evaluation result and raise if corrupted."""
        cache_path = self._get_cache_path(file_path)
        try:
            return json.loads(cache_path.read_text())
        except Exception as e:
            print(f"⚠️  Corrupted cache for {file_path}: {e}")
            return None
    
    def _save_cached_result(self, file_path: Path, result: Dict[str, Any]):
        """Save evaluation result to cache"""
        if not self.config.cache_enabled:
            return
        
        cache_path = self._get_cache_path(file_path)
        try:
            cache_path.write_text(json.dumps(result, indent=2))
        except Exception as e:
            print(f"⚠️  Failed to cache result for {file_path}: {e}")
    
    async def evaluate_single_file(self, file_path: Path) -> Dict[str, Any]:
        """Evaluate a single SQL file with caching"""
        print(f"Evaluating: {file_path}")
        
        # Check cache first
        if self._is_cached_valid(file_path):
            cached_result = self._load_cached_result(file_path)
            if cached_result:
                print(f"📋 Using cached result for {file_path.name}")
                return cached_result
        
        try:
            # Perform evaluation
            result = await self.evaluator.evaluate_sql_file(file_path)
            result_dict = result.model_dump()
            
            # Cache the result
            self._save_cached_result(file_path, result_dict)
            
            return result_dict
            
        except Exception as e:
            print(f"❌ Error evaluating {file_path}: {e}")
            return {
                "error": str(e),
                "file": file_path.name,
                "success": False
            }
    
    async def evaluate_quest_parallel(self, quest_path: Path) -> Dict[str, Any]:
        """Evaluate all files in a quest with controlled parallelism"""
        sql_files = list(quest_path.rglob("*.sql"))
        
        if not sql_files:
            return {"quest": quest_path.name, "files": [], "success": 0, "total": 0}
        
        print(f"🔍 Found {len(sql_files)} SQL files in {quest_path.name}")
        print(f"⚡ Processing with {self.config.max_concurrent_files} concurrent files")
        
        # Process files in batches to control concurrency
        results = []
        for i in range(0, len(sql_files), self.config.max_concurrent_files):
            batch = sql_files[i:i + self.config.max_concurrent_files]
            
            # Create tasks for this batch
            tasks = [self.evaluate_single_file(f) for f in batch]
            
            # Execute batch in parallel
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Process results
            for j, result in enumerate(batch_results):
                if isinstance(result, Exception):
                    print(f"❌ Exception in {batch[j].name}: {result}")
                    results.append({
                        "error": str(result),
                        "file": batch[j].name,
                        "success": False
                    })
                else:
                    results.append(result)
            
            # Small delay between batches to be nice to API
            if i + self.config.max_concurrent_files < len(sql_files):
                await asyncio.sleep(1)
        
        # Save results to output directory
        success_count = sum(1 for r in results if r.get("success", True))
        
        # Determine output directory
        if self.config.output_dir:
            output_path = Path(self.config.output_dir) / quest_path.name
        else:
            # Create proper subdirectory structure
            if len(quest_path.parts) >= 3:
                # For subdirectories like quests/1-data-modeling/00-basic-concepts
                output_path = Path("ai-evaluations") / quest_path.parts[-2] / quest_path.parts[-1]
            else:
                # For main quest directories
                output_path = Path("ai-evaluations") / quest_path.name
        
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Save individual results
        for result in results:
            if "metadata" in result and "file" in result["metadata"]:
                # Use the original filename from metadata
                original_filename = result["metadata"]["file"]
                file_name = original_filename.replace(".sql", ".json")
                result_file = output_path / file_name
                result_file.write_text(json.dumps(result, indent=2))
                print(f"✅ Saved: {result_file}")
            elif "file" in result:
                # Fallback for error results
                file_name = result["file"].replace(".sql", ".json")
                result_file = output_path / file_name
                result_file.write_text(json.dumps(result, indent=2))
                print(f"⚠️  Saved error result: {result_file}")
            else:
                print(f"❌ Result missing file info: {result.keys()}")
        
        return {
            "quest": quest_path.name,
            "files": results,
            "success": success_count,
            "total": len(sql_files)
        }
    
    async def evaluate_all_sequential(self) -> Dict[str, Any]:
        """Evaluate all quests sequentially with parallel file processing within each quest"""
        quests_dir = Path("quests")
        quest_dirs = [d for d in quests_dir.iterdir() if d.is_dir() and d.name[0].isdigit()]
        quest_dirs.sort(key=lambda x: int(x.name.split('-')[0]))
        
        print(f"🎯 Found {len(quest_dirs)} quests to evaluate")
        
        all_results = []
        total_files = 0
        total_success = 0
        
        for quest_dir in quest_dirs:
            print(f"\n📚 Processing quest: {quest_dir.name}")
            quest_result = await self.evaluate_quest_parallel(quest_dir)
            all_results.append(quest_result)
            
            total_files += quest_result["total"]
            total_success += quest_result["success"]
            
            print(f"✅ Quest {quest_dir.name}: {quest_result['success']}/{quest_result['total']} files")
            
            # Delay between quests to avoid overwhelming the system
            await asyncio.sleep(2)
        
        return {
            "quests": all_results,
            "total_files": total_files,
            "total_success": total_success,
            "success_rate": (total_success / total_files * 100) if total_files > 0 else 0
        }

async def evaluate(target: str, config: EvaluationConfig) -> Dict[str, Any]:
    """Unified evaluation function"""
    # Load API key
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise ValueError("OPENAI_API_KEY not found in environment")
    
    # Initialize evaluator
    evaluator = QuestEvaluator(api_key, config)
    
    target_path = Path(target)
    
    if target == "all":
        print("🚀 Starting complete evaluation with quest-level parallelism")
        return await evaluator.evaluate_all_parallel()
    
    elif target_path.is_dir():
        print("🚀 Starting quest evaluation with quest-level parallelism")
        return await evaluator.evaluate_quest_parallel(target_path)
    
    elif target_path.is_file() and target.endswith(".sql"):
        print(f"📄 Evaluating single file: {target}")
        result = await evaluator.evaluate_single_file(target_path)
        
        # Save to output directory
        if config.output_dir:
            output_path = Path(config.output_dir)
        else:
            output_path = Path("ai-evaluations") / target_path.parts[-3] / target_path.parts[-2]
        
        output_path.mkdir(parents=True, exist_ok=True)
        output_file = output_path / f"{target_path.stem}.json"
        output_file.write_text(json.dumps(result, indent=2))
        
        return {"files": [result], "total": 1, "success": 1 if result.get("success", True) else 0}
    
    elif target_path.is_dir():
        print(f"📁 Evaluating quest directory: {target}")
        return await evaluator.evaluate_quest_parallel(target_path)
    
    else:
        raise ValueError(f"Invalid target: {target}")

def main():
    """Main function with command line interface"""
    parser = argparse.ArgumentParser(description="SQL Adventure AI Evaluator (Refactored)")
    parser.add_argument("target", nargs="?", help="SQL file, quest directory, or 'all' for everything")
    parser.add_argument("--output-dir", "-o", help="Output directory for results")
    parser.add_argument("--mode", "-m", choices=["fast", "comprehensive"], default="fast", 
                       help="Evaluation mode")
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
    config = EvaluationConfig(
        max_concurrent_files=args.max_concurrent,
        cache_enabled=not args.no_cache,
        skip_unchanged=not args.force,
        output_dir=args.output_dir,
        mode=args.mode
    )
    
    print(f"⚙️  Configuration:")
    print(f"   Parallel files per quest: {config.max_concurrent_files}")
    print(f"   Caching: {'enabled' if config.cache_enabled else 'disabled'}")
    print(f"   Skip unchanged: {'enabled' if config.skip_unchanged else 'disabled'}")
    print(f"   Mode: {config.mode}")
    
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