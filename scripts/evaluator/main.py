#!/usr/bin/env python3
"""
SQL Adventure AI Evaluator - Main CLI Entry Point
Replaces shell scripts with a comprehensive Python-based evaluation system
"""

import os
import sys
import asyncio
import argparse
import json
from pathlib import Path
from typing import List, Optional, Dict, Any
from datetime import datetime

# Add the evaluator directory to the path
sys.path.insert(0, str(Path(__file__).parent))

try:
    from .core.config import EvaluatorConfig, ConfigManager
    from .core.ai_evaluator import SQLEvaluator
    from .core.database_manager import DatabaseManager
    from .core.validation import SQLValidator
except ImportError:
    # Fallback for direct execution
    from core.config import EvaluatorConfig, ConfigManager
    from core.ai_evaluator import SQLEvaluator
    from core.database_manager import DatabaseManager
    from core.validation import SQLValidator

class EvaluatorCLI:
    """Main CLI interface for the SQL Adventure AI Evaluator"""
    
    def __init__(self):
        self.config = None
        self.evaluator = None
        self.db_manager = None
        self.validator = None
        
    def setup_logging(self):
        """Setup logging based on configuration"""
        if self.config:
            self.config.setup_logging()
    
    def load_config(self, config_path: Optional[str] = None):
        """Load configuration from file or environment"""
        try:
            # Only pass config_path if it's not None
            if config_path:
                self.config = ConfigManager.load_config(config_path)
            else:
                self.config = ConfigManager.load_config()
            self.config.setup_logging()
            self.config.setup_directories()
            
            # Validate configuration
            errors = self.config.validate()
            if errors:
                print("❌ Configuration errors:")
                for section, section_errors in errors.items():
                    print(f"  {section}:")
                    for error in section_errors:
                        print(f"    - {error}")
                sys.exit(1)
                
            print("✅ Configuration loaded successfully")
            
        except Exception as e:
            print(f"❌ Failed to load configuration: {e}")
            sys.exit(1)
    
    def initialize_components(self):
        """Initialize evaluator components"""
        try:
            # Initialize database manager
            self.db_manager = DatabaseManager(self.config)
            
            # Initialize SQL validator
            self.validator = SQLValidator(self.db_manager)
            
            # Initialize AI evaluator
            self.evaluator = SQLEvaluator(
                api_key=self.config.ai.openai_api_key,
                db_manager=self.db_manager
            )
            
            print("✅ Components initialized successfully")
            
        except Exception as e:
            print(f"❌ Failed to initialize components: {e}")
            sys.exit(1)
    
    async def run_validation(self, target: str, options: Dict[str, Any]):
        """Run SQL validation"""
        print(f"🔍 Running validation on: {target}")
        
        if os.path.isfile(target):
            # Single file validation
            result = await self.validator.validate_file(Path(target))
            self._print_validation_result(result)
        else:
            # Directory validation
            results = await self.validator.validate_directory(Path(target))
            self._print_validation_summary(results)
    
    async def run_evaluation(self, target: str, options: Dict[str, Any]):
        """Run AI-powered evaluation"""
        print(f"🤖 Running AI evaluation on: {target}")
        
        if os.path.isfile(target):
            # Single file evaluation
            result = await self.evaluator.evaluate_sql_file(Path(target))
            await self._save_evaluation_result(result, options)
        else:
            # Directory evaluation
            await self._run_batch_evaluation(Path(target), options)
    
    async def run_examples(self, target: str, options: Dict[str, Any]):
        """Run SQL examples"""
        print(f"▶️  Running examples: {target}")
        
        if os.path.isfile(target):
            # Single file execution
            result = await self.db_manager.execute_sql_file(Path(target))
            self._print_execution_result(result)
        else:
            # Directory execution
            await self._run_batch_execution(Path(target), options)
    
    async def generate_report(self, format_type: str, target: Optional[str], options: Dict[str, Any]):
        """Generate evaluation reports"""
        print(f"📊 Generating {format_type} report for: {target or 'all'}")
        
        if format_type == "json":
            await self._generate_json_report(target, options)
        elif format_type == "html":
            await self._generate_html_report(target, options)
        elif format_type == "md":
            await self._generate_markdown_report(target, options)
        else:
            print(f"❌ Unsupported report format: {format_type}")
    
    async def run_consistency_check(self, options: Dict[str, Any]):
        """Run consistency check"""
        print("🔍 Running consistency check...")
        
        results = await self.validator.check_consistency()
        self._print_consistency_results(results)
    
    async def run_performance_test(self, options: Dict[str, Any]):
        """Run performance optimization test"""
        print("⚡ Running performance test...")
        
        results = await self.validator.performance_test()
        self._print_performance_results(results)
    
    def _print_validation_result(self, result: Dict[str, Any]):
        """Print validation result"""
        if result.get('valid'):
            print(f"✅ {result['file']}: Valid")
        else:
            print(f"❌ {result['file']}: Invalid")
            for error in result.get('errors', []):
                print(f"   - {error}")
    
    def _print_validation_summary(self, results: List[Dict[str, Any]]):
        """Print validation summary"""
        total = len(results)
        valid = sum(1 for r in results if r.get('valid'))
        invalid = total - valid
        
        print(f"📊 Validation Summary:")
        print(f"  Total files: {total}")
        print(f"  Valid: {valid}")
        print(f"  Invalid: {invalid}")
        
        if invalid > 0:
            print(f"  ❌ {invalid} files have validation issues")
        else:
            print(f"  ✅ All files are valid")
    
    async def _save_evaluation_result(self, result, options: Dict[str, Any]):
        """Save evaluation result"""
        # Save to file
        if self.config.evaluation.save_to_files:
            output_dir = Path(self.config.evaluation.output_directory)
            output_dir.mkdir(parents=True, exist_ok=True)
            
            output_file = output_dir / f"{result.metadata['filename']}.json"
            output_file.write_text(result.model_dump_json(indent=2))
            print(f"✅ Evaluation saved to: {output_file}")
        
        # Save to database
        if self.config.evaluation.save_to_database:
            saved = await self.evaluator.save_evaluation_to_db(result)
            if saved:
                print("✅ Evaluation saved to database")
            else:
                print("⚠️  Failed to save to database")
    
    async def _run_batch_evaluation(self, directory: Path, options: Dict[str, Any]):
        """Run batch evaluation on directory"""
        sql_files = list(directory.rglob("*.sql"))
        print(f"Found {len(sql_files)} SQL files to evaluate")
        
        batch_size = options.get('batch_size', self.config.evaluation.max_parallel_evaluations)
        
        for i in range(0, len(sql_files), batch_size):
            batch = sql_files[i:i + batch_size]
            print(f"Processing batch {i//batch_size + 1}/{(len(sql_files) + batch_size - 1)//batch_size}")
            
            tasks = []
            for sql_file in batch:
                task = self.evaluator.evaluate_sql_file(sql_file)
                tasks.append(task)
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            for sql_file, result in zip(batch, results):
                if isinstance(result, Exception):
                    print(f"❌ Error evaluating {sql_file}: {result}")
                else:
                    await self._save_evaluation_result(result, options)
    
    async def _run_batch_execution(self, directory: Path, options: Dict[str, Any]):
        """Run batch execution on directory"""
        sql_files = list(directory.rglob("*.sql"))
        print(f"Found {len(sql_files)} SQL files to execute")
        
        verbose = options.get('verbose', True)
        
        for sql_file in sql_files:
            print(f"Executing: {sql_file}")
            
            try:
                result = await self.db_manager.execute_sql_file(sql_file)
                if result.get('success'):
                    print(f"✅ {sql_file.name}: Success")
                    if verbose and result.get('output'):
                        print(result['output'])
                else:
                    print(f"❌ {sql_file.name}: Failed")
                    if verbose and result.get('error'):
                        print(f"   Error: {result['error']}")
            except Exception as e:
                print(f"❌ {sql_file.name}: Exception - {e}")
    
    async def _generate_json_report(self, target: Optional[str], options: Dict[str, Any]):
        """Generate JSON report"""
        # Implementation for JSON report generation
        print("📊 JSON report generation not yet implemented")
    
    async def _generate_html_report(self, target: Optional[str], options: Dict[str, Any]):
        """Generate HTML report"""
        # Implementation for HTML report generation
        print("📊 HTML report generation not yet implemented")
    
    async def _generate_markdown_report(self, target: Optional[str], options: Dict[str, Any]):
        """Generate Markdown report"""
        # Implementation for Markdown report generation
        print("📊 Markdown report generation not yet implemented")
    
    def _print_consistency_results(self, results: Dict[str, Any]):
        """Print consistency check results"""
        print(f"📊 Consistency Results:")
        print(f"  Total files: {results.get('total_files', 0)}")
        print(f"  Consistent: {results.get('consistent_files', 0)}")
        print(f"  Inconsistent: {results.get('inconsistent_files', 0)}")
        
        if results.get('inconsistent_files', 0) > 0:
            print("  Issues found:")
            for issue in results.get('issues', []):
                print(f"    - {issue}")
        else:
            print("  ✅ All files are consistent")
    
    def _print_performance_results(self, results: Dict[str, Any]):
        """Print performance test results"""
        print(f"⚡ Performance Results:")
        print(f"  Average execution time: {results.get('avg_time', 0):.2f}s")
        print(f"  Total queries: {results.get('total_queries', 0)}")
        print(f"  Failed queries: {results.get('failed_queries', 0)}")
        
        if results.get('optimization_suggestions'):
            print("  Optimization suggestions:")
            for suggestion in results['optimization_suggestions']:
                print(f"    - {suggestion}")
    
    def _print_execution_result(self, result: Dict[str, Any]):
        """Print execution result"""
        if result.get('success'):
            print(f"✅ Execution successful")
            if result.get('output'):
                print("Output:")
                print(result['output'])
        else:
            print(f"❌ Execution failed")
            if result.get('error'):
                print(f"Error: {result['error']}")

def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="SQL Adventure AI Evaluator - Python-based evaluation system",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python main.py validate quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql
  python main.py evaluate quests/1-data-modeling --batch-size 5
  python main.py examples quests/1-data-modeling --verbose
  python main.py report json quests/1-data-modeling
  python main.py consistency
  python main.py performance
        """
    )
    
    parser.add_argument('mode', choices=[
        'validate', 'evaluate', 'examples', 'report', 'consistency', 'performance'
    ], help='Evaluation mode')
    
    parser.add_argument('target', nargs='?', help='Target file or directory')
    
    parser.add_argument('--config', help='Configuration file path')
    parser.add_argument('--batch-size', type=int, help='Batch size for parallel processing')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    parser.add_argument('--quiet', action='store_true', help='Quiet mode')
    parser.add_argument('--no-cache', action='store_true', help='Disable caching')
    parser.add_argument('--force', action='store_true', help='Force regeneration')
    
    # Report-specific arguments
    parser.add_argument('--format', choices=['json', 'html', 'md'], 
                       help='Report format (for report mode)')
    
    args = parser.parse_args()
    
    # Build options dictionary
    options = {
        'batch_size': args.batch_size,
        'verbose': args.verbose,
        'quiet': args.quiet,
        'no_cache': args.no_cache,
        'force': args.force,
        'format': args.format
    }
    
    # Initialize CLI
    cli = EvaluatorCLI()
    
    # Load configuration
    cli.load_config(args.config)
    
    # Initialize components
    cli.initialize_components()
    
    # Run the appropriate mode
    async def run():
        try:
            if args.mode == 'validate':
                await cli.run_validation(args.target, options)
            elif args.mode == 'evaluate':
                await cli.run_evaluation(args.target, options)
            elif args.mode == 'examples':
                await cli.run_examples(args.target, options)
            elif args.mode == 'report':
                await cli.generate_report(args.format or 'json', args.target, options)
            elif args.mode == 'consistency':
                await cli.run_consistency_check(options)
            elif args.mode == 'performance':
                await cli.run_performance_test(options)
        except KeyboardInterrupt:
            print("\n⚠️  Operation cancelled by user")
        except Exception as e:
            print(f"❌ Error: {e}")
            if cli.config and cli.config.debug_mode:
                import traceback
                traceback.print_exc()
            sys.exit(1)
    
    # Run the async function
    asyncio.run(run())

if __name__ == "__main__":
    main() 