#!/bin/bash

# SQL Adventure Validation Script - Python Wrapper
# Simplified wrapper around the Python evaluator system

set -e

shopt -s globstar nullglob

# Source print utilities
source "$(dirname "$0")/utils/print-utils.sh"

# Function to load environment variables
load_env() {
    local env_file=".env"
    if [ -f "$env_file" ]; then
        print_status "Loading configuration from $env_file"
        set -a
        source .env
        set +a
    else
        print_warning "No .env file found, using defaults"
    fi
    
    # Set defaults for database connection
    export DB_HOST="${DB_HOST:-localhost}"
    export DB_PORT="${DB_PORT:-${HOST_PORT:-5432}}"
    export DB_USER="${DB_USER:-${POSTGRES_USER:-postgres}}"
    export DB_PASSWORD="${DB_PASSWORD:-${POSTGRES_PASSWORD:-postgres}}"
    export DB_NAME="${DB_NAME:-${POSTGRES_DB:-sql_adventure_db}}"
    
    # Check OPENAI_API_KEY
    if [ -z "$OPENAI_API_KEY" ]; then
        print_warning "⚠️  OPENAI_API_KEY not found in environment"
        print_warning "   Some features may not work without API key"
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
            print_error "   Check Docker containers: docker-compose up -d"
            return 1
        fi
    else
        print_warning "⚠️  psql not found, skipping database test"
        return 0
    fi
}

# Function to call Python evaluator
run_python_evaluator() {
    local target="$1"
    local mode="${2:-fast}"
    local extra_args="${@:3}"
    
    local python_evaluator="scripts/evaluator/run_evaluation.py"
    
    # Check if Python evaluator exists
    if [ ! -f "$python_evaluator" ]; then
        print_error "❌ Python evaluator not found: $python_evaluator"
        print_error "   Make sure you're in the project root directory"
        return 1
    fi
    
    # Build command
    local cmd="python3 $python_evaluator"
    
    if [ -n "$target" ]; then
        cmd="$cmd $target"
    fi
    
    if [ "$mode" = "comprehensive" ]; then
        cmd="$cmd --mode comprehensive"
    fi
    
    # Add extra arguments
    if [ -n "$extra_args" ]; then
        cmd="$cmd $extra_args"
    fi
    
    # Run evaluation
    print_status "Running Python evaluator..."
    print_status "Command: $cmd"
    
    if eval "$cmd"; then
        print_success "✅ Evaluation completed successfully"
        return 0
    else
        print_error "❌ Evaluation failed"
        return 1
    fi
}

run_basic_validation() {
    local target="$1"

    if [ -f "$target" ]; then
        print_header "Basic Validation: $(basename "$target")"

        # 1) Existence & non-empty
        local size
        size=$(stat -f%z "$target" 2>/dev/null || stat -c%s "$target" 2>/dev/null || echo "0")
        if [ "$size" -eq 0 ]; then
            print_warning "⚠️  File is empty"
            return 1
        fi
        print_success "✅ File exists and has content ($size bytes)"

        # 2) Statement presence
        if ! grep -iqE "CREATE|SELECT|INSERT|UPDATE|DELETE|WITH" "$target"; then
            print_warning "⚠️  No recognizable SQL statements found"
        else
            print_success "✅ Contains SQL statements"
        fi

        # 3) Line‐length check
        local long_lines
        long_lines=$(awk 'length($0)>120 { printf("   • line %d: %d chars\n", NR, length($0)) }' "$target")
        if [ -n "$long_lines" ]; then
            print_warning "⚠️  Lines exceeding 120 chars:"
            echo "$long_lines"
        else
            print_success "✅ All lines ≤120 chars"
        fi

        # 4) Naming convention: simple regex on CREATE TABLE names
        local raw_names name bad=()
        # grab what follows CREATE TABLE (with optional IF NOT EXISTS), strip backticks
        raw_names=$(
            grep -Poi 'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?[A-Za-z0-9_]+`?' "$target" \
            | sed -E 's/CREATE TABLE (IF NOT EXISTS )?//I; s/`//g'
        )

        while read -r name; do
            if [[ ! $name =~ ^[a-z0-9_]+$ ]]; then
            bad+=("$name")
            fi
        done <<< "$raw_names"

        if (( ${#bad[@]} )); then
            print_warning "⚠️  Bad table names (must be lower_snake_case): ${bad[*]}"
        else
            print_success "✅ Table naming convention OK"
        fi

        return 0

    elif [ -d "$target" ]; then
        # same directory‐recursion as before…
        print_header "📁 Validating all .sql files in: $target"
        mapfile -t files < <(find "$target" -type f -name '*.sql' | sort)
        print_status "Found ${#files[@]} .sql files in $target"
        if [ "${#files[@]}" -eq 0 ]; then
            print_warning "⚠️  No .sql files found in $target"
            return 1
        fi

        local ok_count=0 fail_count=0
        set +e
        while IFS= read -r file; do
            run_basic_validation "$file"
            rc=$?
            if [ $rc -eq 0 ]; then
                echo "✅ OK: $file"
                ((ok_count++))
            else
                echo "❌ FAIL: $file"
                ((fail_count++))
            fi
        done <<< "$(printf '%s\n' "${files[@]}")"
        set -e

        print_header "📦 Summary for $target"
        print_status "✅ Passed: $ok_count"
        print_status "❌ Failed: $fail_count"
        return 0

    elif [ "$target" = "all" ]; then
        # same “all quests” logic…
        print_header "🚀 Running basic validation on all quests"
        local quest_dirs; quest_dirs=$(find quests -maxdepth 2 -type d -name "[0-9]*-*")
        for dir in $quest_dirs; do
            run_basic_validation "$dir"
        done
        return 0

    else
        print_error "❌ Invalid target for basic validation: $target"
        return 1
    fi
}


# Function to generate summary report
generate_summary() {
    print_header "Generating Summary Report"
    
    local summary_script="scripts/evaluator/evaluation_summary.py"
    if [ -f "$summary_script" ]; then
        print_status "Generating evaluation summary..."
        if python3 "$summary_script"; then
            print_success "✅ Summary report generated"
        else
            print_warning "⚠️  Summary generation failed"
        fi
    else
        print_warning "⚠️  Summary script not found"
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
SQL Adventure Validation Script - Python Wrapper

Usage: $0 [COMMAND] [TARGET] [OPTIONS]

Commands:
  basic <file>              Basic validation of a SQL file
  ai-fast <target>          Fast AI evaluation (default mode)
  ai-batch <target>         Comprehensive AI evaluation
  test-db                   Test database connection
  summary                   Generate evaluation summary report
  
Targets:
  <file.sql>                Single SQL file
  <quest-directory>         Quest directory (e.g., quests/1-data-modeling)
  all                       All quests

Options:
  --force                   Re-evaluate cached files
  --no-cache                Disable caching
  --max-concurrent N        Parallel files per quest (default: 3)
  --output-dir DIR          Custom output directory

Examples:
  $0 basic quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql
  $0 ai-fast quests/1-data-modeling/00-basic-concepts
  $0 ai-batch all --max-concurrent 5
  $0 test-db
  $0 summary

Advanced Usage:
  For full control, use the Python evaluator directly:
  python3 scripts/evaluator/run_evaluation.py --help

Note: This is a simplified wrapper. The Python evaluator provides more features.
EOF
}

# Main function
main() {
    # Load environment
    load_env
    
    # Parse command
    local command="$1"
    local target="$2"
    shift 2 2>/dev/null || true
    local extra_args="$*"
    
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
            run_python_evaluator "$target" "fast" "$extra_args"
            ;;
        "ai-batch")
            if [ -z "$target" ]; then
                print_error "Target required for batch evaluation"
                show_usage
                exit 1
            fi
            run_python_evaluator "$target" "comprehensive" "$extra_args"
            ;;
        "test-db")
            test_database_connection
            ;;
        "summary")
            generate_summary
            ;;
        "help"|"--help"|"-h"|"")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"