#!/bin/bash

# SQL Adventure Validation Script
# Simplified validation with AI context analysis

set -e

# Source print utility functions
source "$(dirname "$0")/print-utils.sh"

# Load environment variables
load_env() {
    local env_file=".env"
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file" 2>/dev/null || true
        set +a
    fi
}

load_env

# Default values
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${HOST_PORT:-5432}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_NAME="${POSTGRES_DB:-sql_adventure_db}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgres}"

# Function to validate SQL syntax
validate_syntax() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\i $file" > /dev/null 2>&1; then
        print_success "✅ Syntax OK"
        return 0
    else
        print_error "❌ Syntax Error"
        return 1
    fi
}

# Function to check structure
check_structure() {
    local file="$1"
    local issues=0
    
    if ! grep -q "WITH RECURSIVE\|SELECT\|CREATE TABLE" "$file"; then
        print_warning "⚠️  No main SQL patterns found"
        issues=$((issues + 1))
    fi
    
    if ! grep -q "^--" "$file"; then
        print_warning "⚠️  No comments found"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "✅ Structure OK"
        return 0
    else
        print_warning "⚠️  Structure issues: $issues"
        return 1
    fi
}

# Function to test execution
test_execution() {
    local file="$1"
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\i $file" > /dev/null 2>&1; then
        print_success "✅ Executes OK"
        return 0
    else
        print_error "❌ Execution failed"
        return 1
    fi
}

# Function to analyze output for AI context
analyze_output() {
    local file="$1"
    local filename=$(basename "$file")
    
    print_status "🤖 AI Context Analysis: $filename"
    
    # Execute and capture output
    local output_file=$(mktemp)
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$file" > "$output_file" 2>&1; then
        
        print_status "📄 Output captured ($(wc -l < "$output_file") lines)"
        
        # Show output summary for AI evaluation
        print_status "📋 Output Summary for AI Context:"
        print_status "📄 Total lines: $(wc -l < "$output_file")"
        
        # Show key sections for context
        local line_count=$(wc -l < "$output_file")
        if [ $line_count -gt 30 ]; then
            print_status "📋 First 15 lines (context):"
            head -15 "$output_file"
            
            print_status "📋 Last 15 lines (results):"
            tail -15 "$output_file"
            
            print_status "💾 Full output saved to: $output_file"
        else
            # For smaller outputs, show everything
            cat "$output_file"
            print_status "💾 Full output saved to: $output_file"
        fi
        
        # Show table results summary
        if [ -f "$output_file" ]; then
            local table_lines=$(grep -c "|" "$output_file" 2>/dev/null || echo "0")
            if [ "$table_lines" -gt 0 ] 2>/dev/null; then
                print_status "📊 Table results: $table_lines lines"
                print_status "📋 Sample table output:"
                grep "|" "$output_file" | head -3
            fi
        fi
    else
        print_error "❌ Failed to capture output"
        rm -f "$output_file"
        return 1
    fi
}

# Function to validate a single file
validate_file() {
    local file="$1"
    local mode="${2:-fast}"
    local filename=$(basename "$file")
    
    print_status "🔍 Validating: $filename (mode: $mode)"
    
    local overall_result=0
    
    # Always run basic checks
    validate_syntax "$file" || overall_result=1
    check_structure "$file" || overall_result=1
    test_execution "$file" || overall_result=1
    
    # AI mode adds context analysis
    if [ "$mode" = "ai" ]; then
        analyze_output "$file" || overall_result=1
    fi
    
    if [ $overall_result -eq 0 ]; then
        print_success "✅ $filename - ALL CHECKS PASSED"
    else
        print_error "❌ $filename - SOME CHECKS FAILED"
    fi
    
    return $overall_result
}

# Function to validate all files in a directory
validate_directory() {
    local dir="$1"
    local mode="${2:-fast}"
    local total=0
    local passed=0
    
    print_status "🔍 Validating directory: $dir (mode: $mode)"
    
    for file in "$dir"/*.sql; do
        if [ -f "$file" ]; then
            total=$((total + 1))
            if validate_file "$file" "$mode"; then
                passed=$((passed + 1))
            fi
        fi
    done
    
    print_status "📊 Results: $passed/$total files passed"
    return $((total - passed))
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [MODE] [FILE|DIR]"
    echo ""
    echo "Modes:"
    echo "  fast                    Quick validation (syntax, structure, execution) - DEFAULT"
    echo "  ai                      Fast + AI context analysis"
    echo ""
    echo "Examples:"
    echo "  $0 fast quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo "  $0 ai quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo "  $0 fast quests/recursive-cte/01-hierarchical-graph-traversal"
    echo ""
    echo "Development Workflow:"
    echo "  $0 fast <file>          # During development (FAST)"
    echo "  $0 ai <file>            # For AI handover (CONTEXT)"
}

# Main execution
case "${1:-fast}" in
    fast|ai)
        mode="$1"
        target="${2:-}"
        
        if [ -z "$target" ]; then
            print_error "File or directory not specified"
            show_usage
            exit 1
        fi
        
        if [ -d "$target" ]; then
            validate_directory "$target" "$mode"
        elif [ -f "$target" ]; then
            validate_file "$target" "$mode"
        else
            print_error "Target not found: $target"
            exit 1
        fi
        ;;
    help|*)
        show_usage
        exit 0
        ;;
esac 