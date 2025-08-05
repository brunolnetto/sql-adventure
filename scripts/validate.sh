#!/bin/bash

# Comprehensive SQL Validation Script
# Quest-agnostic validation with AI-powered pattern detection and evaluation

set -e

# Source dependencies
source "$(dirname "$0")/print-utils.sh"
source "$(dirname "$0")/ai-utils.sh"
source "$(dirname "$0")/report-utils.sh"

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
}

load_env

# Function to check SQL file structure
check_structure() {
    local file="$1"
    local issues=0
    
    [ ! -f "$file" ] && { print_error "❌ File not found: $file"; return 1; }
    [ ! -s "$file" ] && { print_warning "⚠️  Empty file: $file"; issues=$((issues + 1)); }
    ! grep -q -E "(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|WITH|ALTER)" "$file" && { print_warning "⚠️  No SQL statements found"; issues=$((issues + 1)); }
    ! grep -q ";[[:space:]]*$" "$file" && { print_warning "⚠️  No semicolon termination found"; issues=$((issues + 1)); }
    
    return $issues
}

# Function to run comprehensive validation (quest-agnostic)
run_comprehensive_validation() {
    local file="$1" issues=0
    
    print_status "🔍 Validating: $(basename "$file")"
    
    check_structure "$file" || issues=$((issues + 1))
    
    local patterns=$(detect_sql_patterns "$file")
    if [ -n "$patterns" ]; then
        print_success "✅ Detected SQL patterns: $patterns"
    else
        print_warning "⚠️  No specific SQL patterns detected"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to run consistency check
run_consistency_check() {
    print_header "Consistency Check"
    
    local total_files=0 consistent_files=0 inconsistent_files=0
    
    for quest_dir in quests/*; do
        [ ! -d "$quest_dir" ] && continue
        
        local quest_name=$(basename "$quest_dir")
        print_status "Checking quest: $quest_name"
        
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            
            total_files=$((total_files + 1))
            local filename=$(basename "$file")
            
            if [[ "$filename" =~ ^[0-9]{2}-.*\.sql$ ]]; then
                consistent_files=$((consistent_files + 1))
            else
                print_warning "⚠️  Inconsistent naming: $filename"
                inconsistent_files=$((inconsistent_files + 1))
            fi
            
            ! grep -q "^--.*PURPOSE:" "$file" && { print_warning "⚠️  Missing PURPOSE header: $filename"; inconsistent_files=$((inconsistent_files + 1)); }
            ! grep -q "^--.*DIFFICULTY:" "$file" && { print_warning "⚠️  Missing DIFFICULTY header: $filename"; inconsistent_files=$((inconsistent_files + 1)); }
        done
    done
    
    print_status "📊 Consistency Results: $consistent_files/$total_files files consistent"
    
    if [ $inconsistent_files -gt 0 ]; then
        print_warning "⚠️  $inconsistent_files files have consistency issues"
        return 1
    else
        print_success "✅ All files are consistent"
        return 0
    fi
}


# Function to capture and validate output
capture_and_validate_output() {
    local file="$1" filename=$(basename "$file")
    local quest_name=$(echo "$file" | cut -d'/' -f2)
    local output_dir="validation-outputs/$quest_name"
    
    mkdir -p "$output_dir"
    
    local output_file="$output_dir/$(basename "$file" .sql).output"
    local expected_file="$output_dir/$(basename "$file" .sql).expected"
    
    print_status "📊 Capturing output: $filename"
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$file" > "$output_file" 2>&1; then
        
        print_success "✅ Output captured: $output_file"
        
        if [ -f "$expected_file" ]; then
            if diff -q "$output_file" "$expected_file" > /dev/null; then
                print_success "✅ Output matches expected results"
            else
                print_warning "⚠️  Output differs from expected results"
                print_status "💡 Run: diff $output_file $expected_file"
            fi
        else
            print_status "⏭️  No expected file found: $expected_file"
        fi
        
        return 0
    else
        print_error "❌ Failed to capture output: $filename"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [MODE] [OPTIONS]"
    echo ""
    echo "Modes:"
    echo "  fast <file>              Quick syntax and structure validation (quest-agnostic)"
    echo "  ai <file|quest>          AI-powered output evaluation with pattern detection"
    echo "  all                      Comprehensive validation (default)"
    echo "  consistency              Check file naming and structure consistency"
    echo "  report [format]          Generate formatted validation report"
    echo "  list                     List all SQL files"
    echo "  help                     Show this help message"
    echo ""
    echo "Report Formats:"
    echo "  html                     Beautiful HTML report with styling"
    echo "  markdown                 Markdown report for documentation"
    echo "  json                     Comprehensive JSON report"
    echo "  all                      Generate all report formats"
    echo ""
    echo "Examples:"
    echo "  $0 fast quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"
    echo "  $0 ai quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"
    echo "  $0 ai quests/1-data-modeling/                    # Evaluate entire quest"
    echo "  $0 all"
    echo "  $0 consistency"
    echo "  $0 report html                                   # Generate HTML report"
    echo "  $0 report markdown                               # Generate Markdown report"
    echo "  $0 report all                                    # Generate all report formats"
    echo "  $0 output"
    echo "  $0 create-expected"
    echo ""
    echo "Features:"
    echo "  - Quest-agnostic validation (works with any SQL file)"
    echo "  - AI-powered SQL pattern detection"
    echo "  - Intelligent output evaluation"
    echo "  - Comprehensive reporting and analysis"
    echo "  - Automatic pattern recognition and validation"
    echo "  - Beautiful formatted reports (HTML, Markdown, JSON)"
}



# Function to run output validation
run_output_validation() {
    local file="$1"
    
    if [ -n "$file" ]; then
        capture_and_validate_output "$file"
    else
        print_header "Output Validation"
        
        local total_files=0 successful_captures=0 failed_captures=0
        
        for quest_dir in quests/*; do
            [ ! -d "$quest_dir" ] && continue
            
            local quest_name=$(basename "$quest_dir")
            print_status "Processing quest: $quest_name"
            
            for sql_file in "$quest_dir"/*/*.sql; do
                [ ! -f "$sql_file" ] && continue
                
                total_files=$((total_files + 1))
                
                if capture_and_validate_output "$sql_file"; then
                    successful_captures=$((successful_captures + 1))
                else
                    failed_captures=$((failed_captures + 1))
                fi
            done
        done
        
        echo ""
        print_status "📊 Output Validation Results: $successful_captures/$total_files successful captures"
        
        [ $failed_captures -gt 0 ] && print_warning "⚠️  $failed_captures files failed to capture output"
    fi
}

# Main execution
main() {
    case "${1:-all}" in
        "fast")
            [ -z "$2" ] && { print_error "File path required for fast mode"; show_usage; exit 1; }
            run_comprehensive_validation "$2"
            ;;
        "ai")
            run_ai_evaluation "${2:-}"
            ;;
        "all")
            show_comprehensive_report
            ;;
        "consistency")
            run_consistency_check
            ;;
        "report")
            generate_formatted_report "${2:-html}"
            ;;
        "output")
            run_output_validation "$2"
            ;;
        "list")
            print_header "SQL Files"
            find quests -name "*.sql" | sort
            ;;
        "help"|*)
            show_usage
            exit 0
            ;;
    esac
}

# Run main function with all arguments
main "$@" 