#!/usr/bin/env python3
"""
Configuration Management for SQL Adventure AI Evaluator
Handles environment setup, validation, and configuration management
"""

import os
import json
from typing import Dict, Any, Optional, List
from pathlib import Path
from dataclasses import dataclass, field
from enum import Enum
import logging

class LogLevel(Enum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"

class EvaluatorModel(Enum):
    GPT_4O_MINI = "gpt-4o-mini"
    GPT_4O = "gpt-4o"
    GPT_4_TURBO = "gpt-4-turbo"
    GPT_35_TURBO = "gpt-3.5-turbo"

@dataclass
class DatabaseConfig:
    """Database configuration settings"""
    host: str = "localhost"
    port: int = 5432
    user: str = "postgres"
    password: str = "postgres"
    database: str = "sql_adventure_evaluator"
    main_database: str = "sql_adventure_db"
    use_separate_db: bool = True
    
    # Connection pool settings
    pool_size: int = 10
    max_overflow: int = 20
    pool_pre_ping: bool = True
    pool_recycle: int = 3600
    
    # Performance settings
    echo_sql: bool = False
    query_timeout: int = 30
    
    def get_connection_string(self, use_main_db: bool = False) -> str:
        """Get database connection string"""
        db_name = self.main_database if use_main_db else self.database
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{db_name}"
    
    def validate(self) -> List[str]:
        """Validate database configuration"""
        errors = []
        
        if not self.host:
            errors.append("Database host is required")
        if not (1 <= self.port <= 65535):
            errors.append("Database port must be between 1 and 65535")
        if not self.user:
            errors.append("Database user is required")
        if not self.password:
            errors.append("Database password is required")
        if not self.database:
            errors.append("Database name is required")
        if self.pool_size < 1:
            errors.append("Pool size must be at least 1")
        if self.max_overflow < 0:
            errors.append("Max overflow must be non-negative")
        if self.query_timeout < 1:
            errors.append("Query timeout must be at least 1 second")
            
        return errors

@dataclass
class AIConfig:
    """AI/LLM configuration settings"""
    openai_api_key: str = ""
    model: EvaluatorModel = EvaluatorModel.GPT_4O_MINI
    temperature: float = 0.2
    max_tokens: Optional[int] = None
    timeout: int = 60
    max_retries: int = 3
    rate_limit_requests: int = 50
    rate_limit_window: int = 60
    
    # Evaluation settings
    confidence_threshold: float = 0.7
    enable_enhanced_intent: bool = True
    enable_pattern_detection: bool = True
    batch_size: int = 5
    
    def validate(self) -> List[str]:
        """Validate AI configuration"""
        errors = []
        
        if not self.openai_api_key:
            errors.append("OpenAI API key is required")
        if not (0.0 <= self.temperature <= 2.0):
            errors.append("Temperature must be between 0.0 and 2.0")
        if self.max_tokens is not None and self.max_tokens < 1:
            errors.append("Max tokens must be positive")
        if self.timeout < 1:
            errors.append("Timeout must be at least 1 second")
        if self.max_retries < 0:
            errors.append("Max retries must be non-negative")
        if not (0.0 <= self.confidence_threshold <= 1.0):
            errors.append("Confidence threshold must be between 0.0 and 1.0")
        if self.batch_size < 1:
            errors.append("Batch size must be at least 1")
        if self.rate_limit_requests < 1:
            errors.append("Rate limit requests must be at least 1")
        if self.rate_limit_window < 1:
            errors.append("Rate limit window must be at least 1 second")
            
        return errors

@dataclass
class EvaluationConfig:
    """Evaluation process configuration"""
    max_parallel_evaluations: int = 3
    execution_timeout: int = 30
    max_output_lines: int = 1000
    enable_execution: bool = True
    enable_ai_analysis: bool = True
    save_to_database: bool = True
    save_to_files: bool = True
    
    # File handling
    output_directory: str = "ai-evaluations"
    backup_directory: str = "evaluation-backups"
    max_backup_files: int = 10
    
    # Quest discovery
    quests_directory: str = "quests"
    enable_quest_discovery: bool = True
    auto_generate_metadata: bool = False
    
    # Quality control
    min_score_threshold: int = 1
    max_score_threshold: int = 10
    require_valid_sql: bool = True
    skip_unchanged_files: bool = True
    
    def validate(self) -> List[str]:
        """Validate evaluation configuration"""
        errors = []
        
        if self.max_parallel_evaluations < 1:
            errors.append("Max parallel evaluations must be at least 1")
        if self.execution_timeout < 1:
            errors.append("Execution timeout must be at least 1 second")
        if self.max_output_lines < 10:
            errors.append("Max output lines must be at least 10")
        if not self.output_directory:
            errors.append("Output directory is required")
        if not (1 <= self.min_score_threshold <= 10):
            errors.append("Min score threshold must be between 1 and 10")
        if not (1 <= self.max_score_threshold <= 10):
            errors.append("Max score threshold must be between 1 and 10")
        if self.min_score_threshold > self.max_score_threshold:
            errors.append("Min score threshold cannot be greater than max score threshold")
        if self.max_backup_files < 0:
            errors.append("Max backup files must be non-negative")
            
        return errors

@dataclass
class LoggingConfig:
    """Logging configuration"""
    level: LogLevel = LogLevel.INFO
    format: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    log_to_file: bool = True
    log_file: str = "evaluator.log"
    max_log_size: int = 10 * 1024 * 1024  # 10MB
    backup_count: int = 5
    log_to_console: bool = True
    
    def validate(self) -> List[str]:
        """Validate logging configuration"""
        errors = []
        
        if not self.format:
            errors.append("Log format is required")
        if self.log_to_file and not self.log_file:
            errors.append("Log file path is required when logging to file")
        if self.max_log_size < 1024:
            errors.append("Max log size must be at least 1KB")
        if self.backup_count < 0:
            errors.append("Backup count must be non-negative")
            
        return errors

@dataclass
class EvaluatorConfig:
    """Main evaluator configuration"""
    database: DatabaseConfig = field(default_factory=DatabaseConfig)
    ai: AIConfig = field(default_factory=AIConfig)
    evaluation: EvaluationConfig = field(default_factory=EvaluationConfig)
    logging: LoggingConfig = field(default_factory=LoggingConfig)
    
    # Meta configuration
    config_version: str = "2.0"
    environment: str = "development"
    debug_mode: bool = False
    
    @classmethod
    def from_env(cls) -> 'EvaluatorConfig':
        """Create configuration from environment variables"""
        config = cls()
        
        # Database configuration
        config.database.host = os.getenv('DB_HOST', config.database.host)
        config.database.port = int(os.getenv('DB_PORT', config.database.port))
        config.database.user = os.getenv('DB_USER', config.database.user)
        config.database.password = os.getenv('DB_PASSWORD', config.database.password)
        config.database.database = os.getenv('EVALUATOR_DB_NAME', config.database.database)
        config.database.main_database = os.getenv('DB_NAME', config.database.main_database)
        config.database.use_separate_db = os.getenv('USE_SEPARATE_DB', 'true').lower() == 'true'
        config.database.echo_sql = os.getenv('DB_ECHO_SQL', 'false').lower() == 'true'
        
        # AI configuration
        config.ai.openai_api_key = os.getenv('OPENAI_API_KEY', '')
        config.ai.model = EvaluatorModel(os.getenv('EVALUATOR_MODEL', config.ai.model.value))
        config.ai.temperature = float(os.getenv('AI_TEMPERATURE', config.ai.temperature))
        config.ai.timeout = int(os.getenv('AI_TIMEOUT', config.ai.timeout))
        config.ai.max_retries = int(os.getenv('AI_MAX_RETRIES', config.ai.max_retries))
        
        # Evaluation configuration
        config.evaluation.max_parallel_evaluations = int(os.getenv('MAX_PARALLEL_EVAL', config.evaluation.max_parallel_evaluations))
        config.evaluation.execution_timeout = int(os.getenv('EXECUTION_TIMEOUT', config.evaluation.execution_timeout))
        config.evaluation.enable_execution = os.getenv('ENABLE_EXECUTION', 'true').lower() == 'true'
        config.evaluation.enable_ai_analysis = os.getenv('ENABLE_AI_ANALYSIS', 'true').lower() == 'true'
        config.evaluation.save_to_database = os.getenv('SAVE_TO_DATABASE', 'true').lower() == 'true'
        config.evaluation.output_directory = os.getenv('OUTPUT_DIRECTORY', config.evaluation.output_directory)
        
        # Logging configuration
        config.logging.level = LogLevel(os.getenv('LOG_LEVEL', config.logging.level.value))
        config.logging.log_to_file = os.getenv('LOG_TO_FILE', 'true').lower() == 'true'
        config.logging.log_file = os.getenv('LOG_FILE', config.logging.log_file)
        config.logging.log_to_console = os.getenv('LOG_TO_CONSOLE', 'true').lower() == 'true'
        
        # Meta configuration
        config.environment = os.getenv('ENVIRONMENT', config.environment)
        config.debug_mode = os.getenv('DEBUG_MODE', 'false').lower() == 'true'
        
        return config
    
    @classmethod
    def from_file(cls, file_path: str) -> 'EvaluatorConfig':
        """Load configuration from JSON file"""
        if not file_path:
            raise ValueError("File path cannot be empty")
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Configuration file not found: {file_path}")
        
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        return cls.from_dict(data)
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'EvaluatorConfig':
        """Create configuration from dictionary"""
        config = cls()
        
        # Database config
        if 'database' in data:
            db_data = data['database']
            for key, value in db_data.items():
                if hasattr(config.database, key):
                    setattr(config.database, key, value)
        
        # AI config
        if 'ai' in data:
            ai_data = data['ai']
            for key, value in ai_data.items():
                if hasattr(config.ai, key):
                    if key == 'model':
                        setattr(config.ai, key, EvaluatorModel(value))
                    else:
                        setattr(config.ai, key, value)
        
        # Evaluation config
        if 'evaluation' in data:
            eval_data = data['evaluation']
            for key, value in eval_data.items():
                if hasattr(config.evaluation, key):
                    setattr(config.evaluation, key, value)
        
        # Logging config
        if 'logging' in data:
            log_data = data['logging']
            for key, value in log_data.items():
                if hasattr(config.logging, key):
                    if key == 'level':
                        setattr(config.logging, key, LogLevel(value))
                    else:
                        setattr(config.logging, key, value)
        
        # Meta config
        config.config_version = data.get('config_version', config.config_version)
        config.environment = data.get('environment', config.environment)
        config.debug_mode = data.get('debug_mode', config.debug_mode)
        
        return config
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert configuration to dictionary"""
        return {
            'config_version': self.config_version,
            'environment': self.environment,
            'debug_mode': self.debug_mode,
            'database': {
                'host': self.database.host,
                'port': self.database.port,
                'user': self.database.user,
                'password': '***',  # Don't expose password
                'database': self.database.database,
                'main_database': self.database.main_database,
                'use_separate_db': self.database.use_separate_db,
                'pool_size': self.database.pool_size,
                'max_overflow': self.database.max_overflow,
                'pool_pre_ping': self.database.pool_pre_ping,
                'pool_recycle': self.database.pool_recycle,
                'echo_sql': self.database.echo_sql,
                'query_timeout': self.database.query_timeout
            },
            'ai': {
                'openai_api_key': '***' if self.ai.openai_api_key else '',  # Don't expose API key
                'model': self.ai.model.value,
                'temperature': self.ai.temperature,
                'max_tokens': self.ai.max_tokens,
                'timeout': self.ai.timeout,
                'max_retries': self.ai.max_retries,
                'rate_limit_requests': self.ai.rate_limit_requests,
                'rate_limit_window': self.ai.rate_limit_window,
                'confidence_threshold': self.ai.confidence_threshold,
                'enable_enhanced_intent': self.ai.enable_enhanced_intent,
                'enable_pattern_detection': self.ai.enable_pattern_detection,
                'batch_size': self.ai.batch_size
            },
            'evaluation': {
                'max_parallel_evaluations': self.evaluation.max_parallel_evaluations,
                'execution_timeout': self.evaluation.execution_timeout,
                'max_output_lines': self.evaluation.max_output_lines,
                'enable_execution': self.evaluation.enable_execution,
                'enable_ai_analysis': self.evaluation.enable_ai_analysis,
                'save_to_database': self.evaluation.save_to_database,
                'save_to_files': self.evaluation.save_to_files,
                'output_directory': self.evaluation.output_directory,
                'backup_directory': self.evaluation.backup_directory,
                'max_backup_files': self.evaluation.max_backup_files,
                'min_score_threshold': self.evaluation.min_score_threshold,
                'max_score_threshold': self.evaluation.max_score_threshold,
                'require_valid_sql': self.evaluation.require_valid_sql,
                'skip_unchanged_files': self.evaluation.skip_unchanged_files
            },
            'logging': {
                'level': self.logging.level.value,
                'format': self.logging.format,
                'log_to_file': self.logging.log_to_file,
                'log_file': self.logging.log_file,
                'max_log_size': self.logging.max_log_size,
                'backup_count': self.logging.backup_count,
                'log_to_console': self.logging.log_to_console
            }
        }
    
    def save_to_file(self, file_path: str, include_secrets: bool = False):
        """Save configuration to JSON file"""
        data = self.to_dict()
        
        if include_secrets:
            data['database']['password'] = self.database.password
            data['ai']['openai_api_key'] = self.ai.openai_api_key
        
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    def validate(self) -> Dict[str, List[str]]:
        """Validate all configuration sections"""
        errors = {}
        
        db_errors = self.database.validate()
        if db_errors:
            errors['database'] = db_errors
        
        ai_errors = self.ai.validate()
        if ai_errors:
            errors['ai'] = ai_errors
        
        eval_errors = self.evaluation.validate()
        if eval_errors:
            errors['evaluation'] = eval_errors
        
        log_errors = self.logging.validate()
        if log_errors:
            errors['logging'] = log_errors
        
        return errors
    
    def is_valid(self) -> bool:
        """Check if configuration is valid"""
        return len(self.validate()) == 0
    
    def setup_logging(self):
        """Setup logging based on configuration"""
        # Clear any existing handlers
        root_logger = logging.getLogger()
        for handler in root_logger.handlers[:]:
            root_logger.removeHandler(handler)
        
        # Set log level
        log_level = getattr(logging, self.logging.level.value)
        root_logger.setLevel(log_level)
        
        # Create formatter
        formatter = logging.Formatter(self.logging.format)
        
        # Console handler
        if self.logging.log_to_console:
            console_handler = logging.StreamHandler()
            console_handler.setLevel(log_level)
            console_handler.setFormatter(formatter)
            root_logger.addHandler(console_handler)
        
        # File handler
        if self.logging.log_to_file and self.logging.log_file:
            from logging.handlers import RotatingFileHandler
            
            log_dir = os.path.dirname(self.logging.log_file)
            if log_dir:  # Only create directory if it's not empty
                try:
                    os.makedirs(log_dir, exist_ok=True)
                except Exception as e:
                    print(f"Warning: Could not create log directory '{log_dir}': {e}")
            
            file_handler = RotatingFileHandler(
                self.logging.log_file,
                maxBytes=self.logging.max_log_size,
                backupCount=self.logging.backup_count
            )
            file_handler.setLevel(log_level)
            file_handler.setFormatter(formatter)
            root_logger.addHandler(file_handler)
    
    def setup_directories(self):
        """Create necessary directories"""
        directories = [
            self.evaluation.output_directory,
            self.evaluation.backup_directory,
        ]
        
        # Add log file directory if logging to file
        if self.logging.log_to_file and self.logging.log_file:
            log_dir = os.path.dirname(self.logging.log_file)
            if log_dir:  # Only add if directory is not empty
                directories.append(log_dir)
        
        for directory in directories:
            if directory:
                try:
                    os.makedirs(directory, exist_ok=True)
                except Exception as e:
                    print(f"Warning: Could not create directory '{directory}': {e}")

class ConfigManager:
    """Configuration manager with environment detection and validation"""
    
    DEFAULT_CONFIG_PATHS = [
        'evaluator_config.json',
        'config/evaluator.json',
        '~/.sql_adventure/evaluator_config.json',
        '/etc/sql_adventure/evaluator_config.json'
    ]
    
    @classmethod
    def load_config(cls, config_path: Optional[str] = None) -> EvaluatorConfig:
        """Load configuration with fallback priority"""
        
        # 1. Try explicit config path
        if config_path and os.path.exists(config_path):
            try:
                return EvaluatorConfig.from_file(config_path)
            except Exception as e:
                print(f"⚠️  Failed to load config from {config_path}: {e}")
        
        # 2. Try default config paths
        for path in cls.DEFAULT_CONFIG_PATHS:
            expanded_path = os.path.expanduser(path)
            if os.path.exists(expanded_path):
                try:
                    return EvaluatorConfig.from_file(expanded_path)
                except Exception as e:
                    print(f"⚠️  Failed to load config from {expanded_path}: {e}")
        
        # 3. Fall back to environment variables
        print("📝 Loading configuration from environment variables")
        return EvaluatorConfig.from_env()
    
    @classmethod
    def create_sample_config(cls, file_path: str = 'evaluator_config.json'):
        """Create a sample configuration file"""
        config = EvaluatorConfig()
        config.save_to_file(file_path, include_secrets=False)
        print(f"✅ Sample configuration created: {file_path}")
        print("🔧 Please edit the configuration and add your API keys and database credentials")
    
    @classmethod
    def validate_environment(cls) -> Dict[str, Any]:
        """Validate the current environment for running the evaluator"""
        checks = {
            'python_version': True,
            'required_packages': True,
            'database_connection': False,
            'openai_api_key': False,
            'file_permissions': True,
            'disk_space': True
        }
        
        issues = []
        
        # Check Python version
        import sys
        if sys.version_info < (3, 8):
            checks['python_version'] = False
            issues.append("Python 3.8 or higher is required")
        
        # Check required packages
        required_packages = [
            'sqlalchemy', 'psycopg2', 'pydantic', 'pydantic_ai', 'openai'
        ]
        
        for package in required_packages:
            try:
                __import__(package)
            except ImportError:
                checks['required_packages'] = False
                issues.append(f"Required package missing: {package}")
        
        # Check OpenAI API key
        if os.getenv('OPENAI_API_KEY'):
            checks['openai_api_key'] = True
        else:
            issues.append("OPENAI_API_KEY environment variable not set")
        
        # Check database connection (basic connectivity)
        try:
            config = EvaluatorConfig.from_env()
            if config.database.password and config.database.host:
                checks['database_connection'] = True
        except Exception:
            issues.append("Database configuration incomplete or invalid")
        
        return {
            'checks': checks,
            'issues': issues,
            'ready': all(checks.values())
        }

# Create a global config instance
_global_config: Optional[EvaluatorConfig] = None

def get_config() -> EvaluatorConfig:
    """Get the global configuration instance"""
    global _global_config
    if _global_config is None:
        _global_config = ConfigManager.load_config()
    return _global_config

def set_config(config: EvaluatorConfig):
    """Set the global configuration instance"""
    global _global_config
    _global_config = config