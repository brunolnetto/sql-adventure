#!/bin/bash

# SQL Adventure Performance Testing Script
# Benchmarks SQL examples for performance analysis

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
DEFAULT_ITERATIONS=10

# Function to test database connection
test_connection() {
    print_status "Testing database connection..."
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "SELECT 1 as connection_test;" > /dev/null 2>&1; then
        print_success "Database connection successful"
        return 0
    else
        print_error "Database connection failed"
        return 1
    fi
}

# Function to benchmark a single example
benchmark_example() {
    local file="$1"
    local iterations="${2:-$DEFAULT_ITERATIONS}"
    local filename=$(basename "$file")
    
    print_status "🏃 Benchmarking $filename ($iterations iterations)..."
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi
    
    # Arrays to store execution times
    local times=()
    local total_time=0
    
    # Run iterations
    for i in $(seq 1 $iterations); do
        local start_time=$(date +%s.%N)
        
        # Execute the SQL file
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "\pset pager off" \
            -f "$file" > /dev/null 2>&1; then
            
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
    
    # Calculate statistics
    local avg_time=$(echo "scale=3; $total_time / $iterations" | bc -l 2>/dev/null || echo "0")
    
    # Calculate min and max
    local min_time=${times[0]}
    local max_time=${times[0]}
    
    for time in "${times[@]}"; do
        if (( $(echo "$time < $min_time" | bc -l 2>/dev/null || echo "0") )); then
            min_time=$time
        fi
        if (( $(echo "$time > $max_time" | bc -l 2>/dev/null || echo "0") )); then
            max_time=$time
        fi
    done
    
    # Calculate standard deviation
    local variance=0
    for time in "${times[@]}"; do
        local diff=$(echo "$time - $avg_time" | bc -l 2>/dev/null || echo "0")
        local squared=$(echo "$diff * $diff" | bc -l 2>/dev/null || echo "0")
        variance=$(echo "$variance + $squared" | bc -l 2>/dev/null || echo "0")
    done
    local std_dev=$(echo "scale=3; sqrt($variance / $iterations)" | bc -l 2>/dev/null || echo "0")
    
    # Display results
    echo "========================================"
    print_status "📊 Performance Results for $filename:"
    print_status "  Iterations: $iterations"
    print_status "  Average: ${avg_time}s"
    print_status "  Minimum: ${min_time}s"
    print_status "  Maximum: ${max_time}s"
    print_status "  Std Dev: ${std_dev}s"
    
    # Performance assessment
    if (( $(echo "$avg_time > 5.0" | bc -l 2>/dev/null || echo "0") )); then
        print_warning "⚠️  Performance warning: Average execution time > 5s"
        return 1
    elif (( $(echo "$avg_time > 1.0" | bc -l 2>/dev/null || echo "0") )); then
        print_warning "⚠️  Performance notice: Average execution time > 1s"
        return 0
    else
        print_success "✅ Performance: Excellent (< 1s average)"
        return 0
    fi
}

# Function to benchmark all examples in a quest category
benchmark_quest_category() {
    local quest_name="$1"
    local category="$2"
    local iterations="${3:-$DEFAULT_ITERATIONS}"
    local folder="quests/$quest_name/$category"
    
    print_status "📊 Benchmarking category: $quest_name/$category"
    
    if [ ! -d "$folder" ]; then
        print_error "Category folder not found: $folder"
        return 1
    fi
    
    local category_success=0
    local category_total=0
    
    for file in "$folder"/*.sql; do
        if [ -f "$file" ]; then
            category_total=$((category_total + 1))
            if benchmark_example "$file" "$iterations"; then
                category_success=$((category_success + 1))
            fi
            echo ""
        fi
    done
    
    print_status "📊 Category Summary: $category_success/$category_total examples benchmarked successfully"
    return $((category_total - category_success))
}

# Function to benchmark all examples in a quest
benchmark_quest() {
    local quest_name="$1"
    local iterations="${2:-$DEFAULT_ITERATIONS}"
    local quest_dir="quests/$quest_name"
    
    print_status "🏃 Benchmarking quest: $quest_name"
    
    if [ ! -d "$quest_dir" ]; then
        print_error "Quest directory not found: $quest_dir"
        return 1
    fi
    
    local quest_success=0
    local quest_total=0
    
    # Find all category folders (agnostic approach)
    for folder in "$quest_dir"/*; do
        if [ -d "$folder" ]; then
            local category_name=$(basename "$folder")
            
            if benchmark_quest_category "$quest_name" "$category_name" "$iterations"; then
                quest_success=$((quest_success + 1))
            fi
            
            quest_total=$((quest_total + 1))
            echo ""
        fi
    done
    
    print_status "📊 Quest Summary: $quest_success/$quest_total categories benchmarked successfully"
    return $((quest_total - quest_success))
}

# Function to run comprehensive performance tests
run_performance_tests() {
    local iterations="${1:-$DEFAULT_ITERATIONS}"
    
    print_status "🏃 Starting comprehensive performance tests..."
    echo "========================================"
    
    # Test database connection first
    if ! test_connection; then
        print_error "Cannot proceed without database connection"
        exit 1
    fi
    
    local total_quests=0
    local successful_quests=0
    local failed_quests=0
    
    # Test all quests
    for quest_dir in quests/*; do
        if [ -d "$quest_dir" ]; then
            local quest_name=$(basename "$quest_dir")
            total_quests=$((total_quests + 1))
            
            if benchmark_quest "$quest_name" "$iterations"; then
                successful_quests=$((successful_quests + 1))
            else
                failed_quests=$((failed_quests + 1))
            fi
            
            echo ""
        fi
    done
    
    echo "========================================"
    print_status "📊 Performance Test Summary:"
    print_status "  Total Quests: $total_quests"
    print_status "  Successful: $successful_quests"
    print_status "  Failed: $failed_quests"
    print_status "  Iterations per test: $iterations"
    
    if [ $failed_quests -eq 0 ]; then
        print_success "🎉 All performance tests completed!"
        return 0
    else
        print_warning "⚠️  $failed_quests quest(s) had performance issues"
        return 1
    fi
}

# Function to generate performance report
generate_report() {
    local output_file="${1:-performance_report.txt}"
    
    print_status "📄 Generating performance report: $output_file"
    
    {
        echo "SQL Adventure Performance Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""
        
        # Test database connection
        if test_connection; then
            echo "Database Connection: ✅ OK"
        else
            echo "Database Connection: ❌ Failed"
            return 1
        fi
        
        echo ""
        echo "Performance Benchmarks:"
        echo "======================="
        
        # Run performance tests and capture output
        local temp_output=$(mktemp)
        if run_performance_tests 5 > "$temp_output" 2>&1; then
            cat "$temp_output"
            echo ""
            echo "Overall Status: ✅ All tests passed"
        else
            cat "$temp_output"
            echo ""
            echo "Overall Status: ⚠️  Some tests failed"
        fi
        
        rm -f "$temp_output"
        
    } > "$output_file"
    
    print_success "Performance report generated: $output_file"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [FILE|QUEST] [CATEGORY] [ITERATIONS]"
    echo ""
    echo "Commands:"
    echo "  benchmark <file> [iterations]     Benchmark single example"
    echo "  category <quest> <cat> [iter]     Benchmark quest category"
    echo "  quest <name> [iterations]         Benchmark entire quest"
    echo "  all [iterations]                  Benchmark all quests"
    echo "  report [output-file]              Generate performance report"
    echo "  connection                        Test database connection"
    echo "  help                              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 benchmark quests/window-functions/01-basic-ranking/01-row-number.sql 10"
    echo "  $0 category window-functions basic-ranking 5"
    echo "  $0 quest recursive-cte 10"
    echo "  $0 all 5"
    echo "  $0 report my_report.txt"
    echo "  $0 connection"
}

# Main execution
case "${1:-help}" in
    benchmark)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        benchmark_example "$2" "${3:-$DEFAULT_ITERATIONS}"
        ;;
    category)
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Quest name and category not specified"
            show_usage
            exit 1
        fi
        benchmark_quest_category "$2" "$3" "${4:-$DEFAULT_ITERATIONS}"
        ;;
    quest)
        if [ -z "$2" ]; then
            print_error "Quest name not specified"
            show_usage
            exit 1
        fi
        benchmark_quest "$2" "${3:-$DEFAULT_ITERATIONS}"
        ;;
    all)
        run_performance_tests "${2:-$DEFAULT_ITERATIONS}"
        ;;
    report)
        generate_report "$2"
        ;;
    connection)
        test_connection
        ;;
    help|*)
        show_usage
        exit 0
        ;;
esac 