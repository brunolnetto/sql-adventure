#!/bin/bash

# SQL Adventure Regression Testing Script
# Tests all examples across all quests to ensure no breaking changes

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
QUESTS_DIR="quests"

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

# Function to run a single example
run_example() {
    local file="$1"
    local filename=$(basename "$file")
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\pset pager off" \
        -f "$file" > /dev/null 2>&1; then
        print_success "✅ $filename"
        return 0
    else
        print_error "❌ $filename"
        return 1
    fi
}

# Function to test all examples in a quest category
test_quest_category() {
    local quest_name="$1"
    local category="$2"
    local folder="$QUESTS_DIR/$quest_name/$category"
    
    if [ ! -d "$folder" ]; then
        print_error "Category folder not found: $folder"
        return 1
    fi
    
    local category_success=0
    local category_total=0
    
    for file in "$folder"/*.sql; do
        if [ -f "$file" ]; then
            category_total=$((category_total + 1))
            if run_example "$file"; then
                category_success=$((category_success + 1))
            fi
        fi
    done
    
    if [ $category_total -gt 0 ]; then
        print_status "📊 $quest_name/$category: $category_success/$category_total examples passed"
    fi
    
    return $((category_total - category_success))
}

# Function to test all examples in a quest
test_quest() {
    local quest_name="$1"
    local quest_dir="$QUESTS_DIR/$quest_name"
    
    print_status "🧪 Testing quest: $quest_name"
    
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
            local category_failures=0
            
            if test_quest_category "$quest_name" "$category_name"; then
                quest_success=$((quest_success + 1))
            else
                category_failures=1
            fi
            
            quest_total=$((quest_total + 1))
        fi
    done
    
    if [ $quest_total -gt 0 ]; then
        if [ $quest_success -eq $quest_total ]; then
            print_success "🎉 Quest $quest_name: All categories passed"
        else
            print_warning "⚠️  Quest $quest_name: Some categories failed"
        fi
    fi
    
    return $((quest_total - quest_success))
}

# Function to run comprehensive regression tests
run_regression_tests() {
    print_status "🧪 Starting comprehensive regression tests..."
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
    for quest_dir in "$QUESTS_DIR"/*; do
        if [ -d "$quest_dir" ]; then
            local quest_name=$(basename "$quest_dir")
            total_quests=$((total_quests + 1))
            
            if test_quest "$quest_name"; then
                successful_quests=$((successful_quests + 1))
            else
                failed_quests=$((failed_quests + 1))
            fi
            
            echo ""
        fi
    done
    
    echo "========================================"
    print_status "📊 Regression Test Summary:"
    print_status "  Total Quests: $total_quests"
    print_status "  Successful: $successful_quests"
    print_status "  Failed: $failed_quests"
    
    if [ $failed_quests -eq 0 ]; then
        print_success "🎉 All regression tests passed!"
        return 0
    else
        print_error "❌ $failed_quests quest(s) failed regression tests"
        return 1
    fi
}

# Function to test specific quest
test_specific_quest() {
    local quest_name="$1"
    
    print_status "🧪 Testing specific quest: $quest_name"
    
    if ! test_connection; then
        print_error "Cannot proceed without database connection"
        exit 1
    fi
    
    if test_quest "$quest_name"; then
        print_success "✅ Quest $quest_name passed all tests"
        return 0
    else
        print_error "❌ Quest $quest_name failed some tests"
        return 1
    fi
}

# Function to test specific category
test_specific_category() {
    local quest_name="$1"
    local category_name="$2"
    
    print_status "🧪 Testing specific category: $quest_name/$category_name"
    
    if ! test_connection; then
        print_error "Cannot proceed without database connection"
        exit 1
    fi
    
    if test_quest_category "$quest_name" "$category_name"; then
        print_success "✅ Category $quest_name/$category_name passed all tests"
        return 0
    else
        print_error "❌ Category $quest_name/$category_name failed some tests"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [QUEST] [CATEGORY]"
    echo ""
    echo "Commands:"
    echo "  all                    Run regression tests for all quests"
    echo "  quest <name>           Test specific quest"
    echo "  category <quest> <cat> Test specific category"
    echo "  connection             Test database connection only"
    echo "  help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all                                    # Test all quests"
    echo "  $0 quest recursive-cte                    # Test recursive-cte quest"
    echo "  $0 category window-functions basic-ranking # Test specific category"
    echo "  $0 connection                             # Test database connection"
}

# Main execution
case "${1:-help}" in
    all)
        run_regression_tests
        ;;
    quest)
        if [ -z "$2" ]; then
            print_error "Quest name not specified"
            show_usage
            exit 1
        fi
        test_specific_quest "$2"
        ;;
    category)
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Quest name and category not specified"
            show_usage
            exit 1
        fi
        test_specific_category "$2" "$3"
        ;;
    connection)
        test_connection
        ;;
    help|*)
        show_usage
        exit 0
        ;;
esac 