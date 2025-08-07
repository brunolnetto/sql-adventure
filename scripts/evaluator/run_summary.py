#!/usr/bin/env python3
"""
Evaluation Summary Generator (CLI)
Generates and optionally saves/prints comprehensive reports from AI evaluation results
"""

import json
import argparse
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime

from config import ProjectFolderConfig

project_cfg = ProjectFolderConfig()
evaluations_path = project_cfg.evaluations_dir

def load_evaluation_results() -> List[Dict[str, Any]]:
    results = []
    if not evaluations_path.exists():
        print(f"\u274c Evaluations directory not found: {evaluations_path}")
        return results

    for json_file in evaluations_path.rglob("*.json"):
        try:
            with open(json_file, 'r') as f:
                results.append(json.load(f))
        except Exception as e:
            print(f"\u274c Error loading {json_file}: {e}")
    return results

def generate_summary_report(results: List[Dict[str, Any]]) -> Dict[str, Any]:
    if not results:
        return {"error": "No evaluation results found"}

    total_files = len(results)
    successful_executions = sum(1 for r in results if r.get("execution", {}).get("success", False))
    failed_executions = total_files - successful_executions
    total_score = sum(r.get("basic_evaluation", {}).get("score", 0) for r in results)
    assessment_counts = {}
    quest_stats = {}
    pattern_usage = {}

    for result in results:
        assessment = result.get("basic_evaluation", {}).get("overall_assessment", "UNKNOWN")
        assessment_counts[assessment] = assessment_counts.get(assessment, 0) + 1

        quest = result.get("metadata", {}).get("quest", "unknown")
        quest_stats.setdefault(quest, {
            "total_files": 0, "successful_executions": 0,
            "failed_executions": 0, "total_score": 0,
            "assessments": {"PASS": 0, "FAIL": 0, "NEEDS_REVIEW": 0}
        })
        quest_stats[quest]["total_files"] += 1
        quest_stats[quest]["total_score"] += result.get("basic_evaluation", {}).get("score", 0)
        quest_stats[quest]["assessments"][assessment] = quest_stats[quest]["assessments"].get(assessment, 0) + 1
        if result.get("execution", {}).get("success", False):
            quest_stats[quest]["successful_executions"] += 1
        else:
            quest_stats[quest]["failed_executions"] += 1

        for pattern in result.get("intent", {}).get("sql_patterns", []):
            pattern_usage[pattern] = pattern_usage.get(pattern, 0) + 1

    avg_score = total_score / total_files if total_files else 0
    success_rate = (successful_executions / total_files) * 100 if total_files else 0

    return {
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

def save_summary_report(report: Dict[str, Any], output_file: str):
    try:
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)
        print(f"\u2705 Report saved to: {output_file}")
    except Exception as e:
        print(f"\u274c Failed to save report: {e}")

def print_summary_report(report: Dict[str, Any]):
    if "error" in report:
        print(f"\u274c {report['error']}")
        return

    s = report["summary"]
    print("\n" + "="*60)
    print("\U0001F4CA SQL ADVENTURE EVALUATION SUMMARY REPORT")
    print("="*60)
    print(f"\nTotal Files: {s['total_files']}, Success: {s['successful_executions']}, Failures: {s['failed_executions']}")
    print(f"Success Rate: {s['success_rate']}%\nAvg Score: {s['average_score']}/10\n")

    print("Assessments:")
    for k, v in s['assessment_distribution'].items():
        pct = (v / s['total_files']) * 100
        print(f"  {k}: {v} ({pct:.1f}%)")

    print("\nTop Patterns:")
    for pattern, count in report['pattern_analysis']['most_used_patterns']:
        pct = (count / s['total_files']) * 100
        print(f"  {pattern}: {count} ({pct:.1f}%)")

    print("\nGenerated at:", report["generated_at"])
    print("="*60)

def main():
    parser = argparse.ArgumentParser(description="Generate SQL evaluation summary report")
    parser.add_argument("--print", action="store_true", help="Print the summary to console")
    parser.add_argument("--save", metavar="FILE", help="Save the summary report to a JSON file")
    args = parser.parse_args()

    print("\U0001F50D Loading evaluations...")
    results = load_evaluation_results()
    report = generate_summary_report(results)

    if args.print:
        print_summary_report(report)

    if args.save:
        save_summary_report(report, args.save)

if __name__ == "__main__":
    main()
