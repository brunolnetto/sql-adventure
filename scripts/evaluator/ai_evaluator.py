#!/usr/bin/env python3
"""
SQL Adventure AI Evaluator using Pydantic-AI Agents
Replaces the bash script approach with structured, type-safe evaluation
"""

import os
import json
import asyncio
from pathlib import Path
from typing import List, Optional, Dict, Any
from datetime import datetime

from pydantic import BaseModel, Field
from pydantic_ai import Agent, AgentConfig
from pydantic_ai.providers.openai import OpenAIProvider

from .database import DatabaseManager

# Pydantic Models for Structured Output
class SQLPattern(BaseModel):
    pattern_name: str = Field(description="Name of the SQL pattern detected")
    confidence: float = Field(description="Confidence score 0-1", ge=0, le=1)
    description: str = Field(description="Brief description of the pattern")

class TechnicalAnalysis(BaseModel):
    syntax_correctness: str = Field(description="Assessment of SQL syntax")
    logical_structure: str = Field(description="Assessment of logical structure")
    code_quality: str = Field(description="Overall code quality assessment")
    performance_notes: Optional[str] = Field(description="Performance considerations")

class EducationalAnalysis(BaseModel):
    learning_value: str = Field(description="Educational value assessment")
    difficulty_level: str = Field(description="Beginner/Intermediate/Advanced/Expert")
    time_estimate: str = Field(description="Estimated completion time")
    prerequisites: List[str] = Field(description="Required knowledge")

class Assessment(BaseModel):
    grade: str = Field(description="Letter grade A-F")
    score: int = Field(description="Numeric score 1-10", ge=1, le=10)
    overall_assessment: str = Field(description="PASS/FAIL/NEEDS_REVIEW")

class LLMAnalysis(BaseModel):
    technical_analysis: TechnicalAnalysis
    educational_analysis: EducationalAnalysis
    assessment: Assessment
    recommendations: List[str] = Field(description="Improvement suggestions")

class EnhancedIntent(BaseModel):
    detailed_purpose: str = Field(description="Detailed learning objective")
    educational_context: str = Field(description="Educational context")
    real_world_applicability: str = Field(description="Real-world applications")
    specific_skills: List[str] = Field(description="Skills learners will develop")

class EvaluationResult(BaseModel):
    metadata: Dict[str, Any] = Field(description="File metadata")
    intent: Dict[str, Any] = Field(description="Basic intent analysis")
    execution: Dict[str, Any] = Field(description="Execution results")
    basic_evaluation: Dict[str, Any] = Field(description="Basic evaluation")
    basic_analysis: Dict[str, Any] = Field(description="Basic analysis")
    llm_analysis: LLMAnalysis = Field(description="AI-powered analysis")
    enhanced_intent: EnhancedIntent = Field(description="Enhanced intent analysis")

class SQLEvaluator:
    """AI-powered SQL evaluation system using Pydantic-AI agents"""
    
    def __init__(self, api_key: str, db_manager: Optional[DatabaseManager] = None):
        self.provider = OpenAIProvider(api_key=api_key)
        self.config = AgentConfig(
            provider=self.provider,
            model="gpt-4o-mini",
            temperature=0.2
        )
        
        # Create specialized agents
        self.llm_agent = Agent(
            config=self.config,
            system_prompt="You are an expert SQL instructor and educational content analyst."
        )
        
        self.intent_agent = Agent(
            config=self.config,
            system_prompt="You are an expert in educational content analysis and curriculum design."
        )
        
        # Database manager
        self.db_manager = db_manager or DatabaseManager()
    
    async def analyze_sql_intent(self, sql_content: str, quest_name: str, 
                                basic_purpose: str, basic_concepts: str, 
                                basic_difficulty: str) -> EnhancedIntent:
        """Analyze educational intent using AI agent"""
        
        prompt = f"""
        Analyze this SQL exercise for educational intent:
        
        Quest: {quest_name}
        Basic Purpose: {basic_purpose}
        Basic Concepts: {basic_concepts}
        Basic Difficulty: {basic_difficulty}
        
        SQL Code:
        {sql_content}
        
        Provide a comprehensive analysis of the educational intent, including:
        - Detailed learning objectives
        - Educational context
        - Real-world applicability
        - Specific skills learners will develop
        """
        
        result = await self.intent_agent.run(prompt, response_model=EnhancedIntent)
        return result
    
    async def analyze_sql_output(self, sql_content: str, quest_name: str,
                                purpose: str, difficulty: str, concepts: str,
                                output_content: str, sql_patterns: List[str]) -> LLMAnalysis:
        """Analyze SQL execution output using AI agent"""
        
        prompt = f"""
        Analyze this SQL exercise and its execution output:
        
        Quest: {quest_name}
        Purpose: {purpose}
        Difficulty: {difficulty}
        Concepts: {concepts}
        SQL Patterns: {', '.join(sql_patterns)}
        
        SQL Code:
        {sql_content}
        
        Execution Output:
        {output_content}
        
        Provide a comprehensive analysis including:
        - Technical analysis (syntax, logic, quality, performance)
        - Educational analysis (learning value, difficulty, time estimate)
        - Assessment (grade, score, overall assessment)
        - Recommendations for improvement
        """
        
        result = await self.llm_agent.run(prompt, response_model=LLMAnalysis)
        return result
    
    def detect_sql_patterns(self, sql_content: str) -> List[SQLPattern]:
        """Detect SQL patterns in the code"""
        # This could be enhanced with more sophisticated pattern detection
        patterns = []
        
        pattern_definitions = {
            "table_creation": "CREATE TABLE",
            "data_insertion": "INSERT INTO",
            "data_querying": "SELECT",
            "filtering": "WHERE",
            "joining": "JOIN",
            "aggregation": "GROUP BY",
            "window_functions": "OVER\\(",
            "json_operations": "JSON_",
            "recursive_cte": "WITH.*RECURSIVE"
        }
        
        for pattern_name, pattern_regex in pattern_definitions.items():
            if pattern_regex.lower() in sql_content.lower():
                patterns.append(SQLPattern(
                    pattern_name=pattern_name,
                    confidence=0.8,
                    description=f"Detected {pattern_name} pattern"
                ))
        
        return patterns
    
    async def evaluate_sql_file(self, file_path: Path) -> EvaluationResult:
        """Evaluate a single SQL file"""
        
        # Read SQL content
        sql_content = file_path.read_text()
        
        # Extract metadata
        quest_name = file_path.parts[-3]  # quests/1-data-modeling/00-basic-concepts/file.sql
        filename = file_path.name
        
        # Extract basic intent from file path and content
        basic_purpose = self._extract_purpose_from_path(file_path)
        basic_concepts = self._extract_concepts_from_content(sql_content)
        basic_difficulty = self._extract_difficulty_from_path(file_path)
        
        # Detect patterns
        patterns = self.detect_sql_patterns(sql_content)
        pattern_names = [p.pattern_name for p in patterns]
        
        # Execute SQL and capture output using database manager
        execution_results = await self.db_manager.execute_sql_file(str(file_path))
        execution_output = execution_results.get('raw_output', '')
        
        # AI-powered analysis
        enhanced_intent = await self.analyze_sql_intent(
            sql_content, quest_name, basic_purpose, basic_concepts, basic_difficulty
        )
        
        llm_analysis = await self.analyze_sql_output(
            sql_content, quest_name, basic_purpose, basic_difficulty, 
            basic_concepts, execution_output, pattern_names
        )
        
        # Build result
        result = EvaluationResult(
            metadata={
                "generated": datetime.now().isoformat(),
                "file": filename,
                "quest": quest_name,
                "full_path": str(file_path)
            },
            intent={
                "purpose": basic_purpose,
                "difficulty": basic_difficulty,
                "concepts": basic_concepts,
                "sql_patterns": pattern_names
            },
            execution={
                "success": execution_results.get('success', False),
                "output_lines": execution_results.get('output_lines', 0),
                "errors": execution_results.get('errors', 0),
                "warnings": execution_results.get('warnings', 0),
                "result_sets": execution_results.get('result_sets', 0),
                "raw_output": execution_output
            },
            basic_evaluation={
                "overall_assessment": "PASS" if execution_results.get('success', False) else "FAIL",
                "score": 8 if execution_results.get('success', False) else 4,
                "pattern_analysis": f"Detected {len(patterns)} SQL patterns"
            },
            basic_analysis={
                "correctness": "Output appears to execute successfully" if execution_results.get('success', False) else "Execution failed",
                "completeness": f"Generated {execution_results.get('output_lines', 0)} lines of output",
                "learning_value": "Demonstrates intended SQL patterns"
            },
            llm_analysis=llm_analysis,
            enhanced_intent=enhanced_intent
        )
        
        return result
    
    async def save_evaluation_to_db(self, result: EvaluationResult) -> bool:
        """Save evaluation result to database"""
        if not self.db_manager:
            return False
        
        try:
            # Convert Pydantic model to dict
            evaluation_data = result.model_dump()
            return self.db_manager.save_evaluation(evaluation_data)
        except Exception as e:
            print(f"❌ Error saving evaluation to database: {e}")
            return False
    
    def get_evaluation_history(self, quest_name: Optional[str] = None, limit: int = 10) -> List[Dict[str, Any]]:
        """Get evaluation history from database"""
        if not self.db_manager:
            return []
        return self.db_manager.get_evaluation_history(quest_name, limit)
    
    def get_evaluation_stats(self) -> Dict[str, Any]:
        """Get evaluation statistics from database"""
        if not self.db_manager:
            return {}
        return self.db_manager.get_evaluation_stats()
    
    def _extract_purpose_from_path(self, file_path: Path) -> str:
        """Extract purpose from file path structure"""
        path_parts = file_path.parts
        
        # Map quest names to purposes
        quest_purposes = {
            "1-data-modeling": "Database design and schema creation",
            "2-performance-tuning": "Query optimization and performance",
            "3-window-functions": "Advanced analytics and window functions",
            "4-json-operations": "Modern PostgreSQL JSON features",
            "5-recursive-cte": "Hierarchical data and recursive queries"
        }
        
        quest_name = path_parts[-3] if len(path_parts) >= 3 else "unknown"
        return quest_purposes.get(quest_name, "Demonstrate SQL concepts")
    
    def _extract_concepts_from_content(self, sql_content: str) -> str:
        """Extract concepts from SQL content"""
        concepts = []
        
        if "CREATE TABLE" in sql_content.upper():
            concepts.append("table creation")
        if "SELECT" in sql_content.upper():
            concepts.append("data querying")
        if "JOIN" in sql_content.upper():
            concepts.append("table joining")
        if "GROUP BY" in sql_content.upper():
            concepts.append("aggregation")
        if "OVER(" in sql_content.upper():
            concepts.append("window functions")
        if "JSON_" in sql_content.upper():
            concepts.append("JSON operations")
        if "WITH" in sql_content.upper() and "RECURSIVE" in sql_content.upper():
            concepts.append("recursive CTEs")
        
        return ", ".join(concepts) if concepts else "SQL fundamentals"
    
    def _extract_difficulty_from_path(self, file_path: Path) -> str:
        """Extract difficulty from file path structure"""
        path_parts = file_path.parts
        
        # Map subdirectories to difficulty levels
        difficulty_map = {
            "00-basic-concepts": "Beginner",
            "01-normalization-patterns": "Intermediate", 
            "02-advanced-patterns": "Advanced",
            "03-schema-design-principles": "Intermediate",
            "04-performance-basics": "Intermediate",
            "05-advanced-optimization": "Expert"
        }
        
        subdir = path_parts[-2] if len(path_parts) >= 2 else "unknown"
        return difficulty_map.get(subdir, "Beginner")
    
    # Removed _execute_sql_file method as it's now handled by DatabaseManager

async def main():
    """Main evaluation function"""
    
    # Load API key
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("❌ OPENAI_API_KEY not found in environment")
        return
    
    # Initialize evaluator with database manager
    evaluator = SQLEvaluator(api_key)
    
    # Find SQL files
    sql_files = list(Path("quests").rglob("*.sql"))
    print(f"Found {len(sql_files)} SQL files to evaluate")
    
    # Evaluate each file
    for sql_file in sql_files[:1]:  # Start with one file for testing
        print(f"Evaluating: {sql_file}")
        
        try:
            result = await evaluator.evaluate_sql_file(sql_file)
            
            # Save result to JSON file
            output_dir = Path("ai-evaluations") / sql_file.parts[-3] / sql_file.parts[-2]
            output_dir.mkdir(parents=True, exist_ok=True)
            
            output_file = output_dir / f"{sql_file.stem}.json"
            output_file.write_text(result.model_dump_json(indent=2))
            
            print(f"✅ Evaluation saved to: {output_file}")
            
            # Save result to database
            db_saved = await evaluator.save_evaluation_to_db(result)
            if db_saved:
                print(f"✅ Evaluation saved to database")
            else:
                print(f"⚠️  Failed to save to database")
            
        except Exception as e:
            print(f"❌ Error evaluating {sql_file}: {e}")
    
    # Show evaluation statistics
    print("\n📊 Evaluation Statistics:")
    stats = evaluator.get_evaluation_stats()
    if stats:
        print(f"  Total evaluations: {stats.get('total_evaluations', 0)}")
        print(f"  Success rate: {stats.get('success_rate', 0)}%")
        print(f"  Quest stats: {stats.get('quest_stats', {})}")
    else:
        print("  No statistics available")

if __name__ == "__main__":
    asyncio.run(main()) 