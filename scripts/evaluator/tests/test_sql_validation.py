#!/usr/bin/env python3
"""
Test SQL validation with an actual SQL file
"""

import sys
from pathlib import Path

# Add the current directory to the path
sys.path.insert(0, str(Path(__file__).parent))

from core.validation import SQLValidator

def test_sql_validation():
    """Test SQL validation with a real SQL file"""
    
    # Path to the SQL file
    sql_file = Path("../../quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql")
    
    if not sql_file.exists():
        print(f"❌ SQL file not found: {sql_file}")
        return False
    
    print(f"🔍 Testing SQL validation with: {sql_file}")
    
    # Initialize validator
    validator = SQLValidator()
    
    try:
        # Validate the SQL file
        result = validator.validate_sql_file(str(sql_file))
        
        print(f"✅ Validation completed!")
        print(f"   Valid: {result.is_valid}")
        print(f"   Score: {result.score:.2f}")
        print(f"   Total issues: {len(result.issues)}")
        
        if result.has_errors():
            print(f"   ❌ Errors: {len(result.get_errors())}")
            for error in result.get_errors():
                print(f"      - {error.message}")
        
        if result.get_warnings():
            print(f"   ⚠️  Warnings: {len(result.get_warnings())}")
            for warning in result.get_warnings():
                print(f"      - {warning.message}")
        
        return result.is_valid
        
    except Exception as e:
        print(f"❌ Validation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_sql_validation()
    sys.exit(0 if success else 1) 