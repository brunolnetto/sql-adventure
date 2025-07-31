#!/bin/bash

# SQL Adventure Examples Runner
# This script allows you to run examples manually after containers are up
# Works with any quest structure in the quests/ directory

set -e

# Source print utility functions
source "$(dirname "$0")/print-utils.sh"

# Function to load environment variables from .env file
load_env() {
    local env_file=".env"
    
    if [ -f "$env_file" ]; then
        print_status "Loading configuration from $env_file"
        # Source the .env file, but handle potential errors gracefully
        set -a  # automatically export all variables
        source "$env_file" 2>/dev/null || true
        set +a  # stop automatically exporting
    else
        print_warning "No .env file found, using default values"
        print_info "You can copy env.example to .env and customize the settings"
    fi
}

# Load environment variables
load_env

# Default values (fallback if .env is not available)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${HOST_PORT:-5432}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_NAME="${POSTGRES_DB:-sql_adventure_db}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
QUESTS_DIR="quests"
VERBOSE=true

# Function to display current configuration
show_config() {
    echo "Current Configuration:"
    echo "  Database Host: $DB_HOST"
    echo "  Database Port: $DB_PORT"
    echo "  Database User: $DB_USER"
    echo "  Database Name: $DB_NAME"
    echo "  Password: ${DB_PASSWORD:0:3}***"
    echo "  Quests Directory: $QUESTS_DIR"
    echo "  Verbose Mode: $VERBOSE"
    echo ""
}

# Function to test database connection
test_connection() {
    print_status "Testing database connection..."
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\pset pager off" \
        -c "SELECT 1 as connection_test;" > /dev/null 2>&1; then
        print_success "Database connection successful"
        return 0
    else
        print_error "Database connection failed"
        print_error "Please check:"
        print_error "  1. Docker containers are running: docker-compose up -d"
        print_error "  2. Database credentials in .env file"
        print_error "  3. Database host and port settings"
        return 1
    fi
}

# Function to run a single example
run_example() {
    local file="$1"
    local filename=$(basename "$file")
    
    print_status "Running: $filename"
    
    if [ "$VERBOSE" = true ]; then
        echo "----------------------------------------"
        # Configure psql to show all output without truncation
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "\pset expanded off" \
            -c "\pset format unaligned" \
            -c "\pset fieldsep ' | '" \
            -c "\pset null '(null)'" \
            -c "\pset recordsep '\n'" \
            -c "\pset tuples_only off" \
            -c "\pset title on" \
            -c "\pset tableattr 'border=1'" \
            -c "\pset pager off" \
            -f "$file"; then
            echo "----------------------------------------"
            print_success "Completed: $filename"
        else
            echo "----------------------------------------"
            print_error "Failed: $filename"
            return 1
        fi
    else
        # Quiet mode - only show status
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "\pset pager off" \
            -f "$file" > /dev/null 2>&1; then
            print_success "Completed: $filename"
        else
            print_error "Failed: $filename"
            return 1
        fi
    fi
    echo ""
}

# Function to run all examples in a quest category
run_quest_category() {
    local quest_name="$1"
    local category="$2"
    local folder="$QUESTS_DIR/$quest_name/$category"
    
    print_status "Running quest: $quest_name, category: $category"
    if [ "$VERBOSE" = true ]; then
        echo "========================================"
    fi
    
    if [ ! -d "$folder" ]; then
        print_error "Category folder not found: $folder"
        return 1
    fi
    
    for file in "$folder"/*.sql; do
        if [ -f "$file" ]; then
            run_example "$file"
        fi
    done
    
    if [ "$VERBOSE" = true ]; then
        echo "========================================"
    fi
    print_success "Completed quest: $quest_name, category: $category"
    echo ""
}

# Function to run all examples in a quest
run_quest() {
    local quest_name="$1"
    local quest_dir="$QUESTS_DIR/$quest_name"
    
    print_status "Running all examples in quest: $quest_name"
    if [ "$VERBOSE" = true ]; then
        echo "========================================"
    fi
    
    if [ ! -d "$quest_dir" ]; then
        print_error "Quest directory not found: $quest_dir"
        return 1
    fi
    
    # Find all category folders (agnostic approach)
    for folder in "$quest_dir"/*; do
        if [ -d "$folder" ]; then
            local category_name=$(basename "$folder")
            run_quest_category "$quest_name" "$category_name"
        fi
    done
    
    if [ "$VERBOSE" = true ]; then
        echo "========================================"
    fi
    print_success "Completed all examples in quest: $quest_name"
    echo ""
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  quest <name> [category]  Run examples in a specific quest (and optionally category)"
    echo "  list [quest]             List all available quests and examples"
    echo "  example <file>           Run a specific example file"
    echo "  test                     Test database connection"
    echo "  config                   Show current configuration"
    echo ""
    echo "Examples:"
    echo "  $0 quest recursive-cte                    # Run all recursive-cte examples"
    echo "  $0 quest window-functions                 # Run all window-functions examples"
    echo "  $0 quest recursive-cte 01-hierarchical-graph-traversal  # Run specific category"
    echo "  $0 list                                  # List all quests"
    echo "  $0 list recursive-cte                    # List recursive-cte examples"
    echo "  $0 example quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo "  $0 test                                  # Test database connection"
    echo "  $0 config                                # Show current configuration"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST       Database host (overrides .env)"
    echo "  -p, --port PORT       Database port (overrides .env)"
    echo "  -u, --user USER       Database user (overrides .env)"
    echo "  -d, --database DB     Database name (overrides .env)"
    echo "  -w, --password PASS   Database password (overrides .env)"
    echo "  -v, --verbose         Show SQL output (default: true)"
    echo "  -q, --quiet           Hide SQL output, show only status"
    echo "  --help                Show this help message"
    echo ""
    echo "Configuration:"
    echo "  The script loads database credentials from .env file"
    echo "  Copy env.example to .env and customize as needed"
    echo "  Command line options override .env values"
    echo ""
    echo "Note: Make sure Docker containers are running with 'docker-compose up -d'"
}

# Function to determine quest status dynamically (agnostic approach)
# Simple logic: if it has examples, it's in progress; if it has run-all-examples.sql, it's complete
get_quest_status() {
    local quest_dir="$1"
    local quest_name="$2"
    
    # Check if quest has any SQL files
    local total_files=$(find "$quest_dir" -name "*.sql" | wc -l)
    
    if [ "$total_files" -eq 0 ]; then
        echo " 📋 Planned"
        return
    fi
    
    # Check if quest has a run-all-examples.sql file (indicates completion)
    if [ -f "$quest_dir/run-all-examples.sql" ]; then
        echo " ✅ Complete"
        return
    fi
    
    # If it has examples but no run-all file, it's in progress
    echo " 🚧 In Progress"
}

# Function to list all quests
list_quests() {
    echo "Available quests:"
    echo ""
    
    if [ ! -d "$QUESTS_DIR" ]; then
        print_error "Quests directory not found: $QUESTS_DIR"
        return 1
    fi
    
    for quest_dir in "$QUESTS_DIR"/*; do
        if [ -d "$quest_dir" ]; then
            local quest_name=$(basename "$quest_dir")
            local quest_status=$(get_quest_status "$quest_dir" "$quest_name")
            
            echo "🎮 $quest_name$quest_status"
        fi
    done
    echo ""
}

# Function to list examples in a specific quest
list_quest_examples() {
    local quest_name="$1"
    local quest_dir="$QUESTS_DIR/$quest_name"
    
    if [ ! -d "$quest_dir" ]; then
        print_error "Quest directory not found: $quest_dir"
        return 1
    fi
    
    # Get quest statistics
    local total_files=$(find "$quest_dir" -name "*.sql" | wc -l)
    local category_count=$(find "$quest_dir" -maxdepth 1 -type d | wc -l)
    category_count=$((category_count - 1))  # Subtract 1 for the quest directory itself
    local quest_status=$(get_quest_status "$quest_dir" "$quest_name")
    
    echo "Examples in quest: $quest_name$quest_status"
    echo "📊 Statistics: $total_files examples across $category_count categories"
    echo ""
    
    # Find all category folders (agnostic approach)
    for folder in "$quest_dir"/*; do
        if [ -d "$folder" ]; then
            local category_name=$(basename "$folder")
            local category_files=$(find "$folder" -name "*.sql" | wc -l)
            echo "📁 $category_name ($category_files examples)"
            for file in "$folder"/*.sql; do
                if [ -f "$file" ]; then
                    echo "  📄 $(basename "$file")"
                fi
            done
            echo ""
        fi
    done
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -p|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -w|--password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            VERBOSE=false
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        test)
            COMMAND="test"
            shift
            ;;
        config)
            COMMAND="config"
            shift
            ;;
        quest)
            COMMAND="quest"
            QUEST_NAME="$2"
            CATEGORY_NAME="$3"
            if [ -n "$CATEGORY_NAME" ]; then
                shift 3
            else
                shift 2
            fi
            ;;
        list)
            COMMAND="list"
            LIST_QUEST="$2"
            if [ -n "$LIST_QUEST" ]; then
                shift 2
            else
                shift
            fi
            ;;
        example)
            COMMAND="example"
            EXAMPLE_FILE="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if command is provided
if [ -z "$COMMAND" ]; then
    print_error "No command specified"
    show_usage
    exit 1
fi

# Execute command
case $COMMAND in
    test)
        test_connection
        ;;
    config)
        show_config
        ;;
    quest)
        if [ -z "$QUEST_NAME" ]; then
            print_error "Quest name not specified"
            show_usage
            exit 1
        fi
        
        if [ -n "$CATEGORY_NAME" ]; then
            run_quest_category "$QUEST_NAME" "$CATEGORY_NAME"
        else
            run_quest "$QUEST_NAME"
        fi
        ;;
    list)
        if [ -n "$LIST_QUEST" ]; then
            list_quest_examples "$LIST_QUEST"
        else
            list_quests
        fi
        ;;
    example)
        if [ -z "$EXAMPLE_FILE" ]; then
            print_error "Example file not specified"
            show_usage
            exit 1
        fi
        
        if [ -f "$EXAMPLE_FILE" ]; then
            run_example "$EXAMPLE_FILE"
        else
            print_error "Example file not found: $EXAMPLE_FILE"
            exit 1
        fi
        ;;
esac 