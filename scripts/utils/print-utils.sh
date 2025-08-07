#!/bin/bash

# Print utility functions for SQL Adventure scripts (Refactored)
# Provides consistent formatting, colors, and behaviors across all scripts

# Color codes with fallback for unsupported terminals
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Determine terminal width
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
LINE=$(printf '━%.0s' $(seq 1 $TERM_WIDTH))

# Internal helper for printing colored lines
print_line() {
    local color="$1"
    echo -e "${color}${LINE}${NC}"
}

# Core print functions
print_header() {
    [ -z "$1" ] && { echo -e "${RED}❌ Missing argument in print_header${NC}"; return 1; }
    print_line "$PURPLE"
    echo -e "${PURPLE}  $1${NC}"
    print_line "$PURPLE"
}

print_section() {
    [ -z "$1" ] && { echo -e "${RED}❌ Missing argument in print_section${NC}"; return 1; }
    print_line "$CYAN"
    echo -e "${CYAN}  $1${NC}"
    print_line "$CYAN"
}

print_status() {
    [ -z "$1" ] && { echo -e "${RED}❌ Missing argument in print_status${NC}"; return 1; }
    echo -e "${BLUE}ℹ️ $1${NC}"
}

print_success() {
    [ -z "$1" ] && { echo -e "${RED}❌ Missing argument in print_success${NC}"; return 1; }
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    [ -z "$1" ] && { echo -e "${RED}❌ Missing argument in print_warning${NC}"; return 1; }
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    [ -z "$1" ] && { echo -e "${RED}❌ Missing argument in print_error${NC}"; return 1; }
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    [ "${VERBOSE:-true}" = "true" ] && echo -e "${CYAN}💡 $1${NC}"
}

print_debug() {
    [ "${DEBUG:-false}" = "true" ] && echo -e "${WHITE}🐛 $1${NC}"
}

print_step() {
    [ -z "$1" ] && { echo -e "${RED}❌ Missing argument in print_step${NC}"; return 1; }
    echo -e "${WHITE}➡️  $1${NC}"
}

# Table formatting
print_table_header() {
    echo -e "${WHITE}$1${NC}"
    print_line "$WHITE"
}

print_table_row() {
    printf "  %-30s %-40s\n" "$1" "$2"
}

print_table_footer() {
    print_line "$WHITE"
}

# Progress bar
print_progress() {
    local current=$1
    local total=$2
    local width=50

    if [ -z "$current" ] || [ -z "$total" ] || [ "$total" -eq 0 ]; then
        echo -e "${RED}❌ Invalid arguments to print_progress${NC}"
        return 1
    fi

    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    printf "\r["
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%%" $percentage

    [ "$current" -eq "$total" ] && echo
}

# Optional logging
log() {
    local message="$1"
    echo -e "$message" | tee -a "${LOG_FILE:-/tmp/sql_adventure.log}" > /dev/null
}

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi
