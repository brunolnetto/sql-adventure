#!/usr/bin/env python3
"""
Test script for the pydantic-ai SQL evaluator
"""

import os
import asyncio
from pathlib import Path

# Import from the current directory
from ai_evaluator import SQLEvaluator

async def test_evaluator():
    """Test the SQL evaluator with a sample file"""
    
    # Load API key
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("❌ OPENAI_API_KEY not found in environment")
        print("Please set your OpenAI API key:")
        print("export OPENAI_API_KEY='your-api-key-here'")
        return
    
    print("✅ API key loaded")
    
    # Initialize evaluator
    evaluator = SQLEvaluator(api_key)
    print("✅ Evaluator initialized")
    
    # Find a test SQL file
    test_file = Path("quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql")
    
    if not test_file.exists():
        print(f"❌ Test file not found: {test_file}")
        return
    
    print(f"✅ Found test file: {test_file}")
    
    try:
        # Evaluate the file
        print("🤖 Running AI evaluation...")
        result = await evaluator.evaluate_sql_file(test_file)
        
        print("✅ Evaluation completed successfully!")
        print(f"📊 Score: {result.llm_analysis.assessment.score}/10")
        print(f"📈 Grade: {result.llm_analysis.assessment.grade}")
        print(f"🎯 Assessment: {result.llm_analysis.assessment.overall_assessment}")
        
        # Save result
        output_dir = Path("ai-evaluations") / test_file.parts[-3] / test_file.parts[-2]
        output_dir.mkdir(parents=True, exist_ok=True)
        
        output_file = output_dir / f"{test_file.stem}.json"
        output_file.write_text(result.model_dump_json(indent=2))
        
        print(f"💾 Result saved to: {output_file}")
        
        # Save to database
        db_saved = await evaluator.save_evaluation_to_db(result)
        if db_saved:
            print(f"✅ Evaluation saved to database")
        else:
            print(f"⚠️  Failed to save to database")
        
        # Show some details
        print("\n📋 Evaluation Summary:")
        print(f"  - Technical Quality: {result.llm_analysis.technical_analysis.code_quality}")
        print(f"  - Learning Value: {result.llm_analysis.educational_analysis.learning_value}")
        print(f"  - Difficulty: {result.llm_analysis.educational_analysis.difficulty_level}")
        print(f"  - Time Estimate: {result.llm_analysis.educational_analysis.time_estimate}")
        
        print(f"\n💡 Recommendations:")
        for i, rec in enumerate(result.llm_analysis.recommendations[:3], 1):
            print(f"  {i}. {rec}")
        
        # Show evaluation history
        print(f"\n📚 Recent Evaluations:")
        history = evaluator.get_evaluation_history(limit=3)
        for eval_record in history:
            print(f"  - {eval_record['filename']}: {eval_record['grade']} ({eval_record['score']}/10)")
        
    except Exception as e:
        print(f"❌ Error during evaluation: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_evaluator()) 