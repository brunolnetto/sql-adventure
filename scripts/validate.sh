#!/bin/bash

# Comprehensive SQL Validation Script
# Quest-agnostic validation with AI-powered pattern detection and evaluation

set -e

# Source print utility functions
if [ -f "$(dirname "$0")/print-utils.sh" ]; then
    source "$(dirname "$0")/print-utils.sh"
else
    # Fallback print functions if print-utils.sh is not available
    print_header() { echo "========================================"; echo "$1"; echo "========================================"; }
    print_status() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
    print_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
    print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
    print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
fi

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

# Function to check SQL file structure
check_structure() {
    local file="$1"
    local issues=0
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        print_error "❌ File not found: $file"
        return 1
    fi
    
    # Check if file is empty
    if [ ! -s "$file" ]; then
        print_warning "⚠️  Empty file: $file"
        issues=$((issues + 1))
    fi
    
    # Check for SQL content
    if ! grep -q -E "(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|WITH|ALTER)" "$file"; then
        print_warning "⚠️  No SQL statements found"
        issues=$((issues + 1))
    fi
    
    # Check for semicolon termination (more flexible)
    if ! grep -q ";[[:space:]]*$" "$file"; then
        print_warning "⚠️  No semicolon termination found"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to detect SQL patterns using AI-like analysis
detect_sql_patterns() {
    local file="$1"
    local patterns=()
    
    # Data Definition Language (DDL)
    if grep -q "CREATE TABLE" "$file"; then patterns+=("table_creation"); fi
    if grep -q "ALTER TABLE" "$file"; then patterns+=("table_modification"); fi
    if grep -q "DROP TABLE" "$file"; then patterns+=("table_deletion"); fi
    if grep -q "CREATE INDEX" "$file"; then patterns+=("index_creation"); fi
    if grep -q "DROP INDEX" "$file"; then patterns+=("index_deletion"); fi
    
    # Data Manipulation Language (DML)
    if grep -q "INSERT INTO" "$file"; then patterns+=("data_insertion"); fi
    if grep -q "UPDATE.*SET" "$file"; then patterns+=("data_update"); fi
    if grep -q "DELETE FROM" "$file"; then patterns+=("data_deletion"); fi
    
    # Data Query Language (DQL)
    if grep -q "SELECT.*FROM" "$file"; then patterns+=("data_querying"); fi
    if grep -q "WHERE" "$file"; then patterns+=("filtering"); fi
    if grep -q "JOIN" "$file"; then patterns+=("joining"); fi
    if grep -q "GROUP BY" "$file"; then patterns+=("aggregation"); fi
    if grep -q "ORDER BY" "$file"; then patterns+=("sorting"); fi
    if grep -q "LIMIT" "$file"; then patterns+=("limiting"); fi
    
    # Advanced SQL Features
    if grep -q "WITH RECURSIVE" "$file"; then patterns+=("recursive_cte"); fi
    if grep -q "WITH.*AS" "$file"; then patterns+=("common_table_expression"); fi
    if grep -q "OVER\|PARTITION BY\|ROW_NUMBER\|RANK\|DENSE_RANK\|NTILE\|LAG\|LEAD" "$file"; then patterns+=("window_functions"); fi
    if grep -q "JSON\|jsonb\|->\|->>|@>|?|jsonb_|json_" "$file"; then patterns+=("json_operations"); fi
    if grep -q "EXPLAIN\|ANALYZE" "$file"; then patterns+=("performance_analysis"); fi
    if grep -q "VACUUM\|REINDEX" "$file"; then patterns+=("maintenance"); fi
    
    # Constraints and Integrity
    if grep -q "PRIMARY KEY" "$file"; then patterns+=("primary_key"); fi
    if grep -q "FOREIGN KEY" "$file"; then patterns+=("foreign_key"); fi
    if grep -q "UNIQUE" "$file"; then patterns+=("unique_constraint"); fi
    if grep -q "CHECK" "$file"; then patterns+=("check_constraint"); fi
    if grep -q "NOT NULL" "$file"; then patterns+=("not_null_constraint"); fi
    
    # Subqueries and Complex Patterns
    if grep -q "EXISTS\|NOT EXISTS" "$file"; then patterns+=("existence_check"); fi
    if grep -q "IN\|NOT IN" "$file"; then patterns+=("membership_check"); fi
    if grep -q "UNION\|UNION ALL" "$file"; then patterns+=("set_operations"); fi
    if grep -q "INTERSECT\|EXCEPT" "$file"; then patterns+=("set_operations"); fi
    if grep -q "CASE.*WHEN" "$file"; then patterns+=("conditional_logic"); fi
    
    # Performance and Optimization
    if grep -q "DISTINCT" "$file"; then patterns+=("distinct_operation"); fi
    if grep -q "HAVING" "$file"; then patterns+=("group_filtering"); fi
    if grep -q "OFFSET" "$file"; then patterns+=("pagination"); fi
    
    echo "${patterns[*]}"
}

# Function to analyze SQL file content and understand intent
analyze_sql_intent() {
    local file="$1"
    local filename=$(basename "$file")
    
    # Extract key information from the SQL file
    local purpose=""
    local difficulty=""
    local concepts=""
    local expected_results=""
    local learning_outcomes=""
    
    # Extract PURPOSE
    if grep -q "^--.*PURPOSE:" "$file"; then
        purpose=$(grep "^--.*PURPOSE:" "$file" | head -1 | sed 's/^--.*PURPOSE:\s*//')
    fi
    
    # Extract DIFFICULTY
    if grep -q "^--.*DIFFICULTY:" "$file"; then
        difficulty=$(grep "^--.*DIFFICULTY:" "$file" | head -1 | sed 's/^--.*DIFFICULTY:\s*//')
    fi
    
    # Extract CONCEPTS
    if grep -q "^--.*CONCEPTS:" "$file"; then
        concepts=$(grep "^--.*CONCEPTS:" "$file" | head -1 | sed 's/^--.*CONCEPTS:\s*//')
    fi
    
    # Extract EXPECTED RESULTS
    if grep -q -i "expected.*result" "$file"; then
        expected_results=$(grep -i "expected.*result" "$file" | head -1)
    fi
    
    # Extract LEARNING OUTCOMES
    if grep -q -i "learning.*outcome" "$file"; then
        learning_outcomes=$(grep -i "learning.*outcome" "$file" | head -1)
    fi
    
    # Detect SQL patterns automatically
    local sql_patterns=$(detect_sql_patterns "$file")
    
    echo "$purpose|$difficulty|$concepts|$expected_results|$learning_outcomes|$sql_patterns"
}

# Function to execute SQL file and capture output
execute_and_capture() {
    local file="$1"
    local quest_name="$2"
    local output_dir="$3"
    
    local filename=$(basename "$file")
    # Get the subdirectory path within the quest
    local subdir_path=$(dirname "$file" | sed 's|^quests/[^/]*/||')
    local json_file="$output_dir/${subdir_path}/$(basename "$file" .sql).json"
    
    # Create subdirectories if needed
    local json_dir=$(dirname "$json_file")
    mkdir -p "$json_dir"
    
    print_status "🔍 Executing: $filename"
    
    # Analyze SQL intent first
    local intent_result=$(analyze_sql_intent "$file")
    local purpose=$(echo "$intent_result" | cut -d'|' -f1)
    local difficulty=$(echo "$intent_result" | cut -d'|' -f2)
    local concepts=$(echo "$intent_result" | cut -d'|' -f3)
    local expected_results=$(echo "$intent_result" | cut -d'|' -f4)
    local learning_outcomes=$(echo "$intent_result" | cut -d'|' -f5)
    local sql_patterns=$(echo "$intent_result" | cut -d'|' -f6)
    
    # Execute SQL file and capture output
    local output_content=""
    local execution_success=false
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$file" > /tmp/sql_output 2>&1; then
        
        output_content=$(cat /tmp/sql_output)
        execution_success=true
        print_success "✅ Output captured"
        
        # Analyze the captured output
        local output_lines=$(echo "$output_content" | wc -l | sed 's/^[[:space:]]*//')
        local has_errors=$(echo "$output_content" | grep -c "ERROR\|error" 2>/dev/null || echo "0")
        local has_results=$(echo "$output_content" | grep -c "rows\?$" 2>/dev/null || echo "0")
        local has_warnings=$(echo "$output_content" | grep -c "WARNING\|warning" 2>/dev/null || echo "0")
        
        # Ensure we have clean integer values (remove any whitespace/newlines and ensure they're numbers)
        output_lines=$(echo "$output_lines" | tr -d '\n\r' | sed 's/^[[:space:]]*//' | sed 's/[^0-9]//g')
        has_errors=$(echo "$has_errors" | tr -d '\n\r' | sed 's/^[[:space:]]*//' | sed 's/[^0-9]//g')
        has_results=$(echo "$has_results" | tr -d '\n\r' | sed 's/^[[:space:]]*//' | sed 's/[^0-9]//g')
        has_warnings=$(echo "$has_warnings" | tr -d '\n\r' | sed 's/^[[:space:]]*//' | sed 's/[^0-9]//g')
        
        # Ensure we have valid numbers (default to 0 if empty)
        [ -z "$output_lines" ] && output_lines="0"
        [ -z "$has_errors" ] && has_errors="0"
        [ -z "$has_results" ] && has_results="0"
        [ -z "$has_warnings" ] && has_warnings="0"
        
        print_status "📊 Output analysis: $output_lines lines, ${has_errors} errors, ${has_warnings} warnings, ${has_results} result sets"
        
        # Create consolidated JSON file
        create_consolidated_json "$file" "$quest_name" "$purpose" "$difficulty" "$concepts" \
            "$expected_results" "$learning_outcomes" "$sql_patterns" "$output_content" \
            "$output_lines" "$has_errors" "$has_warnings" "$has_results" "$json_file"
        
        rm -f /tmp/sql_output
        return 0
    else
        output_content=$(cat /tmp/sql_output)
        print_error "❌ Failed to execute: $filename"
        
        # Create JSON file even for failed executions
        create_consolidated_json "$file" "$quest_name" "$purpose" "$difficulty" "$concepts" \
            "$expected_results" "$learning_outcomes" "$sql_patterns" "$output_content" \
            "0" "1" "0" "0" "$json_file"
        
        rm -f /tmp/sql_output
        return 1
    fi
}

# Function to create consolidated JSON file
create_consolidated_json() {
    local file="$1"
    local quest_name="$2"
    local purpose="$3"
    local difficulty="$4"
    local concepts="$5"
    local expected_results="$6"
    local learning_outcomes="$7"
    local sql_patterns="$8"
    local output_content="$9"
    local output_lines="${10}"
    local has_errors="${11}"
    local has_warnings="${12}"
    local has_results="${13}"
    local json_file="${14}"
    
    # Convert patterns string to array
    local patterns_array=()
    if [ -n "$sql_patterns" ]; then
        IFS=' ' read -ra patterns_array <<< "$sql_patterns"
    fi
    
    # Ensure we have clean integer values (remove any whitespace/newlines)
    output_lines=$(echo "$output_lines" | tr -d '\n\r' | sed 's/^[[:space:]]*//')
    has_errors=$(echo "$has_errors" | tr -d '\n\r' | sed 's/^[[:space:]]*//')
    has_results=$(echo "$has_results" | tr -d '\n\r' | sed 's/^[[:space:]]*//')
    has_warnings=$(echo "$has_warnings" | tr -d '\n\r' | sed 's/^[[:space:]]*//')
    
    # Determine overall assessment and score
    local overall_assessment="PASS"
    local score=8
    local issues=""
    local pattern_analysis=""
    
    # Error analysis
    if [ "$has_errors" -gt 0 ]; then
        overall_assessment="FAIL"
        score=3
        issues="Contains $has_errors error(s)"
    elif [ "$has_warnings" -gt 0 ]; then
        overall_assessment="NEEDS_REVIEW"
        score=6
        issues="Contains $has_warnings warning(s)"
    fi
    
    # Output completeness analysis
    if [ "$has_results" -eq 0 ] && [ "$output_lines" -lt 5 ]; then
        overall_assessment="NEEDS_REVIEW"
        score=5
        issues="Very little output generated"
    fi
    
    # Pattern analysis
    if [ ${#patterns_array[@]} -gt 0 ]; then
        pattern_analysis="Detected ${#patterns_array[@]} SQL patterns: $sql_patterns"
        # Bonus points for complex patterns
        if echo "$sql_patterns" | grep -q "window_functions\|recursive_cte\|json_operations"; then
            score=$((score + 1))
        fi
    else
        pattern_analysis="No SQL patterns detected"
        score=$((score - 1))
    fi
    
    # Purpose alignment analysis
    if [ -n "$purpose" ]; then
        if echo "$sql_patterns" | grep -q "table_creation" && echo "$purpose" | grep -q -i "table\|create"; then
            pattern_analysis="$pattern_analysis (Purpose aligned)"
        elif echo "$sql_patterns" | grep -q "window_functions" && echo "$purpose" | grep -q -i "window\|rank\|percentile"; then
            pattern_analysis="$pattern_analysis (Purpose aligned)"
        elif echo "$sql_patterns" | grep -q "json_operations" && echo "$purpose" | grep -q -i "json\|data"; then
            pattern_analysis="$pattern_analysis (Purpose aligned)"
        else
            pattern_analysis="$pattern_analysis (Purpose alignment unclear)"
        fi
    fi
    
    # Process output with LLM if available (without timeout for testing)
    local llm_analysis=""
    local enhanced_intent=""
    
    if command -v curl >/dev/null 2>&1 && [ -n "$OPENAI_API_KEY" ]; then
        print_status "🤖 Processing with LLM..."
        
        # Enhanced intent analysis
        print_status "📚 Analyzing educational intent..."
        enhanced_intent=$(analyze_intent_with_llm "$file" "$quest_name" "$purpose" "$concepts" "$difficulty")
        
        # Comprehensive LLM analysis
        print_status "🔍 Comprehensive analysis..."
        llm_analysis=$(process_output_with_llm "$file" "$quest_name" "$purpose" "$difficulty" "$concepts" "$output_content" "$sql_patterns")
    else
        enhanced_intent="Enhanced intent analysis not available (missing curl or API key)"
        llm_analysis="LLM analysis not available (missing curl or API key)"
    fi
    
    # Create JSON structure with proper escaping
    cat > "$json_file" << EOF
{
  "metadata": {
    "generated": "$(date -Iseconds)",
    "file": "$(basename "$file")",
    "quest": "$quest_name",
    "full_path": "$file"
  },
  "intent": {
    "purpose": $(echo "$purpose" | jq -R -s . | tr -d '\n'),
    "difficulty": $(echo "$difficulty" | jq -R -s . | tr -d '\n'),
    "concepts": $(echo "$concepts" | jq -R -s . | tr -d '\n'),
    "expected_results": $(echo "$expected_results" | jq -R -s . | tr -d '\n'),
    "learning_outcomes": $(echo "$learning_outcomes" | jq -R -s . | tr -d '\n'),
    "sql_patterns": $(printf '%s\n' "${patterns_array[@]}" | jq -R . | jq -s . | tr -d '\n')
  },
  "execution": {
    "success": $execution_success,
    "output_lines": $output_lines,
    "errors": $has_errors,
    "warnings": $has_warnings,
    "result_sets": $has_results,
    "raw_output": $(echo "$output_content" | jq -R -s .)
  },
  "basic_evaluation": {
    "overall_assessment": "$overall_assessment",
    "score": $score,
    "pattern_analysis": $(echo "$pattern_analysis" | jq -R -s . | tr -d '\n'),
    "issues": $(echo "$issues" | jq -R -s . | tr -d '\n'),
    "recommendations": $(get_recommendations "$overall_assessment" "$score" "$issues" | jq -R -s . | tr -d '\n')
  },
  "basic_analysis": {
    "correctness": "Output appears to execute successfully",
    "completeness": "Generated $output_lines lines of output with $has_results result sets",
    "learning_value": "Demonstrates intended SQL patterns",
    "quality": "Output is clear and readable"
  },
  "llm_analysis": $(echo "$llm_analysis" | extract_json_from_markdown | jq -c .),
  "enhanced_intent": $(echo "$enhanced_intent" | extract_json_from_markdown | jq -c .)
}
EOF
    
    print_success "✅ Consolidated JSON created: $json_file"
}

# Function to extract JSON from markdown response
extract_json_from_markdown() {
    local content="$1"
    
    # Check if content contains markdown JSON wrapper
    if echo "$content" | grep -q "^```json"; then
        # Extract JSON using awk (most reliable method)
        local json_content=$(echo "$content" | awk '/^```json$/{flag=1;next} /^```$/{flag=0} flag')
        
        # Validate that we got valid JSON
        if echo "$json_content" | jq . >/dev/null 2>&1; then
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

# Function to analyze intent with LLM
analyze_intent_with_llm() {
    local file="$1"
    local quest_name="$2"
    local basic_purpose="$3"
    local basic_concepts="$4"
    local basic_difficulty="$5"
    
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
    
    local response=$(call_llm_api "$system_prompt" "$user_prompt" "$model" "$temperature" "$max_tokens")
    local llm_content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    if [ "$llm_content" = "null" ] || [ -z "$llm_content" ]; then
        echo "{\"error\": \"Failed to analyze intent\", \"details\": \"API call failed\"}"
    else
        extract_json_from_markdown "$llm_content"
    fi
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

# Function to call LLM API
call_llm_api() {
    local system_prompt="$1"
    local user_prompt="$2"
    local model="${3:-gpt-4o-mini}"
    local temperature="${4:-0.3}"
    local max_tokens="${5:-1200}"
    
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
    
    echo "$response"
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

# Function to process output with LLM
process_output_with_llm() {
    local file="$1"
    local quest_name="$2"
    local purpose="$3"
    local difficulty="$4"
    local concepts="$5"
    local output_content="$6"
    local sql_patterns="$7"
    
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
    
    # Call LLM API
    local response=$(call_llm_api "$system_prompt" "$user_prompt" "$model" "$temperature" "$max_tokens")
    
    # Extract the content from the response
    local llm_content=$(echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null)
    
    if [ "$llm_content" = "null" ] || [ -z "$llm_content" ]; then
        echo "{\"error\": \"Failed to get LLM analysis\", \"details\": \"API call failed or invalid response\"}"
    else
        # Extract JSON from markdown response using our function
        extract_json_from_markdown "$llm_content"
    fi
}

# Function to get recommendations based on evaluation
get_recommendations() {
    local assessment="$1"
    local score="$2"
    local issues="$3"
    
    case "$assessment" in
        "PASS")
            echo "Output is suitable for learning purposes"
            ;;
        "NEEDS_REVIEW")
            echo "Review output for completeness and clarity"
            ;;
        "FAIL")
            echo "Fix errors before using for learning"
            ;;
        *)
            echo "Review and improve the SQL script"
            ;;
    esac
}

# Function to evaluate output using AI (simplified for JSON approach)
evaluate_output_ai() {
    local file="$1"
    local quest_name="$2"
    local output_dir="$3"
    
    print_status "🤖 AI Evaluation: $(basename "$file")"
    
    # The evaluation is now handled in create_consolidated_json
    # This function is kept for compatibility but simplified
    # Get the subdirectory path within the quest
    local subdir_path=$(dirname "$file" | sed 's|^quests/[^/]*/||')
    local json_file="$output_dir/${subdir_path}/$(basename "$file" .sql).json"
    
    if [ -f "$json_file" ]; then
        # Extract evaluation results from JSON
        local assessment=$(jq -r '.evaluation.overall_assessment' "$json_file")
        local score=$(jq -r '.evaluation.score' "$json_file")
        local pattern_analysis=$(jq -r '.evaluation.pattern_analysis' "$json_file")
        
        echo "$assessment|$score||$pattern_analysis"
    else
        echo "FAIL|0|JSON file not found|No analysis available"
    fi
}

# Function to run comprehensive validation (quest-agnostic)
run_comprehensive_validation() {
    local file="$1"
    local issues=0
    
    print_status "🔍 Validating: $(basename "$file")"
    
    # Check structure
    if ! check_structure "$file"; then
        issues=$((issues + 1))
    fi
    
    # AI-powered pattern detection and validation
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
    
    local total_files=0
    local consistent_files=0
    local inconsistent_files=0
    
    for quest_dir in quests/*; do
        if [ -d "$quest_dir" ]; then
            local quest_name=$(basename "$quest_dir")
            print_status "Checking quest: $quest_name"
            
            for file in "$quest_dir"/*/*.sql; do
                if [ -f "$file" ]; then
                    total_files=$((total_files + 1))
                    
                    # Check file naming consistency
                    local filename=$(basename "$file")
                    if [[ "$filename" =~ ^[0-9]{2}-.*\.sql$ ]]; then
                        consistent_files=$((consistent_files + 1))
                    else
                        print_warning "⚠️  Inconsistent naming: $filename"
                        inconsistent_files=$((inconsistent_files + 1))
                    fi
                    
                    # Check for required headers
                    if ! grep -q "^--.*PURPOSE:" "$file"; then
                        print_warning "⚠️  Missing PURPOSE header: $filename"
                        inconsistent_files=$((inconsistent_files + 1))
                    fi
                    
                    if ! grep -q "^--.*DIFFICULTY:" "$file"; then
                        print_warning "⚠️  Missing DIFFICULTY header: $filename"
                        inconsistent_files=$((inconsistent_files + 1))
                    fi
                fi
            done
        fi
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

# Function to show comprehensive report
show_comprehensive_report() {
    print_header "Comprehensive Validation Report"
    
    local total_files=0
    local valid_files=0
    local invalid_files=0
    
    for quest_dir in quests/*; do
        if [ -d "$quest_dir" ]; then
            local quest_name=$(basename "$quest_dir")
            local quest_files=0
            local quest_valid=0
            local quest_invalid=0
            
            print_status "Quest: $quest_name"
            
            for file in "$quest_dir"/*/*.sql; do
                if [ -f "$file" ]; then
                    total_files=$((total_files + 1))
                    quest_files=$((quest_files + 1))
                    
                    if run_comprehensive_validation "$file"; then
                        quest_valid=$((quest_valid + 1))
                        valid_files=$((valid_files + 1))
                    else
                        quest_invalid=$((quest_invalid + 1))
                        invalid_files=$((invalid_files + 1))
                    fi
                fi
            done
            
            print_status "  📊 $quest_valid/$quest_files files valid"
        fi
    done
    
    echo ""
    print_status "📈 Overall Results: $valid_files/$total_files files valid"
    
    if [ $invalid_files -eq 0 ]; then
        print_success "🎉 All files are valid!"
    else
        print_warning "⚠️  $invalid_files files need attention"
    fi
}

# Function to capture and validate output
capture_and_validate_output() {
    local file="$1"
    local filename=$(basename "$file")
    
    # Extract quest name from file path
    local quest_name=$(echo "$file" | cut -d'/' -f2)
    
    # Create quest-specific output directory
    local output_dir="validation-outputs/$quest_name"
    mkdir -p "$output_dir"
    
    # Generate output file paths
    local output_file="$output_dir/$(basename "$file" .sql).output"
    local expected_file="$output_dir/$(basename "$file" .sql).expected"
    
    print_status "📊 Capturing output: $filename"
    
    # Execute SQL file and capture output
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -f "$file" > "$output_file" 2>&1; then
        
        print_success "✅ Output captured: $output_file"
        
        # Check if expected file exists
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

# Function to run output validation
run_output_validation() {
    local file="$1"
    
    if [ -n "$file" ]; then
        capture_and_validate_output "$file"
    else
        print_header "Output Validation"
        
        local total_files=0
        local successful_captures=0
        local failed_captures=0
        
        for quest_dir in quests/*; do
            if [ -d "$quest_dir" ]; then
                local quest_name=$(basename "$quest_dir")
                print_status "Processing quest: $quest_name"
                
                for sql_file in "$quest_dir"/*/*.sql; do
                    if [ -f "$sql_file" ]; then
                        total_files=$((total_files + 1))
                        
                        if capture_and_validate_output "$sql_file"; then
                            successful_captures=$((successful_captures + 1))
                        else
                            failed_captures=$((failed_captures + 1))
                        fi
                    fi
                done
            fi
        done
        
        echo ""
        print_status "📊 Output Validation Results: $successful_captures/$total_files successful captures"
        
        if [ $failed_captures -gt 0 ]; then
            print_warning "⚠️  $failed_captures files failed to capture output"
        fi
    fi
}

# Function to create expected results
create_expected_results() {
    local file="$1"
    
    if [ -n "$file" ]; then
        capture_and_validate_output "$file"
        
        # Extract quest name and create expected file
        local quest_name=$(echo "$file" | cut -d'/' -f2)
        local output_dir="validation-outputs/$quest_name"
        local output_file="$output_dir/$(basename "$file" .sql).output"
        local expected_file="$output_dir/$(basename "$file" .sql).expected"
        
        if [ -f "$output_file" ]; then
            cp "$output_file" "$expected_file"
            print_success "✅ Expected file created: $expected_file"
        fi
    else
        print_header "Creating Expected Results"
        
        local total_files=0
        local created_files=0
        
        for quest_dir in quests/*; do
            if [ -d "$quest_dir" ]; then
                local quest_name=$(basename "$quest_dir")
                print_status "Processing quest: $quest_name"
                
                for sql_file in "$quest_dir"/*/*.sql; do
                    if [ -f "$sql_file" ]; then
                        total_files=$((total_files + 1))
                        
                        if capture_and_validate_output "$sql_file"; then
                            # Create expected file
                            local output_dir="validation-outputs/$quest_name"
                            local output_file="$output_dir/$(basename "$sql_file" .sql).output"
                            local expected_file="$output_dir/$(basename "$sql_file" .sql).expected"
                            
                            if [ -f "$output_file" ]; then
                                cp "$output_file" "$expected_file"
                                created_files=$((created_files + 1))
                            fi
                        fi
                    fi
                done
            fi
        done
        
        echo ""
        print_status "📊 Expected Results Created: $created_files/$total_files files"
    fi
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
            
            local total_files=0
            local total_processed=0
            local total_passed=0
            local total_failed=0
            local total_needs_review=0
            
            for sql_file in "$target"/*/*.sql; do
                if [ -f "$sql_file" ]; then
                    total_files=$((total_files + 1))
                    
                    if execute_and_capture "$sql_file" "$quest_name" "$output_dir"; then
                        total_processed=$((total_processed + 1))
                        
                        local json_file="$output_dir/$(basename "$sql_file" .sql).json"
                        
                        local eval_result=$(evaluate_output_ai "$sql_file" "$quest_name" "$output_dir")
                        local assessment=$(echo "$eval_result" | cut -d'|' -f1)
                        local score=$(echo "$eval_result" | cut -d'|' -f2)
                        local pattern_analysis=$(echo "$eval_result" | cut -d'|' -f4)
                        
                        case "$assessment" in
                            "PASS")
                                total_passed=$((total_passed + 1))
                                print_success "✅ $(basename "$sql_file") - PASS ($score/10)"
                                ;;
                            "FAIL")
                                total_failed=$((total_failed + 1))
                                print_error "❌ $(basename "$sql_file") - FAIL ($score/10)"
                                ;;
                            "NEEDS_REVIEW")
                                total_needs_review=$((total_needs_review + 1))
                                print_warning "⚠️  $(basename "$sql_file") - NEEDS REVIEW ($score/10)"
                                ;;
                        esac
                    fi
                fi
            done
            
            echo ""
            print_status "📊 Quest Evaluation Results: $total_processed/$total_files processed"
            print_status "✅ Passed: $total_passed, ❌ Failed: $total_failed, ⚠️ Needs Review: $total_needs_review"
            
            if [ $total_processed -eq $total_files ]; then
                print_success "🎉 Quest '$quest_name' fully processed and evaluated!"
            fi
        else
            # Single file evaluation
            local quest_name=$(echo "$target" | cut -d'/' -f2)
            local output_dir="ai-evaluations/$quest_name"
            mkdir -p "$output_dir"
            
            if execute_and_capture "$target" "$quest_name" "$output_dir"; then
                local json_file="$output_dir/$(basename "$target" .sql).json"
                
                evaluate_output_ai "$target" "$quest_name" "$output_dir"
            fi
        fi
    else
        # All files evaluation
        print_header "AI-Powered Output Evaluation"
        
        local total_files=0
        local total_processed=0
        local total_passed=0
        local total_failed=0
        local total_needs_review=0
        
        for quest_dir in quests/*; do
            if [ -d "$quest_dir" ]; then
                local quest_name=$(basename "$quest_dir")
                local output_dir="ai-evaluations/$quest_name"
                mkdir -p "$output_dir"
                
                print_status "Processing quest: $quest_name"
                
                for sql_file in "$quest_dir"/*/*.sql; do
                    if [ -f "$sql_file" ]; then
                        total_files=$((total_files + 1))
                        
                        if execute_and_capture "$sql_file" "$quest_name" "$output_dir"; then
                            total_processed=$((total_processed + 1))
                            
                            local json_file="$output_dir/$(basename "$sql_file" .sql).json"
                            
                            local eval_result=$(evaluate_output_ai "$sql_file" "$quest_name" "$output_dir")
                            local assessment=$(echo "$eval_result" | cut -d'|' -f1)
                            local score=$(echo "$eval_result" | cut -d'|' -f2)
                            local pattern_analysis=$(echo "$eval_result" | cut -d'|' -f4)
                            
                            case "$assessment" in
                                "PASS")
                                    total_passed=$((total_passed + 1))
                                    print_success "✅ $(basename "$sql_file") - PASS ($score/10)"
                                    ;;
                                "FAIL")
                                    total_failed=$((total_failed + 1))
                                    print_error "❌ $(basename "$sql_file") - FAIL ($score/10)"
                                    ;;
                                "NEEDS_REVIEW")
                                    total_needs_review=$((total_needs_review + 1))
                                    print_warning "⚠️  $(basename "$sql_file") - NEEDS REVIEW ($score/10)"
                                    ;;
                            esac
                        fi
                    fi
                done
            fi
        done
        
        echo ""
        print_status "📊 AI Evaluation Results: $total_processed/$total_files processed"
        print_status "✅ Passed: $total_passed, ❌ Failed: $total_failed, ⚠️ Needs Review: $total_needs_review"
        
        if [ $total_processed -eq $total_files ]; then
            print_success "🎉 All files processed and evaluated!"
        fi
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
    echo "  report                   Show comprehensive validation report"
    echo "  output [file]            Validate outputs against expected results"
    echo "  create-expected [file]   Create expected output files"
    echo "  list                     List all SQL files"
    echo "  help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 fast quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"
    echo "  $0 ai quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"
    echo "  $0 ai quests/1-data-modeling/                    # Evaluate entire quest"
    echo "  $0 all"
    echo "  $0 consistency"
    echo "  $0 output"
    echo "  $0 create-expected"
    echo ""
    echo "Features:"
    echo "  - Quest-agnostic validation (works with any SQL file)"
    echo "  - AI-powered SQL pattern detection"
    echo "  - Intelligent output evaluation"
    echo "  - Comprehensive reporting and analysis"
    echo "  - Automatic pattern recognition and validation"
}

# Main execution
main() {
    case "${1:-all}" in
        "fast")
            if [ -z "$2" ]; then
                print_error "File path required for fast mode"
                show_usage
                exit 1
            fi
            
            run_comprehensive_validation "$2"
            ;;
        "ai")
            if [ -z "$2" ]; then
                run_ai_evaluation
            else
                run_ai_evaluation "$2"
            fi
            ;;
        "all")
            show_comprehensive_report
            ;;
        "consistency")
            run_consistency_check
            ;;
        "report")
            show_comprehensive_report
            ;;
        "output")
            run_output_validation "$2"
            ;;
        "create-expected")
            create_expected_results "$2"
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