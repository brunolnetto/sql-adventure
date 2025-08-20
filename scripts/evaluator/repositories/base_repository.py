from sqlalchemy.orm import Session
from typing import TypeVar, Generic, Type, List, Optional
from sqlalchemy.ext.declarative import declarative_base

class BaseModel:
    pass

Base = declarative_base(cls=BaseModel)

ModelType = TypeVar("ModelType", bound=BaseModel)

class BaseRepository(Generic[ModelType]):
    def __init__(self, session: Session, model: Type[ModelType]):
        """
        Base repository class for common CRUD operations.
        
        This repository follows the Unit of Work pattern:
        - Operations are staged in the session without automatic commits
        - Callers are responsible for committing or rolling back transactions
        - Use flush() to get database-generated IDs without committing
        
        Args:
            session: SQLAlchemy session object (managed by caller)
            model: SQLAlchemy model class to operate on
        """
        self.session = session
        self.model = model

    def get(self, id: int) -> Optional[ModelType]:
        """
        Retrieve a single entity by ID.
        
        Args:
            id: Primary key of the entity
            
        Returns:
            Entity instance or None if not found
        """
        return self.session.get(self.model, id)

    def list(self, **filters) -> List[ModelType]:
        """
        List entities with optional filters.
        
        Args:
            **filters: Column filters to apply
            
        Returns:
            List of entities matching the filters
        """
        return self.session.query(self.model).filter_by(**filters).all()

    def add(self, obj: ModelType) -> ModelType:
        """
        Add a new entity to the session.
        
        Note: This method does not commit the session. The caller is responsible
        for committing or rolling back the transaction.
        
        Args:
            obj: Entity instance to add
            
        Returns:
            The added entity (with ID populated after flush)
        """
        self.session.add(obj)
        self.session.flush()  # Get database-generated ID without committing
        return obj

    def remove(self, obj: ModelType) -> None:
        """
        Remove an entity from the session.
        
        Note: This method does not commit the session. The caller is responsible
        for committing or rolling back the transaction.
        
        Args:
            obj: Entity instance to remove
        """
        self.session.delete(obj)
        self.session.flush()  # Stage deletion without committing
