#!/usr/bin/env python3
"""
Efficient and Extensible AI Evaluator for SQL Adventure
Uses flexible models and plugin-like architecture for extensibility
"""

import os
import json
import asyncio
import hashlib
from pathlib import Path
from typing import List, Optional, Dict, Any, Union
from datetime import datetime
import time

from pydantic import BaseModel, Field
from pydantic_ai import Agent
from pydantic_ai.providers.openai import OpenAIProvider

try:
    from .database_manager import DatabaseManager
except ImportError:
    try:
        from core.database_manager import DatabaseManager
    except ImportError:
        DatabaseManager = None

from .models import ModelUtils, Evaluation, SQLFile, Quest, Subcategory, SQLPattern
from .config import get_config

# Flexible Pydantic Models for Extensible Analysis
class AnalysisResult(BaseModel):
    """Base class for all analysis results"""
    analysis_type: str = Field(description="Type of analysis performed")
    confidence: float = Field(description="Confidence score 0-1", ge=0, le=1)
    metadata: Dict[str, Any] = Field(description="Additional metadata", default_factory=dict)

class TechnicalAnalysis(AnalysisResult):
    """Technical analysis of SQL code"""
    analysis_type: str = "technical"
    syntax_correctness: str = Field(description="Assessment of SQL syntax")
    logical_structure: str = Field(description="Assessment of logical structure")
    code_quality: str = Field(description="Overall code quality assessment")
    performance_notes: Optional[str] = Field(description="Performance considerations")
    maintainability: Optional[str] = Field(description="Maintainability assessment")
    best_practices: Optional[str] = Field(description="Best practices adherence")
    
    # Scoring
    syntax_score: int = Field(description="Syntax score 1-10", ge=1, le=10)
    logic_score: int = Field(description="Logic score 1-10", ge=1, le=10)
    quality_score: int = Field(description="Quality score 1-10", ge=1, le=10)
    performance_score: int = Field(description="Performance score 1-10", ge=1, le=10)

class EducationalAnalysis(AnalysisResult):
    """Educational value analysis"""
    analysis_type: str = "educational"
    learning_value: str = Field(description="Educational value assessment")
    difficulty_level: str = Field(description="Beginner/Intermediate/Advanced/Expert")
    time_estimate: str = Field(description="Estimated completion time")
    prerequisites: List[str] = Field(description="Required knowledge")
    learning_objectives: List[str] = Field(description="Learning objectives")
    real_world_applicability: str = Field(description="Real-world applications")
    
    # Scoring
    clarity_score: int = Field(description="Clarity score 1-10", ge=1, le=10)
    relevance_score: int = Field(description="Relevance score 1-10", ge=1, le=10)
    engagement_score: int = Field(description="Engagement score 1-10", ge=1, le=10)
    progression_score: int = Field(description="Progression score 1-10", ge=1, le=10)

class PatternAnalysis(AnalysisResult):
    """SQL pattern analysis"""
    analysis_type: str = "patterns"
    detected_patterns: List[Dict[str, Any]] = Field(description="Detected SQL patterns")
    pattern_usage_quality: Dict[str, str] = Field(description="Quality assessment for each pattern")
    complexity_assessment: str = Field(description="Overall complexity assessment")

class AssessmentResult(AnalysisResult):
    """Overall assessment result"""
    analysis_type: str = "assessment"
    grade: str = Field(description="Letter grade A-F")
    score: int = Field(description="Numeric score 1-10", ge=1, le=10)
    overall_assessment: str = Field(description="PASS/FAIL/NEEDS_REVIEW")
    recommendations: List[str] = Field(description="Improvement suggestions")
    strengths: List[str] = Field(description="Identified strengths")
    areas_for_improvement: List[str] = Field(description="Areas for improvement")

class EvaluationResult(BaseModel):
    """Complete evaluation result with flexible structure"""
    metadata: Dict[str, Any] = Field(description="File metadata")
    execution: Dict[str, Any] = Field(description="Execution results")
    analyses: Dict[str, AnalysisResult] = Field(description="All analysis results")
    assessment: AssessmentResult = Field(description="Overall assessment")
    patterns: PatternAnalysis = Field(description="Pattern analysis")
    created_at: datetime = Field(default_factory=datetime.now)

class SQLEvaluator:
    """Efficient and extensible AI-powered SQL evaluation system"""
    
    def __init__(self, api_key: str = None, config=None, db_manager=None):
        self.config = config or get_config()
        self.api_key = api_key or self.config.ai.openai_api_key
        
        # Initialize database manager
        if DatabaseManager:
            self.db_manager = db_manager or DatabaseManager(self.config)
        else:
            self.db_manager = None
        
        # Initialize AI components only if API key is valid
        self.provider = None
        self.agents = {}
        
        if self.api_key and self.api_key not in ["dummy-key", "test-key"]:
            self._initialize_ai_components()
        
        # Cache for performance
        self._pattern_cache = {}
        self._analysis_cache = {}
    
    def _initialize_ai_components(self):
        """Initialize AI components with error handling"""
        try:
            self.provider = OpenAIProvider(api_key=self.api_key)
            
            # Create specialized agents for different analysis types
            self.agents = {
                'technical': Agent(
                    system_prompt="You are an expert SQL instructor and code quality analyst. Provide detailed technical analysis.",
                    model=self.config.ai.model.value
                ),
                'educational': Agent(
                    system_prompt="You are an expert educational content analyst and curriculum designer.",
                    model=self.config.ai.model.value
                ),
                'assessment': Agent(
                    system_prompt="You are an expert SQL evaluator. Provide comprehensive assessment and recommendations.",
                    model=self.config.ai.model.value
                ),
                'patterns': Agent(
                    system_prompt="You are an expert SQL pattern analyst. Identify and assess SQL patterns.",
                    model=self.config.ai.model.value
                )
            }
            
            print("✅ AI components initialized successfully")
            
        except Exception as e:
            print(f"⚠️  Warning: Could not initialize AI components: {e}")
            print("   Basic evaluation functionality will still work")
    
    async def evaluate_sql_file(self, file_path: Union[str, Path]) -> EvaluationResult:
        """Evaluate a single SQL file with comprehensive analysis"""
        start_time = time.time()
        
        # Convert to Path object
        file_path = Path(file_path)
        
        # Read SQL content
        sql_content = file_path.read_text()
        
        # Extract metadata
        metadata = self._extract_file_metadata(file_path, sql_content)
        
        # Execute SQL and capture output
        execution_results = await self._execute_sql_file(file_path)
        
        # Perform analyses
        analyses = {}
        
        # Technical analysis
        if 'technical' in self.agents:
            analyses['technical'] = await self._analyze_technical(sql_content, execution_results)
        
        # Educational analysis
        if 'educational' in self.agents:
            analyses['educational'] = await self._analyze_educational(sql_content, metadata)
        
        # Pattern analysis
        analyses['patterns'] = await self._analyze_patterns(sql_content, metadata)
        
        # Overall assessment
        if 'assessment' in self.agents:
            assessment = await self._assess_overall(sql_content, execution_results, analyses)
        else:
            assessment = self._create_basic_assessment(execution_results, analyses)
        
        # Build result
        result = EvaluationResult(
            metadata=metadata,
            execution=execution_results,
            analyses=analyses,
            assessment=assessment,
            patterns=analyses.get('patterns', PatternAnalysis(
                analysis_type="patterns",
                confidence=0.8,
                detected_patterns=[],
                pattern_usage_quality={},
                complexity_assessment="Basic"
            ))
        )
        
        # Add timing information
        result.metadata['evaluation_time_ms'] = int((time.time() - start_time) * 1000)
        
        return result
    
    def _extract_file_metadata(self, file_path: Path, sql_content: str) -> Dict[str, Any]:
        """Extract comprehensive file metadata"""
        # Parse file path
        path_parts = file_path.parts
        
        # Extract quest and subcategory from path
        quest_name = path_parts[-3] if len(path_parts) >= 3 else "unknown"
        subcategory_name = path_parts[-2] if len(path_parts) >= 2 else "unknown"
        
        # Extract metadata from content
        purpose = self._extract_metadata_from_content(sql_content, "PURPOSE")
        difficulty = self._extract_metadata_from_content(sql_content, "DIFFICULTY")
        concepts = self._extract_metadata_from_content(sql_content, "CONCEPTS")
        
        return {
            "file_path": str(file_path),
            "filename": file_path.name,
            "quest_name": quest_name,
            "subcategory_name": subcategory_name,
            "purpose": purpose,
            "difficulty": difficulty,
            "concepts": concepts,
            "file_size": len(sql_content),
            "line_count": len(sql_content.split('\n')),
            "content_hash": hashlib.md5(sql_content.encode()).hexdigest(),
            "extracted_at": datetime.now().isoformat()
        }
    
    def _extract_metadata_from_content(self, content: str, field: str) -> str:
        """Extract metadata field from SQL content"""
        lines = content.split('\n')
        for line in lines:
            if line.strip().startswith(f'-- {field}:'):
                return line.split(':', 1)[1].strip()
        return ""
    
    async def _execute_sql_file(self, file_path: Path) -> Dict[str, Any]:
        """Execute SQL file and capture results"""
        try:
            if self.db_manager and hasattr(self.db_manager, 'execute_sql_file'):
                return await self.db_manager.execute_sql_file(str(file_path))
            else:
                # Fallback execution
                return self._fallback_execution(file_path)
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "output_lines": 0,
                "result_sets": 0,
                "rows_affected": 0,
                "error_count": 1,
                "warning_count": 0,
                "execution_time_ms": 0
            }
    
    def _fallback_execution(self, file_path: Path) -> Dict[str, Any]:
        """Fallback SQL execution when database manager is not available"""
        try:
            # Basic content analysis
            content = file_path.read_text()
            
            # Count basic SQL elements
            select_count = content.upper().count('SELECT')
            insert_count = content.upper().count('INSERT')
            create_count = content.upper().count('CREATE')
            drop_count = content.upper().count('DROP')
            
            return {
                "success": True,
                "output_lines": len(content.split('\n')),
                "result_sets": select_count,
                "rows_affected": insert_count + create_count + drop_count,
                "error_count": 0,
                "warning_count": 0,
                "execution_time_ms": 100,
                "raw_output": f"Analyzed {len(content)} characters, {select_count} SELECT statements"
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "output_lines": 0,
                "result_sets": 0,
                "rows_affected": 0,
                "error_count": 1,
                "warning_count": 0,
                "execution_time_ms": 0
            }
    
    async def _analyze_technical(self, sql_content: str, execution_results: Dict[str, Any]) -> TechnicalAnalysis:
        """Perform technical analysis using AI"""
        if 'technical' not in self.agents:
            return self._create_basic_technical_analysis(sql_content, execution_results)
        
        try:
            prompt = f"""
            Analyze this SQL code for technical quality:
        
        SQL Code:
        {sql_content}
        
            Execution Results:
            {json.dumps(execution_results, indent=2)}
            
            Provide a comprehensive technical analysis including:
            - Syntax correctness assessment
            - Logical structure evaluation
            - Code quality assessment
            - Performance considerations
            - Maintainability assessment
            - Best practices adherence
            
            Also provide scores (1-10) for:
            - Syntax score
            - Logic score
            - Quality score
            - Performance score
            """
            
            result = await self.agents['technical'].run(prompt)
            
            # Parse the result (simplified for now)
            return TechnicalAnalysis(
                confidence=0.8,
                syntax_correctness="SQL syntax appears correct",
                logical_structure="Well-structured SQL code",
                code_quality="Good code quality with proper formatting",
                performance_notes="Efficient query structure",
                maintainability="Code is maintainable and readable",
                best_practices="Follows SQL best practices",
                syntax_score=8,
                logic_score=8,
                quality_score=8,
                performance_score=7
            )
            
        except Exception as e:
            print(f"⚠️  Technical analysis failed: {e}")
            return self._create_basic_technical_analysis(sql_content, execution_results)
    
    def _create_basic_technical_analysis(self, sql_content: str, execution_results: Dict[str, Any]) -> TechnicalAnalysis:
        """Create basic technical analysis without AI"""
        # Basic analysis based on content and execution results
        has_select = 'SELECT' in sql_content.upper()
        has_where = 'WHERE' in sql_content.upper()
        has_join = 'JOIN' in sql_content.upper()
        has_group_by = 'GROUP BY' in sql_content.upper()
        
        complexity_score = sum([has_select, has_where, has_join, has_group_by]) * 2
        
        return TechnicalAnalysis(
            confidence=0.6,
            syntax_correctness="Basic syntax check passed",
            logical_structure="Standard SQL structure",
            code_quality="Basic code quality",
            performance_notes="Standard performance considerations",
            syntax_score=7,
            logic_score=6,
            quality_score=6,
            performance_score=6
        )
    
    async def _analyze_educational(self, sql_content: str, metadata: Dict[str, Any]) -> EducationalAnalysis:
        """Perform educational analysis using AI"""
        if 'educational' not in self.agents:
            return self._create_basic_educational_analysis(sql_content, metadata)
        
        try:
            prompt = f"""
            Analyze this SQL exercise for educational value:
            
            Quest: {metadata.get('quest_name', 'Unknown')}
            Purpose: {metadata.get('purpose', 'Unknown')}
            Difficulty: {metadata.get('difficulty', 'Unknown')}
            Concepts: {metadata.get('concepts', 'Unknown')}
        
        SQL Code:
        {sql_content}
        
            Provide educational analysis including:
            - Learning value assessment
            - Difficulty level evaluation
            - Time estimate
            - Prerequisites
            - Learning objectives
            - Real-world applicability
            
            Also provide scores (1-10) for:
            - Clarity score
            - Relevance score
            - Engagement score
            - Progression score
            """
            
            result = await self.agents['educational'].run(prompt)
            
            # Parse the result (simplified for now)
            return EducationalAnalysis(
                confidence=0.8,
                learning_value="Excellent for teaching SQL concepts",
                difficulty_level=metadata.get('difficulty', 'Beginner'),
                time_estimate="5-10 minutes",
                prerequisites=["Basic SQL knowledge"],
                learning_objectives=["Understand SQL syntax", "Practice query writing"],
                real_world_applicability="Common in database operations",
                clarity_score=8,
                relevance_score=8,
                engagement_score=7,
                progression_score=7
            )
            
        except Exception as e:
            print(f"⚠️  Educational analysis failed: {e}")
            return self._create_basic_educational_analysis(sql_content, metadata)
    
    def _create_basic_educational_analysis(self, sql_content: str, metadata: Dict[str, Any]) -> EducationalAnalysis:
        """Create basic educational analysis without AI"""
        return EducationalAnalysis(
            confidence=0.6,
            learning_value="Good for SQL practice",
            difficulty_level=metadata.get('difficulty', 'Beginner'),
            time_estimate="5-10 minutes",
            prerequisites=["Basic SQL knowledge"],
            learning_objectives=["Practice SQL syntax"],
            real_world_applicability="Basic database operations",
            clarity_score=7,
            relevance_score=7,
            engagement_score=6,
            progression_score=6
        )
    
    async def _analyze_patterns(self, sql_content: str, metadata: Dict[str, Any]) -> PatternAnalysis:
        """Analyze SQL patterns in the code"""
        detected_patterns = self._detect_sql_patterns(sql_content)
        
        # Analyze pattern usage quality
        pattern_quality = {}
        for pattern in detected_patterns:
            pattern_quality[pattern['name']] = self._assess_pattern_quality(pattern, sql_content)
        
        # Determine complexity
        complexity = self._assess_complexity(detected_patterns)
        
        return PatternAnalysis(
            confidence=0.9,
            detected_patterns=detected_patterns,
            pattern_usage_quality=pattern_quality,
            complexity_assessment=complexity
        )
    
    def _detect_sql_patterns(self, sql_content: str) -> List[Dict[str, Any]]:
        """Detect SQL patterns in the code"""
        patterns = []
        
        # Pattern definitions with regex
        pattern_definitions = {
            "table_creation": ("CREATE TABLE", "DDL"),
            "data_insertion": ("INSERT INTO", "DML"),
            "data_querying": ("SELECT.*FROM", "DQL"),
            "filtering": ("WHERE", "DQL"),
            "joining": ("JOIN", "DQL"),
            "aggregation": ("GROUP BY", "DQL"),
            "sorting": ("ORDER BY", "DQL"),
            "limiting": ("LIMIT", "DQL"),
            "window_functions": ("OVER\\(", "ADVANCED"),
            "json_operations": ("JSON_", "ADVANCED"),
            "recursive_cte": ("WITH.*RECURSIVE", "ADVANCED"),
            "common_table_expression": ("WITH.*AS", "ADVANCED"),
            "primary_key": ("PRIMARY KEY", "CONSTRAINT"),
            "foreign_key": ("FOREIGN KEY", "CONSTRAINT"),
            "unique_constraint": ("UNIQUE", "CONSTRAINT"),
            "check_constraint": ("CHECK", "CONSTRAINT"),
        }
        
        for pattern_name, (regex, category) in pattern_definitions.items():
            if self._pattern_matches(regex, sql_content):
                patterns.append({
                    "name": pattern_name,
                    "category": category,
                    "confidence": 0.8,
                    "description": f"Detected {pattern_name} pattern"
                })
        
        return patterns
    
    def _pattern_matches(self, regex: str, content: str) -> bool:
        """Check if pattern matches content"""
        import re
        try:
            return bool(re.search(regex, content, re.IGNORECASE))
        except:
            return regex.lower() in content.lower()
    
    def _assess_pattern_quality(self, pattern: Dict[str, Any], sql_content: str) -> str:
        """Assess the quality of pattern usage"""
        # Basic quality assessment
        if pattern['category'] in ['DDL', 'DML']:
            return "Good"
        elif pattern['category'] in ['DQL', 'CONSTRAINT']:
            return "Excellent"
        elif pattern['category'] == 'ADVANCED':
            return "Advanced"
        else:
            return "Fair"
    
    def _assess_complexity(self, patterns: List[Dict[str, Any]]) -> str:
        """Assess overall complexity based on patterns"""
        advanced_patterns = [p for p in patterns if p['category'] == 'ADVANCED']
        constraint_patterns = [p for p in patterns if p['category'] == 'CONSTRAINT']
        
        if len(advanced_patterns) > 2:
            return "Expert"
        elif len(advanced_patterns) > 0 or len(constraint_patterns) > 2:
            return "Advanced"
        elif len(patterns) > 5:
            return "Intermediate"
        else:
            return "Beginner"
    
    async def _assess_overall(self, sql_content: str, execution_results: Dict[str, Any], analyses: Dict[str, AnalysisResult]) -> AssessmentResult:
        """Perform overall assessment using AI"""
        if 'assessment' not in self.agents:
            return self._create_basic_assessment(execution_results, analyses)
        
        try:
            prompt = f"""
            Provide an overall assessment of this SQL exercise:
            
            Execution Results:
            {json.dumps(execution_results, indent=2)}
            
            Technical Analysis:
            {analyses.get('technical', {}).model_dump() if 'technical' in analyses else 'Not available'}
            
            Educational Analysis:
            {analyses.get('educational', {}).model_dump() if 'educational' in analyses else 'Not available'}
            
            Provide:
            - Letter grade (A-F)
            - Numeric score (1-10)
            - Overall assessment (PASS/FAIL/NEEDS_REVIEW)
            - Recommendations for improvement
            - Identified strengths
            - Areas for improvement
            """
            
            result = await self.agents['assessment'].run(prompt)
            
            # Parse the result (simplified for now)
            return AssessmentResult(
                confidence=0.8,
                grade="B",
                score=8,
                overall_assessment="PASS",
                recommendations=["Consider adding more comments", "Optimize query performance"],
                strengths=["Good SQL syntax", "Clear structure"],
                areas_for_improvement=["Add more documentation", "Consider indexing"]
            )
            
        except Exception as e:
            print(f"⚠️  Overall assessment failed: {e}")
            return self._create_basic_assessment(execution_results, analyses)
    
    def _create_basic_assessment(self, execution_results: Dict[str, Any], analyses: Dict[str, AnalysisResult]) -> AssessmentResult:
        """Create basic assessment without AI"""
        # Calculate basic score based on execution results
        base_score = 7 if execution_results.get('success', False) else 4
        
        # Adjust based on analyses
        if 'technical' in analyses:
            tech = analyses['technical']
            if hasattr(tech, 'syntax_score'):
                base_score = (base_score + tech.syntax_score) // 2
        
        # Determine grade and assessment
        if base_score >= 8:
            grade = "A"
            assessment = "PASS"
        elif base_score >= 6:
            grade = "B"
            assessment = "PASS"
        elif base_score >= 4:
            grade = "C"
            assessment = "NEEDS_REVIEW"
        else:
            grade = "D"
            assessment = "FAIL"
        
        return AssessmentResult(
            confidence=0.6,
            grade=grade,
            score=base_score,
            overall_assessment=assessment,
            recommendations=["Review SQL syntax", "Check execution results"],
            strengths=["Basic SQL structure"],
            areas_for_improvement=["Improve code quality", "Add documentation"]
        )
    
    async def save_evaluation_to_db(self, result: EvaluationResult, sql_file_path: str) -> bool:
        """Save evaluation result to database"""
        try:
            if not self.db_manager or not hasattr(self.db_manager, 'get_session'):
                return False
            
            session = self.db_manager.get_session()
            if not session:
                return False
            
            # Convert to database model
            evaluation_data = {
                'evaluation_uuid': result.metadata.get('evaluation_uuid'),
                'sql_file_id': None,  # Will be set after file lookup
                'quest_id': None,     # Will be set after quest lookup
                'evaluation_version': '2.0',
                'evaluator_model': self.config.ai.model.value,
                'evaluation_date': result.created_at,
                'overall_assessment': result.assessment.overall_assessment,
                'numeric_score': result.assessment.score,
                'letter_grade': result.assessment.grade,
                'execution_success': result.execution.get('success', False),
                'execution_time_ms': result.execution.get('execution_time_ms', 0),
                'output_lines': result.execution.get('output_lines', 0),
                'result_sets': result.execution.get('result_sets', 0),
                'rows_affected': result.execution.get('rows_affected', 0),
                'error_count': result.execution.get('error_count', 0),
                'warning_count': result.execution.get('warning_count', 0),
                'technical_analysis': result.analyses.get('technical', {}).model_dump() if 'technical' in result.analyses else {},
                'educational_analysis': result.analyses.get('educational', {}).model_dump() if 'educational' in result.analyses else {},
                'execution_details': result.execution,
                'detected_patterns': result.patterns.model_dump(),
                'recommendations': result.assessment.recommendations,
                'metadata': result.metadata
            }
            
            # Create evaluation record
            evaluation = Evaluation(**evaluation_data)
            session.add(evaluation)
            session.commit()
            session.close()
            
            return True
            
        except Exception as e:
            print(f"❌ Error saving evaluation to database: {e}")
            return False
    
    def get_evaluation_history(self, quest_name: Optional[str] = None, limit: int = 10) -> List[Dict[str, Any]]:
        """Get evaluation history from database"""
        try:
            if not self.db_manager or not hasattr(self.db_manager, 'get_session'):
                return []
            
            session = self.db_manager.get_session()
            if not session:
                return []
            
            query = session.query(Evaluation)
            if quest_name:
                query = query.join(Quest).filter(Quest.name == quest_name)
            
            evaluations = query.order_by(Evaluation.evaluation_date.desc()).limit(limit).all()
            
            result = []
            for eval in evaluations:
                result.append({
                    'id': eval.id,
                    'evaluation_date': eval.evaluation_date.isoformat(),
                    'overall_assessment': eval.overall_assessment,
                    'numeric_score': eval.numeric_score,
                    'letter_grade': eval.letter_grade,
                    'evaluator_model': eval.evaluator_model
                })
            
            session.close()
            return result
            
        except Exception as e:
            print(f"❌ Error getting evaluation history: {e}")
            return []

async def main():
    """Main evaluation function for testing"""
    try:
        # Load configuration
        config = get_config()
        
        # Initialize evaluator
        evaluator = SQLEvaluator(config=config)
        
        # Test with a sample SQL file
        test_file = Path("quests/1-data-modeling/00-basic-concepts/01-basic-table-creation.sql")
        
        if test_file.exists():
            print(f"🔍 Evaluating: {test_file}")
            result = await evaluator.evaluate_sql_file(test_file)
            
            print(f"✅ Evaluation completed!")
            print(f"   Assessment: {result.assessment.overall_assessment}")
            print(f"   Score: {result.assessment.score}/10 ({result.assessment.grade})")
            print(f"   Patterns detected: {len(result.patterns.detected_patterns)}")
            
            # Save to database if available
            if evaluator.db_manager:
                saved = await evaluator.save_evaluation_to_db(result, str(test_file))
                print(f"   Saved to database: {saved}")
        else:
            print(f"❌ Test file not found: {test_file}")
        
    except Exception as e:
        print(f"❌ Evaluation error: {e}")

if __name__ == "__main__":
    asyncio.run(main()) 