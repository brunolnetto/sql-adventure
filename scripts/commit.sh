#!/bin/bash

# Git Workflow Script - Simplified for Better UX
# Focus on essential commit functionality

set -e

# Source print utility functions
source "$(dirname "$0")/utils/print-utils.sh"

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
}

# Function to show current status with better formatting
show_status() {
    print_header "Git Status"
    
    # Show staged changes
    if ! git diff --cached --quiet; then
        print_status "📦 Staged Changes:"
        git diff --cached --name-status
        echo
    else
        print_warning "No staged changes"
    fi
    
    # Show unstaged changes
    if ! git diff --quiet; then
        print_status "📝 Unstaged Changes:"
        git diff --name-status
        echo
    fi
    
    # Show untracked files
    local untracked=$(git ls-files --others --exclude-standard)
    if [ -n "$untracked" ]; then
        print_status "🆕 Untracked Files:"
        echo "$untracked"
        echo
    fi
}

# Function to stage files with better UX
stage_files() {
    print_header "Stage Files"
    
    # Show what can be staged
    local unstaged=$(git diff --name-only)
    local untracked=$(git ls-files --others --exclude-standard)
    
    if [ -n "$unstaged" ] || [ -n "$untracked" ]; then
        print_status "Available files to stage:"
        
        if [ -n "$unstaged" ]; then
            print_status "📝 Modified files:"
            echo "$unstaged"
            echo
        fi
        
        if [ -n "$untracked" ]; then
            print_status "🆕 New files:"
            echo "$untracked"
            echo
        fi
        
        print_status "Staging all changes..."
        git add .
        print_success "✅ All changes staged"
    else
        print_warning "No files to stage"
    fi
}

# Function to create a commit with guided message creation
create_commit() {
    print_header "Create Commit"
    
    if ! git diff --cached --quiet; then
        print_status "📦 Staged changes:"
        git diff --cached --name-status
        echo
        
        print_status "💡 Commit Message Guidelines:"
        echo "  Format: <type>(<scope>): <subject>"
        echo "  Types: feat, fix, docs, style, refactor, test, chore"
        echo "  Scopes: sql, docs, docker, scripts, config"
        echo "  Examples:"
        echo "    feat(sql): add recursive CTE cheatsheet"
        echo "    fix(docs): correct typo in learning path"
        echo "    docs(sql): improve example documentation"
        echo
        
        print_status "Opening commit message editor..."
        git commit
    else
        print_error "No staged changes to commit"
        print_status "💡 Use '$0 stage' to stage files first"
        return 1
    fi
}

# Function to create a quick commit with message
quick_commit() {
    local message="$1"
    
    if [ -z "$message" ]; then
        print_error "Commit message is required"
        echo "Usage: $0 quick \"<type>(<scope>): <subject>\""
        echo "Example: $0 quick \"feat(sql): add recursive CTE cheatsheet\""
        exit 1
    fi
    
    print_header "Quick Commit"
    
    if ! git diff --cached --quiet; then
        print_status "Creating commit with message: $message"
        git commit -m "$message"
        print_success "✅ Commit created successfully"
    else
        print_error "No staged changes to commit"
        print_status "💡 Use '$0 stage' to stage files first"
        return 1
    fi
}

# Function to show commit history with better formatting
show_history() {
    print_header "Recent Commits"
    print_status "Last 10 commits:"
    git log --oneline -10 --graph --decorate --color=always
}

# Function to show help
show_help() {
    echo "Git Workflow Script - Simplified for Better UX"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  status              Show current git status with better formatting"
    echo "  stage               Stage all changes (modified + new files)"
    echo "  commit              Create a commit with guided message creation"
    echo "  quick MSG           Create a quick commit with message"
    echo "  history             Show recent commit history"
    echo "  help                Show this help message"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 stage"
    echo "  $0 commit"
    echo "  $0 quick \"feat(sql): add recursive CTE cheatsheet\""
    echo "  $0 history"
    echo
    echo "Workflow:"
    echo "  1. $0 status        # Check what's changed"
    echo "  2. $0 stage         # Stage your changes"
    echo "  3. $0 commit        # Create commit with guided message"
    echo "  OR"
    echo "  3. $0 quick \"msg\"  # Quick commit with message"
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
        "quick")
            quick_commit "$2"
            ;;
        "history")
            show_history
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@" 