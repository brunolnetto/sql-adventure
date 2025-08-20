#!/usr/bin/env python3
"""
Initialize or recreate analytics views only
Useful for fixing mart views without full database recreation
"""

import sys
import os
from pathlib import Path

# Add the parent directory to sys.path to import modules
sys.path.insert(0, str(Path(__file__).parent))

from database.manager import DatabaseManager, get_evaluator_connection_string
from database.tables import EvaluationBase
from reporting.mart import AnalyticsViewManager
from config import load_evaluator_env

def main():
    """Main function to recreate analytics views only"""
    print("🔍 Recreating SQL Adventure Analytics Views")
    
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
        
        print("🗃️ Recreating analytics views...")
        success = analytics_view_manager.create_analytics_views()
        
        if success:
            print("✅ Analytics views recreated successfully!")
            print("\n📊 Available views:")
            print("   - evaluation_summary: Comprehensive evaluation details")
            print("   - quest_performance: Quest-level analytics and metrics")
            print("   - pattern_analysis: SQL pattern usage analysis")
            print("   - file_progress: Individual file tracking and status")
            print("   - recommendations_dashboard: Actionable insights")
            print("\n🎉 Analytics system is ready for queries!")
            return True
        else:
            print("❌ Failed to create analytics views")
            return False
        
    except Exception as e:
        print(f"❌ Analytics view initialization failed: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
