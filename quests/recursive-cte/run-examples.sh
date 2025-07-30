#!/bin/bash

# Recursive CTE Examples Runner
# This script allows you to run examples manually after containers are up

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

# Function to run all examples in a category
run_category() {
    local category="$1"
    local folder="$2"
    
    print_status "Running category: $category"
    
    if [ ! -d "$folder" ]; then
        print_error "Category folder not found: $folder"
        return 1
    fi
    
    for file in "$folder"/*.sql; do
        if [ -f "$file" ]; then
            run_example "$file"
        fi
    done
    
    print_success "Completed category: $category"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  all                    Run all examples"
    echo "  category <name>        Run examples in a specific category"
    echo "  example <file>         Run a specific example file"
    echo "  list                   List all available examples"
    echo ""
    echo "Categories:"
    echo "  hierarchical           Hierarchical & Graph Traversal"
    echo "  iteration             Iteration & Loop Emulation"
    echo "  pathfinding           Path-Finding & Analysis"
    echo "  transformation        Data Transformation & Parsing"
    echo "  simulation            Simulation & State Machines"
    echo "  repair                Data Repair & Self-Healing"
    echo "  mathematical          Mathematical & Theoretical"
    echo "  bonus                 Bonus Quirky Examples"
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

# Function to list all examples
list_examples() {
    echo "Available examples:"
    echo ""
    
    for folder in */; do
        if [ -d "$folder" ] && [[ "$folder" =~ ^[0-9] ]]; then
            echo "📁 $folder"
            for file in "$folder"*.sql; do
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
        all)
            COMMAND="all"
            shift
            ;;
        category)
            COMMAND="category"
            CATEGORY="$2"
            shift 2
            ;;
        example)
            COMMAND="example"
            EXAMPLE_FILE="$2"
            shift 2
            ;;
        list)
            COMMAND="list"
            shift
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
    all)
        print_status "Running all examples..."
        run_category "Hierarchical & Graph Traversal" "01-hierarchical-graph-traversal"
        run_category "Iteration & Loop Emulation" "02-iteration-loops"
        run_category "Path-Finding & Analysis" "03-path-finding-analysis"
        run_category "Data Transformation & Parsing" "04-data-transformation-parsing"
        run_category "Simulation & State Machines" "05-simulation-state-machines"
        run_category "Data Repair & Self-Healing" "06-data-repair-healing"
        run_category "Mathematical & Theoretical" "07-mathematical-theoretical"
        run_category "Bonus Quirky Examples" "08-bonus-quirky-examples"
        print_success "All examples completed!"
        ;;
    category)
        case $CATEGORY in
            hierarchical)
                run_category "Hierarchical & Graph Traversal" "01-hierarchical-graph-traversal"
                ;;
            iteration)
                run_category "Iteration & Loop Emulation" "02-iteration-loops"
                ;;
            pathfinding)
                run_category "Path-Finding & Analysis" "03-path-finding-analysis"
                ;;
            transformation)
                run_category "Data Transformation & Parsing" "04-data-transformation-parsing"
                ;;
            simulation)
                run_category "Simulation & State Machines" "05-simulation-state-machines"
                ;;
            repair)
                run_category "Data Repair & Self-Healing" "06-data-repair-healing"
                ;;
            mathematical)
                run_category "Mathematical & Theoretical" "07-mathematical-theoretical"
                ;;
            bonus)
                run_category "Bonus Quirky Examples" "08-bonus-quirky-examples"
                ;;
            *)
                print_error "Unknown category: $CATEGORY"
                show_usage
                exit 1
                ;;
        esac
        ;;
    example)
        if [ -f "$EXAMPLE_FILE" ]; then
            run_example "$EXAMPLE_FILE"
        else
            print_error "Example file not found: $EXAMPLE_FILE"
            exit 1
        fi
        ;;
    list)
        list_examples
        ;;
esac 