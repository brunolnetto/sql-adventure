# Configuration package for SQL Adventure Evaluator

from .env_loader import (
    load_evaluator_env, 
    validate_config,
    get_evaluator_db_config,
    get_quests_db_config,
    get_openai_config
)

# Import configuration classes from the main config file
import sys
import os
sys.path.append(os.path.dirname(__file__))

# Re-export from the parent config.py
try:
    from ..config import ProjectFolderConfig, EvaluatorDatabaseConfig, QuestsDatabaseConfig, EvaluationConfig
except ImportError:
    # If relative import fails, try absolute import
    import importlib.util
    spec = importlib.util.spec_from_file_location("parent_config", 
                                                  os.path.join(os.path.dirname(__file__), "..", "config.py"))
    parent_config = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(parent_config)
    
    ProjectFolderConfig = parent_config.ProjectFolderConfig
    EvaluatorDatabaseConfig = parent_config.EvaluatorDatabaseConfig
    QuestsDatabaseConfig = parent_config.QuestsDatabaseConfig
    EvaluationConfig = parent_config.EvaluationConfig

__all__ = [
    'load_evaluator_env',
    'validate_config', 
    'get_evaluator_db_config',
    'get_quests_db_config',
    'get_openai_config',
    'ProjectFolderConfig',
    'EvaluatorDatabaseConfig',
    'QuestsDatabaseConfig',
    'EvaluationConfig'
]
