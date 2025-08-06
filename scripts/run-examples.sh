#!/bin/bash

# SQL Adventure Examples Runner - Python Backend
# Updated to use the Python evaluator while maintaining backward compatibility

set -e

# Source print utility functions
source "$(dirname "$0")/utils/print-utils.sh"

# Function to load environment variables
load_env() {
    if [ -f ".env" ]; then
        set -a
        source .env
        set +a
        print_status "✅ Environment variables loaded from .env"
    else
        print_warning "⚠️  No .env file found, using system environment variables"
    fi
}

# Function to show configuration
show_config() {
    print_header "Configuration"
    print_status "Database: $DB_HOST:$DB_PORT/$DB_NAME"
    print_status "User: $DB_USER"
    print_status "Output Directory: ai-evaluations"
}

# Function to test database connection
test_connection() {
    print_status "🔍 Testing database connection..."
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "SELECT version();" >/dev/null 2>&1; then
        print_success "✅ Database connection successful"
        return 0
    else
        print_error "❌ Database connection failed"
        print_status "💡 Make sure the database is running and credentials are correct"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "SQL Adventure Examples Runner - Python Backend"
    echo
    echo "Usage: $0 [MODE] [TARGET] [OPTIONS]"
    echo
    echo "Modes:"
    echo "  examples <file|directory>  - Execute SQL examples"
    echo "  validate <file|directory>  - Validate SQL files"
    echo "  evaluate <file|directory>  - Run AI evaluation"
    echo "  report <format> [target]   - Generate reports (json|html|markdown)"
    echo
    echo "Examples:"
    echo "  $0 examples quests/1-data-modeling"
    echo "  $0 examples quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"
    echo "  $0 validate quests/1-data-modeling"
    echo "  $0 evaluate quests/1-data-modeling"
    echo "  $0 report json quests/1-data-modeling"
    echo
    echo "Legacy Modes (deprecated, use Python directly):"
    echo "  run <file|directory>       - Run examples (legacy)"
    echo "  test <file|directory>      - Test examples (legacy)"
    echo
    echo "Note: This script now uses the Python evaluator backend for improved performance and features."
}

# Function to run Python evaluator
run_python_evaluator() {
    local mode="$1"
    local target="$2"
    local options="$3"
    
    print_status "🤖 Using Python evaluator backend..."
    
    # Convert shell arguments to Python format
    case "$mode" in
        "examples")
            python3 "$(dirname "$0")/evaluator/main.py" examples "$target" $options
            ;;
        "validate")
            python3 "$(dirname "$0")/evaluator/main.py" validate "$target" $options
            ;;
        "evaluate")
            python3 "$(dirname "$0")/evaluator/main.py" evaluate "$target" $options
            ;;
        "report")
            local format="$2"
            local report_target="$3"
            python3 "$(dirname "$0")/evaluator/main.py" report "$format" "$report_target" $options
            ;;
        *)
            print_error "❌ Unknown mode: $mode"
            show_usage
            exit 1
            ;;
    esac
}

# Function to run legacy examples (deprecated)
run_legacy_examples() {
    local mode="$1"
    local target="$2"
    
    print_warning "⚠️  Legacy mode detected. Consider using 'examples' mode instead."
    print_status "🔄 Converting to Python evaluator..."
    
    case "$mode" in
        "run")
            run_python_evaluator "examples" "$target"
            ;;
        "test")
            run_python_evaluator "validate" "$target"
            ;;
        *)
            print_error "❌ Unknown legacy mode: $mode"
            show_usage
            exit 1
            ;;
    esac
}

# Main script logic
main() {
    # Load environment variables
    load_env
    
    # Show configuration
    show_config
    
    # Test database connection
    if ! test_connection; then
        print_error "❌ Cannot proceed without database connection"
    exit 1
fi

    # Check if Python evaluator is available
    if [ ! -f "$(dirname "$0")/evaluator/main.py" ]; then
        print_error "❌ Python evaluator not found. Please ensure the evaluator is properly installed."
            exit 1
        fi
        
    # Parse arguments
    local mode="${1:-help}"
    local target="$2"
    local options="${@:3}"
    
    case "$mode" in
        "examples"|"validate"|"evaluate"|"report")
            if [ -z "$target" ]; then
                print_error "❌ Target required for mode: $mode"
            show_usage
            exit 1
        fi
            run_python_evaluator "$mode" "$target" "$options"
            ;;
        "run"|"test")
            if [ -z "$target" ]; then
                print_error "❌ Target required for mode: $mode"
                show_usage
            exit 1
        fi
            run_legacy_examples "$mode" "$target"
            ;;
        "help"|*)
            show_usage
        ;;
esac 
}

# Run main function with all arguments
main "$@" 