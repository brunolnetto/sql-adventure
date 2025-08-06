#!/usr/bin/env python3
"""
SQL Adventure AI Evaluator using OpenAI API
Simplified version with database connection pooling
"""

import os
import json
import asyncio
import sys
from pathlib import Path
from typing import List, Optional, Dict, Any
from datetime import datetime
import asyncpg
from pydantic import BaseModel, Field
from pydantic_ai import Agent

# Handle relative imports
evaluator_dir = Path(__file__).parent
sys.path.insert(0, str(evaluator_dir))

from database import DatabaseManager

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
    """AI-powered SQL evaluation system with database connection pooling"""
    
    def __init__(self, api_key: str):
        self.model_name = os.getenv('MODEL_NAME', 'gpt-4o-mini')

        self.agents = {
            "intent_analyst": Agent(
                self.model_name,
                system_prompt="You are an expert in educational content analysis and curriculum design."
            ),
            "content_analyst": Agent(
                self.model_name,
                system_prompt="You are an expert SQL instructor and educational content analyst."
            )
        }
        self._db_pool = None

        # Initialize database manager for persistence
        self.db_manager = DatabaseManager()
    
    async def _get_db_pool(self):
        """Get or create database connection pool"""
        if self._db_pool is None:
            self._db_pool = await asyncpg.create_pool(
                host=os.getenv('DB_HOST', 'localhost'),
                port=int(os.getenv('DB_PORT', '5432')),
                user=os.getenv('DB_USER', 'postgres'),
                password=os.getenv('DB_PASSWORD', 'postgres'),
                database=os.getenv('DB_NAME', 'sql_adventure_db'),
                min_size=1,
                max_size=5
            )
        return self._db_pool
    
    async def _execute_sql_with_pool(self, sql_content: str) -> Dict[str, Any]:
        """Execute SQL using connection pool for better performance"""
        try:
            pool = await self._get_db_pool()
            
            async with pool.acquire() as conn:
                # Start transaction for isolation
                async with conn.transaction():
                    # Split SQL into individual statements
                    statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
                    
                    results = []
                    total_rows = 0
                    errors = []
                    warnings = []
                    
                    for stmt in statements:
                        try:
                            # Execute statement
                            result = await conn.fetch(stmt)
                            results.append({
                                'statement': stmt,
                                'rows': len(result),
                                'data': [dict(row) for row in result] if result else []
                            })
                            total_rows += len(result)
                            
                        except Exception as e:
                            error_msg = str(e)
                            if 'warning' in error_msg.lower():
                                warnings.append(error_msg)
                            else:
                                errors.append(error_msg)
                    
                    return {
                        "success": len(errors) == 0,
                        "output_content": f"Executed {len(statements)} statements. Total rows: {total_rows}. Errors: {len(errors)}, Warnings: {len(warnings)}",
                        "output_lines": len(statements) + len(errors) + len(warnings),
                        "result_sets": len(results),
                        "errors": len(errors),
                        "warnings": len(warnings),
                        "raw_results": results
                    }
                    
        except Exception as e:
            return {
                "success": False,
                "output_content": f"Database connection error: {str(e)}",
                "output_lines": 1,
                "result_sets": 0,
                "errors": 1,
                "warnings": 0
            }
    
    async def analyze_sql_intent(self, sql_content: str, quest_name: str, 
                                basic_purpose: str, basic_concepts: str, 
                                basic_difficulty: str) -> EnhancedIntent:
        """Analyze educational intent using OpenAI"""
        
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
        
        try:
            return await self.agents["intent_analyst"].run(prompt, output_type=EnhancedIntent)
        except Exception as e:
            print(f"Error in intent analysis: {e}")
            # Fallback
            return EnhancedIntent(
                detailed_purpose=basic_purpose,
                educational_context=f"SQL exercise in {quest_name}",
                real_world_applicability="Database design and management",
                specific_skills=basic_concepts.split(", ")
            )
    
    async def analyze_sql_output(self, sql_content: str, quest_name: str,
                                purpose: str, difficulty: str, concepts: str,
                                output_content: str, sql_patterns: List[str]) -> LLMAnalysis:
        """Analyze SQL output using OpenAI"""
        
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
        
        try:
            result = await self.agents["content_analysis"].run(prompt, output_type=LLMAnalysis)
            return result
        except Exception as e:
            print(f"Error in output analysis: {e}")
            # Fallback
            return LLMAnalysis(
                technical_analysis=TechnicalAnalysis(
                    syntax_correctness="Analysis failed",
                    logical_structure="Analysis failed",
                    code_quality="Analysis failed"
                ),
                educational_analysis=EducationalAnalysis(
                    learning_value="Analysis failed",
                    difficulty_level=difficulty,
                    time_estimate="Unknown",
                    prerequisites=[]
                ),
                assessment=Assessment(
                    grade="C",
                    score=5,
                    overall_assessment="NEEDS_REVIEW"
                ),
                recommendations=["Analysis failed - manual review needed"]
            )
    
    def detect_sql_patterns(self, sql_content: str) -> List[SQLPattern]:
        """Detect SQL patterns in the code"""
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
                pattern=SQLPattern(
                    pattern_name=pattern_name,
                    confidence=0.8,
                    description=f"Detected {pattern_name} pattern"
                )
                patterns.append(pattern)
        
        return patterns
    
    async def execute_sql_file(self, file_path: Path) -> Dict[str, Any]:
        """Execute SQL file using connection pool"""
        try:
            # Read SQL content
            sql_content = file_path.read_text()
            
            # Execute using connection pool
            return await self._execute_sql_with_pool(sql_content)
            
        except Exception as e:
            print(f"Error executing SQL file: {e}")
            return {
                "success": False,
                "output_content": f"Error: {str(e)}",
                "output_lines": 1,
                "result_sets": 0,
                "errors": 1,
                "warnings": 0
            }
    
    async def evaluate_sql_file(self, file_path: Path) -> EvaluationResult:
        """Evaluate a single SQL file"""
        print(f"Evaluating: {file_path}")
        
        # Extract metadata
        quest_name = file_path.parts[-3] if len(file_path.parts) >= 3 else "unknown"
        filename = file_path.name
        purpose = self._extract_purpose_from_path(file_path)
        concepts = self._extract_concepts_from_content(file_path.read_text())
        difficulty = self._extract_difficulty_from_path(file_path)
        
        # Execute SQL
        execution_result = await self.execute_sql_file(file_path)
        
        # Detect patterns
        sql_patterns = self.detect_sql_patterns(file_path.read_text())
        pattern_names = [p.pattern_name for p in sql_patterns]
        
        # Analyze with AI
        enhanced_intent = await self.analyze_sql_intent(
            file_path.read_text(), quest_name, purpose, concepts, difficulty
        )
        
        llm_analysis = await self.analyze_sql_output(
            file_path.read_text(), quest_name, purpose, difficulty, 
            concepts, execution_result["output_content"], pattern_names
        )
        
        # Create basic evaluation
        score = llm_analysis.assessment.score
        assessment = llm_analysis.assessment.overall_assessment
        
        # Create result
        result = EvaluationResult(
            metadata={
                "generated": datetime.now().isoformat(),
                "file": filename,
                "quest": quest_name,
                "full_path": str(file_path)
            },
            intent={
                "purpose": purpose,
                "difficulty": difficulty,
                "concepts": concepts,
                "expected_results": "",
                "learning_outcomes": "",
                "sql_patterns": pattern_names
            },
            execution={
                "success": execution_result["success"],
                "output_lines": execution_result["output_lines"],
                "errors": execution_result["errors"],
                "warnings": execution_result["warnings"],
                "result_sets": execution_result["result_sets"],
                "raw_output": execution_result["output_content"]
            },
            basic_evaluation={
                "overall_assessment": assessment,
                "score": score,
                "pattern_analysis": f"Detected {len(sql_patterns)} SQL patterns",
                "issues": "",
                "recommendations": "Good example with room for improvement"
            },
            basic_analysis={
                "correctness": "Output appears to execute successfully" if execution_result["success"] else "Execution failed",
                "completeness": f"Generated {execution_result['output_lines']} lines of output with {execution_result['result_sets']} result sets",
                "learning_value": "Demonstrates intended SQL patterns",
                "quality": "Output is clear and readable"
            },
            llm_analysis=llm_analysis,
            enhanced_intent=enhanced_intent
        )
        
        # Persist to database
        await self.save_to_database(file_path, result)
        
        return result
    
    def _extract_purpose_from_path(self, file_path: Path) -> str:
        """Extract purpose from file path"""        
        quest_name = file_path.parts[-3] if len(file_path.parts) >= 3 else "unknown"
        return ' '.join(quest_name.split("-")[1:])
    
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
        """Extract difficulty from file path"""
        difficulty_map = {
            "00-basic-concepts": "Beginner",
            "01-normalization-patterns": "Intermediate", 
            "02-advanced-patterns": "Advanced",
            "03-schema-design-principles": "Intermediate",
            "04-performance-basics": "Intermediate",
            "05-advanced-optimization": "Expert"
        }

        subdir = file_path.parts[-2] if len(file_path.parts) >= 2 else "unknown"
        return difficulty_map.get(subdir, "Beginner")
    
    async def save_to_database(self, file_path: Path, result: EvaluationResult):
        """Save evaluation result to database"""
        try:
            # Convert pydantic result to dict for database saving
            evaluation_data = result.model_dump()
            
            # The enhanced database manager will handle the SQL file creation and evaluation saving
            if not self.db_manager.SessionLocal:
                print(f"⚠️  Database not available for {file_path}")
                return
            
            session = self.db_manager.SessionLocal()
            try:
                # Get or create SQL file within the same session
                from models import SQLFile, Quest, Subcategory
                
                # Check if file already exists
                sql_file = session.query(SQLFile).filter(SQLFile.file_path == str(file_path)).first()
                
                if not sql_file:
                    # Create new file record
                    filename = file_path.name
                    
                    # Extract quest and subcategory from path
                    parts = file_path.parts
                    if len(parts) >= 3:
                        quest_name = parts[-3]
                        subcategory_name = parts[-2]
                        
                        # Find quest and subcategory
                        quest = session.query(Quest).filter(Quest.name == quest_name).first()
                        if quest:
                            subcategory = session.query(Subcategory).filter(
                                Subcategory.quest_id == quest.id, 
                                Subcategory.name == subcategory_name
                            ).first()
                            
                            if subcategory:
                                # Calculate content hash
                                content_hash = self.db_manager._calculate_file_hash(str(file_path))
                                
                                sql_file = SQLFile(
                                    subcategory_id=subcategory.id,
                                    filename=filename,
                                    file_path=str(file_path),
                                    display_name=self.db_manager._generate_display_name(filename),
                                    content_hash=content_hash
                                )
                                
                                session.add(sql_file)
                                session.flush()  # Get the ID
                
                if sql_file:
                    # Save evaluation with the same session
                    evaluation = self.db_manager.save_evaluation_with_session(session, evaluation_data, sql_file)
                    if evaluation:
                        session.commit()
                        print(f"💾 Saved to database: evaluation ID {evaluation.id}")
                    else:
                        session.rollback()
                        print(f"⚠️  Failed to save evaluation to database for {file_path}")
                else:
                    session.rollback()
                    print(f"⚠️  Failed to create SQL file record for {file_path}")
                    
            finally:
                session.close()
                
        except Exception as e:
            print(f"❌ Database save error for {file_path}: {e}")
    
    async def close(self):
        """Close database connection pool"""
        if self._db_pool:
            await self._db_pool.close()

async def main():
    """Main evaluation function"""
    
    # Load API key
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("❌ OPENAI_API_KEY not found in environment")
        return
    
    # Initialize evaluator
    evaluator = SQLEvaluator(api_key)
    
    try:
        # Find SQL files
        sql_files = list(Path("quests").rglob("*.sql"))
        print(f"Found {len(sql_files)} SQL files to evaluate")
        
        # Evaluate each file
        for sql_file in sql_files:  # Start with one file for testing           
            try:
                result = await evaluator.evaluate_sql_file(sql_file)
                
                # Save result to JSON file
                output_dir = Path("ai-evaluations") / sql_file.parts[-3] / sql_file.parts[-2]
                output_dir.mkdir(parents=True, exist_ok=True)
                
                output_file = output_dir / f"{sql_file.stem}.json"
                output_file.write_text(result.model_dump_json(indent=2))
                
                print(f"✅ Evaluation saved to: {output_file}")
                
            except Exception as e:
                print(f"❌ Error evaluating {sql_file}: {e}")
    
    finally:
        # Clean up database connections
        await evaluator.close()

if __name__ == "__main__":
    asyncio.run(main()) 