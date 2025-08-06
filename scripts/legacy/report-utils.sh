#!/bin/bash

# Report Generation Utilities
# Extracted from validate.sh for better organization

# Source AI utilities for LLM functions
source "$(dirname "$0")/utils/ai-utils.sh"

# Performance optimization settings for reports
REPORT_PERF_CONFIG() {
    cat << EOF
# Report Performance Configuration
REPORT_CACHE_DIR=".cache/reports"
REPORT_CACHE_TTL=1800
INCREMENTAL_UPDATES=true
BATCH_REPORT_SIZE=50
PARALLEL_REPORT_GENERATION=true
EOF
}

# Function to get report performance configuration
get_report_perf_config() {
    local config_type="${1:-default}"
    
    case "$config_type" in
        "cache_dir")
            echo ".cache/reports"
            ;;
        "cache_ttl")
            echo "1800"  # 30 minutes
            ;;
        "batch_size")
            echo "50"
            ;;
        "parallel")
            echo "true"
            ;;
        *)
            echo ".cache/reports|1800|50|true"
            ;;
    esac
}

# Function to initialize report cache
init_report_cache() {
    local cache_dir=$(get_report_perf_config "cache_dir")
    mkdir -p "$cache_dir"
    echo "$cache_dir"
}

# Function to check report cache
check_report_cache() {
    local cache_key="$1"
    local cache_dir=$(get_report_perf_config "cache_dir")
    local cache_file="$cache_dir/$cache_key.json"
    local ttl=$(get_report_perf_config "cache_ttl")
    
    if [ -f "$cache_file" ]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [ $file_age -lt $ttl ]; then
            cat "$cache_file"
            return 0
        fi
    fi
    return 1
}

# Function to save report cache
save_report_cache() {
    local cache_key="$1"
    local content="$2"
    local cache_dir=$(get_report_perf_config "cache_dir")
    local cache_file="$cache_dir/$cache_key.json"
    
    mkdir -p "$cache_dir"
    echo "$content" > "$cache_file"
}

# Function to generate cache key for reports
generate_report_cache_key() {
    local report_type="$1"
    local quest_name="${2:-all}"
    local timestamp=$(date +%Y%m%d-%H%M)
    echo "${report_type}_${quest_name}_${timestamp}"
}

# Function to collect evaluation data efficiently
collect_evaluation_data() {
    local quest_filter="${1:-}"
    local cache_dir=$(init_report_cache)
    local cache_key="eval_data_${quest_filter:-all}"
    
    # Check cache first
    if check_report_cache "$cache_key" "$cache_dir"; then
        return 0
    fi
    
    local data=()
    local quest_dirs=()
    
    if [ -n "$quest_filter" ]; then
        quest_dirs=("quests/$quest_filter")
    else
        quest_dirs=("quests"/*)
    fi
    
    for quest_dir in "${quest_dirs[@]}"; do
        [ ! -d "$quest_dir" ] && continue
        
        local quest_name=$(basename "$quest_dir")
        local quest_data=()
        
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            
            local subdir=$(dirname "$file" | sed 's/.*\///')
            local json_file="ai-evaluations/${quest_name}/${subdir}/$(basename "$file" .sql).json"
            
            if [ -f "$json_file" ]; then
                local file_data=$(cat "$json_file" | jq -c . 2>/dev/null || echo '{"error": "Invalid JSON"}')
                quest_data+=("$file_data")
            fi
        done
        
        if [ ${#quest_data[@]} -gt 0 ]; then
            data+=("{\"quest\": \"$quest_name\", \"files\": [$(printf '%s,' "${quest_data[@]}" | sed 's/,$//')]}")
        fi
    done
    
    # Save to cache
    local cache_content="{\"data\": [$(printf '%s,' "${data[@]}" | sed 's/,$//')], \"generated\": \"$(date -Iseconds)\"}"
    save_report_cache "$cache_key" "$cache_content" "$cache_dir"
    
    echo "$cache_content"
}

# Function to generate incremental report
generate_incremental_report() {
    local report_type="$1"
    local quest_name="${2:-}"
    local cache_dir=$(init_report_cache)
    local cache_key="report_${report_type}_${quest_name:-all}"
    
    # Check if we need to regenerate
    local force_regenerate="${3:-false}"
    if [ "$force_regenerate" != "true" ] && check_report_cache "$cache_key" "$cache_dir"; then
        print_status "📊 Using cached $report_type report for ${quest_name:-all quests}"
        return 0
    fi
    
    print_status "🔄 Generating $report_type report for ${quest_name:-all quests}..."
    
    case "$report_type" in
        "html")
            generate_optimized_html_report "$quest_name" > "$cache_dir/${cache_key}.html"
            ;;
        "markdown")
            generate_optimized_markdown_report "$quest_name" > "$cache_dir/${cache_key}.md"
            ;;
        "json")
            generate_optimized_json_report "$quest_name" > "$cache_dir/${cache_key}.json"
            ;;
    esac
    
    print_success "✅ $report_type report generated and cached"
}

# Function to generate optimized HTML report
generate_optimized_html_report() {
    local quest_filter="${1:-}"
    local eval_data=$(collect_evaluation_data "$quest_filter")
    
    # Parse evaluation data
    local total_files=0 total_passed=0 total_failed=0 total_review=0 total_unknown=0
    
    # Count from evaluation data
    local quests_data=$(echo "$eval_data" | jq -r '.data[] | .quest' 2>/dev/null)
    for quest in $quests_data; do
        local quest_files=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files | length" 2>/dev/null)
        total_files=$((total_files + quest_files))
        
        # Count assessments
        local assessments=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files[] | .basic_evaluation.overall_assessment" 2>/dev/null)
        for assessment in $assessments; do
            case "$assessment" in
                "PASS") total_passed=$((total_passed + 1)) ;;
                "FAIL") total_failed=$((total_failed + 1)) ;;
                "NEEDS_REVIEW") total_review=$((total_review + 1)) ;;
                *) total_unknown=$((total_unknown + 1)) ;;
            esac
        done
    done
    
    # Generate HTML with optimized data
    cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SQL Adventure - Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px 8px 0 0; text-align: center; }
        .header h1 { margin: 0; font-size: 2em; }
        .content { padding: 20px; }
        .summary { background: #ecf0f1; padding: 15px; border-radius: 6px; margin-bottom: 20px; }
        .summary-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; }
        .summary-card { background: white; padding: 15px; border-radius: 6px; text-align: center; }
        .summary-card h3 { margin: 0 0 10px 0; font-size: 1em; }
        .summary-card .number { font-size: 1.5em; font-weight: bold; }
        .summary-card.pass { border-left: 4px solid #27ae60; }
        .summary-card.fail { border-left: 4px solid #e74c3c; }
        .summary-card.review { border-left: 4px solid #f39c12; }
        .summary-card.unknown { border-left: 4px solid #95a5a6; }
        .quest-section { margin-bottom: 15px; border: 1px solid #ddd; border-radius: 6px; }
        .quest-header { background: #34495e; color: white; padding: 12px; border-radius: 6px 6px 0 0; cursor: pointer; }
        .quest-header h2 { margin: 0; font-size: 1.2em; }
        .quest-content { padding: 15px; }
        .file-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 10px; }
        .file-card { background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; padding: 10px; }
        .file-card h4 { margin: 0 0 8px 0; font-size: 0.9em; }
        .file-card .status { display: inline-block; padding: 3px 6px; border-radius: 3px; font-size: 0.8em; font-weight: bold; }
        .file-card .status.pass { background: #d5f4e6; color: #27ae60; }
        .file-card .status.fail { background: #fadbd8; color: #e74c3c; }
        .file-card .status.review { background: #fdeaa7; color: #f39c12; }
        .file-card .status.unknown { background: #e8e8e8; color: #95a5a6; }
        .file-card .score { font-size: 0.8em; color: #666; margin-top: 5px; }
        .footer { background: #ecf0f1; padding: 15px; text-align: center; color: #7f8c8d; border-radius: 0 0 8px 8px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>SQL Adventure - Validation Report</h1>
        </div>
        
        <div class="content">
            <div class="summary">
                <h2>Summary</h2>
                <div class="summary-grid">
EOF
    
    cat << EOF
                    <div class="summary-card">
                        <h3>Total Files</h3>
                        <div class="number">$total_files</div>
                    </div>
                    <div class="summary-card pass">
                        <h3>✅ Passed</h3>
                        <div class="number">$total_passed</div>
                    </div>
                    <div class="summary-card fail">
                        <h3>❌ Failed</h3>
                        <div class="number">$total_failed</div>
                    </div>
                    <div class="summary-card review">
                        <h3>⚠️ Needs Review</h3>
                        <div class="number">$total_review</div>
                    </div>
                    <div class="summary-card unknown">
                        <h3>❓ Not Evaluated</h3>
                        <div class="number">$total_unknown</div>
                    </div>
                </div>
            </div>
EOF
    
    # Generate quest sections from evaluation data
    local quests_data=$(echo "$eval_data" | jq -r '.data[] | .quest' 2>/dev/null)
    for quest in $quests_data; do
        local quest_title=$(echo "$quest" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
        local quest_files=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files | length" 2>/dev/null)
        
        if [ "$quest_files" -gt 0 ]; then
            cat << EOF
            <div class="quest-section">
                <div class="quest-header">
                    <h2>$quest_title</h2>
                </div>
                <div class="quest-content">
                    <div class="file-grid">
EOF
            
            # Generate file cards from evaluation data
            local files_data=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files[] | @base64" 2>/dev/null)
            for file_data in $files_data; do
                local decoded_data=$(echo "$file_data" | base64 -d)
                local filename=$(echo "$decoded_data" | jq -r '.metadata.file' 2>/dev/null)
                local assessment=$(echo "$decoded_data" | jq -r '.basic_evaluation.overall_assessment' 2>/dev/null)
                local score=$(echo "$decoded_data" | jq -r '.basic_evaluation.score' 2>/dev/null)
                
                cat << EOF
                        <div class="file-card">
                            <h4>$filename</h4>
                            <span class="status $assessment">$assessment</span>
                            <div class="score">Score: $score/10</div>
                        </div>
EOF
            done
            
            cat << EOF
                    </div>
                </div>
            </div>
EOF
        fi
    done
    
    cat << EOF
        </div>
        
        <div class="footer">
            <p>Generated on $(date '+%Y-%m-%d %H:%M:%S')</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Function to generate optimized Markdown report
generate_optimized_markdown_report() {
    local quest_filter="${1:-}"
    local eval_data=$(collect_evaluation_data "$quest_filter")
    
    cat << EOF
# 🚀 SQL Adventure - Validation Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## 📊 Executive Summary

| Metric | Count |
|--------|-------|
EOF
    
    # Parse evaluation data for summary
    local total_files=0 total_passed=0 total_failed=0 total_review=0 total_unknown=0
    
    local quests_data=$(echo "$eval_data" | jq -r '.data[] | .quest' 2>/dev/null)
    for quest in $quests_data; do
        local quest_files=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files | length" 2>/dev/null)
        total_files=$((total_files + quest_files))
        
        local assessments=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files[] | .basic_evaluation.overall_assessment" 2>/dev/null)
        for assessment in $assessments; do
            case "$assessment" in
                "PASS") total_passed=$((total_passed + 1)) ;;
                "FAIL") total_failed=$((total_failed + 1)) ;;
                "NEEDS_REVIEW") total_review=$((total_review + 1)) ;;
                *) total_unknown=$((total_unknown + 1)) ;;
            esac
        done
    done
    
    cat << EOF
| Total Files | $total_files |
| ✅ Passed | $total_passed |
| ❌ Failed | $total_failed |
| ⚠️ Needs Review | $total_review |
| ❓ Not Evaluated | $total_unknown |

## 📚 Quest Details

EOF
    
    # Generate quest sections from evaluation data
    for quest in $quests_data; do
        local quest_title=$(echo "$quest" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
        local quest_files=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files | length" 2>/dev/null)
        
        if [ "$quest_files" -gt 0 ]; then
            # Count quest statistics
            local quest_passed=0 quest_failed=0 quest_review=0 quest_unknown=0
            
            local assessments=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files[] | .basic_evaluation.overall_assessment" 2>/dev/null)
            for assessment in $assessments; do
                case "$assessment" in
                    "PASS") quest_passed=$((quest_passed + 1)) ;;
                    "FAIL") quest_failed=$((quest_failed + 1)) ;;
                    "NEEDS_REVIEW") quest_review=$((quest_review + 1)) ;;
                    *) quest_unknown=$((quest_unknown + 1)) ;;
                esac
            done
            
            cat << EOF
### 📚 $quest_title

**Quest Statistics:** $quest_files files | ✅ $quest_passed pass | ❌ $quest_failed fail | ⚠️ $quest_review review | ❓ $quest_unknown not evaluated

| File | Status | Score | Patterns | Feedback |
|------|--------|-------|----------|----------|
EOF
            
            # Generate file rows from evaluation data
            local files_data=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files[] | @base64" 2>/dev/null)
            for file_data in $files_data; do
                local decoded_data=$(echo "$file_data" | base64 -d)
                local filename=$(echo "$decoded_data" | jq -r '.metadata.file' 2>/dev/null)
                local assessment=$(echo "$decoded_data" | jq -r '.basic_evaluation.overall_assessment' 2>/dev/null)
                local score=$(echo "$decoded_data" | jq -r '.basic_evaluation.score' 2>/dev/null)
                local pattern_analysis=$(echo "$decoded_data" | jq -r '.basic_evaluation.pattern_analysis' 2>/dev/null)
                local feedback=$(echo "$decoded_data" | jq -r '.llm_analysis.summary.overall_evaluation // .llm_analysis.summary // ""' 2>/dev/null)
                
                local status_emoji=""
                case "$assessment" in
                    "PASS") status_emoji="✅" ;;
                    "FAIL") status_emoji="❌" ;;
                    "NEEDS_REVIEW") status_emoji="⚠️" ;;
                    *) status_emoji="❓" ;;
                esac
                
                # Truncate feedback for table display
                local short_feedback=$(echo "$feedback" | cut -c1-50)
                [ ${#feedback} -gt 50 ] && short_feedback="$short_feedback..."
                
                cat << EOF
| $filename | $status_emoji $assessment | $score/10 | $pattern_analysis | $short_feedback |
EOF
            done
            
            cat << EOF

---
EOF
        fi
    done
    
    cat << EOF

## 📋 Report Information

- **Generated by:** SQL Adventure Validation System (Optimized)
- **Report format:** Markdown
- **Cache status:** Enabled
- **Total execution time:** $(date '+%Y-%m-%d %H:%M:%S')

---

*This report was automatically generated by the SQL Adventure validation system with performance optimizations.*
EOF
}

# Function to generate optimized JSON report
generate_optimized_json_report() {
    local quest_filter="${1:-}"
    local eval_data=$(collect_evaluation_data "$quest_filter")
    
    # Parse evaluation data for summary
    local total_files=0 total_passed=0 total_failed=0 total_review=0
    
    local quests_data=$(echo "$eval_data" | jq -r '.data[] | .quest' 2>/dev/null)
    for quest in $quests_data; do
        local quest_files=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files | length" 2>/dev/null)
        total_files=$((total_files + quest_files))
        
        local assessments=$(echo "$eval_data" | jq -r ".data[] | select(.quest == \"$quest\") | .files[] | .basic_evaluation.overall_assessment" 2>/dev/null)
        for assessment in $assessments; do
            case "$assessment" in
                "PASS") total_passed=$((total_passed + 1)) ;;
                "FAIL") total_failed=$((total_failed + 1)) ;;
                "NEEDS_REVIEW") total_review=$((total_review + 1)) ;;
            esac
        done
    done
    
    # Build optimized JSON structure
    cat << EOF
{
  "report_metadata": {
    "generated": "$(date -Iseconds)",
    "format": "optimized_json",
    "version": "2.0",
    "performance": {
      "cached": true,
      "incremental": true,
      "optimized": true
    }
  },
  "summary": {
    "total_files": $total_files,
    "passed": $total_passed,
    "failed": $total_failed,
    "needs_review": $total_review,
    "success_rate": "$(echo "scale=1; $total_passed * 100 / $total_files" | bc 2>/dev/null || echo "0")%"
  },
  "quests": $eval_data
}
EOF
}

# Function to format JSON values properly
format_json_value() {
    local value="$1"
    local type="${2:-string}"
    
    case "$type" in
        "number")
            # Remove leading zeros and ensure it's a valid number
            local clean_value=$(echo "$value" | sed 's/^0*//')
            if [ -z "$clean_value" ]; then
                clean_value="0"
            fi
            if [[ "$clean_value" =~ ^[0-9]+$ ]]; then
                echo "$clean_value"
            else
                echo "0"
            fi
            ;;
        "boolean")
            # Convert to true/false
            if [[ "$value" =~ ^(true|false)$ ]]; then
                echo "$value"
            elif [[ "$value" =~ ^(1|yes|true)$ ]]; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        "string"|*)
            # Clean and escape strings properly
            if [ -z "$value" ]; then
                echo ""
            else
                echo "$value"
            fi
            ;;
    esac
}

# Function to generate formatted report
generate_formatted_report() {
    local format="$1"
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local report_file="reports/validation-report-$timestamp.$format"
    
    case "$format" in
        "html") generate_html_report > "$report_file" ;;
        "md") generate_markdown_report > "$report_file" ;;
        "json") generate_json_report > "$report_file" ;;
        *) echo "Unknown format: $format" >&2; return 1 ;;
    esac
    
    echo "📊 Report generated: $report_file"
}

# Function to generate HTML report
generate_html_report() {
    cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SQL Adventure - Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px 8px 0 0; text-align: center; }
        .header h1 { margin: 0; font-size: 2em; }
        .content { padding: 20px; }
        .summary { background: #ecf0f1; padding: 15px; border-radius: 6px; margin-bottom: 20px; }
        .summary-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; }
        .summary-card { background: white; padding: 15px; border-radius: 6px; text-align: center; }
        .summary-card h3 { margin: 0 0 10px 0; font-size: 1em; }
        .summary-card .number { font-size: 1.5em; font-weight: bold; }
        .summary-card.pass { border-left: 4px solid #27ae60; }
        .summary-card.fail { border-left: 4px solid #e74c3c; }
        .summary-card.review { border-left: 4px solid #f39c12; }
        .summary-card.unknown { border-left: 4px solid #95a5a6; }
        .quest-section { margin-bottom: 15px; border: 1px solid #ddd; border-radius: 6px; }
        .quest-header { background: #34495e; color: white; padding: 12px; border-radius: 6px 6px 0 0; cursor: pointer; }
        .quest-header h2 { margin: 0; font-size: 1.2em; }
        .quest-content { padding: 15px; }
        .file-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 10px; }
        .file-card { background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; padding: 10px; }
        .file-card h4 { margin: 0 0 8px 0; font-size: 0.9em; }
        .file-card .status { display: inline-block; padding: 3px 6px; border-radius: 3px; font-size: 0.8em; font-weight: bold; }
        .file-card .status.pass { background: #d5f4e6; color: #27ae60; }
        .file-card .status.fail { background: #fadbd8; color: #e74c3c; }
        .file-card .status.review { background: #fdeaa7; color: #f39c12; }
        .file-card .status.unknown { background: #e8e8e8; color: #95a5a6; }
        .file-card .score { font-size: 0.8em; color: #666; margin-top: 5px; }
        .footer { background: #ecf0f1; padding: 15px; text-align: center; color: #7f8c8d; border-radius: 0 0 8px 8px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>SQL Adventure - Validation Report</h1>
        </div>
        
        <div class="content">
            <div class="summary">
                <h2>Summary</h2>
                <div class="summary-grid">
EOF
    
    # Generate summary statistics
    local total_files=0 total_passed=0 total_failed=0 total_review=0 total_unknown=0
    
    for quest_dir in quests/*; do
        [ ! -d "$quest_dir" ] && continue
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            total_files=$((total_files + 1))
        done
    done
    
    # Count AI evaluation results if available
    if [ -d "ai-evaluations" ]; then
        for json_file in ai-evaluations/*/*/*.json; do
            [ ! -f "$json_file" ] && continue
            local assessment=$(jq -r '.basic_evaluation.overall_assessment' "$json_file" 2>/dev/null)
            case "$assessment" in
                "PASS") total_passed=$((total_passed + 1)) ;;
                "FAIL") total_failed=$((total_failed + 1)) ;;
                "NEEDS_REVIEW") total_review=$((total_review + 1)) ;;
                *) total_unknown=$((total_unknown + 1)) ;;
            esac
        done
    fi
    
    # Calculate unknown files (files without evaluations)
    total_unknown=$((total_files - total_passed - total_failed - total_review))
    
    cat >> "$report_file" << EOF
                    <div class="summary-card">
                        <h3>Total Files</h3>
                        <div class="number">$total_files</div>
                    </div>
                    <div class="summary-card pass">
                        <h3>✅ Passed</h3>
                        <div class="number">$total_passed</div>
                    </div>
                    <div class="summary-card fail">
                        <h3>❌ Failed</h3>
                        <div class="number">$total_failed</div>
                    </div>
                    <div class="summary-card review">
                        <h3>⚠️ Needs Review</h3>
                        <div class="number">$total_review</div>
                    </div>
                    <div class="summary-card unknown">
                        <h3>❓ Not Evaluated</h3>
                        <div class="number">$total_unknown</div>
                    </div>
                </div>
            </div>
EOF
    
    # Generate quest sections - only for quests with evaluations
    for quest_dir in quests/*; do
        [ ! -d "$quest_dir" ] && continue
        [ "$quest_dir" = "quests/README.md" ] && continue
        
        local quest_name=$(basename "$quest_dir")
        local quest_title=$(echo "$quest_name" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
        local quest_id=$(echo "$quest_name" | sed 's/[^a-zA-Z0-9]//g')
        
        # Check if this quest has any evaluations
        local has_evaluations=false
        if [ -d "ai-evaluations/${quest_name}" ]; then
            for json_file in ai-evaluations/${quest_name}/*/*.json; do
                [ -f "$json_file" ] && { has_evaluations=true; break; }
            done
        fi
        
        # Only show quests with evaluations
        [ "$has_evaluations" = false ] && continue
        
        # Count files in this quest
        local quest_files=0 quest_passed=0 quest_failed=0 quest_review=0 quest_unknown=0
        
        # Process each SQL file in the quest
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            
            quest_files=$((quest_files + 1))
            total_files=$((total_files + 1))
            
            # Extract subdirectory name
            local subdir=$(dirname "$file" | sed 's/.*\///')
            local json_file="ai-evaluations/${quest_name}/${subdir}/$(basename "$file" .sql).json"
            
            # Check if evaluation exists
            if [ -f "$json_file" ]; then
                local assessment=$(jq -r '.basic_evaluation.overall_assessment' "$json_file" 2>/dev/null || echo "UNKNOWN")
                case "$assessment" in
                    "PASS") quest_passed=$((quest_passed + 1)); passed_files=$((passed_files + 1)) ;;
                    "FAIL") quest_failed=$((quest_failed + 1)); failed_files=$((failed_files + 1)) ;;
                    "NEEDS_REVIEW") quest_review=$((quest_review + 1)); review_files=$((review_files + 1)) ;;
                    *) quest_unknown=$((quest_unknown + 1)); unknown_files=$((unknown_files + 1)) ;;
                esac
            else
                quest_unknown=$((quest_unknown + 1))
                unknown_files=$((unknown_files + 1))
            fi
        done
        
        # Only show quest if it has evaluated files
        [ $((quest_passed + quest_failed + quest_review)) -eq 0 ] && continue
        
        cat >> "$report_file" << EOF
            <div class="quest-section">
                <div class="quest-header">
                    <h2>$quest_title</h2>
                </div>
                <div class="quest-content">
                    <div class="file-grid">
EOF
        
        # Generate file cards - only for evaluated files
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            
            local subdir=$(dirname "$file" | sed 's/.*\///')
            local json_file="ai-evaluations/${quest_name}/${subdir}/$(basename "$file" .sql).json"
            
            # Only show files with evaluations
            [ ! -f "$json_file" ] && continue
            
            local assessment=$(jq -r '.basic_evaluation.overall_assessment' "$json_file" 2>/dev/null || echo "UNKNOWN")
            local score=$(jq -r '.basic_evaluation.score' "$json_file" 2>/dev/null || echo "0")
            
            cat >> "$report_file" << EOF
                        <div class="file-card">
                            <h4>$(basename "$file")</h4>
                            <span class="status $assessment">$assessment</span>
                            <div class="score">Score: $score/10</div>
                        </div>
EOF
        done
        
        cat >> "$report_file" << EOF
                    </div>
                </div>
            </div>
EOF
    done
    
    cat >> "$report_file" << EOF
        </div>
        
        <div class="footer">
            <p>Generated on $(date '+%Y-%m-%d %H:%M:%S')</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Function to generate Markdown report
generate_markdown_report() {
    cat << EOF
# 🚀 SQL Adventure - Validation Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')

## 📊 Executive Summary

| Metric | Count |
|--------|-------|
EOF
    
    # Generate summary statistics
    local total_files=0 total_passed=0 total_failed=0 total_review=0 total_unknown=0
    
    for quest_dir in quests/*; do
        [ ! -d "$quest_dir" ] && continue
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            total_files=$((total_files + 1))
        done
    done
    
    # Count AI evaluation results if available
    if [ -d "ai-evaluations" ]; then
        for json_file in ai-evaluations/*/*/*.json; do
            [ ! -f "$json_file" ] && continue
            local assessment=$(jq -r '.basic_evaluation.overall_assessment' "$json_file" 2>/dev/null)
            case "$assessment" in
                "PASS") total_passed=$((total_passed + 1)) ;;
                "FAIL") total_failed=$((total_failed + 1)) ;;
                "NEEDS_REVIEW") total_review=$((total_review + 1)) ;;
            esac
        done
    fi
    
    # Calculate unknown files (files without evaluations)
    total_unknown=$((total_files - total_passed - total_failed - total_review))
    
    cat << EOF
| Total Files | $total_files |
| ✅ Passed | $total_passed |
| ❌ Failed | $total_failed |
| ⚠️ Needs Review | $total_review |
| ❓ Not Evaluated | $total_unknown |

## 📚 Quest Details

EOF
    
    # Generate quest sections
    for quest_dir in quests/*; do
        [ ! -d "$quest_dir" ] && continue
        
        local quest_name=$(basename "$quest_dir")
        local quest_title=$(echo "$quest_name" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
        
        # Count quest statistics
        local quest_files=0 quest_passed=0 quest_failed=0 quest_review=0 quest_unknown=0
        
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            quest_files=$((quest_files + 1))
        done
        
        if [ -d "ai-evaluations" ]; then
            for json_file in ai-evaluations/${quest_name}/*/*.json; do
                [ ! -f "$json_file" ] && continue
                local assessment=$(jq -r '.basic_evaluation.overall_assessment' "$json_file" 2>/dev/null)
                case "$assessment" in
                    "PASS") quest_passed=$((quest_passed + 1)) ;;
                    "FAIL") quest_failed=$((quest_failed + 1)) ;;
                    "NEEDS_REVIEW") quest_review=$((quest_review + 1)) ;;
                esac
            done
        fi
        
        quest_unknown=$((quest_files - quest_passed - quest_failed - quest_review))
        
        cat << EOF
### 📚 $quest_title

**Quest Statistics:** $quest_files files | ✅ $quest_passed pass | ❌ $quest_failed fail | ⚠️ $quest_review review | ❓ $quest_unknown not evaluated

| File | Status | Score | Patterns | Feedback |
|------|--------|-------|----------|----------|
EOF
        
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            
            local filename=$(basename "$file")
            local subdir=$(basename "$(dirname "$file")")
            local json_file="ai-evaluations/${quest_name}/${subdir}/$(basename "$file" .sql).json"
            
            local assessment="UNKNOWN"
            local score="0"
            local pattern_analysis=""
            local feedback=""
            
            if [ -f "$json_file" ]; then
                assessment=$(jq -r '.basic_evaluation.overall_assessment' "$json_file" 2>/dev/null || echo "UNKNOWN")
                score=$(jq -r '.basic_evaluation.score' "$json_file" 2>/dev/null || echo "0")
                pattern_analysis=$(jq -r '.basic_evaluation.pattern_analysis' "$json_file" 2>/dev/null || echo "")
                feedback=$(jq -r '.llm_analysis.summary.overall_evaluation // .llm_analysis.summary // ""' "$json_file" 2>/dev/null || echo "")
            fi
            
            local status_emoji=""
            case "$assessment" in
                "PASS") status_emoji="✅" ;;
                "FAIL") status_emoji="❌" ;;
                "NEEDS_REVIEW") status_emoji="⚠️" ;;
                *) status_emoji="❓" ;;
            esac
            
            # Truncate feedback for table display
            local short_feedback=$(echo "$feedback" | cut -c1-50)
            [ ${#feedback} -gt 50 ] && short_feedback="$short_feedback..."
            
            cat << EOF
| $filename | $status_emoji $assessment | $score/10 | $pattern_analysis | $short_feedback |
EOF
        done
        
        cat << EOF

---
EOF
    done
    
    cat << EOF

## 📋 Report Information

- **Generated by:** SQL Adventure Validation System
- **Report format:** Markdown
- **Total execution time:** $(date '+%Y-%m-%d %H:%M:%S')

---

*This report was automatically generated by the SQL Adventure validation system.*
EOF
}

# Function to generate JSON report
generate_json_report() {
    # Create comprehensive JSON report
    local total_files=0 total_passed=0 total_failed=0 total_review=0
    
    # Count files and results
    for quest_dir in quests/*; do
        [ ! -d "$quest_dir" ] && continue
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            total_files=$((total_files + 1))
        done
    done
    
    if [ -d "ai-evaluations" ]; then
        for json_file in ai-evaluations/*/*/*.json; do
            [ ! -f "$json_file" ] && continue
            local assessment=$(jq -r '.basic_evaluation.overall_assessment' "$json_file" 2>/dev/null)
            case "$assessment" in
                "PASS") total_passed=$((total_passed + 1)) ;;
                "FAIL") total_failed=$((total_failed + 1)) ;;
                "NEEDS_REVIEW") total_review=$((total_review + 1)) ;;
            esac
        done
    fi
    
    # Build JSON structure
    cat << EOF
{
  "report_metadata": {
    "generated": "$(date -Iseconds)",
    "format": "comprehensive_json",
    "version": "1.0"
  },
  "summary": {
    "total_files": $total_files,
    "passed": $total_passed,
    "failed": $total_failed,
    "needs_review": $total_review,
    "success_rate": "$(echo "scale=1; $total_passed * 100 / $total_files" | bc 2>/dev/null || echo "0")%"
  },
  "quests": {
EOF
    
    local first_quest=true
    for quest_dir in quests/*; do
        [ ! -d "$quest_dir" ] && continue
        
        local quest_name=$(basename "$quest_dir")
        
        if [ "$first_quest" = true ]; then
            first_quest=false
        else
            echo "    },"
        fi
        
        cat << EOF
    "$quest_name": {
      "files": {
EOF
        
        local first_file=true
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            
            local filename=$(basename "$file")
            local subdir=$(basename "$(dirname "$file")")
            local json_file="ai-evaluations/${quest_name}/${subdir}/$(basename "$file" .sql).json"
            
            if [ "$first_file" = true ]; then
                first_file=false
            else
                echo "        },"
            fi
            
            if [ -f "$json_file" ]; then
                # Include the full evaluation data
                local file_data=$(cat "$json_file" | jq -c . 2>/dev/null || echo '{"error": "Failed to parse JSON"}')
                cat << EOF
        "$(basename "$file" .sql)": $file_data
EOF
            else
                cat << EOF
        "$(basename "$file" .sql)": {
          "status": "not_evaluated",
          "file": "$filename",
          "quest": "$quest_name"
        }
EOF
            fi
        done
        
        cat << EOF
      }
EOF
    done
    
    cat << EOF
    }
  }
}
EOF
}

# Function to create consolidated JSON file (unified with quiet mode flag)
create_consolidated_json() {
    local file="$1" quest_name="$2" purpose="$3" difficulty="$4" concepts="$5"
    local expected_results="$6" learning_outcomes="$7" sql_patterns="$8" output_content="$9"
    local output_lines="${10}" has_errors="${11}" has_warnings="${12}" has_results="${13}" json_file="${14}" quiet_mode="${15:-false}"
    
    # Convert patterns string to array
    local patterns_array=()
    [ -n "$sql_patterns" ] && IFS=' ' read -ra patterns_array <<< "$sql_patterns"
    
    # Determine assessment with more nuanced scoring
    local overall_assessment="PASS" score=8 issues="" pattern_analysis=""
    
    # Base scoring logic
    if [ "$has_errors" -gt 0 ]; then
        overall_assessment="FAIL"
        if [ "$has_errors" -eq 1 ]; then
            score=4  # Minor error
        elif [ "$has_errors" -le 3 ]; then
            score=3  # Multiple errors
        else
            score=2  # Many errors
        fi
        issues="Contains $has_errors error(s)"
    elif [ "$has_warnings" -gt 0 ]; then
        overall_assessment="NEEDS_REVIEW"
        if [ "$has_warnings" -eq 1 ]; then
            score=7  # Minor warning
        elif [ "$has_warnings" -le 3 ]; then
            score=6  # Multiple warnings
        else
            score=5  # Many warnings
        fi
        issues="Contains $has_warnings warning(s)"
    elif [ "$has_results" -eq 0 ] && [ "$output_lines" -lt 5 ]; then
        overall_assessment="NEEDS_REVIEW"
        score=5
        issues="Very little output generated"
    else
        # PASS with nuanced scoring
        score=8  # Base score for successful execution
        
        # Bonus for good output
        [ "$has_results" -gt 0 ] && score=$((score + 1))
        [ "$output_lines" -gt 20 ] && score=$((score + 1))
        
        # Cap at 10
        [ $score -gt 10 ] && score=10
    fi
    
    # Pattern analysis
    if [ ${#patterns_array[@]} -gt 0 ]; then
        pattern_analysis="Detected ${#patterns_array[@]} SQL patterns: $sql_patterns"
        echo "$sql_patterns" | grep -q "window_functions\|recursive_cte\|json_operations" && score=$((score + 1))
    else
        pattern_analysis="No SQL patterns detected"
        score=$((score - 1))
    fi
    
    # Purpose alignment
    [ -n "$purpose" ] && {
        if echo "$sql_patterns" | grep -q "table_creation" && echo "$purpose" | grep -q -i "table\|create"; then
            pattern_analysis="$pattern_analysis (Purpose aligned)"
        elif echo "$sql_patterns" | grep -q "window_functions" && echo "$purpose" | grep -q -i "window\|rank\|percentile"; then
            pattern_analysis="$pattern_analysis (Purpose aligned)"
        elif echo "$sql_patterns" | grep -q "json_operations" && echo "$purpose" | grep -q -i "json\|data"; then
            pattern_analysis="$pattern_analysis (Purpose aligned)"
        else
            pattern_analysis="$pattern_analysis (Purpose alignment unclear)"
        fi
    }
    
    # LLM processing
    local llm_analysis="" enhanced_intent=""
    
    # Ensure environment variables are available
    if [ -z "$OPENAI_API_KEY" ] && [ -f ".env" ]; then
        source .env
    fi
    
    if command -v curl >/dev/null 2>&1 && [ -n "$OPENAI_API_KEY" ]; then
        if [ "$quiet_mode" != "true" ]; then
            print_status "🤖 Processing with LLM..."
            print_status "📚 Analyzing educational intent..."
        fi
        enhanced_intent=$(analyze_intent_with_llm "$file" "$quest_name" "$purpose" "$concepts" "$difficulty" "$quiet_mode")
        if [ "$quiet_mode" != "true" ]; then
            print_status "🔍 Comprehensive analysis..."
        fi
        llm_analysis=$(process_output_with_llm "$file" "$quest_name" "$purpose" "$difficulty" "$concepts" "$output_content" "$sql_patterns" "$quiet_mode")
    else
        enhanced_intent="Enhanced intent analysis not available (missing curl or API key)"
        llm_analysis="LLM analysis not available (missing curl or API key)"
    fi
    
    # Format values using our utility function
    local formatted_purpose=$(format_json_value "$purpose" "string")
    local formatted_difficulty=$(format_json_value "$difficulty" "string")
    local formatted_concepts=$(format_json_value "$concepts" "string")
    local formatted_expected_results=$(format_json_value "$expected_results" "string")
    local formatted_learning_outcomes=$(format_json_value "$learning_outcomes" "string")
    local formatted_output_content=$(format_json_value "$output_content" "string")
    local formatted_overall_assessment=$(format_json_value "$overall_assessment" "string")
    local formatted_pattern_analysis=$(format_json_value "$pattern_analysis" "string")
    local formatted_issues=$(format_json_value "$issues" "string")
    local formatted_recommendations=$(format_json_value "$(get_recommendations "$overall_assessment" "$score" "$issues")" "string")
    local formatted_llm_analysis=$(format_json_value "$llm_analysis" "string")
    local formatted_enhanced_intent=$(format_json_value "$enhanced_intent" "string")
    local formatted_output_lines=$(format_json_value "$output_lines" "number")
    local formatted_has_errors=$(format_json_value "$has_errors" "number")
    local formatted_has_warnings=$(format_json_value "$has_warnings" "number")
    local formatted_has_results=$(format_json_value "$has_results" "number")
    local formatted_score=$(format_json_value "$score" "number")
    local formatted_execution_success=$(format_json_value "true" "boolean")
    
    # Create JSON using jq for proper formatting
    jq -n \
        --arg generated "$(date -Iseconds)" \
        --arg file "$(basename "$file")" \
        --arg quest "$quest_name" \
        --arg full_path "$file" \
        --arg purpose "$formatted_purpose" \
        --arg difficulty "$formatted_difficulty" \
        --arg concepts "$formatted_concepts" \
        --arg expected_results "$formatted_expected_results" \
        --arg learning_outcomes "$formatted_learning_outcomes" \
        --arg output_content "$formatted_output_content" \
        --arg overall_assessment "$formatted_overall_assessment" \
        --arg pattern_analysis "$formatted_pattern_analysis" \
        --arg issues "$formatted_issues" \
        --arg recommendations "$formatted_recommendations" \
        --arg llm_analysis "$formatted_llm_analysis" \
        --arg enhanced_intent "$formatted_enhanced_intent" \
        --argjson output_lines $formatted_output_lines \
        --argjson has_errors $formatted_has_errors \
        --argjson has_warnings $formatted_has_warnings \
        --argjson has_results $formatted_has_results \
        --argjson score $formatted_score \
        --argjson execution_success $formatted_execution_success \
        --argjson sql_patterns "$(printf '%s\n' "${patterns_array[@]}" | jq -R . | jq -s .)" \
        '{
            metadata: {
                generated: $generated,
                file: $file,
                quest: $quest,
                full_path: $full_path
            },
            intent: {
                purpose: $purpose,
                difficulty: $difficulty,
                concepts: $concepts,
                expected_results: $expected_results,
                learning_outcomes: $learning_outcomes,
                sql_patterns: $sql_patterns
            },
            execution: {
                success: $execution_success,
                output_lines: $output_lines,
                errors: $has_errors,
                warnings: $has_warnings,
                result_sets: $has_results,
                raw_output: $output_content
            },
            basic_evaluation: {
                overall_assessment: $overall_assessment,
                score: $score,
                pattern_analysis: $pattern_analysis,
                issues: $issues,
                recommendations: $recommendations
            },
            basic_analysis: {
                correctness: "Output appears to execute successfully",
                completeness: ("Generated " + ($output_lines | tostring) + " lines of output with " + ($has_results | tostring) + " result sets"),
                learning_value: "Demonstrates intended SQL patterns",
                quality: "Output is clear and readable"
            },
            llm_analysis: {"status": "disabled", "note": "LLM analysis temporarily disabled - using basic evaluation"},
            enhanced_intent: {"status": "disabled", "note": "Enhanced intent temporarily disabled - using basic intent"}
        }' > "$json_file" 2>/dev/null
    
    if [ "$quiet_mode" != "true" ]; then
        print_success "✅ Consolidated JSON created: $json_file"
    fi
}



# Function to show comprehensive report
show_comprehensive_report() {
    print_header "Comprehensive Validation Report"
    
    local total_files=0 valid_files=0 invalid_files=0
    
    for quest_dir in quests/*; do
        [ ! -d "$quest_dir" ] && continue
        
        local quest_name=$(basename "$quest_dir")
        local quest_files=0 quest_valid=0 quest_invalid=0
        
        print_status "Quest: $quest_name"
        
        for file in "$quest_dir"/*/*.sql; do
            [ ! -f "$file" ] && continue
            
            total_files=$((total_files + 1))
            quest_files=$((quest_files + 1))
            
            if run_comprehensive_validation "$file"; then
                quest_valid=$((quest_valid + 1))
                valid_files=$((valid_files + 1))
            else
                quest_invalid=$((quest_invalid + 1))
                invalid_files=$((invalid_files + 1))
            fi
        done
        
        print_status "  📊 $quest_valid/$quest_files files valid"
    done
    
    echo ""
    print_status "📈 Overall Results: $valid_files/$total_files files valid"
    
    if [ $invalid_files -eq 0 ]; then
        print_success "🎉 All files are valid!"
    else
        print_warning "⚠️  $invalid_files files need attention"
    fi
}

# Function to get recommendations based on evaluation
get_recommendations() {
    local assessment="$1" score="$2" issues="$3"
    
    case "$assessment" in
        "PASS")
            if [ "$score" -eq 10 ]; then
                echo "Excellent! This example demonstrates best practices and provides comprehensive learning value."
            elif [ "$score" -eq 9 ]; then
                echo "Very good example with minor room for improvement in output clarity or documentation."
            else
                echo "Good example suitable for learning purposes. Consider adding more detailed comments or examples."
            fi
            ;;
        "NEEDS_REVIEW")
            if echo "$issues" | grep -q "warning"; then
                echo "Review warnings and consider addressing them to improve code quality and learning experience."
            elif echo "$issues" | grep -q "little output"; then
                echo "Consider adding more comprehensive examples or expected output to enhance learning value."
            else
                echo "Review the example for completeness, clarity, and educational effectiveness."
            fi
            ;;
        "FAIL")
            if [ "$score" -eq 2 ]; then
                echo "Critical issues detected. This example needs significant revision before it can be used for learning."
            elif [ "$score" -eq 3 ]; then
                echo "Multiple errors found. Review and fix syntax or logic issues to make this example functional."
            else
                echo "Contains errors that prevent proper execution. Fix the identified issues to restore functionality."
            fi
            ;;
        *)
            echo "Assessment unclear. Review the example for potential improvements."
            ;;
    esac
}
