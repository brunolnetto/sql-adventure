#!/usr/bin/env python3
"""
Test basic evaluation functionality with an actual SQL file
"""

import sys
import asyncio
from pathlib import Path

# Add the current directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from ..core.evaluators import SQLEvaluator

async def test_basic_evaluation():
    """Test basic evaluation functionality with a real SQL file"""
    
    # Path to the SQL file
    sql_file = Path("../../quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql")
    
    if not sql_file.exists():
        print(f"❌ SQL file not found: {sql_file}")
        return False
    
    print(f"📊 Testing basic evaluation with: {sql_file}")
    
    try:
        # Read SQL content
        sql_content = sql_file.read_text()
        print(f"✅ SQL file read successfully ({len(sql_content)} characters)")
        
        # Test pattern detection (doesn't require API key)
        print("🔍 Testing pattern detection...")
        
        # Create evaluator without API key for basic functionality
        evaluator = SQLEvaluator(api_key="dummy-key")
        
        # Test pattern detection
        patterns = evaluator.detect_sql_patterns(sql_content)
        
        print(f"   Detected patterns: {len(patterns)}")
        for pattern in patterns:
            print(f"      - {pattern.pattern_name} (confidence: {pattern.confidence:.2f})")
        
        # Test metadata extraction
        print("📋 Testing metadata extraction...")
        
        purpose = evaluator._extract_purpose_from_path(sql_file)
        concepts = evaluator._extract_concepts_from_content(sql_content)
        difficulty = evaluator._extract_difficulty_from_path(sql_file)
        
        print(f"   Purpose: {purpose}")
        print(f"   Concepts: {concepts}")
        print(f"   Difficulty: {difficulty}")
        
        # Test SQL content analysis
        print("🔍 Testing SQL content analysis...")
        
        # Check for SQL keywords
        sql_keywords = ['CREATE TABLE', 'INSERT INTO', 'SELECT', 'DROP TABLE']
        found_keywords = []
        
        for keyword in sql_keywords:
            if keyword in sql_content.upper():
                found_keywords.append(keyword)
        
        print(f"   Found SQL keywords: {', '.join(found_keywords)}")
        
        # Check for table creation patterns
        table_creation_count = sql_content.upper().count('CREATE TABLE')
        insert_count = sql_content.upper().count('INSERT INTO')
        select_count = sql_content.upper().count('SELECT')
        
        print(f"   Table creations: {table_creation_count}")
        print(f"   Insert statements: {insert_count}")
        print(f"   Select statements: {select_count}")
        
        # Test file structure analysis
        print("📁 Testing file structure analysis...")
        
        file_info = {
            'filename': sql_file.name,
            'size': len(sql_content),
            'lines': len(sql_content.split('\n')),
            'has_purpose_header': '-- PURPOSE:' in sql_content,
            'has_difficulty_header': '-- DIFFICULTY:' in sql_content,
            'has_concepts_header': '-- CONCEPTS:' in sql_content
        }
        
        print(f"   File: {file_info['filename']}")
        print(f"   Size: {file_info['size']} characters")
        print(f"   Lines: {file_info['lines']}")
        print(f"   Has purpose header: {file_info['has_purpose_header']}")
        print(f"   Has difficulty header: {file_info['has_difficulty_header']}")
        print(f"   Has concepts header: {file_info['has_concepts_header']}")
        
        print("✅ Basic evaluation completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Basic evaluation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(test_basic_evaluation())
    sys.exit(0 if success else 1) 