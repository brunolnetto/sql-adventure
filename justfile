# SQL Adventure - Development Justfile
# Run `just --list` to see all available commands

# Default recipe - show available commands
default:
    @just --list

# Setup and Installation
setup:
    #!/usr/bin/env bash
    echo "🚀 Setting up development environment..."
    chmod +x scripts/task_runner.sh
    scripts/task_runner.sh setup

install:
    #!/usr/bin/env bash
    echo "📦 Installing dependencies..."
    scripts/task_runner.sh install

# Database Management
init-db:
    #!/usr/bin/env bash
    echo "🗄️ Initializing database..."
    scripts/task_runner.sh init-db

docker-up:
    #!/usr/bin/env bash
    echo "🐳 Starting services..."
    scripts/task_runner.sh docker-up

docker-down:
    #!/usr/bin/env bash
    echo "🐳 Stopping services..."
    scripts/task_runner.sh docker-down

reset-db:
    #!/usr/bin/env bash
    echo "⚠️ Resetting database..."
    scripts/task_runner.sh reset-db

# Core Operations
eval file:
    #!/usr/bin/env bash
    echo "🔍 Evaluating: {{file}}"
    scripts/task_runner.sh evaluate "{{file}}"

eval-quest quest:
    #!/usr/bin/env bash
    echo "🎯 Evaluating quest: {{quest}}"
    scripts/task_runner.sh evaluate "quests/{{quest}}"

summary:
    #!/usr/bin/env bash
    echo "� Generating summary..."
    scripts/task_runner.sh summary

# Development & Testing
test:
    #!/usr/bin/env bash
    echo "🧪 Running tests..."
    scripts/task_runner.sh test

test-working:
    #!/usr/bin/env bash
    echo "🧪 Running core tests..."
    python3 -m pytest scripts/evaluator/tests/smoke/ scripts/evaluator/tests/unit/ scripts/evaluator/tests/integration/ -v

validate:
    #!/usr/bin/env bash
    echo "✅ Validating setup..."
    scripts/task_runner.sh validate

clean:
    #!/usr/bin/env bash
    echo "🧹 Cleaning up..."
    scripts/task_runner.sh clean

# Quick Commands
logs:
    #!/usr/bin/env bash
    scripts/task_runner.sh logs

# Development Workflow
dev: validate test-working
    #!/usr/bin/env bash
    echo "✅ Development check complete!"
