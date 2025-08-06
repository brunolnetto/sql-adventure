#!/usr/bin/env python3
"""
Evaluation Summary Generator
Creates comprehensive reports from AI evaluation results
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime

def load_evaluation_results(evaluations_dir: str = "ai-evaluations") -> List[Dict[str, Any]]:
    """Load all evaluation results from JSON files"""
    results = []
    evaluations_path = Path(evaluations_dir)
    
    if not evaluations_path.exists():
        print(f"❌ Evaluations directory not found: {evaluations_dir}")
        return results
    
    # Find all JSON files
    json_files = list(evaluations_path.rglob("*.json"))
    print(f"📁 Found {len(json_files)} evaluation files")
    
    for json_file in json_files:
        try:
            with open(json_file, 'r') as f:
                data = json.load(f)
                results.append(data)
        except Exception as e:
            print(f"❌ Error loading {json_file}: {e}")
    
    return results

def generate_summary_report(results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Generate a comprehensive summary report"""
    if not results:
        return {"error": "No evaluation results found"}
    
    # Initialize counters
    total_files = len(results)
    successful_executions = 0
    failed_executions = 0
    total_score = 0
    assessment_counts = {"PASS": 0, "FAIL": 0, "NEEDS_REVIEW": 0}
    quest_stats = {}
    pattern_usage = {}
    
    # Process each result
    for result in results:
        # Execution stats
        if result.get("execution", {}).get("success", False):
            successful_executions += 1
        else:
            failed_executions += 1
        
        # Score stats
        score = result.get("basic_evaluation", {}).get("score", 0)
        total_score += score
        
        # Assessment stats
        assessment = result.get("basic_evaluation", {}).get("overall_assessment", "UNKNOWN")
        assessment_counts[assessment] = assessment_counts.get(assessment, 0) + 1
        
        # Quest stats
        quest_name = result.get("metadata", {}).get("quest", "unknown")
        if quest_name not in quest_stats:
            quest_stats[quest_name] = {
                "total_files": 0,
                "successful_executions": 0,
                "failed_executions": 0,
                "total_score": 0,
                "assessments": {"PASS": 0, "FAIL": 0, "NEEDS_REVIEW": 0}
            }
        
        quest_stats[quest_name]["total_files"] += 1
        if result.get("execution", {}).get("success", False):
            quest_stats[quest_name]["successful_executions"] += 1
        else:
            quest_stats[quest_name]["failed_executions"] += 1
        quest_stats[quest_name]["total_score"] += score
        quest_stats[quest_name]["assessments"][assessment] += 1
        
        # Pattern usage
        patterns = result.get("intent", {}).get("sql_patterns", [])
        for pattern in patterns:
            pattern_usage[pattern] = pattern_usage.get(pattern, 0) + 1
    
    # Calculate averages
    avg_score = total_score / total_files if total_files > 0 else 0
    success_rate = (successful_executions / total_files) * 100 if total_files > 0 else 0
    
    # Generate report
    report = {
        "summary": {
            "total_files": total_files,
            "successful_executions": successful_executions,
            "failed_executions": failed_executions,
            "success_rate": round(success_rate, 2),
            "average_score": round(avg_score, 2),
            "assessment_distribution": assessment_counts
        },
        "quest_performance": quest_stats,
        "pattern_analysis": {
            "most_used_patterns": sorted(pattern_usage.items(), key=lambda x: x[1], reverse=True)[:10],
            "pattern_usage": pattern_usage
        },
        "generated_at": datetime.now().isoformat()
    }
    
    return report

def save_summary_report(report: Dict[str, Any], output_file: str = "evaluation_summary.json"):
    """Save the summary report to a JSON file"""
    try:
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)
        print(f"✅ Summary report saved to: {output_file}")
    except Exception as e:
        print(f"❌ Error saving summary report: {e}")

def print_summary_report(report: Dict[str, Any]):
    """Print a formatted summary report to console"""
    if "error" in report:
        print(f"❌ {report['error']}")
        return
    
    summary = report["summary"]
    
    print("\n" + "="*60)
    print("📊 SQL ADVENTURE EVALUATION SUMMARY REPORT")
    print("="*60)
    
    print(f"\n📈 OVERALL STATISTICS:")
    print(f"   Total Files Evaluated: {summary['total_files']}")
    print(f"   Successful Executions: {summary['successful_executions']}")
    print(f"   Failed Executions: {summary['failed_executions']}")
    print(f"   Success Rate: {summary['success_rate']}%")
    print(f"   Average Score: {summary['average_score']}/10")
    
    print(f"\n📋 ASSESSMENT DISTRIBUTION:")
    for assessment, count in summary['assessment_distribution'].items():
        percentage = (count / summary['total_files']) * 100
        print(f"   {assessment}: {count} files ({percentage:.1f}%)")
    
    print(f"\n🏆 QUEST PERFORMANCE:")
    for quest_name, stats in report["quest_performance"].items():
        quest_success_rate = (stats["successful_executions"] / stats["total_files"]) * 100
        quest_avg_score = stats["total_score"] / stats["total_files"]
        print(f"   {quest_name}:")
        print(f"     Files: {stats['total_files']}, Success Rate: {quest_success_rate:.1f}%, Avg Score: {quest_avg_score:.1f}/10")
    
    print(f"\n🔍 TOP SQL PATTERNS:")
    for pattern, count in report["pattern_analysis"]["most_used_patterns"][:5]:
        percentage = (count / summary['total_files']) * 100
        print(f"   {pattern}: {count} files ({percentage:.1f}%)")
    
    print(f"\n📅 Generated: {report['generated_at']}")
    print("="*60)

def main():
    """Main function"""
    print("🔍 Loading evaluation results...")
    results = load_evaluation_results()
    
    if not results:
        print("❌ No evaluation results found")
        return
    
    print("📊 Generating summary report...")
    report = generate_summary_report(results)
    
    # Print to console
    print_summary_report(report)
    
    # Save to file
    save_summary_report(report)

if __name__ == "__main__":
    main() 