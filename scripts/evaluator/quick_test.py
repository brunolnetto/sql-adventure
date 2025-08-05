#!/usr/bin/env python3
"""
Quick test for the evaluator with database integration
"""

import os
import asyncio
from pathlib import Path

# Test imports
try:
    from ai_evaluator import SQLEvaluator
    from database import DatabaseManager
    print("✅ All imports successful")
except ImportError as e:
    print(f"❌ Import error: {e}")
    exit(1)

async def quick_test():
    """Quick test of the evaluator"""
    
    print("=== Quick Test ===")
    
    # Check API key
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("❌ OPENAI_API_KEY not found")
        return
    
    print("✅ API key available")
    
    # Test database connection
    try:
        db_manager = DatabaseManager()
        print("✅ Database manager initialized")
    except Exception as e:
        print(f"⚠️  Database connection failed: {e}")
        db_manager = None
    
    # Test evaluator initialization
    try:
        evaluator = SQLEvaluator(api_key, db_manager)
        print("✅ Evaluator initialized")
    except Exception as e:
        print(f"❌ Evaluator initialization failed: {e}")
        return
    
    # Test pattern detection
    test_sql = "CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(50)); SELECT * FROM users;"
    patterns = evaluator.detect_sql_patterns(test_sql)
    print(f"✅ Pattern detection: Found {len(patterns)} patterns")
    
    # Test path extraction
    test_path = Path("quests/1-data-modeling/00-basic-concepts/test.sql")
    purpose = evaluator._extract_purpose_from_path(test_path)
    difficulty = evaluator._extract_difficulty_from_path(test_path)
    concepts = evaluator._extract_concepts_from_content(test_sql)
    
    print(f"✅ Path extraction: {purpose} | {difficulty} | {concepts}")
    
    print("✅ Quick test completed successfully!")

if __name__ == "__main__":
    asyncio.run(quick_test()) 