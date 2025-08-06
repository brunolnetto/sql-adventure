#!/bin/bash

# Comprehensive SQL Validation Script
# Quest-agnostic validation with AI-powered pattern detection and evaluation

set -e

# Source dependencies
source "$(dirname "$0")/utils/print-utils.sh"
source "$(dirname "$0")/utils/ai-utils.sh"
source "$(dirname "$0")/utils/report-utils.sh"

# Configuration
CONFIG=(
    "DB_HOST:localhost"
    "DB_PORT:5432"
    "DB_USER:postgres"
    "DB_NAME:sql_adventure_db"
    "DB_PASSWORD:postgres"
)

# Load environment variables
load_env() {
    local env_file=".env"
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file" 2>/dev/null || true
        set +a
    fi
    
    # Set defaults from config
    for config in "${CONFIG[@]}"; do
        local key="${config%:*}"
        local default="${config#*:}"
        local env_key="${key}"
        [ "$key" = "DB_PORT" ] && env_key="HOST_PORT"
        [ "$key" = "DB_USER" ] && env_key="POSTGRES_USER"
        [ "$key" = "DB_NAME" ] && env_key="POSTGRES_DB"
        [ "$key" = "DB_PASSWORD" ] && env_key="POSTGRES_PASSWORD"
        export "$key"="${!env_key:-$default}"
    done
    
    # Ensure OPENAI_API_KEY is available
    if [ -z "$OPENAI_API_KEY" ]; then
        print_warning "⚠️  OPENAI_API_KEY not found in environment"
    else
        print_status "✅ OPENAI_API_KEY loaded successfully"
    fi
}

# Function to test database connection
test_database_connection() {
    print_status "Testing database connection..."
    
    if command -v psql >/dev/null 2>&1; then
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "SELECT 1;" > /dev/null 2>&1; then
            print_success "✅ Database connection successful"
            return 0
        else
            print_error "❌ Database connection failed"
            return 1
        fi
    else
        print_warning "⚠️  psql not found, skipping database test"
        return 0
    fi
}

# Function to validate SQL syntax (basic check)
validate_sql_syntax() {
    local file="$1"
    print_status "Validating SQL syntax: $(basename "$file")"
    
    # Simple syntax checks
    if grep -q "^[[:space:]]*--" "$file"; then
        print_status "  ✅ Contains comments"
    fi
    
    if grep -iq "^[[:space:]]*CREATE\|SELECT\|INSERT\|UPDATE\|DELETE\|WITH" "$file"; then
        print_success "  ✅ Contains valid SQL statements"
        return 0
    else
        print_warning "  ⚠️  No recognizable SQL statements found"
        return 1
    fi
}

# Function to run basic validation on a file
run_basic_validation() {
    local file="$1"
    local results=()
    
    print_header "Basic Validation: $(basename "$file")"
    
    # File exists check
    if [ -f "$file" ]; then
        print_success "✅ File exists and is readable"
        results+=("file_exists:PASS")
    else
        print_error "❌ File not found or not readable"
        results+=("file_exists:FAIL")
        return 1
    fi
    
    # File size check
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
    if [ "$size" -gt 0 ]; then
        print_success "✅ File has content ($size bytes)"
        results+=("file_size:PASS")
    else
        print_warning "⚠️  File is empty"
        results+=("file_size:WARNING")
    fi
    
    # SQL syntax validation
    if validate_sql_syntax "$file"; then
        results+=("syntax:PASS")
    else
        results+=("syntax:WARNING")
    fi
    
    # Summary
    local pass_count=$(printf '%s\n' "${results[@]}" | grep -c ":PASS" || echo "0")
    local total_count=${#results[@]}
    
    print_status "📊 Basic validation: $pass_count/$total_count checks passed"
    
    return 0
}

# Function to run AI evaluation (calls Python evaluator)
run_ai_evaluation() {
    local target="$1"
    local mode="${2:-fast}"
    
    print_header "AI-Powered Evaluation"
    print_status "Target: $target"
    print_status "Mode: $mode"
    
    # Check if Python evaluator exists
    local python_evaluator="scripts/evaluator/run_evaluation.py"
    if [ ! -f "$python_evaluator" ]; then
        print_error "❌ Python evaluator not found: $python_evaluator"
        return 1
    fi
    
    # Set up environment
    export DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME
    
    # Run Python evaluator
    print_status "Running Python evaluator..."
    if python3 "$python_evaluator" "$target" --mode "$mode"; then
        print_success "✅ AI evaluation completed successfully"
        return 0
    else
        print_error "❌ AI evaluation failed"
        return 1
    fi
}

# Function to run batch evaluation
run_batch_evaluation() {
    local target="$1"
    local output_dir="$2"
    
    print_header "Batch AI Evaluation"
    
    # Check if Python evaluator exists
    local python_evaluator="scripts/evaluator/run_evaluation.py"
    if [ ! -f "$python_evaluator" ]; then
        print_error "❌ Python evaluator not found: $python_evaluator"
        return 1
    fi
    
    # Set up environment
    export DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME
    
    # Build command
    local cmd="python3 $python_evaluator $target --mode comprehensive"
    if [ -n "$output_dir" ]; then
        cmd="$cmd --output-dir $output_dir"
    fi
    
    # Run evaluation
    print_status "Running batch evaluation..."
    if eval "$cmd"; then
        print_success "✅ Batch evaluation completed successfully"
        return 0
    else
        print_error "❌ Batch evaluation failed"
        return 1
    fi
}

# Function to generate summary report
generate_summary_report() {
    print_header "Generating Summary Report"
    
    # Check if summary script exists
    local summary_script="scripts/evaluator/evaluation_summary.py"
    if [ -f "$summary_script" ]; then
        print_status "Generating evaluation summary..."
        if python3 "$summary_script"; then
            print_success "✅ Summary report generated"
        else
            print_warning "⚠️  Summary generation failed"
        fi
    else
        print_warning "⚠️  Summary script not found, skipping report generation"
    fi
}

# Function to show usage
show_usage() {
    echo "SQL Adventure Validation Script"
    echo ""
    echo "Usage: $0 [COMMAND] [TARGET] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  basic <file>              Run basic validation on a SQL file"
    echo "  ai-fast <target>          Run fast AI evaluation on file/quest/all"
    echo "  ai-batch <target>         Run comprehensive AI evaluation"
    echo "  test-db                   Test database connection"
    echo "  summary                   Generate summary report"
    echo ""
    echo "Targets:"
    echo "  <file.sql>                Single SQL file"
    echo "  <quest-directory>         Quest directory (e.g., quests/1-data-modeling)"
    echo "  all                       All quests"
    echo ""
    echo "Examples:"
    echo "  $0 basic quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"
    echo "  $0 ai-fast quests/1-data-modeling/00-basic-concepts"
    echo "  $0 ai-batch all"
    echo "  $0 test-db"
    echo "  $0 summary"
    echo ""
    echo "Note: This script is a wrapper around the Python evaluator system."
    echo "For advanced options, use scripts/evaluator/run_evaluation.py directly."
}

# Main function
main() {
    # Load environment
    load_env
    
    # Parse command
    local command="$1"
    local target="$2"
    local option="$3"
    
    case "$command" in
        "basic")
            if [ -z "$target" ]; then
                print_error "Target file required for basic validation"
                show_usage
                exit 1
            fi
            run_basic_validation "$target"
            ;;
        "ai-fast")
            if [ -z "$target" ]; then
                print_error "Target required for AI evaluation"
                show_usage
                exit 1
            fi
            run_ai_evaluation "$target" "fast"
            ;;
        "ai-batch")
            if [ -z "$target" ]; then
                print_error "Target required for batch evaluation"
                show_usage
                exit 1
            fi
            run_batch_evaluation "$target" "$option"
            ;;
        "test-db")
            test_database_connection
            ;;
        "summary")
            generate_summary_report
            ;;
        "help"|"--help"|"-h"|"")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"