#!/bin/bash

# Git Workflow Script for Scoped, Small Commits
# This script helps maintain consistent commit practices

set -e

# Source print utility functions
source "$(dirname "$0")/print-utils.sh"

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
}

# Function to check for staged changes
check_staged_changes() {
    if ! git diff --cached --quiet; then
        return 0
    else
        print_warning "No staged changes found"
        return 1
    fi
}

# Function to show current status
show_status() {
    print_header "Git Status"
    git status --short
    echo
}

# Function to stage files interactively
stage_files() {
    print_header "Stage Files"
    print_status "Staging files interactively..."
    git add -i
}

# Function to create a scoped commit
create_commit() {
    print_header "Create Scoped Commit"
    
    if ! check_staged_changes; then
        print_error "No staged changes to commit"
        return 1
    fi
    
    print_status "Opening commit message editor..."
    print_status "Remember to use the format: <type>(<scope>): <subject>"
    print_status "Examples:"
    echo "  feat(sql): add recursive CTE cheatsheet"
    echo "  fix(docs): correct typo in learning path"
    echo "  docs(sql): improve example documentation"
    echo
    
    git commit
}

# Function to create a quick commit with message
quick_commit() {
    local message="$1"
    
    if [ -z "$message" ]; then
        print_error "Commit message is required"
        echo "Usage: $0 quick-commit \"<type>(<scope>): <subject>\""
        exit 1
    fi
    
    print_header "Quick Commit"
    
    if ! check_staged_changes; then
        print_error "No staged changes to commit"
        return 1
    fi
    
    print_status "Creating commit with message: $message"
    git commit -m "$message"
}

# Function to show commit history
show_history() {
    print_header "Recent Commits"
    git log --oneline -10 --graph --decorate
}

# Function to check commit message format
check_commit_format() {
    local commit_hash="$1"
    
    if [ -z "$commit_hash" ]; then
        commit_hash="HEAD"
    fi
    
    local message=$(git log --format=%B -n 1 "$commit_hash")
    local subject=$(echo "$message" | head -n 1)
    
    print_header "Commit Message Format Check"
    print_status "Checking commit: $commit_hash"
    print_status "Subject: $subject"
    
    # Check if it follows the format
    if echo "$subject" | grep -qE '^(feat|fix|docs|style|refactor|test|chore|perf|ci|build)\([a-z-]+\): .+'; then
        print_status "✅ Commit message format is correct"
    else
        print_warning "⚠️  Commit message doesn't follow the expected format"
        print_status "Expected: <type>(<scope>): <subject>"
        print_status "Example: feat(sql): add recursive CTE cheatsheet"
    fi
}

# Function to show help
show_help() {
    echo "Git Workflow Script for Scoped, Small Commits"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  status              Show current git status"
    echo "  stage               Stage files interactively"
    echo "  commit              Create a scoped commit (opens editor)"
    echo "  quick-commit MSG    Create a quick commit with message"
    echo "  history             Show recent commit history"
    echo "  check-format [HASH] Check commit message format"
    echo "  help                Show this help message"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 stage"
    echo "  $0 commit"
    echo "  $0 quick-commit \"feat(sql): add recursive CTE cheatsheet\""
    echo "  $0 history"
    echo "  $0 check-format"
    echo
    echo "Commit Message Format:"
    echo "  <type>(<scope>): <subject>"
    echo
    echo "Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build"
    echo "Scopes: sql, docs, docker, scripts, config, ui, api, db"
    echo
    echo "Examples:"
    echo "  feat(sql): add recursive CTE cheatsheet"
    echo "  fix(docs): correct typo in learning path"
    echo "  docs(sql): improve example documentation"
    echo "  refactor(scripts): simplify docker setup"
    echo "  test(sql): add validation for CTE examples"
}

# Main script logic
main() {
    check_git_repo
    
    case "${1:-help}" in
        "status")
            show_status
            ;;
        "stage")
            stage_files
            ;;
        "commit")
            create_commit
            ;;
        "quick-commit")
            quick_commit "$2"
            ;;
        "history")
            show_history
            ;;
        "check-format")
            check_commit_format "$2"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@" 