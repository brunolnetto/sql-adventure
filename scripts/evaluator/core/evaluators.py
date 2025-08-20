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

# JSON encoder for datetime objects
class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super(DateTimeEncoder, self).default(obj)

from pydantic_ai import Agent
from core.models import Intent, ComprehensiveAnalysis, Assessment, Recommendation, LLMAnalysis, EvaluationResult
from core.agents import (
    intent_agent, 
    sql_instructor_agent, 
    quality_assessor_agent
)
from utils.discovery import MetadataExtractor, detect_sql_patterns
from utils.cache import (
    _is_cached_valid, 
    _get_cache_path, 
    _load_cached_result, 
    _save_cached_result
)

from repositories.sqlfile_repository import SQLFileRepository

# Handle relative imports
evaluator_dir = Path(__file__).parent.parent
sys.path.insert(0, str(evaluator_dir))

from database.manager import DatabaseManager
from database.tables import EvaluationBase
from config import ProjectFolderConfig, EvaluationConfig


class SQLEvaluator:
    """AI-powered SQL evaluation system with database connection pooling"""
    
    def __init__(self):
        self.model_name = os.getenv('MODEL_NAME', 'gpt-4o-mini')

        self.agents = {
            "intent_analyst": intent_agent,
            "sql_instructor": sql_instructor_agent,
            "quality_assessor": quality_assessor_agent
        }
        self._db_pool = None

        # Initialize database manager for persistence (use evaluator database)
        from database.utils import get_evaluator_connection_string, get_quests_connection_string
        evaluator_connection_string = get_evaluator_connection_string()
        quests_connection_string = get_quests_connection_string()
        
        # Evaluator database: stores evaluation metadata with proper schema
        self.db_manager = DatabaseManager(EvaluationBase, database_type="evaluator")
        
        # Quests database: execution sandbox only, no schema needed
        self.sql_execution_manager = DatabaseManager(None, database_type="quests")
    
    async def analyze_sql_intent(self, sql_metadata: dict) -> Intent:
        """Analyze educational intent using OpenAI"""
        
        quest_name=sql_metadata['quest_name']
        purpose=sql_metadata['purpose']
        concepts=sql_metadata['concepts']
        difficulty=sql_metadata['difficulty']
        sql_content=sql_metadata['sql_content']

        prompt = f"""
        Analyze this SQL exercise for educational intent:
        
        Quest: {quest_name}
        Initial Purpose: {purpose}
        Initial Concepts: {concepts}
        Initial Difficulty: {difficulty}
        
        Note: The complete SQL code and execution results are available in the technical analysis phase.
        Base your analysis on the metadata above and the educational context.
        
        Provide a comprehensive analysis of the educational intent, including:
        - Detailed learning objectives
        - Educational context
        - Real-world applicability
        - Specific skills learners will develop
        """
        
        try:
            result = await self.agents["intent_analyst"].run(prompt, output_type=Intent)
            return result.data  # Extract the actual data from AgentRunResult
        except Exception as e:
            print(f"Error in intent analysis: {e}")
            # Fallback
            return Intent(
                detailed_purpose=purpose,
                educational_context=f"SQL exercise in {quest_name}",
                real_world_applicability="Database design and management",
                specific_skills=concepts.split(", ")
            )
    
    async def analyze_sql_output(self, quest_name: str,
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
        
        Execution Output:
        {output_content}
        
        Note: The execution output above contains the complete SQL code and results.
        
        Provide a comprehensive analysis with separate technical and educational reasoning:
        
        TECHNICAL REASONING: Provide detailed analysis of:
        - Score (1-10): Overall technical quality assessment
        - Explanation: Detailed technical analysis covering syntax, logic, and implementation quality
        - Strengths: List specific technical strengths identified
        - Weaknesses: List technical issues or areas for improvement  
        - Syntax Quality: Assessment of SQL syntax and structure
        - Performance Considerations: Performance implications and optimizations
        
        EDUCATIONAL REASONING: Provide detailed analysis of:
        - Score (1-10): Educational value and learning effectiveness
        - Explanation: Detailed educational analysis covering learning objectives and pedagogical value
        - Learning Objectives: Specific learning objectives this exercise addresses
        - Skill Development: Skills that learners will develop through this exercise
        - Real World Relevance: How this applies to real-world database scenarios
        - Pedagogical Value: Assessment of teaching/learning effectiveness
        
        OVERALL ASSESSMENT:
        - Overall feedback combining technical and educational aspects
        - Difficulty level (Beginner/Intermediate/Advanced/Expert)
        - Time estimate (e.g., "5 min", "10-15 min")
        - Detected patterns with quality assessment
        - Final grade and score
        - Actionable recommendations for improvement
        """
        
        try:
            result = await self.agents["sql_instructor"].run(prompt, output_type=LLMAnalysis)
            return result.data  # Extract the actual data from AgentRunResult
        except Exception as e:
            print(f"Error in output analysis: {e}")
            # Fallback with simplified structure
            from core.models import TechnicalReasoning, EducationalReasoning
            return LLMAnalysis(
                analysis=ComprehensiveAnalysis(
                    overall_feedback="Analysis failed due to technical error",
                    difficulty_level=difficulty,
                    time_estimate="10 min",
                    technical_reasoning=TechnicalReasoning(
                        score=5,
                        explanation="Technical analysis failed - manual review needed",
                        strengths=[],
                        weaknesses=["Analysis error occurred"],
                        syntax_quality="Unable to assess due to technical error",
                        performance_considerations="Unable to assess due to technical error"
                    ),
                    educational_reasoning=EducationalReasoning(
                        score=5,
                        explanation="Educational analysis failed - manual review needed", 
                        learning_objectives=[],
                        skill_development=[],
                        real_world_relevance="Unable to assess due to technical error",
                        pedagogical_value="Unable to assess due to technical error"
                    ),
                    detected_patterns=[]
                ),
                assessment=Assessment(
                    grade="C",
                    score=5,
                    overall_assessment="NEEDS_REVIEW"
                ),
                recommendations=[Recommendation(
                    priority="High",
                    recommendation_text="Analysis failed - manual review needed",
                    implementation_effort="High"
                )]
            )
    
    async def execute_sql_file(self, file_path: Path) -> Dict[str, Any]:
        """Execute SQL file using connection pool"""
        try:
            # Clean up execution sandbox before running SQL file
            self._cleanup_execution_sandbox()
            
            # Use the SQL execution manager (connects to quests database)
            return await self.sql_execution_manager.execute_sql_file(str(file_path))
            
        except Exception as e:
            print(f"Error executing SQL file: {e}")
            return {
                "success": False,
                "errors": 1,
                "warnings": 0,
                "output_content": str(e),
                "output_lines": 1,
                "result_sets": 0,
                "statement_details": []
            }

    def _cleanup_execution_sandbox(self):
        """
        Clean up execution sandbox before running SQL files.
        This is domain logic specific to the evaluation process.
        """
        tables_dropped = self.sql_execution_manager.drop_all_tables()
        if tables_dropped > 0:
            print(f"🧹 Cleaned up {tables_dropped} tables from execution sandbox")
        else:
            print("🧹 Execution sandbox is already clean")
    
    def parse_sql_file(self, file_path: Path) -> str:
        """Parse SQL file content"""
        # Extract metadata
        quest_name = file_path.parts[-3] if len(file_path.parts) >= 3 else "unknown"
        filename = file_path.name
        sql_content = file_path.read_text()

        metadata = MetadataExtractor.parse_header(sql_content)
        if not metadata:
            print(f"⚠️  No metadata found in {file_path}")
            metadata = {"quest": quest_name, "filename": filename}

        purpose = metadata.get("purpose", "No purpose defined")
        concepts = metadata.get("concepts", "No concepts defined")
        difficulty = metadata.get("difficulty", "No difficulty defined")
        
        return {
            "quest_name": quest_name,
            "filename": filename,
            "sql_content": sql_content,
            "metadata": metadata,
            "purpose": purpose,
            "concepts": concepts,
            "difficulty": difficulty
        }
    
    async def evaluate_sql_file(self, file_path: Path) -> EvaluationResult:
        """Evaluate a single SQL file"""
        print(f"Evaluating: {file_path}")
        
        # Parse sql file
        sql_context = self.parse_sql_file(file_path) 

        # Execute SQL
        execution_result = await self.execute_sql_file(file_path)        
        sql_context["execution_result"] = execution_result
        sql_context["output_content"] = execution_result.get("output_content", "No output")

        sql_content = sql_context["sql_content" ]

        # Detect patterns
        sql_patterns = detect_sql_patterns(sql_content)
        pattern_names = [p[0] for p in sql_patterns]  # Extract pattern_name from tuple
        sql_context["pattern_names"] = pattern_names

        # Analyze with AI
        sql_intent: Intent = await self.analyze_sql_intent(sql_context)
        llm_analysis: LLMAnalysis = await self.analyze_sql_output(
            sql_context["quest_name"],
            sql_context["purpose"],
            sql_context["difficulty"],
            sql_context["concepts"],
            sql_context["output_content"],
            sql_context["pattern_names"]
        )

        # Create basic evaluation
        score = llm_analysis.assessment.score
        assessment = llm_analysis.assessment.overall_assessment
        
        # Create result
        result = EvaluationResult(
            metadata={
                "file": sql_context["filename"],
                "quest": sql_context["quest_name"],
                "full_path": str(file_path)
            },
            intent=sql_intent,
            execution={
                "success": execution_result.get("success", False),
                "output_content": sql_context["output_content"],
                "output_lines": execution_result.get("output_lines", 0),
                "errors": execution_result.get("errors", 0),
                "warnings": execution_result.get("warnings", 0),
                "result_sets": execution_result.get("result_sets", 0),
                "raw_output": sql_context["output_content"]
            },
            basic_evaluation={
                "overall_assessment": assessment,
                "score": score,
                "pattern_analysis": f"Detected {len(sql_patterns)} SQL patterns",
                "issues": "",
                "recommendations": "Good example with room for improvement"
            },
            basic_analysis={
                "correctness": "Output appears to execute successfully" if execution_result.get("success", False) else "Execution failed",
                "completeness": f"Generated {execution_result.get('output_lines', 0)} lines of output with {execution_result.get('result_sets', 0)} result sets",
                "learning_value": "Demonstrates intended SQL patterns",
                "quality": "Output is clear and readable"
            },
            llm_analysis=llm_analysis,
            enhanced_intent=sql_intent
        )
        
        # Persist to database
        await self._save_to_database(file_path, result)
        
        return result
    
    async def _save_to_database(self, file_path: Path, result: EvaluationResult):
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
                # Get existing SQL file from database
                from database.tables import SQLFile, Quest, Subcategory
                from repositories.sqlfile_repository import SQLFileRepository
                
                sql_file_repository = SQLFileRepository(session)
                sql_file = sql_file_repository.get_by_path(str(file_path))
                
                if sql_file:
                    # Save evaluation with the existing SQL file
                    print(f"✅ Found SQL file (ID: {sql_file.id}) for path: {file_path}")
                    from repositories.enhanced_evaluation_repository import EnhancedEvaluationRepository
                    evaluation_repository = EnhancedEvaluationRepository(session)
                    
                    # Add file_path to evaluation_data for the EvaluationRepository
                    evaluation_data_with_path = evaluation_data.copy()
                    
                    # Convert absolute path to relative path as stored in database
                    # Database stores paths like: "quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql"
                    file_path_str = str(file_path)
                    if "quests/" in file_path_str:
                        # Extract the part starting from "quests/"
                        relative_path = file_path_str[file_path_str.find("quests/"):]
                        evaluation_data_with_path['file_path'] = relative_path
                        print(f"🔍 Using relative path for database lookup: {relative_path}")
                    else:
                        evaluation_data_with_path['file_path'] = file_path_str
                    
                    evaluation_repository.upsert_evaluation(evaluation_data_with_path)
                    session.commit()
                    print(f"✅ Successfully saved evaluation for {file_path}")
                else:
                    session.rollback()
                    print(f"⚠️  SQL file not found in database: {file_path}")
                    print(f"💡 Hint: Run 'python init_database.py' to populate SQL files")
            except Exception as e:
                session.rollback()
                print(f"❌ Error saving evaluation for {file_path}: {e}")
            finally:
                session.close()
                
        except Exception as e:
            print(f"❌ Database save error for {file_path}: {e}")
    
    async def close(self):
        """Close database connection pool"""
        if self._db_pool:
            await self._db_pool.close()


class QuestEvaluator:
    """Unified evaluator with quest-level parallelism and caching"""
    
    def __init__(self):
        self.evaluator = SQLEvaluator()
        self.config = EvaluationConfig()
        self.folder_config = ProjectFolderConfig()
    
    async def evaluate_subcategory(self, file_path: Path) -> Dict[str, Any]:
        """Evaluate a single SQL file with caching"""
        
        # Check cache first
        cache_enabled = False  # Simplified: disable caching for now
        skip_unchanged = False  # Simplified: always evaluate

        if cache_enabled and _is_cached_valid(file_path) and skip_unchanged:
            cached_result = _load_cached_result(self.folder_config.cache_dir, file_path)
            if cached_result:
                print(f"📋 Using cached result for {file_path.name}")
                return cached_result

        try:
            # Perform evaluation
            result = await self.evaluator.evaluate_sql_file(file_path)
            result_dict = result.model_dump()
            
            if cache_enabled:
                # Cache the result
                _save_cached_result(
                    self.folder_config.cache_dir, file_path, result_dict
                )
            
            return result_dict
            
        except Exception as e:
            print(f"❌ Error evaluating {file_path}: {e}")
            return {
                "error": str(e),
                "file": file_path.name,
                "success": False
            }
    
    async def evaluate_quest(self, quest_path: Path) -> Dict[str, Any]:
        """Evaluate all files in a quest with controlled parallelism"""
        sql_files = list(quest_path.rglob("*.sql"))
        
        if not sql_files:
            return {"quest": quest_path.name, "files": [], "success": 0, "total": 0}
        
        print(f"🔍 Found {len(sql_files)} SQL files in {quest_path.name}")
        print(f"⚡ Processing with {self.config.max_concurrent_files} concurrent files")
        
        # Process files in batches to control concurrency
        results = []
        for i in range(0, len(sql_files), self.config.max_concurrent_files):
            batch = sql_files[i:i + self.config.max_concurrent_files]
            
            # Create tasks for this batch
            tasks = [self.evaluate_subcategory(f) for f in batch]
            
            # Execute batch in parallel
            batch_results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Process results
            for j, result in enumerate(batch_results):
                if isinstance(result, Exception):
                    print(f"❌ Exception in {batch[j].name}: {result}")
                    results.append({
                        "error": str(result),
                        "file": batch[j].name,
                        "success": False
                    })
                else:
                    results.append(result)
            
            # Small delay between batches to be nice to API
            if i + self.config.max_concurrent_files < len(sql_files):
                await asyncio.sleep(1)
        
        # Save results to output directory
        success_count = sum(1 for r in results if r.get("success", True))
        
        # Determine output directory
        if self.config.output_dir:
            output_path = Path(self.config.output_dir) / quest_path.name
        else:
            # Create proper subdirectory structure
            if len(quest_path.parts) >= 3:
                # For subdirectories like quests/1-data-modeling/00-basic-concepts
                output_path = Path("ai-evaluations") / quest_path.parts[-2] / quest_path.parts[-1]
            else:
                # For main quest directories
                output_path = Path("ai-evaluations") / quest_path.name
        
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Save individual results
        for result in results:
            if "metadata" in result and "file" in result["metadata"]:
                # Use the original filename from metadata
                original_filename = result["metadata"]["file"]
                file_name = original_filename.replace(".sql", ".json")
                result_file = output_path / file_name
                result_file.write_text(json.dumps(result, indent=2, cls=DateTimeEncoder))
                print(f"✅ Saved: {result_file}")
            elif "file" in result:
                # Fallback for error results
                file_name = result["file"].replace(".sql", ".json")
                result_file = output_path / file_name
                result_file.write_text(json.dumps(result, indent=2, cls=DateTimeEncoder))
                print(f"⚠️  Saved error result: {result_file}")
            else:
                print(f"❌ Result missing file info: {result.keys()}")
        
        return {
            "quest": quest_path.name,
            "files": results,
            "success": success_count,
            "total": len(sql_files)
        }
    
    async def evaluate_all(self) -> Dict[str, Any]:
        """Evaluate all quests sequentially with parallel file processing within each quest"""
        return await self.evaluate_all_in_directory(self.folder_config.quests_dir)
    
    async def evaluate_all_in_directory(self, quests_dir: Path) -> Dict[str, Any]:
        """Evaluate all quests in the specified directory"""
        quest_dirs = [d for d in quests_dir.iterdir() if d.is_dir() and d.name[0].isdigit()]
        quest_dirs.sort(key=lambda x: int(x.name.split('-')[0]))
        
        print(f"🎯 Found {len(quest_dirs)} quests to evaluate")
        
        all_results = []
        total_files = 0
        total_success = 0
        
        for quest_dir in quest_dirs:
            print(f"\n📚 Processing quest: {quest_dir.name}")
            quest_result = await self.evaluate_quest(quest_dir)
            all_results.append(quest_result)
            
            total_files += quest_result["total"]
            total_success += quest_result["success"]
            
            print(f"✅ Quest {quest_dir.name}: {quest_result['success']}/{quest_result['total']} files")
            
            # Delay between quests to avoid overwhelming the system
            await asyncio.sleep(2)
        
        return {
            "quests": all_results,
            "total_files": total_files,
            "total_success": total_success,
            "success_rate": (total_success / total_files * 100) if total_files > 0 else 0
        }


async def main():
    """Main evaluation function"""
    
    # Load API key
    evaluator = SQLEvaluator()
    
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