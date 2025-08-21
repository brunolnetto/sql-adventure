#!/usr/bin/env python3
"""
Evaluation Summary Generator (CLI)
Generates comprehensive reports from the analytics database views
"""

import json
import os
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime
from decimal import Decimal

# Custom JSON encoder for database types
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super(DecimalEncoder, self).default(obj)

# Add the evaluator directory to the path for module imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import EvaluationConfig, ProjectFolderConfig
from reporting.mart import AnalyticsViewManager
from database.manager import DatabaseManager
from database.tables import EvaluationBase

config = EvaluationConfig()

def get_analytics_summary() -> Dict[str, Any]:
    """Get enriched summary from analytics database views"""
    try:
        # Initialize database manager for evaluator database
        db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
        
        # Create analytics manager
        analytics = AnalyticsViewManager(db_manager)
        
        # Create views if they don't exist
        analytics.create_analytics_views()
        
        # Get comprehensive summary with dashboard data
        return analytics.get_dashboard_data()
        
    except Exception as e:
        print(f"❌ Error accessing analytics database: {e}")
        return {"error": f"Database error: {e}"}

def generate_summary_report() -> Dict[str, Any]:
    """Generate summary report using analytics views"""
    return get_analytics_summary()

def print_summary_report(report: Dict[str, Any]):
    """Print an enriched, comprehensive summary report"""
    if "error" in report:
        print(f"❌ {report['error']}")
        return

    print("\n" + "="*80)
    print("📊 SQL ADVENTURE STRATEGIC EVALUATION REPORT")
    print("="*80)

    if 'system_overview' in report:
        overview = report['system_overview']
        quality = report.get('quality_metrics', {})
        activity = report.get('activity_metrics', {})
        insights = report.get('insights', {})
        
        # === EXECUTIVE SUMMARY ===
        total_evals = overview.get('total_evaluations', 0)
        success_rate = quality.get('overall_success_rate', 0)
        avg_score = quality.get('overall_avg_score', 0)
        excellent_rate = quality.get('excellent_evaluations', 0) / max(total_evals, 1) * 100 if total_evals > 0 else 0
        
        print(f"\n📋 EXECUTIVE SUMMARY")
        print("-" * 40)
        
        # System status indicator
        if avg_score >= 8.5 and success_rate >= 80:
            status = "🟢 EXCELLENT"
        elif avg_score >= 7.5 and success_rate >= 70:
            status = "🟡 GOOD PROGRESS"
        elif total_evals > 0:
            status = "🔴 NEEDS ATTENTION"
        else:
            status = "⚪ NOT STARTED"
            
        print(f"  🎯 Overall Status: {status}")
        print(f"  📊 Performance: {avg_score:.1f}/10 average, {success_rate:.1f}% success rate")
        print(f"  🏆 Excellence: {excellent_rate:.1f}% of evaluations rated excellent")
        print(f"  📈 Coverage: {total_evals}/{overview.get('total_sql_files', 0)} files evaluated ({total_evals/max(overview.get('total_sql_files', 1), 1)*100:.1f}%)")
        
        # Quick insights
        high_priority = quality.get('high_priority_issues', 0)
        if high_priority > 0:
            print(f"  � ATTENTION: {high_priority} high-priority issues require immediate action")
        elif excellent_rate >= 80:
            print(f"  ✨ ACHIEVEMENT: Consistently excellent performance across evaluations")
        elif total_evals == 0:
            print(f"  🏁 READY: {overview.get('total_sql_files', 0)} SQL files available for evaluation")

        # === QUEST PROGRESS & RECOMMENDATIONS ===
        if 'quest_breakdown' in report:
            print(f"\n🎯 QUEST PROGRESS & NEXT ACTIONS")
            print("-" * 40)
            quest_breakdown = report['quest_breakdown']
            
            # Sort by evaluation count for better insights
            active_quests = [q for q in quest_breakdown if q.get('evaluation_count', 0) > 0]
            inactive_quests = [q for q in quest_breakdown if q.get('evaluation_count', 0) == 0]
            
            if active_quests:
                print(f"  📊 Active Quest Performance ({len(active_quests)} quests):")
                for quest in active_quests:
                    name = quest.get('quest_display_name', quest.get('quest_name', 'Unknown'))
                    score = quest.get('avg_score', 0) or 0
                    success = quest.get('success_rate', 0) or 0
                    files = quest.get('file_count', 0) or 0
                    evals = quest.get('evaluation_count', 0) or 0
                    excellent = quest.get('excellent_count', 0) or 0
                    
                    # Action-oriented status
                    if score >= 8.5 and success >= 80:
                        status = "� EXCELLENT - Continue advanced challenges"
                    elif score >= 7.5 and success >= 70:
                        status = "🟡 GOOD - Focus on consistency"
                    else:
                        status = "🔴 NEEDS WORK - Review fundamentals"
                    
                    completion = evals / max(files, 1) * 100
                    print(f"     {status}")
                    print(f"     📂 {name}: {completion:.0f}% complete ({evals}/{files} files)")
                    print(f"        Performance: {score:.1f}/10 avg | {success:.1f}% success | {excellent} excellent")
            
            if inactive_quests:
                print(f"\n  🎯 RECOMMENDED NEXT QUESTS ({len(inactive_quests)} available):")
                # Sort by quest number/order for logical progression
                sorted_inactive = sorted(inactive_quests, key=lambda x: x.get('quest_name', ''))
                for i, quest in enumerate(sorted_inactive[:3], 1):  # Show top 3 recommendations
                    name = quest.get('quest_display_name', quest.get('quest_name', 'Unknown'))
                    files = quest.get('file_count', 0) or 0
                    subcats = quest.get('subcategory_count', 0) or 0
                    print(f"     {i}. 🎯 {name}")
                    print(f"        📊 {files} files across {subcats} subcategories - Ready to start")
                
                if len(inactive_quests) > 3:
                    print(f"     ... and {len(inactive_quests) - 3} more quests available for exploration")

        # === KEY PATTERN INSIGHTS ===
        if 'pattern_insights' in report:
            print(f"\n🧩 SQL PATTERN LEARNING INSIGHTS")
            print("-" * 40)
            patterns = report['pattern_insights']
            
            if patterns:
                # Identify strengths and areas for improvement
                strong_patterns = [p for p in patterns if p.get('avg_score_when_used', 0) >= 8.5]
                weak_patterns = [p for p in patterns if p.get('avg_score_when_used', 0) < 7.5 and p.get('usage_count', 0) > 0]
                underused_advanced = [p for p in patterns if p.get('complexity_level') in ['Advanced', 'Expert'] and p.get('usage_count', 0) < 3]
                
                print(f"  💪 PATTERN STRENGTHS ({len(strong_patterns)} patterns mastered):")
                for pattern in strong_patterns[:3]:  # Top 3 strengths
                    name = pattern.get('display_name', pattern.get('name', 'Unknown'))
                    score = pattern.get('avg_score_when_used', 0) or 0
                    usage = pattern.get('usage_count', 0) or 0
                    print(f"     ✅ {name}: {score:.1f}/10 avg ({usage} uses) - Well mastered")
                
                if weak_patterns:
                    print(f"\n  🎯 PATTERNS NEEDING PRACTICE ({len(weak_patterns)} patterns):")
                    for pattern in weak_patterns[:3]:  # Top 3 to improve
                        name = pattern.get('display_name', pattern.get('name', 'Unknown'))
                        score = pattern.get('avg_score_when_used', 0) or 0
                        usage = pattern.get('usage_count', 0) or 0
                        complexity = pattern.get('complexity_level', 'Unknown')
                        print(f"     🔄 {name}: {score:.1f}/10 avg ({usage} uses) - Focus area for {complexity.lower()} level")
                
                if underused_advanced:
                    print(f"\n  � ADVANCED OPPORTUNITIES ({len(underused_advanced)} patterns available):")
                    for pattern in underused_advanced[:3]:  # Top 3 growth opportunities
                        name = pattern.get('display_name', pattern.get('name', 'Unknown'))
                        complexity = pattern.get('complexity_level', 'Unknown')
                        category = pattern.get('category', 'Unknown')
                        print(f"     📈 {name} ({category}): Ready for {complexity.lower()} challenges")
            else:
                print(f"  🔍 Start evaluating SQL files to discover your pattern strengths and opportunities")

        # === PERFORMANCE HIGHLIGHTS ===
        if 'top_performers' in report:
            top_files = report['top_performers']
            if top_files:
                print(f"\n🏆 PERFORMANCE HIGHLIGHTS")
                print("-" * 40)
                print(f"  🌟 Best Examples (for reference and motivation):")
                for i, file in enumerate(top_files[:3], 1):  # Show only top 3
                    path = file.get('relative_path', 'Unknown').split('/')[-1]  # Just filename
                    quest = file.get('quest_name', 'Unknown')
                    grade = file.get('letter_grade', 'N/A')
                    score = file.get('numeric_score', 0) or 0
                    print(f"     {i}. 📄 {path} ({quest}): Grade {grade} ({score}/10)")
                
                if len(top_files) > 3:
                    print(f"     ... and {len(top_files) - 3} more excellent files as examples")

        # === PRIORITY AREAS FOR IMPROVEMENT ===
        if 'improvement_opportunities' in report:
            print(f"\n🔧 PRIORITY IMPROVEMENT TARGETS")
            print("-" * 40)
            improvements = report['improvement_opportunities']
            
            if improvements:
                print(f"  🎯 Files with AI-Generated Recommendations:")
                for i, item in enumerate(improvements[:5], 1):  # Show top 5 with full details
                    filename = item.get('filename', 'Unknown')
                    quest = item.get('quest_name', 'Unknown')
                    score = item.get('latest_score', 0) or 0
                    grade = item.get('latest_grade', 'N/A')
                    high_priority = item.get('high_priority_recommendations', 0) or 0
                    high_priority_text = item.get('high_priority_recommendations_text', '')
                    medium_priority_text = item.get('medium_priority_recommendations_text', '')
                    
                    urgency = "🔴 URGENT" if high_priority > 0 else "🟡 REVIEW"
                    print(f"\n     {i}. {urgency}: {filename} ({quest})")
                    print(f"        📊 Current Performance: {score}/10 (Grade {grade})")
                    
                    if high_priority > 0 and high_priority_text and high_priority_text != 'No high priority recommendations':
                        print(f"        🚨 HIGH PRIORITY ACTIONS:")
                        # Split multiple recommendations by |
                        high_recs = high_priority_text.split(' | ')
                        for j, rec in enumerate(high_recs, 1):
                            print(f"           {j}. {rec.strip()}")
                    
                    if medium_priority_text and medium_priority_text != 'No medium priority recommendations':
                        print(f"        📋 Additional Improvements:")
                        # Split multiple recommendations by |
                        medium_recs = medium_priority_text.split(' | ')
                        for j, rec in enumerate(medium_recs[:2], 1):  # Show top 2 medium priority
                            print(f"           • {rec.strip()}")
                
                if len(improvements) > 5:
                    print(f"\n     ... and {len(improvements) - 5} additional files have recommendations")
                    print(f"         Use detailed analytics to view all recommendations")
            else:
                print(f"  ✨ Excellent! No improvement opportunities identified")
                print(f"     All evaluated files are performing well")

        # === STRATEGIC RECOMMENDATIONS FROM SYSTEM ANALYSIS ===
        print(f"\n🎯 STRATEGIC RECOMMENDATIONS & ACTION PLAN")
        print("=" * 60)
        
        # Get actual recommendations from our system
        recommendations = report.get('improvement_opportunities', [])
        
        # Get detailed recommendations if available
        detailed_recommendations = []
        if 'recent_evaluations' in report:
            # Extract recommendations from recent evaluations if needed
            for eval_data in report['recent_evaluations'][:10]:
                if eval_data.get('high_priority_recommendations', 0) > 0:
                    detailed_recommendations.append({
                        'filename': eval_data.get('filename', 'Unknown'),
                        'quest': eval_data.get('quest_display_name', 'Unknown'),
                        'score': eval_data.get('numeric_score', 0),
                        'high_priority_count': eval_data.get('high_priority_recommendations', 0)
                    })
        
        # === IMMEDIATE ACTIONS (HIGH PRIORITY) ===
        high_priority_files = [rec for rec in recommendations if rec.get('high_priority_recommendations', 0) > 0]
        
        if high_priority_files:
            print(f"\n🚨 IMMEDIATE ACTIONS REQUIRED:")
            for i, file_rec in enumerate(high_priority_files[:3], 1):
                filename = file_rec.get('filename', 'Unknown')
                quest = file_rec.get('quest_name', 'Unknown')
                score = file_rec.get('latest_score', 0)
                high_priority_count = file_rec.get('high_priority_recommendations', 0)
                issues = file_rec.get('primary_issues', 'No details available')
                
                print(f"   {i}. 🚨 URGENT: {filename} ({quest})")
                print(f"      Current Score: {score}/10 | {high_priority_count} critical issues")
                print(f"      Focus Areas: {issues}")
        
        # === FOCUS AREAS FROM SYSTEM RECOMMENDATIONS ===
        medium_priority_files = [rec for rec in recommendations 
                               if rec.get('high_priority_recommendations', 0) == 0 
                               and rec.get('latest_score', 10) < 8]
        
        if medium_priority_files:
            print(f"\n📋 FOCUS AREAS (Medium Priority):")
            for i, file_rec in enumerate(medium_priority_files[:3], 1):
                filename = file_rec.get('filename', 'Unknown')
                quest = file_rec.get('quest_name', 'Unknown')
                score = file_rec.get('latest_score', 0)
                issues = file_rec.get('primary_issues', 'General improvements needed')
                
                print(f"   {i}. 📈 IMPROVE: {filename} ({quest})")
                print(f"      Current Score: {score}/10 | Areas: {issues}")
        
        # === SYSTEM-WIDE RECOMMENDATIONS ===
        total_evals = overview.get('total_evaluations', 0)
        success_rate = quality.get('overall_success_rate', 0)
        avg_score = quality.get('overall_avg_score', 0)
        high_priority_total = quality.get('high_priority_issues', 0)
        medium_priority_total = quality.get('medium_priority_issues', 0)
        
        print(f"\n💡 SYSTEM-WIDE IMPROVEMENT OPPORTUNITIES:")
        
        system_recommendations = []
        
        if success_rate < 70:
            system_recommendations.append(f"� CRITICAL: Improve SQL execution success rate from {success_rate:.1f}% to >80%")
        elif success_rate < 90:
            system_recommendations.append(f"⚙️  Fine-tune execution reliability (current: {success_rate:.1f}%)")
        
        if total_evals < 50:
            system_recommendations.append(f"📊 Continue building evaluation data (current: {total_evals}, target: 50+)")
        
        if avg_score < 7.0:
            system_recommendations.append(f"📚 Review basic SQL patterns and best practices (avg: {avg_score:.1f}/10)")
        elif avg_score < 8.5:
            system_recommendations.append(f"🔍 Focus on advanced SQL techniques and optimization (avg: {avg_score:.1f}/10)")
        else:
            system_recommendations.append(f"🌟 Explore complex scenarios and edge cases (excellent foundation: {avg_score:.1f}/10)")
        
        if medium_priority_total > 0:
            system_recommendations.append(f"📋 Address {medium_priority_total} medium-priority recommendations across all files")
        
        # Quest-specific recommendations
        if 'quest_breakdown' in report:
            pending_quests = [q for q in report['quest_breakdown'] if q.get('evaluation_count', 0) == 0]
            low_performing = [q for q in report['quest_breakdown'] if (q.get('avg_score') or 0) < 8.0 and q.get('evaluation_count', 0) > 0]
            
            if pending_quests:
                quest_names = [q.get('quest_display_name', 'Unknown') for q in pending_quests[:3]]
                system_recommendations.append(f"🗂️  Evaluate pending quests: {', '.join(quest_names)}")
            
            if low_performing:
                quest_name = low_performing[0].get('quest_display_name', 'Unknown')
                score = low_performing[0].get('avg_score', 0)
                system_recommendations.append(f"📈 Revisit {quest_name} for improvement (current: {score:.1f}/10)")
        
        for i, rec in enumerate(system_recommendations, 1):
            print(f"   {i}. {rec}")
        
        # === SYSTEM INSIGHTS ===
        if insights:
            print(f"\n💡 KEY PERFORMANCE INSIGHTS:")
            print(f"   🎯 Most Active: {insights.get('most_active_quest', 'None')} - continue momentum here")
            print(f"   🏅 Highest Quality: {insights.get('highest_scoring_quest', 'None')} - model for other quests")
            print(f"   💪 System Health: {insights.get('system_health', 'Unknown')} - overall trajectory")
        
        # === SUCCESS TARGETS ===
        print(f"\n📈 SUCCESS TARGETS:")
        target_success = 85 if success_rate >= 70 else 75
        target_score = 9.0 if avg_score >= 8.5 else 8.5
        excellent_rate = quality.get('excellent_evaluations', 0) / max(total_evals, 1) * 100 if total_evals > 0 else 0
        target_excellent = 90 if excellent_rate >= 80 else 80
        
        print(f"   🎯 Success Rate: {success_rate:.1f}% → {target_success}%")
        print(f"   📊 Average Score: {avg_score:.1f}/10 → {target_score}/10")
        print(f"   ⭐ Excellence Rate: {excellent_rate:.1f}% → {target_excellent}%")
        
        if high_priority_total == 0 and medium_priority_total == 0:
            print(f"   ✨ Issue Resolution: Complete! Maintain quality standards")
        else:
            print(f"   🔧 Priority Issues: {high_priority_total} high, {medium_priority_total} medium - Address systematically")
    
    else:
        # Fallback to basic display if structure is different
        print(f"\n📄 BASIC SUMMARY")
        print("-" * 40)
        for key, value in report.items():
            if key not in ['error', 'generated_at']:
                print(f"  {key}: {value}")
    
    print(f"\n" + "="*80)
    print(f"📊 FOCUS ON STRATEGIC ACTIONS ABOVE FOR MAXIMUM IMPACT")
    print(f"⏰ Report Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*80)

def save_summary_report(report: Dict[str, Any], output_file: str):
    """Save summary report to JSON file"""
    try:
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2, cls=DecimalEncoder)
        print(f"✅ Report saved to: {output_file}")
    except Exception as e:
        print(f"❌ Failed to save report: {e}")

def main():
    parser = argparse.ArgumentParser(description="Generate SQL evaluation summary report using analytics database")
    parser.add_argument("--print", action="store_true", help="Print the summary to console")
    parser.add_argument("--save", metavar="FILE", help="Save the summary report to a JSON file")
    args = parser.parse_args()

    print("🔍 Loading evaluations...")
    report = generate_summary_report()

    if args.print or not args.save:  # Default to print if no save specified
        print_summary_report(report)

    if args.save:
        save_summary_report(report, args.save)

if __name__ == "__main__":
    main()
