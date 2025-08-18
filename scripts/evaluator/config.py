from pathlib import Path
from typing import Optional
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings


class ProjectFolderConfig(BaseSettings):
    """
    Configuration for persistence of evaluation data.
    Ensures required directories exist on initialization.
    """
    quests_dir: Path = Field(default_factory=lambda: Path("quests"))
    cache_dir: Path = Field(default_factory=lambda: Path(".evaluations-cache"))
    evaluations_dir: Path = Field(default_factory=lambda: Path("ai-evaluations"))

    @field_validator("quests_dir", "cache_dir", "evaluations_dir", pre=True)
    def expand_and_create_dirs(cls, v):
        path = Path(v)
        # expand user and make absolute
        path = path.expanduser().resolve()
        # create directory if it doesn't exist
        path.mkdir(parents=True, exist_ok=True)
        return path

    class Config:
        env_file = ".env"


class EvaluationConfig(BaseSettings):
    """Configuration for evaluation runs"""
    openai_api_key: Optional[str] = Field(None, description="OpenAI API Key")
    model_name: str = Field("gpt-4o-mini", description="OpenAI model to use for evaluations")
    max_concurrent_files: int = Field(3, description="Parallel files per quest")
    cache_enabled: bool = Field(True, description="Enable caching of results")
    skip_unchanged: bool = Field(True, description="Skip files unchanged since last evaluation")
    output_dir: Optional[Path] = Field(None, description="Custom output directory for evaluations")

    @field_validator("output_dir", pre=True, always=True)
    def default_output_dir(cls, v):
        if v is None:
            # default to evaluations_dir from ProjectFolderConfig
            project_cfg = ProjectFolderConfig()
            return project_cfg.evaluations_dir
        path = Path(v).expanduser().resolve()
        path.mkdir(parents=True, exist_ok=True)
        return path

    class Config:
        env_file = ".env"