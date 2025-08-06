#!/bin/bash

# AI Utilities for SQL Adventure

# Contains all LLM-related functions for AI-powered analysis

# Performance optimization settings
PERF_CONFIG() {
    cat << EOF
# Performance Configuration
MAX_PARALLEL_JOBS=4
CACHE_DIR=".cache"
CACHE_TTL=3600
BATCH_SIZE=10
API_RATE_LIMIT=10
API_RATE_WINDOW=60
EOF
}

# Function to get performance configuration
get_perf_config() {
    local config_type="${1:-default}"
    
    case "$config_type" in
        "parallel")
            echo "4"  # Max parallel jobs
            ;;
        "cache_ttl")
            echo "3600"  # Cache TTL in seconds
            ;;
        "batch_size")
            echo "10"  # Batch size for operations
            ;;
        "rate_limit")
            echo "10|60"  # Requests per window
            ;;
        *)
            echo "4|3600|10|10|60"
            ;;
    esac
}

# Function to create cache directory
init_cache() {
    local cache_dir="${1:-.cache}"
    mkdir -p "$cache_dir"
    echo "$cache_dir"
}

# Function to generate cache key
generate_cache_key() {
    local content="$1"
    local prefix="${2:-ai}"
    echo "${prefix}_$(echo "$content" | md5sum | cut -d' ' -f1)"
}

# Function to check cache
check_cache() {
    local cache_key="$1"
    local cache_dir="${2:-.cache}"
    local cache_file="$cache_dir/$cache_key.json"
    local ttl="${3:-3600}"
    
    if [ -f "$cache_file" ]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [ $file_age -lt $ttl ]; then
            cat "$cache_file"
            return 0
        fi
    fi
    return 1
}

# Function to save to cache
save_cache() {
    local cache_key="$1"
    local content="$2"
    local cache_dir="${3:-.cache}"
    local cache_file="$cache_dir/$cache_key.json"
    
    mkdir -p "$cache_dir"
    echo "$content" > "$cache_file"
}

# Function to process files sequentially (changed from parallel to avoid conflicts)
process_files_parallel() {
    local all_args=("$@")
    local files_array=()
    local quiet_mode="false"
    local max_jobs=4
    
    # Parse arguments: files come first, then options
    local i=0
    while [ $i -lt ${#all_args[@]} ]; do
        local arg="${all_args[$i]}"
        if [ "$arg" = "true" ] || [ "$arg" = "false" ]; then
            quiet_mode="$arg"
        elif [[ "$arg" =~ ^[0-9]+$ ]]; then
            max_jobs="$arg"
        else
            files_array+=("$arg")
        fi
        i=$((i + 1))
    done
    
    local total_files=${#files_array[@]}
    local completed_files=0
    
    print_status "⚡ Processing $total_files files sequentially for better isolation..."
    
    for file in "${files_array[@]}"; do
        # Process files sequentially to avoid database conflicts
        process_single_file "$file" "$quiet_mode"
        completed_files=$((completed_files + 1))
        
        # Show progress
        if [ $((completed_files % 5)) -eq 0 ] || [ $completed_files -eq $total_files ]; then
            print_status "📊 Progress: $completed_files/$total_files files processed"
        fi
    done
    
    print_success "✅ Sequential processing completed: $completed_files/$total_files files"
}

# Function to process a single file (for parallel execution)
process_single_file() {
    local file="$1"
    local quiet_mode="${2:-false}"
    local quest_name=$(echo "$file" | cut -d'/' -f2)
    local output_dir="ai-evaluations/$quest_name"
    
    mkdir -p "$output_dir"
    execute_and_capture "$file" "$quest_name" "$output_dir" "$quiet_mode"
}

# Function to run AI evaluation
run_ai_evaluation() {
    local target="$1"
    
    if [ -n "$target" ]; then
        if [ -d "$target" ]; then
            # Quest directory evaluation
            local quest_name=$(basename "$target")
            local output_dir="ai-evaluations/$quest_name"
            mkdir -p "$output_dir"
            
            print_header "🤖 AI Evaluation - Quest: $quest_name"
            
            local total_files=0 total_processed=0 total_passed=0 total_failed=0 total_needs_review=0
            
            # Try both patterns: direct files and subdirectory files
            for sql_file in "$target"/*.sql "$target"/*/*.sql; do
                [ ! -f "$sql_file" ] && continue
                
                total_files=$((total_files + 1))
                
                if execute_and_capture "$sql_file" "$quest_name" "$output_dir"; then
                    total_processed=$((total_processed + 1))
                    
                    local eval_result=$(evaluate_output_ai "$sql_file" "$quest_name" "$output_dir")
                    local assessment=$(echo "$eval_result" | cut -d'|' -f1)
                    local score=$(echo "$eval_result" | cut -d'|' -f2)
                    
                    case "$assessment" in
                        "PASS") total_passed=$((total_passed + 1)); print_success "✅ $(basename "$sql_file") - PASS ($score/10)" ;;
                        "FAIL") total_failed=$((total_failed + 1)); print_error "❌ $(basename "$sql_file") - FAIL ($score/10)" ;;
                        "NEEDS_REVIEW") total_needs_review=$((total_needs_review + 1)); print_warning "⚠️  $(basename "$sql_file") - NEEDS REVIEW ($score/10)" ;;
                    esac
                fi
            done
            
            echo ""
            print_status "📊 Quest Evaluation Results: $total_processed/$total_files processed"
            print_status "✅ Passed: $total_passed, ❌ Failed: $total_failed, ⚠️ Needs Review: $total_needs_review"
            
            [ $total_processed -eq $total_files ] && print_success "🎉 Quest '$quest_name' fully processed and evaluated!"
        else
            # Single file evaluation
            local quest_name=$(echo "$target" | cut -d'/' -f2)
            local output_dir="ai-evaluations/$quest_name"
            mkdir -p "$output_dir"
            
            if execute_and_capture "$target" "$quest_name" "$output_dir"; then
                evaluate_output_ai "$target" "$quest_name" "$output_dir"
            fi
        fi
    else
        # All files evaluation
        print_header "AI-Powered Output Evaluation"
        
        local total_files=0 total_processed=0 total_passed=0 total_failed=0 total_needs_review=0
        
        for quest_dir in quests/*; do
            [ ! -d "$quest_dir" ] && continue
            
            local quest_name=$(basename "$quest_dir")
            local output_dir="ai-evaluations/$quest_name"
            mkdir -p "$output_dir"
            
            print_status "Processing quest: $quest_name"
            
            # Try both patterns: direct files and subdirectory files
            for sql_file in "$quest_dir"/*.sql "$quest_dir"/*/*.sql; do
                [ ! -f "$sql_file" ] && continue
                
                total_files=$((total_files + 1))
                
                if execute_and_capture "$sql_file" "$quest_name" "$output_dir"; then
                    total_processed=$((total_processed + 1))
                    
                    local eval_result=$(evaluate_output_ai "$sql_file" "$quest_name" "$output_dir")
                    local assessment=$(echo "$eval_result" | cut -d'|' -f1)
                    local score=$(echo "$eval_result" | cut -d'|' -f2)
                    
                    case "$assessment" in
                        "PASS") total_passed=$((total_passed + 1)); print_success "✅ $(basename "$sql_file") - PASS ($score/10)" ;;
                        "FAIL") total_failed=$((total_failed + 1)); print_error "❌ $(basename "$sql_file") - FAIL ($score/10)" ;;
                        "NEEDS_REVIEW") total_needs_review=$((total_needs_review + 1)); print_warning "⚠️  $(basename "$sql_file") - NEEDS REVIEW ($score/10)" ;;
                    esac
                fi
            done
        done
        
        echo ""
        print_status "📊 AI Evaluation Results: $total_processed/$total_files processed"
        print_status "✅ Passed: $total_passed, ❌ Failed: $total_failed, ⚠️ Needs Review: $total_needs_review"
        
        [ $total_processed -eq $total_files ] && print_success "🎉 All files processed and evaluated!"
    fi
}

# Function to call LLM API
call_llm_api() {
    local system_prompt="$1"
    local user_prompt="$2"
    local model="${3:-gpt-4o-mini}"
    local temperature="${4:-0.3}"
    local max_tokens="${5:-1200}"
    
    # Ensure environment variables are available
    if [ -z "$OPENAI_API_KEY" ]; then
        # Try to load from .env file if not set
        if [ -f ".env" ]; then
            set -a
            source .env
            set +a
        fi
    fi
    
    if [ -z "$OPENAI_API_KEY" ]; then
        echo "ERROR: OPENAI_API_KEY not set"
        echo "DEBUG: Current working directory: $(pwd)"
        echo "DEBUG: .env file exists: $([ -f ".env" ] && echo "yes" || echo "no")"
        return 1
    fi
    
    # Debug: Check if we're in the right directory
    if [ ! -f ".env" ]; then
        echo "DEBUG: .env not found in $(pwd), trying parent directory"
        if [ -f "../.env" ]; then
            source ../.env
        fi
    fi
    
    local response=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [
                {
                    \"role\": \"system\",
                    \"content\": \"$system_prompt\"
                },
                {
                    \"role\": \"user\",
                    \"content\": \"$user_prompt\"
                }
            ],
            \"temperature\": $temperature,
            \"max_tokens\": $max_tokens
        }" 2>/dev/null)
    
    if [ -z "$response" ]; then
        echo "ERROR: Empty response from API"
        return 1
    fi
    
    if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
        echo "ERROR: API error: $(echo "$response" | jq -r '.error.message')"
        return 1
    fi
    
    # Debug: Check if response has content
    local content_check=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    if [ "$content_check" = "null" ] || [ -z "$content_check" ]; then
        echo "ERROR: No content in API response"
        echo "DEBUG: Full response: $response"
        return 1
    fi
    
    echo "$response"
}

# Function to batch LLM API calls
batch_llm_calls() {
    local files_array=("$@")
    local batch_size=$(get_perf_config "batch_size")
    local cache_dir=$(init_cache)
    local total_files=${#files_array[@]}
    local processed_files=0
    
    print_status "📦 Processing $total_files files in batches of $batch_size..."
    
    for ((i=0; i<${#files_array[@]}; i+=batch_size)); do
        local batch=("${files_array[@]:i:batch_size}")
        local batch_num=$((i/batch_size + 1))
        local total_batches=$(((${#files_array[@]} + batch_size - 1) / batch_size))
        
        print_status "📦 Processing batch $batch_num/$total_batches (${#batch[@]} files)..."
        
        # Process each file in the batch
        for file in "${batch[@]}"; do
            local quest_name=$(echo "$file" | cut -d'/' -f2)
            local output_dir="ai-evaluations/$quest_name"
            mkdir -p "$output_dir"
            
            # Process the file using quiet mode
            execute_and_capture "$file" "$quest_name" "$output_dir" "true"
            processed_files=$((processed_files + 1))
        done
        
        # Show progress
        if [ $((batch_num % 5)) -eq 0 ] || [ $batch_num -eq $total_batches ]; then
            print_status "📊 Progress: $processed_files/$total_files files processed"
        fi
    done
    
    print_success "✅ Batch processing completed: $processed_files/$total_files files"
}

# Function to process a batch of files
process_batch() {
    local batch=("$@")
    local cache_dir="${batch[-1]}"
    unset batch[-1]
    
    local batch_prompts=()
    local batch_files=()
    
    for file in "${batch[@]}"; do
        local sql_content=$(cat "$file" | head -50 | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-800)
        local cache_key=$(generate_cache_key "$sql_content" "llm")
        
        # Check cache first
        if ! check_cache "$cache_key" "$cache_dir"; then
            batch_prompts+=("$sql_content")
            batch_files+=("$file")
        fi
    done
    
    # Make batch API call if needed
    if [ ${#batch_prompts[@]} -gt 0 ]; then
        local batch_response=$(call_batch_llm_api "${batch_prompts[@]}")
        
        # Extract responses using jq with proper error handling
        if echo "$batch_response" | jq -e '.responses' >/dev/null 2>&1; then
            local responses=($(echo "$batch_response" | jq -r '.responses[]' 2>/dev/null))
            
            for i in "${!batch_files[@]}"; do
                local file="${batch_files[$i]}"
                local response="${responses[$i]:-}"
                if [ -n "$response" ]; then
                    local sql_content=$(cat "$file" | head -50 | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-800)
                    local cache_key=$(generate_cache_key "$sql_content" "llm")
                    
                    save_cache "$cache_key" "$response" "$cache_dir"
                fi
            done
        else
            print_warning "⚠️  Failed to parse batch response"
        fi
    fi
}

# Function to call LLM API with rate limiting
call_llm_api_with_rate_limit() {
    local system_prompt="$1"
    local user_prompt="$2"
    local model="${3:-gpt-4o-mini}"
    local temperature="${4:-0.3}"
    local max_tokens="${5:-1200}"
    
    # Rate limiting
    local rate_config=$(get_perf_config "rate_limit")
    local max_requests=$(echo "$rate_config" | cut -d'|' -f1)
    local window_seconds=$(echo "$rate_config" | cut -d'|' -f2)
    
    # Simple rate limiting using file-based tracking
    local rate_file=".cache/rate_limit"
    mkdir -p ".cache"
    
    local current_time=$(date +%s)
    local requests_this_window=0
    
    if [ -f "$rate_file" ]; then
        local last_request_time=$(head -1 "$rate_file" 2>/dev/null || echo "0")
        local requests_count=$(tail -1 "$rate_file" 2>/dev/null || echo "0")
        
        if [ $((current_time - last_request_time)) -lt $window_seconds ]; then
            requests_this_window=$requests_count
        fi
    fi
    
    if [ $requests_this_window -ge $max_requests ]; then
        local sleep_time=$((window_seconds - (current_time - last_request_time)))
        print_status "⏳ Rate limit reached, waiting ${sleep_time}s..."
        sleep $sleep_time
        requests_this_window=0
    fi
    
    # Make API call
    local response=$(call_llm_api "$system_prompt" "$user_prompt" "$model" "$temperature" "$max_tokens")
    
    # Update rate limit tracking
    echo "$current_time" > "$rate_file"
    echo "$((requests_this_window + 1))" >> "$rate_file"
    
    echo "$response"
}

# Function to call batch LLM API (if supported)
call_batch_llm_api() {
    local prompts=("$@")
    
    # For now, simulate batch processing by making individual calls
    # In a real implementation, you'd use a batch API endpoint
    local responses=()
    for prompt in "${prompts[@]}"; do
        local response=$(call_llm_api "You are an expert SQL instructor." "$prompt")
        # Escape the response properly for JSON
        local escaped_response=$(echo "$response" | jq -R -s .)
        responses+=("$escaped_response")
    done
    
    # Build proper JSON array using jq
    local json_array=$(printf '%s\n' "${responses[@]}" | jq -R . | jq -s .)
    echo "{\"responses\": $json_array}"
}

# Function to extract JSON from markdown response
extract_json_from_markdown() {
    local content="$1"
    
    # Handle empty content
    if [ -z "$content" ]; then
        echo '{"error": "Empty content provided"}'
        return
    fi
    
    # Check if content contains markdown JSON wrapper (avoid backticks in grep)
    if echo "$content" | grep -q "json"; then
        # Extract JSON using awk (most reliable method)
        local json_content=$(echo "$content" | awk '/^```json$/{flag=1;next} /^```$/{flag=0} flag')
        
        # Validate that we got valid JSON
        if [ -n "$json_content" ] && echo "$json_content" | jq . >/dev/null 2>&1; then
            echo "$json_content"
        else
            # If JSON is invalid, return error object
            echo '{"error": "Invalid JSON extracted from markdown", "raw_content": "'$(echo "$content" | jq -R -s . | tr -d '\n')'"}'
        fi
    else
        # Check if content is already valid JSON
        if echo "$content" | jq . >/dev/null 2>&1; then
            echo "$content"
        else
            # If not JSON, return as error object
            echo '{"error": "Content is not valid JSON", "raw_content": "'$(echo "$content" | jq -R -s . | tr -d '\n')'"}'
        fi
    fi
}

# LLM Configuration
LLM_CONFIG() {
    cat << EOF
# LLM Configuration Settings
LLM_MODEL="gpt-4o-mini"
LLM_TEMPERATURE="0.3"
LLM_MAX_TOKENS="1200"
LLM_TIMEOUT="30"

# Analysis-specific configurations
VALIDATION_TEMPERATURE="0.2"
VALIDATION_MAX_TOKENS="600"
DIFFICULTY_TEMPERATURE="0.2"
DIFFICULTY_MAX_TOKENS="500"
INTENT_TEMPERATURE="0.2"
INTENT_MAX_TOKENS="800"
EOF
}

# Function to get LLM configuration
get_llm_config() {
    local config_type="${1:-default}"
    
    case "$config_type" in
        "validation")
            echo "gpt-4o-mini|0.2|600"
            ;;
        "difficulty")
            echo "gpt-4o-mini|0.2|500"
            ;;
        "comprehensive")
            echo "gpt-4o-mini|0.3|1200"
            ;;
        "intent")
            echo "gpt-4o-mini|0.2|800"
            ;;
        *)
            echo "gpt-4o-mini|0.3|1200"
            ;;
    esac
}

# Function to build prompt for enhanced intent analysis
build_intent_analysis_prompt() {
    local sql_content="$1"
    local quest_name="$2"
    local basic_purpose="$3"
    local basic_concepts="$4"
    local basic_difficulty="$5"
    
    cat << EOF
Analyze this SQL exercise for educational intent: Quest: $quest_name, Basic Purpose: $basic_purpose, Basic Concepts: $basic_concepts, Basic Difficulty: $basic_difficulty. SQL Code: $sql_content. Provide JSON with: purpose (detailed_learning_objective, educational_context, real_world_applicability), learning_outcomes (specific_skills, knowledge_gained, competencies_developed), expected_results (what_learners_should_achieve, success_criteria, measurable_outcomes), difficulty_assessment (refined_difficulty_level, complexity_factors, time_estimate), and concepts (detailed_concept_breakdown, prerequisites, related_topics).
EOF
}

# Function to build LLM prompt for SQL analysis
build_sql_analysis_prompt() {
    local quest_name="$1"
    local purpose="$2"
    local difficulty="$3"
    local concepts="$4"
    local sql_patterns="$5"
    local sql_content="$6"
    local output_summary="$7"
    
    cat << EOF
Analyze this SQL exercise: Quest: $quest_name, Purpose: $purpose, Difficulty: $difficulty, Concepts: $concepts, SQL Patterns: $sql_patterns. SQL Code: $sql_content. Output: $output_summary. Provide JSON with: technical_analysis (syntax, logic, quality, performance_notes), educational_analysis (learning_value, appropriateness, difficulty_assessment, time_estimate), assessment (grade A-F, score 1-10, overall_assessment PASS/FAIL/NEEDS_REVIEW), output_validation (correctness_check, expected_vs_actual, output_quality, completeness_assessment), difficulty_calibration (current_level, suggested_level, complexity_analysis, adjustment_reasoning), recommendations (improvements, next_steps, best_practices), and summary.
EOF
}

# Function to build prompt for output validation only
build_output_validation_prompt() {
    local sql_content="$1"
    local output_content="$2"
    local expected_concepts="$3"
    
    cat << EOF
Validate this SQL output: SQL Code: $sql_content. Output: $output_content. Expected Concepts: $expected_concepts. Provide JSON with: correctness_check (is_output_correct, error_analysis), expected_vs_actual (matches_expectations, discrepancies), output_quality (readability, structure, completeness), and validation_score (1-10).
EOF
}

# Function to build prompt for difficulty assessment only
build_difficulty_assessment_prompt() {
    local sql_content="$1"
    local current_difficulty="$2"
    local concepts="$3"
    
    cat << EOF
Assess the difficulty of this SQL exercise: SQL Code: $sql_content. Current Difficulty: $current_difficulty. Concepts: $concepts. Provide JSON with: current_level (beginner/intermediate/advanced/expert), suggested_level, complexity_analysis (factors, reasoning), and adjustment_recommendation (keep/upgrade/downgrade).
EOF
}

# Function to build LLM system prompt
build_system_prompt() {
    local analysis_type="${1:-sql_analysis}"
    
    case "$analysis_type" in
        "sql_analysis")
            echo "You are an expert SQL instructor and educational content evaluator. Provide comprehensive analysis in JSON format."
            ;;
        "output_validation")
            echo "You are an expert SQL output validator. Analyze SQL execution results for correctness and quality."
            ;;
        "difficulty_assessment")
            echo "You are an expert educational content assessor. Evaluate the complexity and difficulty of SQL exercises."
            ;;
        "intent_analysis")
            echo "You are an expert educational content evaluator. Analyze SQL exercises for educational intent and provide detailed JSON output."
            ;;
        *)
            echo "You are an expert SQL instructor and educational content evaluator. Provide comprehensive analysis in JSON format."
            ;;
    esac
}

# Function to evaluate output using AI (simplified for JSON approach)
evaluate_output_ai() {
    local file="$1" quest_name="$2" output_dir="$3"
    
    print_status "🤖 AI Evaluation: $(basename "$file")"
    
    local subdir_path=$(dirname "$file" | sed 's|^quests/[^/]*/||')
    local json_file="$output_dir/${subdir_path}/$(basename "$file" .sql).json"
    
    if [ -f "$json_file" ]; then
        local assessment=$(jq -r '.basic_evaluation.overall_assessment' "$json_file")
        local score=$(jq -r '.basic_evaluation.score' "$json_file")
        local pattern_analysis=$(jq -r '.basic_evaluation.pattern_analysis' "$json_file")
        echo "$assessment|$score||$pattern_analysis"
    else
        echo "FAIL|0|JSON file not found|No analysis available"
    fi
}

# Function to detect SQL patterns using AI-like analysis
detect_sql_patterns() {
    local file="$1"
    local patterns=()
    
    # Pattern definitions
    local pattern_defs=(
        "CREATE TABLE:table_creation"
        "ALTER TABLE:table_modification"
        "DROP TABLE:table_deletion"
        "CREATE INDEX:index_creation"
        "DROP INDEX:index_deletion"
        "INSERT INTO:data_insertion"
        "UPDATE.*SET:data_update"
        "DELETE FROM:data_deletion"
        "SELECT.*FROM:data_querying"
        "WHERE:filtering"
        "JOIN:joining"
        "GROUP BY:aggregation"
        "ORDER BY:sorting"
        "LIMIT:limiting"
        "WITH RECURSIVE:recursive_cte"
        "WITH.*AS:common_table_expression"
        "OVER|PARTITION BY|ROW_NUMBER|RANK|DENSE_RANK|NTILE|LAG|LEAD:window_functions"
        "JSON|jsonb|->|->>|@>|?|jsonb_|json_:json_operations"
        "EXPLAIN|ANALYZE:performance_analysis"
        "VACUUM|REINDEX:maintenance"
        "PRIMARY KEY:primary_key"
        "FOREIGN KEY:foreign_key"
        "UNIQUE:unique_constraint"
        "CHECK:check_constraint"
        "NOT NULL:not_null_constraint"
        "EXISTS|NOT EXISTS:existence_check"
        "IN|NOT IN:membership_check"
        "UNION|UNION ALL:set_operations"
        "INTERSECT|EXCEPT:set_operations"
        "CASE.*WHEN:conditional_logic"
        "DISTINCT:distinct_operation"
        "HAVING:group_filtering"
        "OFFSET:pagination"
    )
    
    for pattern_def in "${pattern_defs[@]}"; do
        local regex="${pattern_def%:*}"
        local pattern_name="${pattern_def#*:}"
        if grep -q "$regex" "$file"; then
            patterns+=("$pattern_name")
        fi
    done
    
    echo "${patterns[*]}"
}

# Utility functions
clean_number() {
    local result=$(echo "$1" | tr -d '\n\r' | sed 's/^[[:space:]]*//' | sed 's/[^0-9]//g')
    [ -z "$result" ] && result="0"
    echo "$result"
}

count_matches() {
    local content="$1"
    local pattern="$2"
    local count=$(echo "$content" | grep -c "$pattern" 2>/dev/null || echo "0")
    clean_number "$count"
}

extract_metadata() {
    local file="$1"
    local field="$2"
    grep "^--.*$field:" "$file" | head -1 | sed "s/^--.*$field:\\s*//" || echo ""
}

# Function to analyze SQL file content and understand intent
analyze_sql_intent() {
    local file="$1"
    
    local purpose=$(extract_metadata "$file" "PURPOSE")
    local difficulty=$(extract_metadata "$file" "DIFFICULTY")
    local concepts=$(extract_metadata "$file" "CONCEPTS")
    local expected_results=$(grep -i "expected.*result" "$file" | head -1 || echo "")
    local learning_outcomes=$(grep -i "learning.*outcome" "$file" | head -1 || echo "")
    local sql_patterns=$(detect_sql_patterns "$file")
    
    echo "$purpose|$difficulty|$concepts|$expected_results|$learning_outcomes|$sql_patterns"
}

# Function to execute SQL file and capture output (unified with quiet mode flag)
execute_and_capture() {
    local file="$1"
    local quest_name="$2"
    local output_dir="$3"
    local quiet_mode="${4:-false}"
    
    local filename=$(basename "$file")
    local subdir_path=$(dirname "$file" | sed 's|^quests/[^/]*/||')
    local json_file="$output_dir/${subdir_path}/$(basename "$file" .sql).json"
    local json_dir=$(dirname "$json_file")
    
    mkdir -p "$json_dir"
    
    # Analyze SQL intent
    local intent_result=$(analyze_sql_intent "$file")
    IFS='|' read -r purpose difficulty concepts expected_results learning_outcomes sql_patterns <<< "$intent_result"
    
    # Execute SQL file and capture output
    local output_content=""
    local execution_success=false
    
    # Create unique temporary file for this execution
    local temp_output_file="/tmp/sql_output_$(basename "$file" .sql)_$$"
    
    if [ "$quiet_mode" != "true" ]; then
        print_status "🔍 Executing: $filename"
    fi
    
    # Use transaction isolation instead of separate databases
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "BEGIN; $(cat "$file"); ROLLBACK;" > "$temp_output_file" 2>&1; then
        
        output_content=$(cat "$temp_output_file")
        execution_success=true
        
        if [ "$quiet_mode" != "true" ]; then
            print_success "✅ Output captured"
        fi
        
        # Analyze output
        local output_lines=$(clean_number "$(echo "$output_content" | wc -l)")
        local has_errors=$(count_matches "$output_content" "ERROR\|error")
        local has_results=$(count_matches "$output_content" "\([0-9]\+ rows\?\)")
        local has_warnings=$(count_matches "$output_content" "WARNING\|warning")
        
        if [ "$quiet_mode" != "true" ]; then
            print_status "📊 Output analysis: $output_lines lines, $has_errors errors, $has_warnings warnings, $has_results result sets"
        fi
        
        create_consolidated_json "$file" "$quest_name" "$purpose" "$difficulty" "$concepts" \
            "$expected_results" "$learning_outcomes" "$sql_patterns" "$output_content" \
            "$output_lines" "$has_errors" "$has_warnings" "$has_results" "$json_file" "$quiet_mode"
        
        # Cleanup
        rm -f "$temp_output_file"
        return 0
    else
        output_content=$(cat "$temp_output_file" 2>/dev/null || echo "")
        
        if [ "$quiet_mode" != "true" ]; then
            print_error "❌ Failed to execute: $filename"
        fi
        
        create_consolidated_json "$file" "$quest_name" "$purpose" "$difficulty" "$concepts" \
            "$expected_results" "$learning_outcomes" "$sql_patterns" "$output_content" \
            "0" "1" "0" "0" "$json_file" "$quiet_mode"
        
        # Cleanup
        rm -f "$temp_output_file"
        return 1
    fi
}

# Function to analyze intent with LLM (unified with quiet mode flag)
analyze_intent_with_llm() {
    local file="$1"
    local quest_name="$2"
    local basic_purpose="$3"
    local basic_concepts="$4"
    local basic_difficulty="$5"
    local quiet_mode="${6:-false}"
    
    # Read the SQL content
    local sql_content=$(cat "$file" | head -50 | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-800)
    
    # Build prompts
    local system_prompt=$(build_system_prompt "intent_analysis")
    local user_prompt=$(build_intent_analysis_prompt "$sql_content" "$quest_name" "$basic_purpose" "$basic_concepts" "$basic_difficulty")
    
    # Get intent-specific configuration
    local config=$(get_llm_config "intent")
    local model=$(echo "$config" | cut -d'|' -f1)
    local temperature=$(echo "$config" | cut -d'|' -f2)
    local max_tokens=$(echo "$config" | cut -d'|' -f3)
    
    if [ "$quiet_mode" != "true" ]; then
        print_status "📚 Analyzing educational intent..."
    fi
    
    local response=$(call_llm_api "$system_prompt" "$user_prompt" "$model" "$temperature" "$max_tokens")
    
    if [ $? -ne 0 ]; then
        echo "{\"error\": \"Failed to analyze intent\", \"details\": \"API call failed\", \"fallback\": \"Using basic analysis\"}"
        return
    fi
    
    local llm_content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    if [ "$llm_content" = "null" ] || [ -z "$llm_content" ]; then
        echo "{\"error\": \"Failed to analyze intent\", \"details\": \"API call failed\"}"
    else
        extract_json_from_markdown "$llm_content"
    fi
}

# Function to validate output only
validate_output_with_llm() {
    local sql_content="$1"
    local output_content="$2"
    local expected_concepts="$3"
    
    local system_prompt=$(build_system_prompt "output_validation")
    local user_prompt=$(build_output_validation_prompt "$sql_content" "$output_content" "$expected_concepts")
    
    # Get validation-specific configuration
    local config=$(get_llm_config "validation")
    local model=$(echo "$config" | cut -d'|' -f1)
    local temperature=$(echo "$config" | cut -d'|' -f2)
    local max_tokens=$(echo "$config" | cut -d'|' -f3)
    
    local response=$(call_llm_api "$system_prompt" "$user_prompt" "$model" "$temperature" "$max_tokens")
    local llm_content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    if [ "$llm_content" = "null" ] || [ -z "$llm_content" ]; then
        echo "{\"error\": \"Failed to validate output\", \"details\": \"API call failed\"}"
    else
        extract_json_from_markdown "$llm_content"
    fi
}

# Function to assess difficulty only
assess_difficulty_with_llm() {
    local sql_content="$1"
    local current_difficulty="$2"
    local concepts="$3"
    
    local system_prompt=$(build_system_prompt "difficulty_assessment")
    local user_prompt=$(build_difficulty_assessment_prompt "$sql_content" "$current_difficulty" "$concepts")
    
    # Get difficulty-specific configuration
    local config=$(get_llm_config "difficulty")
    local model=$(echo "$config" | cut -d'|' -f1)
    local temperature=$(echo "$config" | cut -d'|' -f2)
    local max_tokens=$(echo "$config" | cut -d'|' -f3)
    
    local response=$(call_llm_api "$system_prompt" "$user_prompt" "$model" "$temperature" "$max_tokens")
    local llm_content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    if [ "$llm_content" = "null" ] || [ -z "$llm_content" ]; then
        echo "{\"error\": \"Failed to assess difficulty\", \"details\": \"API call failed\"}"
    else
        extract_json_from_markdown "$llm_content"
    fi
}

# Function to process output with LLM (unified with quiet mode flag)
process_output_with_llm() {
    local file="$1"
    local quest_name="$2"
    local purpose="$3"
    local difficulty="$4"
    local concepts="$5"
    local output_content="$6"
    local sql_patterns="$7"
    local quiet_mode="${8:-false}"
    
    # Read the original SQL content
    local sql_content=$(cat "$file" | head -50 | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-800)
    
    # Create a simplified summary of the output
    local output_summary=$(echo "$output_content" | head -20 | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-500)
    
    # Build prompts
    local system_prompt=$(build_system_prompt "sql_analysis")
    local user_prompt=$(build_sql_analysis_prompt "$quest_name" "$purpose" "$difficulty" "$concepts" "$sql_patterns" "$sql_content" "$output_summary")
    
    # Get comprehensive analysis configuration
    local config=$(get_llm_config "comprehensive")
    local model=$(echo "$config" | cut -d'|' -f1)
    local temperature=$(echo "$config" | cut -d'|' -f2)
    local max_tokens=$(echo "$config" | cut -d'|' -f3)
    
    if [ "$quiet_mode" != "true" ]; then
        print_status "🔍 Comprehensive analysis..."
    fi
    
    local response=$(call_llm_api "$system_prompt" "$user_prompt" "$model" "$temperature" "$max_tokens")
    local llm_content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    if [ "$llm_content" = "null" ] || [ -z "$llm_content" ]; then
        echo "{\"error\": \"Failed to get LLM analysis\", \"details\": \"API call failed or invalid response\"}"
    else
        # Extract JSON from markdown response using our function
        extract_json_from_markdown "$llm_content"
    fi
} 

 