from sqlalchemy.orm import Session
from typing import TypeVar, Generic, Type
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

ModelType = TypeVar("ModelType", bound=Base)

class BaseRepository(Generic[ModelType]):
    def __init__(self, session: Session, model: Type[ModelType]):
        """
        Base repository class for common CRUD operations.
        :param session: SQLAlchemy session object
        :param model: SQLAlchemy model class to operate on
        """
        self.session = session
        self.model = model

    def get(self, id: int) -> ModelType | None:
        return self.session.get(self.model, id)  # modern API (SQLAlchemy 1.4+)

    def list(self, **filters) -> list[ModelType]:
        return self.session.query(self.model).filter_by(**filters).all()

    def add(self, obj: ModelType) -> ModelType:
        self.session.add(obj)
        self.session.flush()
        return obj

    def remove(self, obj: ModelType) -> None:
        self.session.delete(obj)
        self.session.flush()
