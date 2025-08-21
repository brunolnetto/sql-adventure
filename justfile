# SQL Adventure - Development Justfile
# Run just --list to see all available commands
# Interface matches scripts/task_runner.sh commands

# Default recipe - show available commands
default:
	just --list
    
# Setup Commands
setup:
    scripts/task_runner.sh setup

install:
    scripts/task_runner.sh install

init-db:
    scripts/task_runner.sh init-db

docker-up:
    scripts/task_runner.sh docker-up

docker-down:
    scripts/task_runner.sh docker-down

# Evaluation Commands
evaluate path:
    scripts/task_runner.sh evaluate "{{path}}"

summary:
    scripts/task_runner.sh summary

basic path:
    scripts/task_runner.sh basic "{{path}}"

test:
    scripts/task_runner.sh test

validate:
    scripts/task_runner.sh validate

# Development Commands
clean:
    scripts/task_runner.sh clean

reset-db:
    scripts/task_runner.sh reset-db

logs:
    scripts/task_runner.sh logs
