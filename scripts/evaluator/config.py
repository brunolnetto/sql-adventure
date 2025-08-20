from pathlib import Path
from typing import Optional
import os
from pydantic import Field, field_validator, ValidationError
from pydantic_settings import BaseSettings

# Load evaluator environment variables
from config.env_loader import load_evaluator_env, get_evaluator_db_config, get_quests_db_config, get_openai_config, validate_config

# Ensure environment is loaded
load_evaluator_env()


class ProjectFolderConfig(BaseSettings):
    """
    Configuration for persistence of evaluation data.
    Ensures required directories exist on initialization.
    """
    quests_dir: Path = Field(default_factory=lambda: Path("quests"))
    cache_dir: Path = Field(default_factory=lambda: Path(".evaluations-cache"))
    evaluations_dir: Path = Field(default_factory=lambda: Path("ai-evaluations"))

    @field_validator("quests_dir", "cache_dir", "evaluations_dir", mode='before')
    def expand_and_create_dirs(cls, v):
        path = Path(v)
        # expand user and make absolute
        path = path.expanduser().resolve()
        # create directory if it doesn't exist
        path.mkdir(parents=True, exist_ok=True)
        return path

    model_config = {"env_file": ".env", "extra": "ignore"}


class EvaluatorDatabaseConfig(BaseSettings):
    """Configuration for evaluator database (metadata storage)"""
    host: str = Field(default="localhost")
    port: int = Field(default=5432)
    user: str = Field(default="postgres")
    password: str = Field(default="postgres")
    database: str = Field(default="sql_adventure_evaluator")
    
    def __init__(self, **kwargs):
        # Load from environment loader
        env_config = get_evaluator_db_config()
        # Override with any provided kwargs
        config = {**env_config, **kwargs}
        super().__init__(**config)
    
    @property
    def connection_string(self) -> str:
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}"


class QuestsDatabaseConfig(BaseSettings):
    """Configuration for quests database (SQL execution sandbox)"""
    host: str = Field(default="localhost")
    port: int = Field(default=5432)
    user: str = Field(default="postgres")
    password: str = Field(default="postgres")
    database: str = Field(default="sql_adventure_quests")
    
    def __init__(self, **kwargs):
        # Load from environment loader
        env_config = get_quests_db_config()
        # Override with any provided kwargs
        config = {**env_config, **kwargs}
        super().__init__(**config)
    
    @property
    def connection_string(self) -> str:
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}"


class EvaluationConfig(BaseSettings):
    """
    Simplified configuration for evaluation runs with validation and helpful error messages.
    
    Environment Variables:
        OPENAI_API_KEY: Required for AI evaluations
        EVALUATOR_DB_NAME: Evaluator database name (default: sql_adventure_evaluator)
        EVALUATOR_DB_HOST: Database host (default: localhost)
        EVALUATOR_DB_USER: Database user (default: postgres)
        EVALUATOR_DB_PASSWORD: Database password (required for production)
    """
    # OpenAI Configuration
    openai_api_key: Optional[str] = Field(None, description="OpenAI API Key")
    model_name: str = Field("gpt-4o-mini", description="OpenAI model to use for evaluations")
    
    # Evaluator Database Configuration (metadata storage)
    evaluator_db_name: str = Field("sql_adventure_evaluator", description="Evaluator database name")
    evaluator_db_host: str = Field("localhost", description="Evaluator database host")
    evaluator_db_user: str = Field("postgres", description="Evaluator database user")
    evaluator_db_password: Optional[str] = Field(None, description="Evaluator database password")
    evaluator_db_port: int = Field(5432, description="Evaluator database port")
    
    # Quests Database Configuration (SQL execution sandbox)
    quests_db_name: str = Field("sql_adventure_quests", description="Quests database name")
    quests_db_host: str = Field("localhost", description="Quests database host")
    quests_db_user: str = Field("postgres", description="Quests database user")
    quests_db_password: Optional[str] = Field(None, description="Quests database password")
    quests_db_port: int = Field(5432, description="Quests database port")
    
    # Performance Configuration
    use_async_pool: bool = Field(False, description="Use async connection pooling")
    atomic_execution: bool = Field(True, description="Enable atomic execution")
    detailed_logging: bool = Field(False, description="Enable detailed logging")
    
    # Evaluation Settings
    max_concurrent_files: int = Field(3, description="Parallel files per quest")
    cache_enabled: bool = Field(True, description="Enable caching of results")
    skip_unchanged: bool = Field(True, description="Skip files unchanged since last evaluation")
    output_dir: Optional[Path] = Field(None, description="Custom output directory for evaluations")

    model_config = {
        "env_file_encoding": "utf-8", 
        "extra": "ignore"  # Ignore extra environment variables from root .env
    }

    def validate_setup(self) -> tuple[bool, list[str]]:
        """
        Validate configuration and return helpful error messages.
        
        Returns:
            Tuple of (is_valid, error_messages)
        """
        errors = []
        
        # Check OpenAI API key
        if not self.openai_api_key:
            errors.append("❌ OPENAI_API_KEY is required. Get one from https://platform.openai.com/api-keys")
        elif len(self.openai_api_key) < 20:
            errors.append("❌ OPENAI_API_KEY appears invalid (too short)")
        
        # Check database configuration
        if not self.evaluator_db_password and self.evaluator_db_host != "localhost":
            errors.append("❌ EVALUATOR_DB_PASSWORD is required for non-localhost connections")
        
        # Provide helpful setup suggestions
        if errors:
            errors.append("")
            errors.append("💡 Quick setup options:")
            errors.append("   1. Run: python scripts/evaluator/setup_wizard.py")
            errors.append("   2. Copy .env.example to .env and edit")
            errors.append("   3. Set environment variables manually")
        
        return len(errors) == 0, errors

    @property
    def evaluator_database_url(self) -> str:
        """Get evaluator database connection URL"""
        password_part = f":{self.evaluator_db_password}" if self.evaluator_db_password else ""
        return f"postgresql://{self.evaluator_db_user}{password_part}@{self.evaluator_db_host}:{self.evaluator_db_port}/{self.evaluator_db_name}"

    @property
    def evaluator_database_url_async(self) -> str:
        """Get async evaluator database connection URL"""
        password_part = f":{self.evaluator_db_password}" if self.evaluator_db_password else ""
        return f"postgresql+asyncpg://{self.evaluator_db_user}{password_part}@{self.evaluator_db_host}:{self.evaluator_db_port}/{self.evaluator_db_name}"

    @property
    def quests_database_url(self) -> str:
        """Get quests database connection URL"""
        password_part = f":{self.quests_db_password}" if self.quests_db_password else ""
        return f"postgresql://{self.quests_db_user}{password_part}@{self.quests_db_host}:{self.quests_db_port}/{self.quests_db_name}"

    @property
    def quests_database_url_async(self) -> str:
        """Get async quests database connection URL"""
        password_part = f":{self.quests_db_password}" if self.quests_db_password else ""
        return f"postgresql+asyncpg://{self.quests_db_user}{password_part}@{self.quests_db_host}:{self.quests_db_port}/{self.quests_db_name}"

    # Legacy compatibility properties
    @property
    def database_url(self) -> str:
        """Legacy property - returns evaluator database URL"""
        return self.evaluator_database_url

    @property
    def database_url_async(self) -> str:
        """Legacy property - returns evaluator database URL"""
        return self.evaluator_database_url_async


# Quick validation function for scripts
def validate_config_or_exit():
    """Validate configuration and exit with helpful message if invalid"""
    try:
        config = EvaluationConfig()
        is_valid, errors = config.validate_setup()
        
        if not is_valid:
            print("🚫 Configuration Error")
            print("=" * 30)
            for error in errors:
                print(error)
            print("")
            exit(1)
        
        return config
        
    except ValidationError as e:
        print("🚫 Configuration Validation Failed")
        print("=" * 35)
        for error in e.errors():
            field = error.get('loc', ['unknown'])[0]
            message = error.get('msg', 'Unknown error')
            print(f"❌ {field}: {message}")
        print("")
        print("💡 Run: python scripts/evaluator/setup_wizard.py")
        exit(1)

    @field_validator("openai_api_key", mode='before')
    def validate_openai_key(cls, v):
        """Validate OpenAI API key is provided"""
        if not v:
            # Check environment variable directly
            v = os.getenv("OPENAI_API_KEY")
            if not v:
                raise ValueError(
                    "OPENAI_API_KEY is required for AI evaluations. "
                    "Set it as an environment variable or in .env file."
                )
        return v

    @field_validator("db_password", mode='before')
    def validate_db_password(cls, v):
        """Validate database password for production environments"""
        if not v:
            v = os.getenv("DB_PASSWORD")
            if not v and os.getenv("ENVIRONMENT", "development") == "production":
                raise ValueError(
                    "DB_PASSWORD is required for production environment. "
                    "Set it as an environment variable or in .env file."
                )
        return v

    @field_validator("output_dir", mode='before')
    def default_output_dir(cls, v):
        if v is None:
            # default to evaluations_dir from ProjectFolderConfig
            project_cfg = ProjectFolderConfig()
            return project_cfg.evaluations_dir
        path = Path(v).expanduser().resolve()
        path.mkdir(parents=True, exist_ok=True)
        return path
    
    @property
    def database_url(self) -> str:
        """Construct PostgreSQL connection URL"""
        password_part = f":{self.db_password}" if self.db_password else ""
        return f"postgresql://{self.db_user}{password_part}@{self.db_host}:{self.db_port}/{self.postgres_db_name}"
    
    def validate_configuration(self) -> bool:
        """
        Validate complete configuration and provide helpful error messages.
        
        Returns:
            True if configuration is valid
            
        Raises:
            ValidationError: With detailed error message for missing configurations
        """
        errors = []
        
        # Check OpenAI API key
        if not self.openai_api_key:
            errors.append("❌ OPENAI_API_KEY is required for AI evaluations")
            
        # Check database configuration
        if not self.postgres_db_name:
            errors.append("❌ POSTGRES_DB_NAME is required")
            
        if not self.db_host:
            errors.append("❌ DB_HOST is required")
            
        if not self.db_user:
            errors.append("❌ DB_USER is required")
            
        if errors:
            error_msg = "\n".join(errors)
            error_msg += "\n\n💡 Create a .env file with the required variables or set them as environment variables."
            raise ValidationError(error_msg)
            
        return True

    model_config = {"env_file": ".env"}