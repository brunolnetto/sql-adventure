#!/bin/bash

# SQL Adventure Examples Runner
# This script allows you to run examples manually after containers are up
# Works with any quest structure in the quests/ directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DB_HOST="localhost"
DB_PORT="5433"
DB_USER="postgres"
DB_NAME="sql_adventure_db"
DB_PASSWORD="postgres"
QUESTS_DIR="quests"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run a single example
run_example() {
    local file="$1"
    local filename=$(basename "$file")
    
    print_status "Running: $filename"
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file" > /dev/null 2>&1; then
        print_success "Completed: $filename"
    else
        print_error "Failed: $filename"
        return 1
    fi
}

# Function to run all examples in a quest category
run_quest_category() {
    local quest_name="$1"
    local category="$2"
    local folder="$QUESTS_DIR/$quest_name/$category"
    
    print_status "Running quest: $quest_name, category: $category"
    
    if [ ! -d "$folder" ]; then
        print_error "Category folder not found: $folder"
        return 1
    fi
    
    for file in "$folder"/*.sql; do
        if [ -f "$file" ]; then
            run_example "$file"
        fi
    done
    
    print_success "Completed quest: $quest_name, category: $category"
}

# Function to run all examples in a quest
run_quest() {
    local quest_name="$1"
    local quest_dir="$QUESTS_DIR/$quest_name"
    
    print_status "Running all examples in quest: $quest_name"
    
    if [ ! -d "$quest_dir" ]; then
        print_error "Quest directory not found: $quest_dir"
        return 1
    fi
    
    # Find all numbered category folders
    for folder in "$quest_dir"/[0-9]*; do
        if [ -d "$folder" ]; then
            local category_name=$(basename "$folder")
            run_quest_category "$quest_name" "$category_name"
        fi
    done
    
    print_success "Completed all examples in quest: $quest_name"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  quest <name> [category]  Run examples in a specific quest (and optionally category)"
    echo "  list [quest]             List all available quests and examples"
    echo "  example <file>           Run a specific example file"
    echo ""
    echo "Examples:"
    echo "  $0 quest recursive-cte                    # Run all recursive-cte examples"
    echo "  $0 quest recursive-cte hierarchical       # Run hierarchical category only"
    echo "  $0 list                                  # List all quests"
    echo "  $0 list recursive-cte                    # List recursive-cte examples"
    echo "  $0 example quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo ""
    echo "Options:"
    echo "  -h, --host HOST       Database host (default: localhost)"
    echo "  -p, --port PORT       Database port (default: 5433)"
    echo "  -u, --user USER       Database user (default: postgres)"
    echo "  -d, --database DB     Database name (default: sql_adventure_db)"
    echo "  -w, --password PASS   Database password (default: postgres)"
    echo "  --help                Show this help message"
    echo ""
    echo "Note: Make sure Docker containers are running with 'docker-compose up -d'"
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
            echo "🎮 $quest_name"
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
    
    echo "Examples in quest: $quest_name"
    echo ""
    
    # Find all numbered category folders
    for folder in "$quest_dir"/[0-9]*; do
        if [ -d "$folder" ]; then
            local category_name=$(basename "$folder")
            echo "📁 $category_name"
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
        --help)
            show_usage
            exit 0
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