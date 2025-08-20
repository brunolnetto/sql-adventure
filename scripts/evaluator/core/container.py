"""
Dependency injection container to eliminate circular dependencies.
Provides centralized service registration and resolution.
"""

from typing import Dict, Any, Callable, Optional, TypeVar, Type
from pathlib import Path
import inspect

T = TypeVar('T')


class ServiceContainer:
    """
    Simple dependency injection container to manage service dependencies.
    Eliminates circular imports by providing late binding of services.
    """
    
    def __init__(self):
        self._services: Dict[str, Any] = {}
        self._factories: Dict[str, Callable] = {}
        self._singletons: Dict[str, Any] = {}
    
    def register_singleton(self, name: str, instance: Any) -> None:
        """Register a singleton instance"""
        self._singletons[name] = instance
    
    def register_factory(self, name: str, factory: Callable) -> None:
        """Register a factory function for lazy instantiation"""
        self._factories[name] = factory
    
    def register_service(self, name: str, service_class: Type[T], **kwargs) -> None:
        """Register a service class with optional constructor arguments"""
        self._services[name] = (service_class, kwargs)
    
    def get(self, name: str) -> Any:
        """Resolve a service by name"""
        # Check singletons first
        if name in self._singletons:
            return self._singletons[name]
        
        # Check factories
        if name in self._factories:
            instance = self._factories[name]()
            self._singletons[name] = instance  # Cache as singleton
            return instance
        
        # Check registered services
        if name in self._services:
            service_class, kwargs = self._services[name]
            instance = service_class(**kwargs)
            self._singletons[name] = instance  # Cache as singleton
            return instance
        
        raise ValueError(f"Service '{name}' not registered")
    
    def get_optional(self, name: str) -> Optional[Any]:
        """Get service if available, return None otherwise"""
        try:
            return self.get(name)
        except ValueError:
            return None


# Global container instance
_container = ServiceContainer()


def get_container() -> ServiceContainer:
    """Get the global service container"""
    return _container


def register_core_services():
    """Register core application services"""
    from .agents import intent_agent, sql_instructor_agent, quality_assessor_agent, quest_summary_agent
    from ..utils.discovery import MetadataExtractor, detect_sql_patterns
    
    # Register agents
    _container.register_singleton("intent_agent", intent_agent)
    _container.register_singleton("sql_instructor_agent", sql_instructor_agent)
    _container.register_singleton("quality_assessor_agent", quality_assessor_agent)
    _container.register_singleton("quest_summary_agent", quest_summary_agent)
    
    # Register utility functions
    _container.register_singleton("metadata_extractor", MetadataExtractor)
    _container.register_singleton("pattern_detector", detect_sql_patterns)


# Service accessor functions (eliminates import dependencies)
def get_quest_summary_agent():
    """Get quest summary agent without direct import"""
    return _container.get("quest_summary_agent")


def get_pattern_detector():
    """Get pattern detector without direct import"""
    return _container.get("pattern_detector")


def get_metadata_extractor():
    """Get metadata extractor without direct import"""
    return _container.get("metadata_extractor")


# Decorator for dependency injection
def inject_service(service_name: str):
    """Decorator to inject services into functions"""
    def decorator(func):
        def wrapper(*args, **kwargs):
            service = _container.get(service_name)
            return func(service, *args, **kwargs)
        return wrapper
    return decorator


# Usage example for quest_summary.py:
@inject_service("quest_summary_agent")
async def generate_quest_description_ai(agent, aggregated_content: str) -> str:
    """Generate AI description using injected agent"""
    prompt = f"""
    Analyze this SQL quest content and generate a succinct description:
    
    {aggregated_content}
    
    Generate a 2-3 sentence description that clearly explains what this quest teaches 
    and what practical skills students will develop.
    """
    
    try:
        result = await agent.run(prompt)
        return result.data
    except Exception as e:
        print(f"⚠️  AI summarization failed: {e}")
        return _generate_fallback_description(aggregated_content)


def _generate_fallback_description(content: str) -> str:
    """Generate simple fallback description when AI is unavailable."""
    lines = content.split('\n')
    topics = []
    for line in lines[:10]:
        if any(keyword in line.lower() for keyword in ['modeling', 'performance', 'window', 'json', 'recursive']):
            topics.append(line.strip())
    
    if topics:
        return f"SQL training covering {', '.join(topics[:3])} and related database concepts."
    else:
        return "Comprehensive SQL training covering essential database concepts and practical skills."
