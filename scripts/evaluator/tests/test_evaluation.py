#!/usr/bin/env python3
"""
Test evaluation of a quest file
"""

import os
import asyncio
import sys
from pathlib import Path

# Add the parent directory to the path so we can import the evaluator modules
sys.path.append(str(Path(__file__).parent))

from ai_evaluator import SQLEvaluator

async def test_evaluation():
    """Test evaluation of a quest file"""
    
    print("🚀 Starting SQL Adventure Evaluator Test")
    print("=" * 50)
    
    # Set up API key
    api_key = "sk-proj-api-key"
    
    # Initialize evaluator
    print("📋 Initializing evaluator...")
    evaluator = SQLEvaluator(api_key=api_key)
    print("✅ Evaluator initialized successfully")
    
    # Test file path
    test_file = Path("../../quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql")
    
    if not test_file.exists():
        print(f"❌ Test file not found: {test_file}")
        return
    
    print(f"📁 Evaluating file: {test_file}")
    
    # Read the SQL content
    with open(test_file, 'r') as f:
        sql_content = f.read()
    
    print(f"📄 SQL content length: {len(sql_content)} characters")
    print("📄 SQL content preview:")
    print("-" * 40)
    print(sql_content[:500] + "..." if len(sql_content) > 500 else sql_content)
    print("-" * 40)
    
    # Test pattern detection
    print("\n🔍 Testing pattern detection...")
    patterns = evaluator.detect_sql_patterns(sql_content)
    print(f"✅ Found {len(patterns)} SQL patterns:")
    for pattern in patterns:
        print(f"   - {pattern.pattern_name} (confidence: {pattern.confidence:.2f})")
    
    # Test path analysis
    print("\n📊 Testing path analysis...")
    purpose = evaluator._extract_purpose_from_path(test_file)
    difficulty = evaluator._extract_difficulty_from_path(test_file)
    concepts = evaluator._extract_concepts_from_content(sql_content)
    
    print(f"   Purpose: {purpose}")
    print(f"   Difficulty: {difficulty}")
    print(f"   Concepts: {concepts}")
    
    # Test AI analysis (this will make API calls)
    print("\n🤖 Testing AI analysis...")
    try:
        llm_analysis = await evaluator.analyze_sql_output(
            sql_content=sql_content,
            quest_name="1-data-modeling",
            purpose=purpose,
            difficulty=difficulty,
            concepts=concepts,
            output_content="Sample output would go here",
            sql_patterns=[p.pattern_name for p in patterns]
        )
        
        print("✅ AI analysis completed successfully!")
        print(f"   Grade: {llm_analysis.assessment.grade}")
        print(f"   Score: {llm_analysis.assessment.score}/10")
        print(f"   Assessment: {llm_analysis.assessment.overall_assessment}")
        print(f"   Difficulty Level: {llm_analysis.educational_analysis.difficulty_level}")
        print(f"   Time Estimate: {llm_analysis.educational_analysis.time_estimate}")
        
        print("\n📝 Technical Analysis:")
        print(f"   Syntax: {llm_analysis.technical_analysis.syntax_correctness}")
        print(f"   Logic: {llm_analysis.technical_analysis.logical_structure}")
        print(f"   Quality: {llm_analysis.technical_analysis.code_quality}")
        
        print("\n🎓 Educational Analysis:")
        print(f"   Learning Value: {llm_analysis.educational_analysis.learning_value}")
        print(f"   Prerequisites: {', '.join(llm_analysis.educational_analysis.prerequisites)}")
        
        print("\n💡 Recommendations:")
        for i, rec in enumerate(llm_analysis.recommendations, 1):
            print(f"   {i}. {rec}")
            
    except Exception as e:
        print(f"❌ AI analysis failed: {e}")
    
    print("\n✅ Test completed!")

if __name__ == "__main__":
    asyncio.run(test_evaluation()) 
