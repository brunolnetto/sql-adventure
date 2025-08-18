from pydantic import BaseModel, Field, conint, confloat
from typing import List, Optional, Dict, Any, Literal

from datetime import datetime


class SQLPattern(BaseModel):
    """
    Represents a detected SQL pattern with metadata.
    """
    pattern_name: str = Field(..., description="Name of the SQL pattern detected")
    confidence: float = Field(..., ge=0, le=1, description="Confidence score between 0 and 1")
    description: str = Field(..., description="Brief description of the pattern")

class Intent(BaseModel):
    """
    Represents the intent of the SQL code.
    """
    detailed_purpose: str = Field(..., description="Detailed learning objective")
    educational_context: str = Field(..., description="Context in which this SQL is used")
    real_world_applicability: str = Field(..., description="Real-world relevance of the code")
    specific_skills: List[str] = Field(default_factory=list, description="Skills that learners will develop")


class TechnicalAnalysis(BaseModel):
    """
    Technical analysis of the SQL code.
    """
    syntax_correctness: str = Field(..., description="Assessment of SQL syntax")
    logical_structure: str = Field(..., description="Assessment of logical structure")
    code_quality: str = Field(..., description="Overall code quality assessment")
    performance_notes: Optional[str] = Field(None, description="Performance considerations")


class EducationalAnalysis(BaseModel):
    """
    Educational analysis of the SQL code.
    """
    learning_value: str = Field(..., description="Educational value assessment")
    difficulty_level: Literal["Beginner", "Intermediate", "Advanced", "Expert"] = Field(
        ..., description="Difficulty level")
    time_estimate: str = Field(..., description="Estimated completion time (e.g., '5 min', '10-15 min')")
    prerequisites: List[str] = Field(default_factory=list, description="Required knowledge or skills")


class Assessment(BaseModel):
    """
    Assessment of the SQL code quality and educational value.
    """
    grade: Literal["A", "B", "C", "D", "E", "F"] = Field(..., description="Letter grade")
    score: float = Field(..., ge=0, le=1, description="Numeric score from 1 to 10")
    overall_assessment: Literal["PASS", "FAIL", "NEEDS_REVIEW"] = Field(..., description="Final assessment verdict")


class Recommendation(BaseModel):
    """
    Improvement suggestions for the SQL code.
    """
    priority: Literal["High", "Medium", "Low"] = Field(..., description="Recommendation priority")
    implementation_effort: Literal["High", "Medium", "Low"] = Field(..., description="Estimated effort to implement")
    recommendation_text: str = Field(..., description="Description of the improvement suggestion")


class LLMAnalysis(BaseModel):
    """
    AI-powered analysis of the SQL code.
    """
    technical_analysis: TechnicalAnalysis
    educational_analysis: EducationalAnalysis
    assessment: Assessment
    recommendations: List[Recommendation] = Field(default_factory=list, description="Improvement suggestions")

class ExecutionResult(BaseModel):
    success: bool
    output_content: str
    output_lines: int
    result_sets: int
    errors: int
    warnings: int
    statement_details: Optional[List[Dict[str, Any]]] = None

class EvaluationResult(BaseModel):
    """
    Represents the result of evaluating a SQL code file.
    """
    metadata: Dict[str, Any] = Field(..., description="File metadata such as filename or author")
    execution: ExecutionResult = Field(..., description="Execution results (e.g., output, error, runtime)")
    intent: Intent = Field(..., description="Intent analysis of the SQL code")
    llm_analysis: LLMAnalysis = Field(..., description="AI-powered technical and educational analysis")
    evaluated_at: datetime = Field(default_factory=datetime.now)

