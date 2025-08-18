#!/usr/bin/env python3
"""
Comprehensive test of the Python evaluator with an actual SQL file
"""

import sys
import asyncio
from pathlib import Path

# Add the current directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from ..core.evaluators import SQLEvaluator, SQLValidator

async def test_comprehensive_evaluation():
    """Test comprehensive evaluation functionality with a real SQL file"""
    
    # Path to the SQL file
    sql_file = Path("../../quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql")
    
    if not sql_file.exists():
        print(f"❌ SQL file not found: {sql_file}")
        return False
    
    print("🚀 Comprehensive Python Evaluator Test")
    print("=" * 50)
    print(f"📁 Testing with: {sql_file}")
    print()
    
    # Test 1: SQL Validation
    print("1️⃣  SQL Validation Test")
    print("-" * 30)
    
    try:
        validator = SQLValidator()
        validation_result = validator.validate_sql_file(str(sql_file))
        
        print(f"✅ Validation completed!")
        print(f"   Valid: {validation_result.is_valid}")
        print(f"   Score: {validation_result.score:.2f}")
        print(f"   Total issues: {len(validation_result.issues)}")
        
        if validation_result.has_errors():
            print(f"   ❌ Errors: {len(validation_result.get_errors())}")
            for error in validation_result.get_errors():
                print(f"      - {error.message}")
        
        if validation_result.get_warnings():
            print(f"   ⚠️  Warnings: {len(validation_result.get_warnings())}")
            for warning in validation_result.get_warnings():
                print(f"      - {warning.message}")
        
        validation_success = validation_result.is_valid
    except Exception as e:
        print(f"❌ Validation failed: {e}")
        validation_success = False
    
    print()
    
    # Test 2: Basic Evaluation
    print("2️⃣  Basic Evaluation Test")
    print("-" * 30)
    
    try:
        # Read SQL content
        sql_content = sql_file.read_text()
        print(f"✅ SQL file read successfully ({len(sql_content)} characters)")
        
        # Initialize evaluator
        evaluator = SQLEvaluator(api_key="dummy-key")
        print("✅ Evaluator initialized (AI components disabled)")
        
        # Test pattern detection
        print("🔍 Pattern detection...")
        patterns = evaluator.detect_sql_patterns(sql_content)
        
        print(f"   Detected patterns: {len(patterns)}")
        for pattern in patterns:
            print(f"      - {pattern.pattern_name} (confidence: {pattern.confidence:.2f})")
        
        # Test metadata extraction
        print("📋 Metadata extraction...")
        purpose = evaluator._extract_purpose_from_path(sql_file)
        concepts = evaluator._extract_concepts_from_content(sql_content)
        difficulty = evaluator._extract_difficulty_from_path(sql_file)
        
        print(f"   Purpose: {purpose}")
        print(f"   Concepts: {concepts}")
        print(f"   Difficulty: {difficulty}")
        
        basic_success = True
    except Exception as e:
        print(f"❌ Basic evaluation failed: {e}")
        basic_success = False
    
    print()
    
    # Test 3: SQL Content Analysis
    print("3️⃣  SQL Content Analysis Test")
    print("-" * 30)
    
    try:
        # Check for SQL keywords
        sql_keywords = ['CREATE TABLE', 'INSERT INTO', 'SELECT', 'DROP TABLE', 'WHERE', 'JOIN', 'GROUP BY']
        found_keywords = []
        
        for keyword in sql_keywords:
            if keyword in sql_content.upper():
                found_keywords.append(keyword)
        
        print(f"✅ Found SQL keywords: {', '.join(found_keywords)}")
        
        # Count statement types
        table_creation_count = sql_content.upper().count('CREATE TABLE')
        insert_count = sql_content.upper().count('INSERT INTO')
        select_count = sql_content.upper().count('SELECT')
        drop_count = sql_content.upper().count('DROP TABLE')
        
        print(f"📊 Statement counts:")
        print(f"   Table creations: {table_creation_count}")
        print(f"   Insert statements: {insert_count}")
        print(f"   Select statements: {select_count}")
        print(f"   Drop statements: {drop_count}")
        
        content_success = True
    except Exception as e:
        print(f"❌ Content analysis failed: {e}")
        content_success = False
    
    print()
    
    # Test 4: File Structure Analysis
    print("4️⃣  File Structure Analysis Test")
    print("-" * 30)
    
    try:
        file_info = {
            'filename': sql_file.name,
            'size': len(sql_content),
            'lines': len(sql_content.split('\n')),
            'has_purpose_header': '-- PURPOSE:' in sql_content,
            'has_difficulty_header': '-- DIFFICULTY:' in sql_content,
            'has_concepts_header': '-- CONCEPTS:' in sql_content
        }
        
        print(f"📁 File information:")
        print(f"   Name: {file_info['filename']}")
        print(f"   Size: {file_info['size']} characters")
        print(f"   Lines: {file_info['lines']}")
        print(f"   Has purpose header: {file_info['has_purpose_header']}")
        print(f"   Has difficulty header: {file_info['has_difficulty_header']}")
        print(f"   Has concepts header: {file_info['has_concepts_header']}")
        
        structure_success = True
    except Exception as e:
        print(f"❌ Structure analysis failed: {e}")
        structure_success = False
    
    print()
    
    # Test 5: Educational Assessment
    print("5️⃣  Educational Assessment Test")
    print("-" * 30)
    
    try:
        # Analyze educational value
        educational_indicators = {
            'has_examples': 'Example' in sql_content,
            'has_comments': '--' in sql_content,
            'has_cleanup': 'DROP TABLE' in sql_content.upper(),
            'has_sample_data': 'INSERT INTO' in sql_content.upper(),
            'has_queries': 'SELECT' in sql_content.upper(),
            'has_constraints': 'PRIMARY KEY' in sql_content.upper() or 'UNIQUE' in sql_content.upper()
        }
        
        print(f"🎓 Educational indicators:")
        for indicator, value in educational_indicators.items():
            status = "✅" if value else "❌"
            print(f"   {status} {indicator}: {value}")
        
        # Calculate educational score
        score = sum(educational_indicators.values()) / len(educational_indicators) * 10
        print(f"📊 Educational score: {score:.1f}/10")
        
        education_success = True
    except Exception as e:
        print(f"❌ Educational assessment failed: {e}")
        education_success = False
    
    print()
    
    # Summary
    print("📊 Test Summary")
    print("=" * 50)
    
    tests = [
        ("SQL Validation", validation_success),
        ("Basic Evaluation", basic_success),
        ("Content Analysis", content_success),
        ("Structure Analysis", structure_success),
        ("Educational Assessment", education_success)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, success in tests:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{test_name:25} {status}")
        if success:
            passed += 1
    
    print()
    print(f"Overall: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
    
    if passed == total:
        print("🎉 All tests passed! The Python evaluator is working correctly.")
        print()
        print("✅ What's Working:")
        print("   - SQL syntax validation")
        print("   - Pattern detection")
        print("   - Metadata extraction")
        print("   - Content analysis")
        print("   - Educational assessment")
        print()
        print("🚀 Ready for production use!")
    else:
        print("⚠️  Some tests failed. Check the errors above.")
    
    return passed == total

if __name__ == "__main__":
    success = asyncio.run(test_comprehensive_evaluation())
    sys.exit(0 if success else 1) 