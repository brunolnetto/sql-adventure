# Configuration Management

This document describes the configuration system for the SQL Adventure evaluation platform, including environment validation, error handling, and deployment patterns.

## Overview

The configuration system uses Pydantic Settings for type-safe environment variable management with validation and helpful error messages.

## Configuration Classes

### EvaluationConfig

Main configuration class for evaluation runs and system settings.

```python
from config import EvaluationConfig

# Basic initialization
config = EvaluationConfig()

# Validate configuration
try:
    config.validate_configuration()
    print("✅ Configuration valid")
except ValidationError as e:
    print(f"❌ Configuration error: {e}")
```

#### Required Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `OPENAI_API_KEY` | OpenAI API key for AI evaluations | Yes | None |
| `POSTGRES_DB_NAME` | PostgreSQL database name | No | `sql_adventure` |
| `DB_HOST` | Database host | No | `localhost` |
| `DB_USER` | Database user | No | `postgres` |
| `DB_PASSWORD` | Database password | Production only | None |
| `DB_PORT` | Database port | No | `5432` |

#### Optional Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `MODEL_NAME` | OpenAI model for evaluations | `gpt-4o-mini` |
| `MAX_CONCURRENT_FILES` | Parallel files per quest | `3` |
| `CACHE_ENABLED` | Enable result caching | `True` |
| `SKIP_UNCHANGED` | Skip unchanged files | `True` |
| `ENVIRONMENT` | Deployment environment | `development` |

### ProjectFolderConfig

Configuration for file system paths and directories.

```python
from config import ProjectFolderConfig

# Initialize with defaults
folders = ProjectFolderConfig()

print(f"Quests directory: {folders.quests_dir}")
print(f"Cache directory: {folders.cache_dir}")
print(f"Evaluations directory: {folders.evaluations_dir}")
```

#### Default Paths

| Setting | Default | Description |
|---------|---------|-------------|
| `quests_dir` | `quests/` | SQL exercise files |
| `cache_dir` | `.evaluations-cache/` | Cached evaluation results |
| `evaluations_dir` | `ai-evaluations/` | Output evaluation reports |

## Environment Setup

### Development Environment

Create a `.env` file in the project root:

```bash
# .env file for development
OPENAI_API_KEY=your-openai-api-key-here
POSTGRES_DB_NAME=sql_adventure_dev
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=your-dev-password
ENVIRONMENT=development

# Optional overrides
MODEL_NAME=gpt-4o-mini
MAX_CONCURRENT_FILES=2
CACHE_ENABLED=true
```

### Production Environment

Set environment variables through your deployment system:

```bash
# Production environment variables
export OPENAI_API_KEY="sk-..."
export POSTGRES_DB_NAME="sql_adventure"
export DB_HOST="db.production.com"
export DB_USER="sql_adventure_user"
export DB_PASSWORD="secure-production-password"
export ENVIRONMENT="production"
export MODEL_NAME="gpt-4o"
export MAX_CONCURRENT_FILES="5"
```

### Docker Environment

Use Docker Compose with environment files:

```yaml
# docker-compose.yml
version: '3.8'
services:
  evaluator:
    build: .
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - POSTGRES_DB_NAME=sql_adventure
      - DB_HOST=postgres
      - DB_USER=postgres
      - DB_PASSWORD=${DB_PASSWORD}
    env_file:
      - .env.production
```

## Configuration Validation

### Automatic Validation

Configuration is automatically validated when instances are created:

```python
try:
    config = EvaluationConfig()
    # Configuration is valid
except ValidationError as e:
    # Handle validation errors
    print(f"Configuration error: {e}")
```

### Manual Validation

Explicitly validate configuration with helpful error messages:

```python
from config import EvaluationConfig
from pydantic import ValidationError

def validate_environment():
    """Validate environment configuration with user-friendly messages."""
    try:
        config = EvaluationConfig()
        config.validate_configuration()
        
        print("✅ Configuration validation successful")
        print(f"   Database: {config.database_url}")
        print(f"   Model: {config.model_name}")
        print(f"   Output: {config.output_dir}")
        
        return config
        
    except ValidationError as e:
        print("❌ Configuration validation failed:")
        print(e)
        print("\n💡 Setup instructions:")
        print("   1. Copy env.example to .env")
        print("   2. Set your OPENAI_API_KEY")
        print("   3. Configure database credentials")
        raise

# Usage in application startup
if __name__ == "__main__":
    config = validate_environment()
    # Continue with application
```

### Environment-Specific Validation

Different validation rules for different environments:

```python
import os
from config import EvaluationConfig

def get_validated_config():
    """Get configuration with environment-specific validation."""
    env = os.getenv("ENVIRONMENT", "development")
    
    if env == "production":
        # Strict validation for production
        config = EvaluationConfig()
        
        # Additional production checks
        if not config.db_password:
            raise ValueError("DB_PASSWORD required in production")
            
        if config.model_name.endswith("-mini"):
            print("⚠️  Using mini model in production")
            
    else:
        # Relaxed validation for development
        config = EvaluationConfig()
        
        # Provide defaults for missing dev settings
        if not config.db_password:
            print("💡 Using default development database")
    
    return config
```

## Database Configuration

### Connection URL Generation

The configuration automatically generates PostgreSQL connection URLs:

```python
config = EvaluationConfig()

# Basic URL without password
# postgresql://postgres@localhost:5432/sql_adventure

# URL with password
# postgresql://postgres:password@localhost:5432/sql_adventure

print(f"Database URL: {config.database_url}")
```

### Connection Pool Settings

Configure connection pooling for production:

```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

config = EvaluationConfig()

# Production engine with connection pooling
engine = create_engine(
    config.database_url,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    echo=False  # Set to True for SQL debugging
)
```

## Error Handling Patterns

### Configuration Errors

Handle configuration errors gracefully:

```python
def safe_config_load():
    """Load configuration with fallback handling."""
    try:
        return EvaluationConfig()
    except ValidationError as e:
        if "OPENAI_API_KEY" in str(e):
            print("❌ OpenAI API key missing")
            print("   Get your key from: https://platform.openai.com/api-keys")
            print("   Set it with: export OPENAI_API_KEY='your-key'")
        elif "DB_PASSWORD" in str(e):
            print("❌ Database password required")
            print("   Set it with: export DB_PASSWORD='your-password'")
        else:
            print(f"❌ Configuration error: {e}")
        
        # Exit gracefully
        sys.exit(1)
```

### Runtime Configuration Changes

Handle configuration changes during runtime:

```python
class ConfigurableEvaluator:
    def __init__(self):
        self.config = EvaluationConfig()
        
    def reload_config(self):
        """Reload configuration from environment."""
        try:
            new_config = EvaluationConfig()
            new_config.validate_configuration()
            
            # Update configuration
            old_model = self.config.model_name
            self.config = new_config
            
            if old_model != new_config.model_name:
                print(f"🔄 Model changed: {old_model} → {new_config.model_name}")
                
        except ValidationError as e:
            print(f"⚠️  Configuration reload failed: {e}")
            # Keep existing configuration
```

## Testing Configuration

### Test Configuration

Use separate configuration for tests:

```python
# conftest.py
import pytest
from config import EvaluationConfig

@pytest.fixture
def test_config():
    """Test configuration with safe defaults."""
    return EvaluationConfig(
        openai_api_key="test-key",
        postgres_db_name="test_database",
        db_host="localhost",
        db_user="test_user",
        db_password="test_password",
        model_name="gpt-3.5-turbo",
        max_concurrent_files=1,
        cache_enabled=False
    )
```

### Mock Configuration

Mock configuration for unit tests:

```python
from unittest.mock import patch
import pytest

def test_evaluator_with_mock_config():
    """Test with mocked configuration."""
    with patch('config.EvaluationConfig') as mock_config:
        mock_config.return_value.model_name = "test-model"
        mock_config.return_value.openai_api_key = "test-key"
        
        evaluator = SQLEvaluator()
        assert evaluator.config.model_name == "test-model"
```

## Configuration Migration

### Version Compatibility

Handle configuration changes across versions:

```python
def migrate_config_v1_to_v2():
    """Migrate old configuration format."""
    old_db_url = os.getenv("DATABASE_URL")
    if old_db_url and not os.getenv("POSTGRES_DB_NAME"):
        # Parse old format and set new variables
        parsed = urlparse(old_db_url)
        os.environ["DB_HOST"] = parsed.hostname
        os.environ["DB_USER"] = parsed.username
        os.environ["DB_PASSWORD"] = parsed.password
        os.environ["POSTGRES_DB_NAME"] = parsed.path.lstrip("/")
        
        print("🔄 Migrated DATABASE_URL to new format")
```

### Configuration Backup

Backup working configurations:

```python
import json
from datetime import datetime

def backup_config():
    """Backup current configuration."""
    config = EvaluationConfig()
    
    backup_data = {
        "timestamp": datetime.now().isoformat(),
        "model_name": config.model_name,
        "database_url": config.database_url,
        "output_dir": str(config.output_dir)
    }
    
    backup_file = f"config-backup-{datetime.now().strftime('%Y%m%d')}.json"
    with open(backup_file, 'w') as f:
        json.dump(backup_data, f, indent=2)
    
    print(f"✅ Configuration backed up to {backup_file}")
```

## Best Practices

### 1. Environment Isolation
- Use separate `.env` files for different environments
- Never commit `.env` files to version control
- Use `.env.example` as a template

### 2. Validation Early
- Validate configuration at application startup
- Provide clear error messages for missing settings
- Use type hints and Pydantic validation

### 3. Secure Defaults
- Require sensitive values in production
- Use secure defaults for development
- Log configuration errors without exposing secrets

### 4. Documentation
- Document all environment variables
- Provide setup instructions
- Include example configurations

## See Also

- [Deployment Guide](deployment.md)
- [Error Handling Patterns](error-handling.md)
- [Database Schema Documentation](database-schema.md)
