#!/bin/bash
# SQL Adventure Evaluator - Task Runner
# Provides simple commands for common operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo -e "${BLUE}SQL Adventure Evaluator - Task Runner${NC}"
    echo "======================================"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Setup Commands:"
    echo "  setup         Run interactive configuration wizard"
    echo "  install       Install Python dependencies"
    echo "  init-db       Initialize database schema"
    echo "  docker-up     Start PostgreSQL with Docker"
    echo "  docker-down   Stop PostgreSQL Docker container"
    echo ""
    echo "Evaluation Commands:"
    echo "  evaluate <path>   Evaluate SQL file or quest directory"
    echo "  ai-demo <file>    Quick AI analysis of a single SQL file"
    echo "  summary          Generate evaluation summary report"
    echo "  basic <path>      Basic SQL validation (syntax, style)"
    echo "  test             Run test suite"
    echo "  validate         Validate current configuration"
    echo ""
    echo "Development Commands:"
    echo "  clean            Clean cache and temporary files"
    echo "  reset-db         Reset database (destructive!)"
    echo "  logs             Show recent evaluation logs"
    echo ""
    echo "Examples:"
    echo "  $0 setup                           # Initial setup"
    echo "  $0 ai-demo file.sql                # Quick AI analysis"
    echo "  $0 evaluate quests/1-data-modeling # Evaluate entire quest"
    echo "  $0 summary                         # Generate evaluation report"
    echo "  $0 basic file.sql                  # Basic validation"
    echo "  $0 evaluate file.sql               # Evaluate single file"
}

setup() {
    echo -e "${BLUE}🚀 Running setup wizard...${NC}"
    cd "$PROJECT_ROOT"
    python3 scripts/evaluator/setup_wizard.py
}

install() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    cd "$PROJECT_ROOT"
    
    if [ -f "scripts/evaluator/requirements.txt" ]; then
        # Check if we're in a virtual environment
        if [[ "$VIRTUAL_ENV" != "" ]]; then
            echo "📦 Virtual environment detected: $VIRTUAL_ENV"
            pip install -r scripts/evaluator/requirements.txt
        else
            echo -e "${YELLOW}⚠️  No virtual environment detected${NC}"
            echo "💡 Trying pip3 with user install..."
            pip3 install --user -r scripts/evaluator/requirements.txt || {
                echo -e "${YELLOW}⚠️  Consider creating a virtual environment:${NC}"
                echo "   python3 -m venv venv"
                echo "   source venv/bin/activate"
                echo "   pip install -r scripts/evaluator/requirements.txt"
                exit 1
            }
        fi
        echo -e "${GREEN}✅ Dependencies installed${NC}"
    else
        echo -e "${RED}❌ requirements.txt not found${NC}"
        exit 1
    fi
}

init_db() {
    echo -e "${BLUE}🗄️  Initializing database...${NC}"
    cd "$PROJECT_ROOT"
    
    # Check if configuration exists
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}⚠️  No .env file found. Running setup first...${NC}"
        setup
    fi
    
    python3 scripts/evaluator/init_database.py
    echo -e "${GREEN}✅ Database initialized${NC}"
}

docker_up() {
    echo -e "${BLUE}🐳 Starting PostgreSQL with Docker...${NC}"
    cd "$PROJECT_ROOT"
    
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${YELLOW}⚠️  No docker-compose.yml found. Running setup first...${NC}"
        setup
    fi
    
    docker-compose up -d
    echo -e "${GREEN}✅ PostgreSQL started${NC}"
    echo -e "${BLUE}💡 Connect: psql -h localhost -U postgres -d sql_adventure${NC}"
}

docker_down() {
    echo -e "${BLUE}🐳 Stopping PostgreSQL Docker container...${NC}"
    cd "$PROJECT_ROOT"
    docker-compose down
    echo -e "${GREEN}✅ PostgreSQL stopped${NC}"
}

evaluate() {
    local target="$1"
    if [ -z "$target" ]; then
        echo -e "${RED}❌ Please specify a file or directory to evaluate${NC}"
        echo "Usage: $0 evaluate <path>"
        exit 1
    fi
    
    echo -e "${BLUE}🔍 Evaluating: $target${NC}"
    cd "$PROJECT_ROOT"
    
    # Load environment variables
    if [ -f ".env" ]; then
        echo -e "${BLUE}📋 Loading configuration from .env...${NC}"
        set -a
        source .env
        set +a
    else
        echo -e "${YELLOW}⚠️  No .env file found. Some features may not work.${NC}"
    fi
    
    if [ -f "$target" ]; then
        # Single file evaluation
        PYTHONPATH="$PWD/scripts/evaluator:$PYTHONPATH" python3 scripts/evaluator/run_evaluation.py "$target"
    elif [ -d "$target" ]; then
        # Directory evaluation
        PYTHONPATH="$PWD/scripts/evaluator:$PYTHONPATH" python3 scripts/evaluator/run_evaluation.py "$target"
    else
        echo -e "${RED}❌ File or directory not found: $target${NC}"
        exit 1
    fi
}

run_tests() {
    echo -e "${BLUE}🧪 Running test suite...${NC}"
    cd "$PROJECT_ROOT"
    
    # Load environment variables
    if [ -f ".env" ]; then
        set -a
        source .env
        set +a
    fi
    
    if command -v pytest &> /dev/null; then
        PYTHONPATH=scripts pytest scripts/evaluator/tests/ -v
    else
        PYTHONPATH=scripts python3 -m evaluator.tests.test_basic_evaluation
    fi
}

validate_config() {
    echo -e "${BLUE}✅ Validating configuration...${NC}"
    cd "$PROJECT_ROOT"
    
    python3 -c "
from scripts.evaluator.config import validate_config_or_exit
config = validate_config_or_exit()
print('🎉 Configuration is valid!')
print(f'Model: {config.model_name}')
print(f'Database: {config.postgres_db_name}@{config.db_host}')
"
}

ai_demo() {
    local target="$1"
    if [ -z "$target" ]; then
        echo -e "${RED}❌ Please specify a SQL file for AI analysis${NC}"
        echo "Usage: $0 ai-demo <file.sql>"
        exit 1
    fi
    
    echo -e "${BLUE}🤖 Running AI-powered analysis...${NC}"
    cd "$PROJECT_ROOT"
    
    if [ ! -f "$target" ]; then
        echo -e "${RED}❌ File not found: $target${NC}"
        exit 1
    fi
    
    # Load environment variables
    if [ -f ".env" ]; then
        echo -e "${BLUE}📋 Loading configuration from .env...${NC}"
        set -a
        source .env
        set +a
    else
        echo -e "${YELLOW}⚠️  No .env file found. Some features may not work.${NC}"
    fi
    
    # Use the existing run_evaluation.py script for single file analysis
    PYTHONPATH="$PWD/scripts/evaluator:$PYTHONPATH" python3 scripts/evaluator/run_evaluation.py "$target"
}

summary() {
    echo -e "${BLUE}📊 Generating evaluation summary report...${NC}"
    cd "$PROJECT_ROOT"
    
    # Load environment variables
    if [ -f ".env" ]; then
        echo -e "${BLUE}📋 Loading configuration from .env...${NC}"
        set -a
        source .env
        set +a
    else
        echo -e "${YELLOW}⚠️  No .env file found. Some features may not work.${NC}"
    fi
    
    # Use the existing run_summary.py script
    PYTHONPATH="$PWD/scripts/evaluator:$PYTHONPATH" python3 scripts/evaluator/run_summary.py --print
}

basic_validate() {
    local target="$1"
    if [ -z "$target" ]; then
        echo -e "${RED}❌ Please specify a file to validate${NC}"
        echo "Usage: $0 basic <file.sql>"
        exit 1
    fi
    
    echo -e "${BLUE}🔍 Basic validation: $target${NC}"
    cd "$PROJECT_ROOT"
    
    if [ ! -f "$target" ]; then
        echo -e "${RED}❌ File not found: $target${NC}"
        exit 1
    fi
    
    # Basic file checks
    echo "📁 File checks:"
    local size=$(stat -c%s "$target" 2>/dev/null || echo "0")
    if [ "$size" -eq 0 ]; then
        echo -e "${RED}❌ File is empty${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ File exists and has content ($size bytes)${NC}"
    
    # SQL statement presence
    if ! grep -iqE "CREATE|SELECT|INSERT|UPDATE|DELETE|WITH" "$target"; then
        echo -e "${YELLOW}⚠️  No recognizable SQL statements found${NC}"
    else
        echo -e "${GREEN}✅ Contains SQL statements${NC}"
    fi
    
    # Line length check
    local long_lines=$(awk 'length($0)>120 { count++ } END { print count+0 }' "$target")
    if [ "$long_lines" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $long_lines lines exceed 120 characters${NC}"
    else
        echo -e "${GREEN}✅ All lines ≤120 characters${NC}"
    fi
    
    echo -e "${GREEN}✅ Basic validation completed${NC}"
}

clean() {
    echo -e "${BLUE}🧹 Cleaning temporary files...${NC}"
    cd "$PROJECT_ROOT"
    
    # Remove cache directories
    rm -rf .evaluations-cache/
    rm -rf scripts/evaluator/__pycache__/
    rm -rf scripts/evaluator/utils/__pycache__/
    rm -rf scripts/evaluator/core/__pycache__/
    
    # Remove temporary files
    find . -name "*.pyc" -delete
    find . -name "*.pyo" -delete
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

reset_db() {
    echo -e "${YELLOW}⚠️  This will destroy all evaluation data!${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🗄️  Resetting database...${NC}"
        cd "$PROJECT_ROOT"
        
        # Drop and recreate database
        python3 -c "
from scripts.evaluator.database.manager import DatabaseManager
from scripts.evaluator.config import EvaluationConfig

config = EvaluationConfig()
db_manager = DatabaseManager()
db_manager.reset_database()
print('✅ Database reset complete')
"
        echo -e "${GREEN}✅ Database reset complete${NC}"
    else
        echo "Operation cancelled"
    fi
}

show_logs() {
    echo -e "${BLUE}📋 Recent evaluation logs...${NC}"
    cd "$PROJECT_ROOT"
    
    if [ -f "ai-evaluations/evaluations.log" ]; then
        tail -n 50 ai-evaluations/evaluations.log
    else
        echo -e "${YELLOW}⚠️  No log file found${NC}"
    fi
}

# Main command dispatcher
case "$1" in
    setup)
        setup
        ;;
    install)
        install
        ;;
    init-db)
        init_db
        ;;
    docker-up)
        docker_up
        ;;
    docker-down)
        docker_down
        ;;
    evaluate)
        evaluate "$2"
        ;;
    ai-demo)
        ai_demo "$2"
        ;;
    summary)
        summary
        ;;
    basic)
        basic_validate "$2"
        ;;
    test)
        run_tests
        ;;
    validate)
        validate_config
        ;;
    clean)
        clean
        ;;
    reset-db)
        reset_db
        ;;
    logs)
        show_logs
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
