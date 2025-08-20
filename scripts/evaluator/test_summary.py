#!/usr/bin/env python3
"""
Test the comprehensive summary functionality
"""

import sys
import os
from pathlib import Path
import json

# Add the parent directory to sys.path to import modules
sys.path.insert(0, str(Path(__file__).parent))

from database.manager import DatabaseManager, get_evaluator_connection_string
from database.tables import EvaluationBase
from reporting.mart import AnalyticsViewManager
from config import load_evaluator_env

def main():
    """Test the comprehensive summary functionality"""
    print("📊 Testing SQL Adventure Comprehensive Summary")
    
    try:
        # Load environment
        load_evaluator_env()
        print("📋 Environment loaded successfully")
        
        # Get connection string for evaluator database
        connection_string = get_evaluator_connection_string()
        print(f"📡 Using evaluator database: {connection_string.split('@')[1]}")
        
        # Initialize evaluator database manager
        db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
        print("✅ Database connection established")
        
        # Create analytics view manager
        analytics_view_manager = AnalyticsViewManager(db_manager)
        
        print("🔍 Getting comprehensive summary...")
        summary = analytics_view_manager.get_comprehensive_summary()
        
        if 'error' in summary:
            print(f"❌ Error getting summary: {summary['error']}")
            return False
        
        print("✅ Comprehensive summary generated successfully!")
        print("\n" + "="*60)
        print("📈 SQL ADVENTURE SYSTEM SUMMARY")
        print("="*60)
        
        # System Overview
        overview = summary['system_overview']
        print(f"\n🎯 SYSTEM OVERVIEW:")
        print(f"   • Total Quests: {overview['total_quests']}")
        print(f"   • Total Subcategories: {overview['total_subcategories']}")
        print(f"   • Total SQL Files: {overview['total_sql_files']}")
        print(f"   • Total Evaluations: {overview['total_evaluations']}")
        print(f"   • SQL Patterns Available: {overview['total_patterns']}")
        print(f"   • Pattern Categories: {overview['pattern_categories']}")
        
        # Quality Metrics
        quality = summary['quality_metrics']
        print(f"\n📊 QUALITY METRICS:")
        print(f"   • Overall Average Score: {quality['overall_avg_score']}/10")
        print(f"   • Overall Success Rate: {quality['overall_success_rate']}%")
        print(f"   • Excellent Evaluations (A grades): {quality['excellent_evaluations']} ({quality['excellent_percentage']}%)")
        print(f"   • Good Evaluations (B grades): {quality['good_evaluations']}")
        print(f"   • Fair Evaluations (C grades): {quality['fair_evaluations']}")
        print(f"   • Poor Evaluations (D/F grades): {quality['poor_evaluations']}")
        print(f"   • High Priority Issues: {quality['high_priority_issues']}")
        print(f"   • Medium Priority Issues: {quality['medium_priority_issues']}")
        
        # Activity Metrics
        activity = summary['activity_metrics']
        print(f"\n🔄 ACTIVITY METRICS:")
        print(f"   • Evaluations Last Day: {activity['evaluations_last_day']}")
        print(f"   • Evaluations Last Week: {activity['evaluations_last_week']}")
        print(f"   • Evaluations Last Month: {activity['evaluations_last_month']}")
        print(f"   • Recent Activity: {activity['recent_activity_percentage']}%")
        
        # Quest Breakdown
        print(f"\n🎮 QUEST BREAKDOWN:")
        for quest in summary['quest_breakdown']:
            print(f"   • {quest['quest_display_name']}:")
            print(f"     - Files: {quest['file_count'] or 0}, Evaluations: {quest['evaluation_count'] or 0}")
            print(f"     - Avg Score: {quest['avg_score'] or 'N/A'}, Success Rate: {quest['success_rate'] or 'N/A'}%")
            print(f"     - Excellent: {quest['excellent_count'] or 0}, Issues: {quest['high_priority_issues'] or 0}")
        
        # Top Performers
        if summary['top_performers']:
            print(f"\n🏆 TOP PERFORMING FILES:")
            for performer in summary['top_performers'][:5]:  # Show top 5
                print(f"   • {performer['filename']} ({performer['quest_name']})")
                print(f"     - Grade: {performer['letter_grade']}, Score: {performer['numeric_score']}")
                print(f"     - Patterns: {performer['pattern_count']}")
        
        # Pattern Insights
        if summary['pattern_insights']:
            print(f"\n🧩 PATTERN INSIGHTS:")
            for pattern in summary['pattern_insights'][:5]:  # Show top 5
                print(f"   • {pattern['display_name']} ({pattern['complexity_level']})")
                print(f"     - Used: {pattern['usage_count']} times, Avg Score: {pattern['avg_score_when_used'] or 'N/A'}")
        
        # System Insights
        insights = summary['insights']
        print(f"\n💡 SYSTEM INSIGHTS:")
        print(f"   • Most Active Quest: {insights['most_active_quest']}")
        print(f"   • Highest Scoring Quest: {insights['highest_scoring_quest']}")
        print(f"   • Patterns with Analysis: {insights['patterns_with_analysis']}")
        print(f"   • System Health: {insights['system_health']}")
        
        print("\n" + "="*60)
        print("🎉 Summary complete! System is ready for learning and evaluation.")
        print("="*60)
        
        return True
        
    except Exception as e:
        print(f"❌ Summary test failed: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
