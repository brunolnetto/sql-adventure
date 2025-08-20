import os
from typing import Literal

def get_evaluator_connection_string() -> str:
    """Get connection string for the evaluator database (metadata storage)"""
    host = os.getenv('EVALUATOR_DB_HOST', 'localhost')
    port = os.getenv('EVALUATOR_DB_PORT', '5432')
    user = os.getenv('EVALUATOR_DB_USER', 'postgres')
    password = os.getenv('EVALUATOR_DB_PASSWORD', 'postgres')
    database = os.getenv('EVALUATOR_DB_NAME', 'sql_adventure_evaluator')
    return f"postgresql://{user}:{password}@{host}:{port}/{database}"

def get_quests_connection_string() -> str:
    """Get connection string for the quests database (SQL execution sandbox)"""
    host = os.getenv('QUESTS_DB_HOST', 'localhost')
    port = os.getenv('QUESTS_DB_PORT', '5432')
    user = os.getenv('QUESTS_DB_USER', 'postgres')
    password = os.getenv('QUESTS_DB_PASSWORD', 'postgres')
    database = os.getenv('QUESTS_DB_NAME', 'sql_adventure_quests')
    return f"postgresql://{user}:{password}@{host}:{port}/{database}"

def get_connection_string(database_type: Literal["evaluator", "quests"] = "evaluator") -> str:
    """
    Get connection string for specified database type
    
    Args:
        database_type: "evaluator" for metadata storage, "quests" for SQL execution
    """
    if database_type == "evaluator":
        return get_evaluator_connection_string()
    elif database_type == "quests":
        return get_quests_connection_string()
    else:
        raise ValueError(f"Invalid database_type: {database_type}. Must be 'evaluator' or 'quests'")

# Legacy compatibility function (defaults to evaluator database)
def get_connection_string_legacy(database_name: str) -> str:
    """Legacy function for backward compatibility - uses evaluator database"""
    host = os.getenv('EVALUATOR_DB_HOST', 'localhost')
    port = os.getenv('EVALUATOR_DB_PORT', '5432')
    user = os.getenv('EVALUATOR_DB_USER', 'postgres')
    password = os.getenv('EVALUATOR_DB_PASSWORD', 'postgres')
    return f"postgresql://{user}:{password}@{host}:{port}/{database_name}"