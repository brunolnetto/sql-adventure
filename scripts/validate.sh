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
    cat << EOF
Usage: $0 <mode> [target] [options]

Modes:
  ai <file|quest>                    # AI-powered evaluation with caching
  ai-fast <file|quest>               # Fast AI evaluation (parallel + caching)
  ai-batch <quest>                   # Batch AI evaluation (optimized for large datasets)
  report <format> [quest]            # Generate reports (html|md|json)
  report-fast <format> [quest]       # Fast report generation (cached)
  validate <file|quest>              # Basic validation
  consistency                        # Check file consistency
  performance                        # Performance optimization test

Options:
  --parallel <jobs>                  # Set parallel job count (default: 4)
  --cache-ttl <seconds>              # Set cache TTL (default: 3600)
  --batch-size <size>                # Set batch size (default: 10)
  --force-regenerate                 # Force regenerate cached reports
  --no-cache                         # Disable caching
  --quiet                            # Quiet mode for parallel processing
  --verbose                          # Verbose output

Examples:
  $0 ai quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql
  $0 ai-fast quests/1-data-modeling
  $0 ai-batch quests/1-data-modeling --parallel 8
  $0 report html quests/1-data-modeling
  $0 report-fast json --force-regenerate
  $0 performance

Performance Modes:
  ai-fast: Parallel processing + caching + rate limiting
  ai-batch: Batch API calls + optimized data collection
  report-fast: Cached reports + incremental updates
EOF
}

# Function to parse performance options
parse_performance_options() {
    local parallel_jobs=4
    local cache_ttl=3600
    local batch_size=10
    local force_regenerate=false
    local no_cache=false
    local verbose=false
    local quiet=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --parallel)
                parallel_jobs="$2"
                shift 2
                ;;
            --cache-ttl)
                cache_ttl="$2"
                shift 2
                ;;
            --batch-size)
                batch_size="$2"
                shift 2
                ;;
            --force-regenerate)
                force_regenerate=true
                shift
                ;;
            --no-cache)
                no_cache=true
                shift
                ;;
            --quiet)
                quiet=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    echo "$parallel_jobs|$cache_ttl|$batch_size|$force_regenerate|$no_cache|$verbose|$quiet"
}

# Function to run fast AI evaluation
run_fast_ai_evaluation() {
    local target="$1"
    shift
    local options=$(parse_performance_options "$@")
    IFS='|' read -r parallel_jobs cache_ttl batch_size force_regenerate no_cache verbose quiet <<< "$options"
    
    print_header "🚀 Fast AI Evaluation (Parallel + Caching)"
    print_status "⚙️  Configuration: $parallel_jobs parallel jobs, ${cache_ttl}s cache TTL"
    
    # Initialize cache
    if [ "$no_cache" != "true" ]; then
        local cache_dir=$(init_cache)
        print_status "📁 Cache directory: $cache_dir"
    fi
    
    if [ -n "$target" ]; then
        if [ -d "$target" ]; then
            # Quest directory evaluation with parallel processing
            local quest_name=$(basename "$target")
            local output_dir="ai-evaluations/$quest_name"
            mkdir -p "$output_dir"
            
            print_status "🔄 Collecting files for parallel processing..."
            local files_array=()
            for sql_file in "$target"/*/*.sql; do
                [ ! -f "$sql_file" ] && continue
                files_array+=("$sql_file")
            done
            
            print_status "⚡ Processing ${#files_array[@]} files in parallel..."
            process_files_parallel "${files_array[@]}" "$quiet"
            
            print_success "✅ Fast evaluation completed for quest: $quest_name"
        else
            # Single file evaluation with caching
            local quest_name=$(echo "$target" | cut -d'/' -f2)
            local output_dir="ai-evaluations/$quest_name"
            mkdir -p "$output_dir"
            
            if [ "$no_cache" != "true" ]; then
                local sql_content=$(cat "$target" | head -50 | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-800)
                local cache_key=$(generate_cache_key "$sql_content" "llm")
                
                if check_cache "$cache_key"; then
                    print_status "📋 Using cached LLM analysis"
                fi
            fi
            
            execute_and_capture "$target" "$quest_name" "$output_dir"
        fi
    else
        # All files evaluation with batch processing
        print_header "🚀 Fast AI Evaluation - All Quests"
        
        local all_files=()
        for quest_dir in quests/*; do
            [ ! -d "$quest_dir" ] && continue
            for sql_file in "$quest_dir"/*/*.sql; do
                [ ! -f "$sql_file" ] && continue
                all_files+=("$sql_file")
            done
        done
        
        print_status "⚡ Processing ${#all_files[@]} files with batch optimization..."
        batch_llm_calls "${all_files[@]}"
        
        print_success "✅ Fast evaluation completed for all quests"
    fi
}

# Function to run batch AI evaluation
run_batch_ai_evaluation() {
    local target="$1"
    shift
    local options=$(parse_performance_options "$@")
    IFS='|' read -r parallel_jobs cache_ttl batch_size force_regenerate no_cache verbose quiet <<< "$options"
    
    print_header "📦 Batch AI Evaluation (Optimized for Large Datasets)"
    print_status "⚙️  Configuration: Batch size $batch_size, $parallel_jobs parallel jobs"
    
    if [ -n "$target" ] && [ -d "$target" ]; then
        local quest_name=$(basename "$target")
        local output_dir="ai-evaluations/$quest_name"
        mkdir -p "$output_dir"
        
        # Collect all files
        local files_array=()
        for sql_file in "$target"/*/*.sql; do
            [ ! -f "$sql_file" ] && continue
            files_array+=("$sql_file")
        done
        
        print_status "📦 Processing ${#files_array[@]} files in batches of $batch_size..."
        
        # Process in batches
        for ((i=0; i<${#files_array[@]}; i+=batch_size)); do
            local batch=("${files_array[@]:i:batch_size}")
            local batch_num=$((i/batch_size + 1))
            local total_batches=$(((${#files_array[@]} + batch_size - 1) / batch_size))
            
            print_status "📦 Processing batch $batch_num/$total_batches (${#batch[@]} files)..."
            process_batch "${batch[@]}" "$(init_cache)"
        done
        
        print_success "✅ Batch evaluation completed for quest: $quest_name"
    else
        print_error "❌ Batch evaluation requires a quest directory"
        return 1
    fi
}

# Function to run fast report generation
run_fast_report_generation() {
    local format="$1"
    local quest_filter="${2:-}"
    shift 2
    local options=$(parse_performance_options "$@")
    IFS='|' read -r parallel_jobs cache_ttl batch_size force_regenerate no_cache verbose quiet <<< "$options"
    
    print_header "🚀 Fast Report Generation (Cached + Incremental)"
    
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local report_file="reports/validation-report-$timestamp.$format"
    
    case "$format" in
        "html")
            if [ "$force_regenerate" = "true" ] || [ "$no_cache" = "true" ]; then
                generate_optimized_html_report "$quest_filter" > "$report_file"
            else
                generate_incremental_report "html" "$quest_filter" "$force_regenerate" > "$report_file"
            fi
            ;;
        "md")
            if [ "$force_regenerate" = "true" ] || [ "$no_cache" = "true" ]; then
                generate_optimized_markdown_report "$quest_filter" > "$report_file"
            else
                generate_incremental_report "markdown" "$quest_filter" "$force_regenerate" > "$report_file"
            fi
            ;;
        "json")
            if [ "$force_regenerate" = "true" ] || [ "$no_cache" = "true" ]; then
                generate_optimized_json_report "$quest_filter" > "$report_file"
            else
                generate_incremental_report "json" "$quest_filter" "$force_regenerate" > "$report_file"
            fi
            ;;
        *)
            print_error "❌ Unknown format: $format"
            return 1
            ;;
    esac
    
    print_success "✅ Fast report generated: $report_file"
}

# Function to run performance test
run_performance_test() {
    print_header "⚡ Performance Optimization Test"
    
    local test_file="quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"
    local iterations=5
    
    print_status "🧪 Testing performance optimizations..."
    
    # Test 1: Cache performance
    print_status "📊 Test 1: Cache Performance"
    local start_time=$(date +%s)
    for i in $(seq 1 $iterations); do
        local sql_content=$(cat "$test_file" | head -50 | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-800)
        local cache_key=$(generate_cache_key "$sql_content" "test")
        save_cache "$cache_key" "test_data" ".cache"
        check_cache "$cache_key" ".cache" >/dev/null
    done
    local end_time=$(date +%s)
    local cache_time=$((end_time - start_time))
    print_success "✅ Cache operations: ${cache_time}s for $iterations iterations"
    
    # Test 2: Parallel processing simulation
    print_status "📊 Test 2: Parallel Processing Simulation"
    start_time=$(date +%s)
    local pids=()
    for i in $(seq 1 4); do
        sleep 1 &
        pids+=($!)
    done
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    end_time=$(date +%s)
    local parallel_time=$((end_time - start_time))
    print_success "✅ Parallel processing: ${parallel_time}s (should be ~1s for 4 parallel jobs)"
    
    # Test 3: Report generation performance
    print_status "📊 Test 3: Report Generation Performance"
    start_time=$(date +%s)
    generate_optimized_json_report "1-data-modeling" >/dev/null
    end_time=$(date +%s)
    local report_time=$((end_time - start_time))
    print_success "✅ Report generation: ${report_time}s"
    
    # Summary
    echo ""
    print_status "📈 Performance Test Summary:"
    print_status "   Cache operations: ${cache_time}s"
    print_status "   Parallel processing: ${parallel_time}s"
    print_status "   Report generation: ${report_time}s"
    print_status "   Total optimization time: $((cache_time + parallel_time + report_time))s"
    
    if [ $cache_time -lt 5 ] && [ $parallel_time -lt 3 ] && [ $report_time -lt 10 ]; then
        print_success "🎉 Performance optimizations working well!"
    else
        print_warning "⚠️  Some performance optimizations may need tuning"
    fi
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
    case "${1:-help}" in
        "fast")
            [ -z "$2" ] && { print_error "File path required for fast mode"; show_usage; exit 1; }
            run_comprehensive_validation "$2"
            ;;
        "ai")
            run_ai_evaluation "${2:-}"
            ;;
        "ai-fast")
            # Check if second argument is an option (starts with --)
            if [[ "${2:-}" == --* ]]; then
                # No target specified, process all quests with options
                run_fast_ai_evaluation "" "${@:2}"
            else
                # Target specified, pass target and remaining options
                run_fast_ai_evaluation "${2:-}" "${@:3}"
            fi
            ;;
        "ai-batch")
            # Check if second argument is an option (starts with --)
            if [[ "${2:-}" == --* ]]; then
                # No target specified, process all quests with options
                run_batch_ai_evaluation "" "${@:2}"
            else
                # Target specified, pass target and remaining options
                run_batch_ai_evaluation "${2:-}" "${@:3}"
            fi
            ;;
        "report")
            generate_formatted_report "${2:-html}"
            ;;
        "report-fast")
            # Check if third argument is an option (starts with --)
            if [[ "${3:-}" == --* ]]; then
                # No quest filter specified, process all quests with options
                run_fast_report_generation "${2:-html}" "" "${@:3}"
            else
                # Quest filter specified, pass format, quest, and remaining options
                run_fast_report_generation "${2:-html}" "${3:-}" "${@:4}"
            fi
            ;;
        "validate")
            run_comprehensive_validation "$2"
            ;;
        "output")
            run_output_validation "$2"
            ;;
        "consistency")
            run_consistency_check
            ;;
        "performance")
            run_performance_test
            ;;
        "list")
            print_header "SQL Files"
            find quests -name "*.sql" | sort
            ;;
        "help"|"-h"|"--help"|*)
            show_usage
            exit 0
            ;;
    esac
}

# Run main function with all arguments
main "$@" 