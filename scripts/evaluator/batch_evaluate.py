#!/usr/bin/env python3
"""
Batch Evaluation Script for SQL Adventure
Systematically evaluates all quests using the Python evaluator
"""

import sys
import asyncio
import json
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime
import time

# Add the current directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from core.validation import SQLValidator
from core.ai_evaluator import SQLEvaluator

class BatchEvaluator:
    """Batch evaluation system for all SQL Adventure quests"""
    
    def __init__(self):
        self.validator = SQLValidator()
        self.evaluator = SQLEvaluator(api_key="dummy-key")  # AI components disabled for batch
        self.results = {}
        self.stats = {
            'total_files': 0,
            'processed_files': 0,
            'successful_evaluations': 0,
            'failed_evaluations': 0,
            'start_time': None,
            'end_time': None
        }
    
    def discover_sql_files(self, quests_dir: Path) -> Dict[str, List[Path]]:
        """Discover all SQL files in quests directory"""
        quests = {}
        
        for quest_dir in quests_dir.iterdir():
            if quest_dir.is_dir() and quest_dir.name.startswith(('1-', '2-', '3-', '4-', '5-')):
                quest_name = quest_dir.name
                quests[quest_name] = []
                
                # Find SQL files in subcategories
                for subcategory_dir in quest_dir.iterdir():
                    if subcategory_dir.is_dir():
                        for sql_file in subcategory_dir.glob("*.sql"):
                            quests[quest_name].append(sql_file)
        
        return quests
    
    async def evaluate_sql_file(self, sql_file: Path) -> Dict[str, Any]:
        """Evaluate a single SQL file"""
        result = {
            'file_path': str(sql_file),
            'filename': sql_file.name,
            'quest': sql_file.parts[-3] if len(sql_file.parts) >= 3 else 'unknown',
            'subcategory': sql_file.parts[-2] if len(sql_file.parts) >= 2 else 'unknown',
            'evaluation_time': None,
            'validation': None,
            'patterns': None,
            'metadata': None,
            'content_analysis': None,
            'educational_assessment': None,
            'success': False,
            'error': None
        }
        
        start_time = time.time()
        
        try:
            # Read SQL content
            sql_content = sql_file.read_text()
            
            # 1. SQL Validation
            validation_result = self.validator.validate_sql_file(str(sql_file))
            result['validation'] = {
                'is_valid': validation_result.is_valid,
                'score': validation_result.score,
                'total_issues': len(validation_result.issues),
                'errors': len(validation_result.get_errors()),
                'warnings': len(validation_result.get_warnings())
            }
            
            # 2. Pattern Detection
            patterns = self.evaluator.detect_sql_patterns(sql_content)
            result['patterns'] = [
                {
                    'name': pattern.pattern_name,
                    'confidence': pattern.confidence,
                    'description': pattern.description
                }
                for pattern in patterns
            ]
            
            # 3. Metadata Extraction
            purpose = self.evaluator._extract_purpose_from_path(sql_file)
            concepts = self.evaluator._extract_concepts_from_content(sql_content)
            difficulty = self.evaluator._extract_difficulty_from_path(sql_file)
            
            result['metadata'] = {
                'purpose': purpose,
                'concepts': concepts,
                'difficulty': difficulty
            }
            
            # 4. Content Analysis
            sql_keywords = ['CREATE TABLE', 'INSERT INTO', 'SELECT', 'DROP TABLE', 'WHERE', 'JOIN', 'GROUP BY']
            found_keywords = [kw for kw in sql_keywords if kw in sql_content.upper()]
            
            result['content_analysis'] = {
                'file_size': len(sql_content),
                'lines': len(sql_content.split('\n')),
                'found_keywords': found_keywords,
                'table_creations': sql_content.upper().count('CREATE TABLE'),
                'insert_statements': sql_content.upper().count('INSERT INTO'),
                'select_statements': sql_content.upper().count('SELECT'),
                'drop_statements': sql_content.upper().count('DROP TABLE'),
                'has_purpose_header': '-- PURPOSE:' in sql_content,
                'has_difficulty_header': '-- DIFFICULTY:' in sql_content,
                'has_concepts_header': '-- CONCEPTS:' in sql_content
            }
            
            # 5. Educational Assessment
            educational_indicators = {
                'has_examples': 'Example' in sql_content,
                'has_comments': '--' in sql_content,
                'has_cleanup': 'DROP TABLE' in sql_content.upper(),
                'has_sample_data': 'INSERT INTO' in sql_content.upper(),
                'has_queries': 'SELECT' in sql_content.upper(),
                'has_constraints': 'PRIMARY KEY' in sql_content.upper() or 'UNIQUE' in sql_content.upper()
            }
            
            educational_score = sum(educational_indicators.values()) / len(educational_indicators) * 10
            
            result['educational_assessment'] = {
                'indicators': educational_indicators,
                'score': educational_score
            }
            
            result['success'] = True
            
        except Exception as e:
            result['error'] = str(e)
            result['success'] = False
        
        result['evaluation_time'] = time.time() - start_time
        return result
    
    async def evaluate_quest(self, quest_name: str, sql_files: List[Path]) -> Dict[str, Any]:
        """Evaluate all SQL files in a quest"""
        print(f"🔍 Evaluating quest: {quest_name} ({len(sql_files)} files)")
        
        quest_results = {
            'quest_name': quest_name,
            'total_files': len(sql_files),
            'successful_evaluations': 0,
            'failed_evaluations': 0,
            'files': [],
            'summary': {}
        }
        
        for i, sql_file in enumerate(sql_files, 1):
            print(f"  📄 [{i}/{len(sql_files)}] {sql_file.name}")
            
            result = await self.evaluate_sql_file(sql_file)
            quest_results['files'].append(result)
            
            if result['success']:
                quest_results['successful_evaluations'] += 1
                self.stats['successful_evaluations'] += 1
            else:
                quest_results['failed_evaluations'] += 1
                self.stats['failed_evaluations'] += 1
            
            self.stats['processed_files'] += 1
        
        # Generate quest summary
        quest_results['summary'] = self._generate_quest_summary(quest_results)
        
        print(f"  ✅ Quest {quest_name} completed: {quest_results['successful_evaluations']}/{quest_results['total_files']} successful")
        
        return quest_results
    
    def _generate_quest_summary(self, quest_results: Dict[str, Any]) -> Dict[str, Any]:
        """Generate summary statistics for a quest"""
        successful_files = [f for f in quest_results['files'] if f['success']]
        
        if not successful_files:
            return {
                'average_validation_score': 0,
                'total_patterns': 0,
                'average_educational_score': 0,
                'common_patterns': [],
                'difficulty_distribution': {},
                'file_size_stats': {'min': 0, 'max': 0, 'avg': 0}
            }
        
        # Validation scores
        validation_scores = [f['validation']['score'] for f in successful_files if f['validation']]
        avg_validation_score = sum(validation_scores) / len(validation_scores) if validation_scores else 0
        
        # Pattern analysis
        all_patterns = []
        for file_result in successful_files:
            if file_result['patterns']:
                all_patterns.extend([p['name'] for p in file_result['patterns']])
        
        pattern_counts = {}
        for pattern in all_patterns:
            pattern_counts[pattern] = pattern_counts.get(pattern, 0) + 1
        
        common_patterns = sorted(pattern_counts.items(), key=lambda x: x[1], reverse=True)[:5]
        
        # Educational scores
        educational_scores = [f['educational_assessment']['score'] for f in successful_files if f['educational_assessment']]
        avg_educational_score = sum(educational_scores) / len(educational_scores) if educational_scores else 0
        
        # Difficulty distribution
        difficulty_counts = {}
        for file_result in successful_files:
            if file_result['metadata'] and file_result['metadata']['difficulty']:
                difficulty = file_result['metadata']['difficulty']
                difficulty_counts[difficulty] = difficulty_counts.get(difficulty, 0) + 1
        
        # File size statistics
        file_sizes = [f['content_analysis']['file_size'] for f in successful_files if f['content_analysis']]
        file_size_stats = {
            'min': min(file_sizes) if file_sizes else 0,
            'max': max(file_sizes) if file_sizes else 0,
            'avg': sum(file_sizes) / len(file_sizes) if file_sizes else 0
        }
        
        return {
            'average_validation_score': round(avg_validation_score, 2),
            'total_patterns': len(all_patterns),
            'average_educational_score': round(avg_educational_score, 1),
            'common_patterns': common_patterns,
            'difficulty_distribution': difficulty_counts,
            'file_size_stats': file_size_stats
        }
    
    async def evaluate_all_quests(self, quests_dir: Path) -> Dict[str, Any]:
        """Evaluate all quests systematically"""
        print("🚀 Starting batch evaluation of all quests")
        print("=" * 60)
        
        self.stats['start_time'] = datetime.now()
        
        # Discover all SQL files
        quests = self.discover_sql_files(quests_dir)
        self.stats['total_files'] = sum(len(files) for files in quests.values())
        
        print(f"📁 Found {len(quests)} quests with {self.stats['total_files']} SQL files")
        print()
        
        # Evaluate each quest
        for quest_name, sql_files in quests.items():
            if sql_files:  # Only evaluate quests with SQL files
                quest_results = await self.evaluate_quest(quest_name, sql_files)
                self.results[quest_name] = quest_results
                print()
        
        self.stats['end_time'] = datetime.now()
        
        return self._generate_overall_summary()
    
    def _generate_overall_summary(self) -> Dict[str, Any]:
        """Generate overall evaluation summary"""
        total_quests = len(self.results)
        total_files = sum(q['total_files'] for q in self.results.values())
        total_successful = sum(q['successful_evaluations'] for q in self.results.values())
        total_failed = sum(q['failed_evaluations'] for q in self.results.values())
        
        duration = (self.stats['end_time'] - self.stats['start_time']).total_seconds()
        
        # Overall statistics
        all_patterns = []
        all_validation_scores = []
        all_educational_scores = []
        
        for quest_result in self.results.values():
            for file_result in quest_result['files']:
                if file_result['success']:
                    if file_result['patterns']:
                        all_patterns.extend([p['name'] for p in file_result['patterns']])
                    if file_result['validation']:
                        all_validation_scores.append(file_result['validation']['score'])
                    if file_result['educational_assessment']:
                        all_educational_scores.append(file_result['educational_assessment']['score'])
        
        # Pattern analysis
        pattern_counts = {}
        for pattern in all_patterns:
            pattern_counts[pattern] = pattern_counts.get(pattern, 0) + 1
        
        top_patterns = sorted(pattern_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        
        return {
            'evaluation_summary': {
                'total_quests': total_quests,
                'total_files': total_files,
                'successful_evaluations': total_successful,
                'failed_evaluations': total_failed,
                'success_rate': round(total_successful / total_files * 100, 1) if total_files > 0 else 0,
                'evaluation_duration_seconds': round(duration, 2)
            },
            'quality_metrics': {
                'average_validation_score': round(sum(all_validation_scores) / len(all_validation_scores), 2) if all_validation_scores else 0,
                'average_educational_score': round(sum(all_educational_scores) / len(all_educational_scores), 1) if all_educational_scores else 0,
                'total_patterns_detected': len(all_patterns),
                'unique_patterns': len(pattern_counts)
            },
            'top_patterns': top_patterns,
            'quest_results': self.results,
            'evaluation_stats': self.stats
        }
    
    def save_results(self, output_file: Path):
        """Save evaluation results to JSON file"""
        summary = self._generate_overall_summary()
        
        # Add timestamp
        summary['evaluation_timestamp'] = datetime.now().isoformat()
        summary['evaluator_version'] = '2.0'
        
        # Convert datetime objects to strings for JSON serialization
        def convert_datetime(obj):
            if isinstance(obj, datetime):
                return obj.isoformat()
            elif isinstance(obj, dict):
                return {k: convert_datetime(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [convert_datetime(item) for item in obj]
            else:
                return obj
        
        summary = convert_datetime(summary)
        
        # Save to file
        output_file.parent.mkdir(parents=True, exist_ok=True)
        with open(output_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"💾 Results saved to: {output_file}")
    
    def print_summary(self):
        """Print evaluation summary to console"""
        summary = self._generate_overall_summary()
        
        print("\n" + "=" * 60)
        print("📊 BATCH EVALUATION SUMMARY")
        print("=" * 60)
        
        eval_summary = summary['evaluation_summary']
        quality_metrics = summary['quality_metrics']
        
        print(f"🎯 Evaluation Results:")
        print(f"   Total Quests: {eval_summary['total_quests']}")
        print(f"   Total Files: {eval_summary['total_files']}")
        print(f"   Successful: {eval_summary['successful_evaluations']}")
        print(f"   Failed: {eval_summary['failed_evaluations']}")
        print(f"   Success Rate: {eval_summary['success_rate']}%")
        print(f"   Duration: {eval_summary['evaluation_duration_seconds']}s")
        
        print(f"\n📈 Quality Metrics:")
        print(f"   Average Validation Score: {quality_metrics['average_validation_score']}/1.0")
        print(f"   Average Educational Score: {quality_metrics['average_educational_score']}/10.0")
        print(f"   Total Patterns Detected: {quality_metrics['total_patterns_detected']}")
        print(f"   Unique Patterns: {quality_metrics['unique_patterns']}")
        
        print(f"\n🔝 Top Patterns:")
        for pattern, count in summary['top_patterns'][:5]:
            print(f"   {pattern}: {count} occurrences")
        
        print(f"\n📋 Quest Breakdown:")
        for quest_name, quest_result in self.results.items():
            success_rate = quest_result['successful_evaluations'] / quest_result['total_files'] * 100
            print(f"   {quest_name}: {quest_result['successful_evaluations']}/{quest_result['total_files']} ({success_rate:.1f}%)")

async def main():
    """Main function for batch evaluation"""
    if len(sys.argv) < 2:
        print("Usage: python batch_evaluate.py <quests_directory> [output_file]")
        print("Example: python batch_evaluate.py ../../quests results/batch_evaluation.json")
        sys.exit(1)
    
    quests_dir = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("results/batch_evaluation.json")
    
    if not quests_dir.exists():
        print(f"❌ Quests directory not found: {quests_dir}")
        sys.exit(1)
    
    # Create batch evaluator
    evaluator = BatchEvaluator()
    
    try:
        # Run evaluation
        summary = await evaluator.evaluate_all_quests(quests_dir)
        
        # Save results
        evaluator.save_results(output_file)
        
        # Print summary
        evaluator.print_summary()
        
        print(f"\n🎉 Batch evaluation completed successfully!")
        
    except Exception as e:
        print(f"❌ Batch evaluation failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main()) 