#!/bin/bash

# Data Modeling Quality Validation Script
# Validates all Data Modeling examples against quality patterns

set -e

echo "🔍 Validating Data Modeling Examples..."

# Check file structure
echo "📁 Checking file structure..."
for category in normalization-patterns denormalization-strategies schema-design-principles real-world-applications; do
    if [ ! -d "quests/data-modeling/$category" ]; then
        echo "❌ Missing category: $category"
        exit 1
    fi
    
    file_count=$(find "quests/data-modeling/$category" -name "*.sql" | wc -l)
    if [ "$file_count" -ne 3 ]; then
        echo "❌ Category $category has $file_count files (expected 3)"
        exit 1
    fi
done

# Check header patterns
echo "📋 Checking header patterns..."
for file in quests/data-modeling/*/*.sql; do
    echo "Checking $file..."
    
    # Check for required header elements
    if ! grep -q "PURPOSE:" "$file"; then
        echo "❌ Missing PURPOSE in $file"
        exit 1
    fi
    
    if ! grep -q "DIFFICULTY:" "$file"; then
        echo "❌ Missing DIFFICULTY in $file"
        exit 1
    fi
    
    if ! grep -q "CONCEPTS:" "$file"; then
        echo "❌ Missing CONCEPTS in $file"
        exit 1
    fi
    
    # Check for cleanup section
    if ! grep -q "Clean up" "$file"; then
        echo "❌ Missing cleanup section in $file"
        exit 1
    fi
    
    # Check for DROP statements
    if ! grep -q "DROP TABLE" "$file"; then
        echo "❌ Missing DROP TABLE statements in $file"
        exit 1
    fi
done

# Check example count
echo "📊 Checking example count..."
for file in quests/data-modeling/*/*.sql; do
    example_count=$(grep -c "Example [0-9]:" "$file" || echo "0")
    if [ "$example_count" -ne 3 ]; then
        echo "❌ $file has $example_count examples (expected 3)"
        exit 1
    fi
done

# Check for complexity indicators
echo "⚡ Checking complexity levels..."
for file in quests/data-modeling/*/*.sql; do
    # Check for overly complex queries
    complex_queries=$(grep -c "WITH.*RECURSIVE\|LATERAL\|WINDOW\|PARTITION BY" "$file" || echo "0")
    if [ "$complex_queries" -gt 2 ]; then
        echo "⚠️  $file may be too complex ($complex_queries complex queries)"
    fi
    
    # Check for large datasets
    insert_count=$(grep -c "INSERT INTO" "$file" || echo "0")
    if [ "$insert_count" -gt 10 ]; then
        echo "⚠️  $file may have too much sample data ($insert_count INSERT statements)"
    fi
done

echo "✅ Data Modeling validation complete!"
echo "📋 Quality patterns applied successfully" 