from pydantic import BaseModel, Field, conint, confloat, field_validator
from typing import List, Optional, Dict, Any, Literal, Annotated

from datetime import datetime


class SQLPattern(BaseModel):
    """
    Represents a detected SQL pattern with metadata.
    """
    pattern_name: str = Field(..., description="Name of the SQL pattern detected")
    confidence: Annotated[float, Field(ge=0, le=1)] = Field(..., description="Confidence score between 0 and 1")
    description: str = Field(..., description="Brief description of the pattern")

class Intent(BaseModel):
    """
    Represents the intent of the SQL code.
    """
    detailed_purpose: str = Field(..., description="Detailed learning objective")
    educational_context: str = Field(..., description="Context in which this SQL is used")
    real_world_applicability: str = Field(..., description="Real-world relevance of the code")
    specific_skills: List[str] = Field(default_factory=list, description="Skills that learners will develop")


class SimplifiedAnalysis(BaseModel):
    """
    Simplified analysis combining technical and educational aspects.
    """
    overall_feedback: str = Field(..., description="Combined technical and educational feedback")
    difficulty_level: Literal["Beginner", "Intermediate", "Advanced", "Expert"] = Field(
        ..., description="Difficulty level")
    time_estimate: str = Field(..., description="Estimated completion time (e.g., '5 min', '10-15 min')")
    technical_score: int = Field(..., ge=1, le=10, description="Technical quality score (1-10)")
    educational_score: int = Field(..., ge=1, le=10, description="Educational value score (1-10)")
    detected_patterns: List[str] = Field(default_factory=list, description="List of detected SQL pattern names")
    
    @field_validator('difficulty_level', mode='before')
    def clean_difficulty_level(cls, v):
        """Extract clean difficulty level from potentially decorated text"""
        if isinstance(v, str):
            # Remove emojis and extract the difficulty level
            import re
            # Look for known difficulty levels in the text
            for level in ["Beginner", "Intermediate", "Advanced", "Expert"]:
                if level.lower() in v.lower():
                    return level
            # If no match found, try to extract first word that looks like a level
            words = re.findall(r'\b[A-Za-z]+\b', v)
            for word in words:
                if word.lower() in ["beginner", "intermediate", "advanced", "expert"]:
                    return word.capitalize()
        return v  # Return as-is if we can't clean it


class Assessment(BaseModel):
    """
    Assessment of the SQL code quality and educational value.
    """
    grade: Literal["A", "B", "C", "D", "E", "F"] = Field(..., description="Letter grade")
    score: Annotated[int, Field(ge=1, le=10)] = Field(..., description="Numeric score from 1 to 10")
    overall_assessment: Literal["PASS", "FAIL", "NEEDS_REVIEW"] = Field(..., description="Final assessment verdict")
    
    @field_validator('grade', mode='before')
    def clean_grade(cls, v):
        """Extract clean grade from potentially decorated text"""
        if isinstance(v, str):
            import re
            # Look for letter grades A-F
            for grade in ["A", "B", "C", "D", "E", "F"]:
                if grade in v.upper():
                    return grade
            # Try to extract first letter that looks like a grade
            letters = re.findall(r'\b[A-F]\b', v.upper())
            if letters:
                return letters[0]
        return v
    
    @field_validator('overall_assessment', mode='before')
    def clean_overall_assessment(cls, v):
        """Extract clean assessment from potentially decorated text"""
        if isinstance(v, str):
            v_upper = v.upper()
            for assessment in ["PASS", "FAIL", "NEEDS_REVIEW"]:
                if assessment in v_upper:
                    return assessment
        return v


class Recommendation(BaseModel):
    """
    Improvement suggestions for the SQL code.
    """
    priority: Literal["High", "Medium", "Low"] = Field(..., description="Recommendation priority")
    implementation_effort: Literal["High", "Medium", "Low"] = Field(..., description="Estimated effort to implement")
    recommendation_text: str = Field(..., description="Description of the improvement suggestion")


class LLMAnalysis(BaseModel):
    """
    AI-powered analysis of the SQL code - simplified structure.
    """
    analysis: SimplifiedAnalysis
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

