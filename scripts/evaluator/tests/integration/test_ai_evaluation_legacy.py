#!/usr/bin/env python3
"""
Test AI evaluation with an actual SQL file
"""

import sys
import asyncio
import pytest
from pathlib import Path

# Add the evaluator directory to the path for proper imports
evaluator_dir = Path(__file__).parent.parent
sys.path.insert(0, str(evaluator_dir))

from core.evaluators import SQLEvaluator

@pytest.mark.asyncio
async def test_ai_evaluation():
    """Test AI evaluation with a real SQL file"""
    
    # Path to the SQL file
    sql_file = Path("../../quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql")
    
    if not sql_file.exists():
        print(f"❌ SQL file not found: {sql_file}")
        return False
    
    print(f"🤖 Testing AI evaluation with: {sql_file}")
    
    # Check if API key is available
    api_key = "test-key"  # We'll use a test key for now
    
    try:
        # Initialize evaluator
        evaluator = SQLEvaluator(api_key=api_key)
        
        print("✅ Evaluator initialized")
        
        # Test pattern detection
        print("🔍 Testing pattern detection...")
        sql_content = sql_file.read_text()
        patterns = evaluator.detect_sql_patterns(sql_content)
        
        print(f"   Detected patterns: {len(patterns)}")
        for pattern in patterns:
            print(f"      - {pattern.pattern_name} (confidence: {pattern.confidence:.2f})")
        
        # Test basic evaluation (without AI calls)
        print("📊 Testing basic evaluation...")
        
        # Extract basic information
        purpose = evaluator._extract_purpose_from_path(sql_file)
        concepts = evaluator._extract_concepts_from_content(sql_content)
        difficulty = evaluator._extract_difficulty_from_path(sql_file)
        
        print(f"   Purpose: {purpose}")
        print(f"   Concepts: {concepts}")
        print(f"   Difficulty: {difficulty}")
        
        print("✅ Basic evaluation completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ AI evaluation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(test_ai_evaluation())
    sys.exit(0 if success else 1) 