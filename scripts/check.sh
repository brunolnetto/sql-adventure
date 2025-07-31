#!/bin/bash

# SQL Adventure Unified Check Script
# Single script for all validation needs - FAST and FLEXIBLE

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

# Function to benchmark performance
benchmark_performance() {
    local file="$1"
    local iterations="${2:-3}"
    local filename=$(basename "$file")
    
    print_status "🏃 Benchmarking $filename ($iterations iterations)..."
    
    local total_time=0
    local times=()
    
    for i in $(seq 1 $iterations); do
        local start_time=$(date +%s.%N)
        
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "\i $file" > /dev/null 2>&1; then
            
            local end_time=$(date +%s.%N)
            local execution_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
            times+=($execution_time)
            total_time=$(echo "$total_time + $execution_time" | bc -l 2>/dev/null || echo "0")
            
            print_status "  Run $i: ${execution_time}s"
        else
            print_error "  Run $i: Failed"
            return 1
        fi
    done
    
    local avg_time=$(echo "scale=3; $total_time / $iterations" | bc -l 2>/dev/null || echo "0")
    
    print_status "📊 Average: ${avg_time}s"
    
    if (( $(echo "$avg_time > 1.0" | bc -l 2>/dev/null || echo "0") )); then
        print_warning "⚠️  Slow (> 1s)"
        return 1
    else
        print_success "✅ Fast (< 1s)"
        return 0
    fi
}

# Function to analyze output for AI
analyze_output() {
    local file="$1"
    local filename=$(basename "$file")
    
    print_status "🤖 AI Analysis: $filename"
    
    # Execute and capture output
    local output_file=$(mktemp)
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$file" > "$output_file" 2>&1; then
        
        print_status "📄 Output captured ($(wc -l < "$output_file") lines)"
        print_status "💾 Saved to: $output_file"
        
        # Show first few lines for quick review
        print_status "📋 Sample output:"
        head -10 "$output_file"
        
        if [ $(wc -l < "$output_file") -gt 10 ]; then
            print_status "... (truncated)"
        fi
    else
        print_error "❌ Failed to capture output"
        rm -f "$output_file"
        return 1
    fi
}

# Function to check a single file
check_file() {
    local file="$1"
    local mode="${2:-fast}"
    local filename=$(basename "$file")
    
    print_status "🔍 Checking: $filename (mode: $mode)"
    
    local overall_result=0
    
    # Always run basic checks
    validate_syntax "$file" || overall_result=1
    check_structure "$file" || overall_result=1
    test_execution "$file" || overall_result=1
    
    # Mode-specific checks
    case "$mode" in
        fast)
            # Just basic checks (already done above)
            :
            ;;
        full)
            # Add performance benchmark
            benchmark_performance "$file" 3 || overall_result=1
            ;;
        ai)
            # Add AI analysis
            analyze_output "$file" || overall_result=1
            ;;
        all)
            # Everything
            benchmark_performance "$file" 3 || overall_result=1
            analyze_output "$file" || overall_result=1
            ;;
    esac
    
    if [ $overall_result -eq 0 ]; then
        print_success "✅ $filename - ALL CHECKS PASSED"
    else
        print_error "❌ $filename - SOME CHECKS FAILED"
    fi
    
    return $overall_result
}

# Function to check all files in a directory
check_directory() {
    local dir="$1"
    local mode="${2:-fast}"
    local total=0
    local passed=0
    
    print_status "🔍 Checking directory: $dir (mode: $mode)"
    
    for file in "$dir"/*.sql; do
        if [ -f "$file" ]; then
            total=$((total + 1))
            if check_file "$file" "$mode"; then
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
    echo "  fast                    Quick check (syntax, structure, execution) - DEFAULT"
    echo "  full                    Fast + performance benchmark"
    echo "  ai                      Fast + AI output analysis"
    echo "  all                     Everything (fast + performance + AI)"
    echo ""
    echo "Examples:"
    echo "  $0 fast quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo "  $0 full quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo "  $0 ai quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo "  $0 all quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo "  $0 fast quests/recursive-cte/01-hierarchical-graph-traversal"
    echo ""
    echo "Development Workflow:"
    echo "  $0 fast <file>          # During development (FAST)"
    echo "  $0 full <file>          # Before commit (PERFORMANCE)"
    echo "  $0 ai <file>            # For AI handover (CONTEXT)"
    echo "  $0 all <file>           # Complete validation (EVERYTHING)"
}

# Main execution
case "${1:-fast}" in
    fast|full|ai|all)
        mode="$1"
        target="${2:-}"
        
        if [ -z "$target" ]; then
            print_error "File or directory not specified"
            show_usage
            exit 1
        fi
        
        if [ -d "$target" ]; then
            check_directory "$target" "$mode"
        elif [ -f "$target" ]; then
            check_file "$target" "$mode"
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