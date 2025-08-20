#!/usr/bin/env python3
"""
Environment Configuration Loader for SQL Adventure Evaluator

Handles the complexity of loading evaluator environment variables
when called from project root or evaluator directory.
"""

import os
from pathlib import Path
from typing import Optional


# Global flag to track if environment has been loaded
_env_loaded = False


def load_evaluator_env() -> None:
    """
    Load evaluator environment variables from .env file.
    Uses singleton pattern to avoid loading multiple times.
    
    Searches for .env file in:
    1. scripts/evaluator/.env (when called from project root)
    2. .env (when called from evaluator directory)
    """
    global _env_loaded
    
    if _env_loaded:
        return  # Already loaded, skip
    
    try:
        from dotenv import load_dotenv
    except ImportError:
        # dotenv not available, rely on system environment
        print("📝 Note: python-dotenv not available, using system environment variables")
        _env_loaded = True
        return
    
    # Determine the correct path to .env file
    evaluator_env_paths = [
        Path("scripts/evaluator/.env"),  # From project root
        Path(".env"),  # From evaluator directory
        Path(__file__).parent.parent / ".env",  # Relative to this file
    ]
    
    env_file_loaded = False
    for env_path in evaluator_env_paths:
        if env_path.exists():
            print(f"📋 Loading evaluator environment from: {env_path}")
            load_dotenv(env_path)
            env_file_loaded = True
            break
    
    if not env_file_loaded:
        print("⚠️  No evaluator .env file found, using system environment variables")
        print("   Searched paths:", [str(p) for p in evaluator_env_paths])
    
    _env_loaded = True


def get_evaluator_db_config() -> dict:
    """Get evaluator database configuration from environment variables"""
    return {
        'host': os.getenv('EVALUATOR_DB_HOST', 'localhost'),
        'port': int(os.getenv('EVALUATOR_DB_PORT', '5432')),
        'user': os.getenv('EVALUATOR_DB_USER', 'postgres'),
        'password': os.getenv('EVALUATOR_DB_PASSWORD', 'postgres'),
        'database': os.getenv('EVALUATOR_DB_NAME', 'sql_adventure_evaluator'),
    }


def get_quests_db_config() -> dict:
    """Get quests database configuration from environment variables"""
    return {
        'host': os.getenv('QUESTS_DB_HOST', 'localhost'),
        'port': int(os.getenv('QUESTS_DB_PORT', '5432')),
        'user': os.getenv('QUESTS_DB_USER', 'postgres'),
        'password': os.getenv('QUESTS_DB_PASSWORD', 'postgres'),
        'database': os.getenv('QUESTS_DB_NAME', 'sql_adventure_quests'),
    }


def get_openai_config() -> dict:
    """Get OpenAI configuration from environment variables"""
    return {
        'api_key': os.getenv('OPENAI_API_KEY'),
        'model_name': os.getenv('MODEL_NAME', 'gpt-4o-mini'),
    }


def validate_config() -> bool:
    """
    Validate that required configuration is available
    
    Returns:
        bool: True if configuration is valid, False otherwise
    """
    evaluator_config = get_evaluator_db_config()
    quests_config = get_quests_db_config()
    openai_config = get_openai_config()
    
    # Check required configurations
    if not openai_config['api_key']:
        print("❌ OPENAI_API_KEY is required but not set")
        return False
    
    print("✅ Configuration validation passed")
    print(f"   Evaluator DB: {evaluator_config['user']}@{evaluator_config['host']}:{evaluator_config['port']}/{evaluator_config['database']}")
    print(f"   Quests DB: {quests_config['user']}@{quests_config['host']}:{quests_config['port']}/{quests_config['database']}")
    print(f"   OpenAI Model: {openai_config['model_name']}")
    
    return True


# Auto-load environment when this module is imported
load_evaluator_env()
