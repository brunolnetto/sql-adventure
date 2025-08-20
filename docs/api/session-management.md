# Session Management Patterns

This document describes the standardized session management patterns used throughout the SQL Adventure evaluation system.

## Overview

The system follows the **Unit of Work** pattern with **caller-controlled transactions** to ensure data consistency and proper error handling.

## Core Principles

### 1. Repository Responsibility
- Repositories perform database operations without committing
- Use `session.flush()` to get database-generated IDs
- Let callers control transaction boundaries

### 2. Caller Responsibility
- Create and manage session lifecycle
- Commit successful operations
- Rollback failed operations
- Always close sessions in finally blocks

### 3. Error Handling
- Catch exceptions at operation boundaries
- Rollback on any error
- Log errors with context
- Re-raise to allow caller handling

## Implementation Patterns

### Standard Repository Pattern

```python
class BaseRepository(Generic[ModelType]):
    def __init__(self, session: Session, model: Type[ModelType]):
        """
        Repository with caller-managed session.
        
        Args:
            session: SQLAlchemy session (managed by caller)
            model: SQLAlchemy model class
        """
        self.session = session
        self.model = model

    def add(self, obj: ModelType) -> ModelType:
        """
        Add entity without committing.
        
        Note: Caller must commit or rollback the transaction.
        """
        self.session.add(obj)
        self.session.flush()  # Get ID without committing
        return obj
```

### Service Layer Pattern

```python
class EvaluationService:
    async def save_evaluation(self, file_path: Path, result: EvaluationResult):
        """Service method with complete session management."""
        session = self.db_manager.SessionLocal()
        try:
            # Multiple repository operations in same transaction
            sql_file_repo = SQLFileRepository(session)
            eval_repo = EvaluationRepository(session)
            
            # Get or create SQL file
            sql_file = sql_file_repo.get_or_create(str(file_path))
            
            # Save evaluation data
            evaluation = eval_repo.add_from_data(sql_file.id, result.model_dump())
            
            # Commit entire transaction
            session.commit()
            return evaluation
            
        except Exception as e:
            session.rollback()
            print(f"❌ Error saving evaluation: {e}")
            raise
        finally:
            session.close()
```

### Multiple Repository Operations

```python
def complex_operation():
    """Example of coordinating multiple repositories."""
    session = db_manager.SessionLocal()
    try:
        # Use multiple repositories with same session
        quest_repo = QuestRepository(session)
        sql_file_repo = SQLFileRepository(session)
        eval_repo = EvaluationRepository(session)
        
        # Perform related operations
        quest = quest_repo.get_by_name("data-modeling")
        sql_files = sql_file_repo.list(quest_id=quest.id)
        
        for sql_file in sql_files:
            # Process each file
            evaluation_data = process_file(sql_file)
            eval_repo.add_from_data(sql_file.id, evaluation_data)
        
        # Commit all changes together
        session.commit()
        
    except Exception as e:
        session.rollback()
        logger.error(f"Complex operation failed: {e}")
        raise
    finally:
        session.close()
```

## Error Patterns

### Repository Error Handling

```python
def add_from_data(self, sql_file_id: int, data: dict) -> Evaluation:
    """Repository method with proper error handling."""
    try:
        # Validate input
        if not sql_file_id:
            raise ValueError("SQL file ID is required")
            
        # Perform database operations
        sql_file = self.session.query(SQLFile).get(sql_file_id)
        if not sql_file:
            raise ValueError(f"SQL file {sql_file_id} not found")
            
        evaluation = Evaluation(sql_file_id=sql_file_id, **data)
        self.session.add(evaluation)
        self.session.flush()  # Get ID without committing
        
        return evaluation
        
    except Exception as e:
        # Log error but don't rollback - let caller handle
        logger.error(f"Error in add_from_data: {e}")
        raise
```

### Service Error Handling

```python
async def evaluate_quest(self, quest_path: Path):
    """Service method with comprehensive error handling."""
    session = self.db_manager.SessionLocal()
    results = []
    
    try:
        sql_files = discover_sql_files(quest_path)
        
        for sql_file_path in sql_files:
            try:
                # Process individual file
                result = await self.evaluate_file(sql_file_path)
                
                # Save to database within main transaction
                eval_repo = EvaluationRepository(session)
                evaluation = eval_repo.add_from_data(result.sql_file_id, result.data)
                results.append(evaluation)
                
            except Exception as file_error:
                # Log but continue with other files
                logger.warning(f"Failed to evaluate {sql_file_path}: {file_error}")
                continue
        
        # Commit all successful evaluations
        session.commit()
        return results
        
    except Exception as e:
        session.rollback()
        logger.error(f"Quest evaluation failed: {e}")
        raise
    finally:
        session.close()
```

## Anti-Patterns to Avoid

### ❌ Repository Auto-Commit
```python
# DON'T: Repository commits automatically
def add(self, obj):
    self.session.add(obj)
    self.session.commit()  # ❌ Repository shouldn't commit
    return obj
```

### ❌ Missing Rollback
```python
# DON'T: No rollback on error
try:
    session.add(obj)
    session.commit()
except Exception as e:
    # ❌ Missing rollback
    pass
finally:
    session.close()
```

### ❌ Session Reuse
```python
# DON'T: Reuse sessions across operations
class BadService:
    def __init__(self):
        self.session = SessionLocal()  # ❌ Long-lived session
        
    def operation1(self):
        # Uses self.session
        pass
        
    def operation2(self):
        # Uses same session - error prone
        pass
```

## Best Practices

### 1. Session Scope
- Create sessions at operation boundaries
- Use sessions for single logical operations
- Close sessions promptly

### 2. Transaction Boundaries
- Group related operations in transactions
- Keep transactions as short as possible
- Commit only after all operations succeed

### 3. Error Recovery
- Always rollback on errors
- Log errors with sufficient context
- Allow callers to handle or re-raise

### 4. Resource Management
- Use try/finally blocks for cleanup
- Close sessions even on errors
- Consider using context managers

### Context Manager Example

```python
from contextlib import contextmanager

@contextmanager
def database_session():
    """Context manager for safe session handling."""
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

# Usage
def service_operation():
    with database_session() as session:
        repo = EvaluationRepository(session)
        return repo.add_from_data(file_id, data)
```

## Testing Patterns

### Repository Testing
```python
def test_repository_operation():
    """Test repository without committing."""
    session = create_test_session()
    try:
        repo = EvaluationRepository(session)
        
        # Test operation
        result = repo.add_from_data(1, {"score": 8})
        
        # Verify in session (not committed)
        assert session.query(Evaluation).filter_by(id=result.id).first()
        
    finally:
        session.rollback()  # Don't commit test data
        session.close()
```

### Service Testing
```python
@pytest.fixture
def mock_session():
    """Mock session for service testing."""
    session = Mock(spec=Session)
    session.commit = Mock()
    session.rollback = Mock()
    session.close = Mock()
    return session

def test_service_error_handling(mock_session):
    """Test service error handling."""
    service = EvaluationService()
    service.db_manager.SessionLocal = Mock(return_value=mock_session)
    
    # Setup error condition
    mock_session.query.side_effect = Exception("Database error")
    
    with pytest.raises(Exception):
        service.save_evaluation(Path("test.sql"), mock_result)
    
    # Verify rollback was called
    mock_session.rollback.assert_called_once()
    mock_session.close.assert_called_once()
```

## See Also

- [Repository API Documentation](repositories.md)
- [Database Schema Documentation](database-schema.md)
- [Error Handling Patterns](error-handling.md)
