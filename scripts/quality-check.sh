#!/bin/bash

# SQL Adventure Quality Assurance Script
# Comprehensive validation for SQL examples

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
    print_status "🔍 Validating SQL syntax for: $(basename "$file")"
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi
    
    # Test database connection
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "SELECT 1;" > /dev/null 2>&1; then
        print_error "Database connection failed"
        return 1
    fi
    
    # Validate syntax by attempting to parse the file
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "\i $file" > /dev/null 2>&1; then
        print_success "Syntax validation passed"
        return 0
    else
        print_error "Syntax validation failed"
        return 1
    fi
}

# Function to test idempotency
validate_idempotency() {
    local file="$1"
    print_status "🔄 Testing idempotency for: $(basename "$file")"
    
    # Create temporary database for testing
    local temp_db="temp_qa_$(date +%s)"
    
    # Create temporary database
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "CREATE DATABASE $temp_db;" > /dev/null 2>&1 || true
    
    # Run example twice
    local first_run=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$temp_db" \
        -c "\i $file" 2>&1 | wc -l)
    
    local second_run=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$temp_db" \
        -c "\i $file" 2>&1 | wc -l)
    
    # Clean up temporary database
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "DROP DATABASE IF EXISTS $temp_db;" > /dev/null 2>&1 || true
    
    # Check if runs are similar (allowing for minor differences)
    local diff=$((first_run - second_run))
    if [ $diff -lt 5 ] && [ $diff -gt -5 ]; then
        print_success "Idempotency test passed"
        return 0
    else
        print_warning "Idempotency test: Results differ significantly between runs"
        return 1
    fi
}

# Function to validate data quality
validate_data_quality() {
    local file="$1"
    print_status "📊 Validating data quality for: $(basename "$file")"
    
    # Check for required elements in the file
    local has_drop_table=$(grep -i "DROP TABLE" "$file" | wc -l)
    local has_create_table=$(grep -i "CREATE TABLE" "$file" | wc -l)
    local has_insert=$(grep -i "INSERT" "$file" | wc -l)
    local has_select=$(grep -i "SELECT" "$file" | wc -l)
    local has_cleanup=$(grep -i "DROP TABLE.*CASCADE" "$file" | wc -l)
    
    local issues=0
    
    if [ $has_drop_table -eq 0 ]; then
        print_warning "No DROP TABLE statements found (idempotency concern)"
        issues=$((issues + 1))
    fi
    
    if [ $has_create_table -eq 0 ]; then
        print_warning "No CREATE TABLE statements found"
        issues=$((issues + 1))
    fi
    
    if [ $has_insert -eq 0 ]; then
        print_warning "No INSERT statements found"
        issues=$((issues + 1))
    fi
    
    if [ $has_select -eq 0 ]; then
        print_warning "No SELECT statements found"
        issues=$((issues + 1))
    fi
    
    if [ $has_cleanup -eq 0 ]; then
        print_warning "No cleanup statements found (idempotency concern)"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "Data quality validation passed"
        return 0
    else
        print_warning "Data quality validation: $issues issues found"
        return 1
    fi
}

# Function to validate performance
validate_performance() {
    local file="$1"
    print_status "⚡ Testing performance for: $(basename "$file")"
    
    local iterations=3
    local total_time=0
    
    for i in $(seq 1 $iterations); do
        local start_time=$(date +%s.%N)
        
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -c "\i $file" > /dev/null 2>&1
        
        local end_time=$(date +%s.%N)
        local execution_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        total_time=$(echo "$total_time + $execution_time" | bc -l 2>/dev/null || echo "0")
    done
    
    local avg_time=$(echo "scale=3; $total_time / $iterations" | bc -l 2>/dev/null || echo "0")
    
    print_status "⏱️  Average execution time: ${avg_time}s"
    
    # Performance thresholds
    if (( $(echo "$avg_time > 5.0" | bc -l 2>/dev/null || echo "0") )); then
        print_warning "Performance warning: Execution time > 5s"
        return 1
    elif (( $(echo "$avg_time > 1.0" | bc -l 2>/dev/null || echo "0") )); then
        print_warning "Performance notice: Execution time > 1s"
        return 0
    else
        print_success "Performance validation passed"
        return 0
    fi
}

# Function to validate documentation
validate_documentation() {
    local file="$1"
    print_status "📝 Validating documentation for: $(basename "$file")"
    
    local has_header=$(grep -c "====" "$file" || echo "0")
    local has_comments=$(grep -c "^--" "$file" || echo "0")
    local has_cleanup_comment=$(grep -c "Clean up" "$file" || echo "0")
    
    local issues=0
    
    if [ $has_header -eq 0 ]; then
        print_warning "No header section found"
        issues=$((issues + 1))
    fi
    
    if [ $has_comments -lt 3 ]; then
        print_warning "Insufficient comments found"
        issues=$((issues + 1))
    fi
    
    if [ $has_cleanup_comment -eq 0 ]; then
        print_warning "No cleanup comment found"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "Documentation validation passed"
        return 0
    else
        print_warning "Documentation validation: $issues issues found"
        return 1
    fi
}

# Function to validate query context and purpose
validate_query_context() {
    local file="$1"
    print_status "🎯 Validating query context and purpose for: $(basename "$file")"
    
    # Check for context header
    local has_context=0
    local has_purpose=0
    local has_learning_outcome=0
    local has_expected_results=0
    
    if grep -q "Context:" "$file" 2>/dev/null; then
        has_context=1
    fi
    
    if grep -q "Purpose:" "$file" 2>/dev/null; then
        has_purpose=1
    fi
    
    if grep -q "Learning Outcome:" "$file" 2>/dev/null; then
        has_learning_outcome=1
    fi
    
    if grep -q "Expected Results:" "$file" 2>/dev/null; then
        has_expected_results=1
    fi
    
    local issues=0
    
    if [ $has_context -eq 0 ]; then
        print_warning "No context section found"
        issues=$((issues + 1))
    fi
    
    if [ $has_purpose -eq 0 ]; then
        print_warning "No purpose section found"
        issues=$((issues + 1))
    fi
    
    if [ $has_learning_outcome -eq 0 ]; then
        print_warning "No learning outcome specified"
        issues=$((issues + 1))
    fi
    
    if [ $has_expected_results -eq 0 ]; then
        print_warning "No expected results section found"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "Query context validation passed"
        return 0
    else
        print_warning "Query context validation: $issues issues found"
        return 1
    fi
}

# Function to validate all quest categories (automated checks only)
validate_all_quests() {
    print_status "🧪 Starting automated quality check for all quests..."
    echo ""

    total_files=0
    passed_files=0
    failed_files=0

    # Find all quest category directories (one level below quests/)
    for category_dir in quests/*/; do
        # Skip if not a directory
        [ -d "$category_dir" ] || continue
        category_name=$(basename "$category_dir")
        print_quest "Checking quest: $category_name"

        # Find all .sql files recursively in this quest
        mapfile -t sql_files < <(find "$category_dir" -type f -name "*.sql" | sort)
        if [[ ${#sql_files[@]} -eq 0 ]]; then
            print_warning "No SQL files found in $category_dir"
            continue
        fi
        print_status "Found ${#sql_files[@]} SQL files in $category_dir"

        for file in "${sql_files[@]}"; do
            print_status "Validating: $file"
            ((total_files++))
            if validate_example "$file" > /dev/null 2>&1; then
                print_success "✅ $file - PASSED (automated)"
                ((passed_files++))
            else
                print_error "❌ $file - FAILED (automated)"
                ((failed_files++))
            fi
        done
        echo ""
    done

    # Summary
    print_header "📋 AUTOMATED QUALITY CHECK SUMMARY"
    echo -e "${CYAN}Total files checked:${NC} $total_files"
    echo -e "${GREEN}Passed:${NC} $passed_files"
    echo -e "${RED}Failed:${NC} $failed_files"
    if [[ $failed_files -eq 0 ]]; then
        print_success "🎉 All files passed automated checks!"
    else
        print_warning "⚠️  Some files failed automated checks. Review the errors above."
    fi
    if [[ $total_files -gt 0 ]]; then
        local success_rate=$(( (passed_files * 100) / total_files ))
        echo -e "${CYAN}Success rate:${NC} ${success_rate}%"
    fi
    echo ""
    print_status "Automated quality check completed!"
    print_warning "Note: Context and educational value require AI evaluation using 'analyze-output' command"
}

# Function to analyze query output and context (AI handover)
analyze_query_output() {
    local file="$1"
    print_status "🤖 AI HANDOVER - Analyzing query logic and educational context for: $(basename "$file")"
    
    # Create temporary file for main query output
    local output_file=$(mktemp)
    local context_file=$(mktemp)
    local query_structure_file=$(mktemp)
    
    # Extract context information
    grep -A 10 "Context:" "$file" > "$context_file" 2>/dev/null || true
    grep -A 5 "Purpose:" "$file" >> "$context_file" 2>/dev/null || true
    grep -A 5 "Learning Outcome:" "$file" >> "$context_file" 2>/dev/null || true
    grep -A 10 "Expected Results:" "$file" >> "$context_file" 2>/dev/null || true
    
    # Extract and analyze the main query structure
    print_status "🔍 Analyzing query structure and logic..."
    awk '/^-- Demonstrate window functions/,/^-- Validation:/{print}' "$file" > "$query_structure_file" 2>/dev/null || true
    
    # Execute the main query and capture output
    print_status "📊 Executing main query and capturing output..."
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$file" > "$output_file" 2>&1; then
        
        # Extract validation queries and execute them
        local validation_file=$(mktemp)
        awk '/^-- Validation:/{flag=1; next} /^-- [^V]/{flag=0} flag{print}' "$file" > "$validation_file"
        
        if [ -s "$validation_file" ]; then
            print_status "🔍 Executing validation queries and capturing results..."
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
                -f "$validation_file" >> "$output_file" 2>&1
        fi
        
        # Display analysis for AI evaluation
        echo "========================================"
        print_header "🤖 AI EVALUATION DATA"
        print_status "📋 EDUCATIONAL CONTEXT:"
        if [ -s "$context_file" ]; then
            cat "$context_file"
        else
            echo "No context information found"
        fi
        
        echo ""
        print_status "🔍 QUERY STRUCTURE AND LOGIC:"
        if [ -s "$query_structure_file" ]; then
            cat "$query_structure_file"
        else
            echo "No main query structure found"
        fi
        
        echo ""
        print_status "📊 QUERY OUTPUT FOR ANALYSIS:"
        echo "File: $(basename "$file")"
        echo "Output captured successfully"
        echo "Output size: $(wc -l < "$output_file") lines"
        
        # Show full output for AI analysis
        echo ""
        print_status "📄 FULL OUTPUT (AI Analysis Required):"
        cat "$output_file"
        
        # Basic pattern analysis (for reference)
        echo ""
        print_status "🔍 BASIC PATTERN ANALYSIS (Reference Only):"
        local row_count=$(grep -c "^[0-9]" "$output_file" || echo "0")
        local error_count=$(grep -c "ERROR\|error" "$output_file" || echo "0")
        local warning_count=$(grep -c "WARNING\|warning" "$output_file" || echo "0")
        
        echo "Data rows returned: $row_count"
        echo "Error messages: $error_count"
        echo "Warning messages: $warning_count"
        
        # Check if output contains expected patterns
        if grep -q "ROW_NUMBER\|RANK\|DENSE_RANK" "$output_file" 2>/dev/null; then
            echo "✅ Window function output detected"
        fi
        
        if grep -q "PARTITION BY\|ORDER BY" "$output_file" 2>/dev/null; then
            echo "✅ Window function syntax detected"
        fi
        
        # AI handover summary
        echo ""
        print_header "🤖 AI EVALUATION REQUIRED"
        print_status "The following aspects require AI analysis:"
        print_status "1. Query logic and educational intent"
        print_status "2. SQL structure and window function usage"
        print_status "3. Learning progression and complexity"
        print_status "4. Query results alignment with expected results"
        print_status "5. Validation query effectiveness and educational value"
        print_status "6. Overall educational quality and clarity"
        
        # Store output for AI analysis
        echo ""
        print_status "💾 Output saved for AI analysis: $output_file"
        
    else
        print_error "Failed to execute query and capture output"
    fi
    
    # Clean up temporary files
    rm -f "$context_file" "$validation_file" "$query_structure_file"
    
    return 0
}

# Function to validate expected results (legacy - now redirects to analysis)
validate_expected_results() {
    local file="$1"
    print_status "🧪 Analyzing expected results for: $(basename "$file")"
    
    # Check for validation queries
    local has_validation_queries=0
    if grep -q "Validation:" "$file" 2>/dev/null; then
        has_validation_queries=1
    fi
    
    if [ $has_validation_queries -eq 0 ]; then
        print_warning "No validation queries found - analyzing main query output only"
    fi
    
    # Analyze the actual output instead of just validating
    analyze_query_output "$file"
    
    return 0
}

# Function to execute validation queries (legacy - now part of analysis)
execute_validation_queries() {
    local file="$1"
    print_status "🔍 Executing validation queries for: $(basename "$file")"
    
    # Create temporary file with only validation queries
    local temp_file=$(mktemp)
    
    # Extract validation queries (lines starting with -- Validation:)
    awk '/^-- Validation:/{flag=1; next} /^-- [^V]/{flag=0} flag{print}' "$file" > "$temp_file"
    
    if [ -s "$temp_file" ]; then
        # Execute validation queries and capture output
        local output_file=$(mktemp)
        if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
            -f "$temp_file" > "$output_file" 2>&1; then
            print_success "Validation queries executed successfully"
            print_status "📄 Validation output:"
            cat "$output_file"
        else
            print_warning "Some validation queries failed to execute"
        fi
        rm -f "$output_file"
    fi
    
    # Clean up temporary file
    rm -f "$temp_file"
}

# Function to run automated validation checks (boolean evaluation)
validate_example() {
    local file="$1"
    
    print_status "🔍 Starting automated validation for: $(basename "$file")"
    echo "========================================"
    
    local overall_result=0
    
    # Run automated checks (boolean evaluation)
    validate_syntax "$file" || overall_result=1
    validate_idempotency "$file" || overall_result=1
    validate_data_quality "$file" || overall_result=1
    validate_performance "$file" || overall_result=1
    validate_documentation "$file" || overall_result=1
    
    echo "========================================"
    
    if [ $overall_result -eq 0 ]; then
        print_success "✅ All automated checks passed for: $(basename "$file")"
    else
        print_warning "⚠️  Some automated checks failed for: $(basename "$file")"
    fi
    
    return $overall_result
}

# Function to run automated validation + AI handover for context analysis
validate_example_with_context() {
    local file="$1"
    
    print_status "🔍 Starting automated validation + AI handover for: $(basename "$file")"
    echo "========================================"
    
    local overall_result=0
    
    # Run automated checks (boolean evaluation)
    validate_syntax "$file" || overall_result=1
    validate_idempotency "$file" || overall_result=1
    validate_data_quality "$file" || overall_result=1
    validate_performance "$file" || overall_result=1
    validate_documentation "$file" || overall_result=1
    
    echo "========================================"
    
    if [ $overall_result -eq 0 ]; then
        print_success "✅ All automated checks passed for: $(basename "$file")"
    else
        print_warning "⚠️  Some automated checks failed for: $(basename "$file")"
    fi
    
    echo ""
    print_header "🤖 AI HANDOVER - CONTEXT ANALYSIS"
    print_status "The following context and output analysis requires AI evaluation:"
    print_status "- Educational intent and learning outcomes"
    print_status "- Query results vs expected results"
    print_status "- Context relevance and clarity"
    print_status "- Validation query effectiveness"
    echo ""
    
    # Hand over to AI analysis
    analyze_query_output "$file"
    
    return $overall_result
}

# Function to lint SQL files
lint_sql() {
    local file="$1"
    print_status "🔧 Linting SQL file: $(basename "$file")"
    
    local issues=0
    
    # Check for common issues
    if grep -q "SELECT \*" "$file"; then
        print_warning "Found SELECT * - consider specifying columns"
        issues=$((issues + 1))
    fi
    
    if grep -q "ORDER BY [0-9]" "$file"; then
        print_warning "Found ORDER BY with numbers - consider using column names"
        issues=$((issues + 1))
    fi
    
    if grep -q "GROUP BY [0-9]" "$file"; then
        print_warning "Found GROUP BY with numbers - consider using column names"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "Linting passed - no issues found"
        return 0
    else
        print_warning "Linting found $issues potential issues"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [FILE]"
    echo ""
    echo "Commands:"
    echo "  validate <file>              Run automated validation (syntax, performance, etc.)"
    echo "  validate-with-context <file> Run automated validation + AI handover for context"
    echo "  analyze-output <file>        AI handover: analyze query output and context"
    echo "  validate-all                 Run automated checks for all quest categories"
    echo "  syntax <file>                Validate SQL syntax only"
    echo "  idempotency <file>           Test idempotency only"
    echo "  data-quality <file>          Validate data quality only"
    echo "  performance <file>           Test performance only"
    echo "  docs <file>                  Validate documentation only"
    echo "  context <file>               Validate query context only"
    echo "  expected-results <file>      Analyze expected results (legacy)"
    echo "  lint <file>                  Lint SQL file for common issues"
    echo "  lint-with-context <file>     Lint SQL file with context validation"
    echo "  help                         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 validate quests/window-functions/01-basic-ranking/01-row-number.sql"
    echo "  $0 validate-with-context quests/window-functions/01-basic-ranking/01-row-number.sql"
    echo "  $0 analyze-output quests/window-functions/01-basic-ranking/01-row-number-enhanced.sql"
    echo "  $0 syntax quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql"
    echo "  $0 context quests/window-functions/02-aggregation-windows/01-running-totals.sql"
    echo "  $0 lint-with-context quests/window-functions/02-aggregation-windows/01-running-totals.sql"
}

# Main execution
case "${1:-help}" in
    validate)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_example "$2"
        ;;
    validate-with-context)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_example_with_context "$2"
        ;;
    analyze-output)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        analyze_query_output "$2"
        ;;
    validate-all)
        validate_all_quests
        ;;
    syntax)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_syntax "$2"
        ;;
    idempotency)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_idempotency "$2"
        ;;
    data-quality)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_data_quality "$2"
        ;;
    performance)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_performance "$2"
        ;;
    docs)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_documentation "$2"
        ;;
    context)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_query_context "$2"
        ;;
    expected-results)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        validate_expected_results "$2"
        ;;
    lint)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        lint_sql "$2"
        ;;
    lint-with-context)
        if [ -z "$2" ]; then
            print_error "File not specified"
            show_usage
            exit 1
        fi
        lint_sql "$2"
        validate_query_context "$2"
        ;;
    help|*)
        show_usage
        exit 0
        ;;
esac 