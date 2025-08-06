#!/usr/bin/env python3
"""
Validation System for SQL Adventure AI Evaluator
Implements data validation, integrity checks, and quality assurance
"""

import re
import json
import logging
from typing import Dict, Any, List, Optional, Tuple, Set
from datetime import datetime, timedelta
from pathlib import Path
from dataclasses import dataclass
from enum import Enum

import sqlparse
from sqlparse import sql, tokens
from pydantic import BaseModel, ValidationError

from .models import Evaluation, SQLFile, SQLPattern, TechnicalAnalysis, EducationalAnalysis
from .database_manager import DatabaseManager

class ValidationLevel(Enum):
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"

class ValidationCategory(Enum):
    SYNTAX = "syntax"
    SEMANTICS = "semantics"
    PERFORMANCE = "performance"
    SECURITY = "security"
    BEST_PRACTICES = "best_practices"
    DATA_INTEGRITY = "data_integrity"
    BUSINESS_LOGIC = "business_logic"

@dataclass
class ValidationIssue:
    """Represents a validation issue"""
    level: ValidationLevel
    category: ValidationCategory
    message: str
    location: Optional[str] = None
    suggestion: Optional[str] = None
    rule_id: Optional[str] = None

@dataclass
class ValidationResult:
    """Represents validation results"""
    is_valid: bool
    issues: List[ValidationIssue]
    score: float  # 0.0 to 1.0
    
    def get_errors(self) -> List[ValidationIssue]:
        return [issue for issue in self.issues if issue.level == ValidationLevel.ERROR]
    
    def get_warnings(self) -> List[ValidationIssue]:
        return [issue for issue in self.issues if issue.level == ValidationLevel.WARNING]
    
    def has_errors(self) -> bool:
        return len(self.get_errors()) > 0
    
    def summary(self) -> Dict[str, int]:
        return {
            'total_issues': len(self.issues),
            'errors': len(self.get_errors()),
            'warnings': len(self.get_warnings()),
            'info': len([i for i in self.issues if i.level == ValidationLevel.INFO])
        }

class SQLValidator:
    """Validates SQL syntax and semantics"""
    
    def __init__(self, db_manager: Optional[DatabaseManager] = None):
        self.logger = logging.getLogger(__name__)
        self.db_manager = db_manager
        
        # SQL keywords that should be uppercase
        self.sql_keywords = {
            'SELECT', 'FROM', 'WHERE', 'JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL',
            'ON', 'AND', 'OR', 'NOT', 'IN', 'EXISTS', 'BETWEEN', 'LIKE', 'IS',
            'NULL', 'ORDER', 'BY', 'GROUP', 'HAVING', 'LIMIT', 'OFFSET',
            'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE', 'CREATE',
            'TABLE', 'ALTER', 'DROP', 'INDEX', 'VIEW', 'CONSTRAINT', 'PRIMARY',
            'KEY', 'FOREIGN', 'REFERENCES', 'UNIQUE', 'CHECK', 'DEFAULT',
            'WITH', 'RECURSIVE', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END'
        }
        
        # Dangerous patterns
        self.dangerous_patterns = [
            (r'\bDROP\s+TABLE\b', 'DROP TABLE can be destructive'),
            (r'\bDELETE\s+FROM\s+\w+\s*(?:;|$)', 'DELETE without WHERE clause'),
            (r'\bUPDATE\s+\w+\s+SET\s+.*?(?:;|$)(?!.*WHERE)', 'UPDATE without WHERE clause'),
            (r'\bTRUNCATE\s+TABLE\b', 'TRUNCATE can be destructive'),
            (r'\bALTER\s+TABLE\s+\w+\s+DROP\b', 'ALTER TABLE DROP can be destructive'),
            (r'--\s*\$\{', 'Possible SQL injection vulnerability'),
            (r"'\s*\+\s*", 'Possible SQL injection pattern'),
        ]
    
    async def validate_file(self, file_path: Path) -> Dict[str, Any]:
        """Validate a single SQL file"""
        try:
            result = self.validate_sql_file(str(file_path))
            return {
                'file': str(file_path),
                'valid': not result.has_errors(),
                'errors': [issue.message for issue in result.get_errors()],
                'warnings': [issue.message for issue in result.get_warnings()],
                'score': result.score
            }
        except Exception as e:
            return {
                'file': str(file_path),
                'valid': False,
                'errors': [f"Validation error: {str(e)}"],
                'warnings': [],
                'score': 0.0
            }
    
    async def validate_directory(self, directory: Path) -> List[Dict[str, Any]]:
        """Validate all SQL files in a directory"""
        results = []
        sql_files = list(directory.rglob("*.sql"))
        
        for sql_file in sql_files:
            result = await self.validate_file(sql_file)
            results.append(result)
        
        return results
    
    async def check_consistency(self) -> Dict[str, Any]:
        """Check file naming and structure consistency"""
        issues = []
        total_files = 0
        consistent_files = 0
        inconsistent_files = 0
        
        quests_dir = Path("quests")
        if not quests_dir.exists():
            return {
                'total_files': 0,
                'consistent_files': 0,
                'inconsistent_files': 0,
                'issues': ['Quests directory not found']
            }
        
        for quest_dir in quests_dir.iterdir():
            if not quest_dir.is_dir():
                continue
                
            quest_name = quest_dir.name
            for sql_file in quest_dir.rglob("*.sql"):
                total_files += 1
                filename = sql_file.name
                
                # Check naming consistency
                if not re.match(r'^[0-9]{2}-.*\.sql$', filename):
                    issues.append(f"Inconsistent naming: {filename}")
                    inconsistent_files += 1
                else:
                    consistent_files += 1
                
                # Check for required headers
                try:
                    content = sql_file.read_text()
                    if not re.search(r'^--.*PURPOSE:', content, re.MULTILINE):
                        issues.append(f"Missing PURPOSE header: {filename}")
                        inconsistent_files += 1
                    if not re.search(r'^--.*DIFFICULTY:', content, re.MULTILINE):
                        issues.append(f"Missing DIFFICULTY header: {filename}")
                        inconsistent_files += 1
                except Exception as e:
                    issues.append(f"Error reading file {filename}: {e}")
                    inconsistent_files += 1
        
        return {
            'total_files': total_files,
            'consistent_files': consistent_files,
            'inconsistent_files': inconsistent_files,
            'issues': issues
        }
    
    async def performance_test(self) -> Dict[str, Any]:
        """Run performance optimization test"""
        # This is a placeholder implementation
        # In a real implementation, this would run actual performance tests
        return {
            'avg_time': 0.5,
            'total_queries': 10,
            'failed_queries': 0,
            'optimization_suggestions': [
                'Consider adding indexes on frequently queried columns',
                'Use EXPLAIN ANALYZE to identify slow queries',
                'Consider query optimization for complex joins'
            ]
        }
    
    def validate_sql_file(self, file_path: str) -> ValidationResult:
        """Validate a SQL file"""
        issues = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            issues.append(ValidationIssue(
                level=ValidationLevel.ERROR,
                category=ValidationCategory.SYNTAX,
                message=f"Cannot read file: {e}",
                rule_id="FILE_READ_ERROR"
            ))
            return ValidationResult(is_valid=False, issues=issues, score=0.0)
        
        # Validate syntax
        issues.extend(self._validate_syntax(content, file_path))
        
        # Validate semantics
        issues.extend(self._validate_semantics(content, file_path))
        
        # Check for dangerous patterns
        issues.extend(self._check_dangerous_patterns(content, file_path))
        
        # Check formatting and style
        issues.extend(self._check_style(content, file_path))
        
        # Calculate score
        score = self._calculate_score(issues)
        is_valid = len([i for i in issues if i.level == ValidationLevel.ERROR]) == 0
        
        return ValidationResult(is_valid=is_valid, issues=issues, score=score)
    
    def _validate_syntax(self, content: str, file_path: str) -> List[ValidationIssue]:
        """Validate SQL syntax"""
        issues = []
        
        try:
            # Parse SQL
            parsed = sqlparse.parse(content)
            
            if not parsed:
                issues.append(ValidationIssue(
                    level=ValidationLevel.ERROR,
                    category=ValidationCategory.SYNTAX,
                    message="No valid SQL statements found",
                    location=file_path,
                    rule_id="NO_SQL_STATEMENTS"
                ))
                return issues
            
            for i, statement in enumerate(parsed):
                if statement.ttype is None and str(statement).strip():
                    # Check for basic syntax errors
                    stmt_str = str(statement).strip()
                    
                    # Check for unmatched parentheses
                    if stmt_str.count('(') != stmt_str.count(')'):
                        issues.append(ValidationIssue(
                            level=ValidationLevel.ERROR,
                            category=ValidationCategory.SYNTAX,
                            message=f"Unmatched parentheses in statement {i+1}",
                            location=f"{file_path}:statement_{i+1}",
                            rule_id="UNMATCHED_PARENTHESES"
                        ))
                    
                    # Check for unmatched quotes
                    single_quotes = stmt_str.count("'") - stmt_str.count("\\'")
                    double_quotes = stmt_str.count('"') - stmt_str.count('\\"')
                    
                    if single_quotes % 2 != 0:
                        issues.append(ValidationIssue(
                            level=ValidationLevel.ERROR,
                            category=ValidationCategory.SYNTAX,
                            message=f"Unmatched single quotes in statement {i+1}",
                            location=f"{file_path}:statement_{i+1}",
                            rule_id="UNMATCHED_QUOTES"
                        ))
                    
                    if double_quotes % 2 != 0:
                        issues.append(ValidationIssue(
                            level=ValidationLevel.ERROR,
                            category=ValidationCategory.SYNTAX,
                            message=f"Unmatched double quotes in statement {i+1}",
                            location=f"{file_path}:statement_{i+1}",
                            rule_id="UNMATCHED_QUOTES"
                        ))
        
        except Exception as e:
            issues.append(ValidationIssue(
                level=ValidationLevel.ERROR,
                category=ValidationCategory.SYNTAX,
                message=f"SQL parsing error: {e}",
                location=file_path,
                rule_id="PARSE_ERROR"
            ))
        
        return issues
    
    def _validate_semantics(self, content: str, file_path: str) -> List[ValidationIssue]:
        """Validate SQL semantics"""
        issues = []
        
        # Check for common semantic issues
        content_upper = content.upper()
        
        # Check for SELECT without FROM (except for simple expressions)
        select_pattern = r'\bSELECT\s+(?!.*\bFROM\b).*?(?:;|$)'
        select_matches = re.finditer(select_pattern, content_upper, re.MULTILINE | re.DOTALL)
        
        for match in select_matches:
            # Allow simple expressions like SELECT 1, SELECT NOW(), etc.
            select_content = match.group(0)
            if not re.search(r'\b(NOW|CURRENT_|VERSION|[0-9]+|\'[^\']*\')\s*(?:;|$)', select_content):
                if 'FROM' not in select_content:
                    issues.append(ValidationIssue(
                        level=ValidationLevel.WARNING,
                        category=ValidationCategory.SEMANTICS,
                        message="SELECT statement without FROM clause",
                        location=file_path,
                        suggestion="Add FROM clause or verify if this is intentional",
                        rule_id="SELECT_WITHOUT_FROM"
                    ))
        
        # Check for ORDER BY without LIMIT in subqueries
        order_by_pattern = r'\(\s*SELECT.*?ORDER\s+BY.*?\)'
        order_by_matches = re.finditer(order_by_pattern, content_upper, re.IGNORECASE | re.DOTALL)
        
        for match in order_by_matches:
            if 'LIMIT' not in match.group(0):
                issues.append(ValidationIssue(
                    level=ValidationLevel.WARNING,
                    category=ValidationCategory.PERFORMANCE,
                    message="ORDER BY in subquery without LIMIT",
                    location=file_path,
                    suggestion="Consider adding LIMIT clause for better performance",
                    rule_id="ORDER_BY_WITHOUT_LIMIT"
                ))
        
        # Check for cartesian products (JOIN without ON)
        cartesian_pattern = r'\bFROM\s+\w+\s*,\s*\w+'
        if re.search(cartesian_pattern, content_upper):
            issues.append(ValidationIssue(
                level=ValidationLevel.WARNING,
                category=ValidationCategory.PERFORMANCE,
                message="Possible cartesian product detected",
                location=file_path,
                suggestion="Use explicit JOIN with ON clause instead of comma syntax",
                rule_id="CARTESIAN_PRODUCT"
            ))
        
        return issues
    
    def _check_dangerous_patterns(self, content: str, file_path: str) -> List[ValidationIssue]:
        """Check for dangerous SQL patterns"""
        issues = []
        
        for pattern, message in self.dangerous_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                issues.append(ValidationIssue(
                    level=ValidationLevel.WARNING,
                    category=ValidationCategory.SECURITY,
                    message=message,
                    location=file_path,
                    rule_id="DANGEROUS_PATTERN"
                ))
        
        return issues
    
    def _check_style(self, content: str, file_path: str) -> List[ValidationIssue]:
        """Check SQL style and formatting"""
        issues = []
        
        # Check for mixed case keywords
        for keyword in self.sql_keywords:
            # Look for lowercase version of keyword
            pattern = r'\b' + keyword.lower() + r'\b'
            if re.search(pattern, content):
                issues.append(ValidationIssue(
                    level=ValidationLevel.INFO,
                    category=ValidationCategory.BEST_PRACTICES,
                    message=f"Keyword '{keyword}' should be uppercase",
                    location=file_path,
                    suggestion=f"Use '{keyword}' instead of '{keyword.lower()}'",
                    rule_id="KEYWORD_CASE"
                ))
        
        # Check for missing semicolons at statement end
        statements = content.split(';')
        if len(statements) > 1 and statements[-1].strip():
            issues.append(ValidationIssue(
                level=ValidationLevel.INFO,
                category=ValidationCategory.BEST_PRACTICES,
                message="Missing semicolon at end of last statement",
                location=file_path,
                rule_id="MISSING_SEMICOLON"
            ))
        
        # Check for excessive line length
        lines = content.split('\n')
        for i, line in enumerate(lines, 1):
            if len(line) > 120:
                issues.append(ValidationIssue(
                    level=ValidationLevel.INFO,
                    category=ValidationCategory.BEST_PRACTICES,
                    message=f"Line {i} is too long ({len(line)} characters)",
                    location=f"{file_path}:line_{i}",
                    suggestion="Consider breaking long lines for better readability",
                    rule_id="LINE_TOO_LONG"
                ))
        
        return issues
    
    def _calculate_score(self, issues: List[ValidationIssue]) -> float:
        """Calculate validation score based on issues"""
        if not issues:
            return 1.0
        
        # Weight different issue levels
        weights = {
            ValidationLevel.ERROR: -0.3,
            ValidationLevel.WARNING: -0.1,
            ValidationLevel.INFO: -0.05
        }
        
        total_penalty = sum(weights.get(issue.level, 0) for issue in issues)
        score = max(0.0, 1.0 + total_penalty)
        
        return round(score, 3)

class EvaluationValidator:
    """Validates evaluation results and data integrity"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db_manager = db_manager
        self.logger = logging.getLogger(__name__)
    
    def validate_evaluation_data(self, evaluation_data: Dict[str, Any]) -> ValidationResult:
        """Validate evaluation data structure and content"""
        issues = []
        
        # Check required fields
        required_fields = ['metadata', 'intent', 'execution', 'llm_analysis']
        for field in required_fields:
            if field not in evaluation_data:
                issues.append(ValidationIssue(
                    level=ValidationLevel.ERROR,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message=f"Missing required field: {field}",
                    rule_id="MISSING_FIELD"
                ))
        
        # Validate metadata
        if 'metadata' in evaluation_data:
            issues.extend(self._validate_metadata(evaluation_data['metadata']))
        
        # Validate execution results
        if 'execution' in evaluation_data:
            issues.extend(self._validate_execution_results(evaluation_data['execution']))
        
        # Validate LLM analysis
        if 'llm_analysis' in evaluation_data:
            issues.extend(self._validate_llm_analysis(evaluation_data['llm_analysis']))
        
        # Validate score consistency
        issues.extend(self._validate_score_consistency(evaluation_data))
        
        score = self._calculate_data_score(issues)
        is_valid = len([i for i in issues if i.level == ValidationLevel.ERROR]) == 0
        
        return ValidationResult(is_valid=is_valid, issues=issues, score=score)
    
    def _validate_metadata(self, metadata: Dict[str, Any]) -> List[ValidationIssue]:
        """Validate metadata section"""
        issues = []
        
        required_meta_fields = ['generated', 'file', 'quest', 'full_path']
        for field in required_meta_fields:
            if field not in metadata:
                issues.append(ValidationIssue(
                    level=ValidationLevel.ERROR,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message=f"Missing metadata field: {field}",
                    rule_id="MISSING_METADATA"
                ))
        
        # Validate timestamp format
        if 'generated' in metadata:
            try:
                datetime.fromisoformat(metadata['generated'])
            except (ValueError, TypeError):
                issues.append(ValidationIssue(
                    level=ValidationLevel.ERROR,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message="Invalid timestamp format in metadata.generated",
                    rule_id="INVALID_TIMESTAMP"
                ))
        
        # Validate file path
        if 'full_path' in metadata:
            file_path = metadata['full_path']
            if not isinstance(file_path, str) or not file_path.endswith('.sql'):
                issues.append(ValidationIssue(
                    level=ValidationLevel.WARNING,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message="File path should be a .sql file",
                    rule_id="INVALID_FILE_PATH"
                ))
        
        return issues
    
    def _validate_execution_results(self, execution: Dict[str, Any]) -> List[ValidationIssue]:
        """Validate execution results"""
        issues = []
        
        # Check for required execution fields
        required_exec_fields = ['success', 'output_lines', 'errors', 'warnings']
        for field in required_exec_fields:
            if field not in execution:
                issues.append(ValidationIssue(
                    level=ValidationLevel.ERROR,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message=f"Missing execution field: {field}",
                    rule_id="MISSING_EXECUTION_FIELD"
                ))
        
        # Validate numeric fields
        numeric_fields = ['output_lines', 'errors', 'warnings', 'result_sets']
        for field in numeric_fields:
            if field in execution:
                value = execution[field]
                if not isinstance(value, int) or value < 0:
                    issues.append(ValidationIssue(
                        level=ValidationLevel.ERROR,
                        category=ValidationCategory.DATA_INTEGRITY,
                        message=f"Execution field {field} must be a non-negative integer",
                        rule_id="INVALID_NUMERIC_VALUE"
                    ))
        
        # Validate boolean fields
        if 'success' in execution:
            if not isinstance(execution['success'], bool):
                issues.append(ValidationIssue(
                    level=ValidationLevel.ERROR,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message="Execution success must be boolean",
                    rule_id="INVALID_BOOLEAN_VALUE"
                ))
        
        # Check consistency: if success is False, there should be errors
        if execution.get('success') is False and execution.get('errors', 0) == 0:
            issues.append(ValidationIssue(
                level=ValidationLevel.WARNING,
                category=ValidationCategory.BUSINESS_LOGIC,
                message="Execution marked as failed but no errors reported",
                rule_id="INCONSISTENT_EXECUTION_STATUS"
            ))
        
        return issues
    
    def _validate_llm_analysis(self, llm_analysis: Dict[str, Any]) -> List[ValidationIssue]:
        """Validate LLM analysis results"""
        issues = []
        
        # Check for required analysis sections
        required_sections = ['technical_analysis', 'educational_analysis', 'assessment']
        for section in required_sections:
            if section not in llm_analysis:
                issues.append(ValidationIssue(
                    level=ValidationLevel.ERROR,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message=f"Missing LLM analysis section: {section}",
                    rule_id="MISSING_ANALYSIS_SECTION"
                ))
        
        # Validate assessment
        if 'assessment' in llm_analysis:
            assessment = llm_analysis['assessment']
            
            # Check score range
            if 'score' in assessment:
                score = assessment['score']
                if not isinstance(score, int) or not (1 <= score <= 10):
                    issues.append(ValidationIssue(
                        level=ValidationLevel.ERROR,
                        category=ValidationCategory.DATA_INTEGRITY,
                        message="Assessment score must be integer between 1 and 10",
                        rule_id="INVALID_SCORE_RANGE"
                    ))
            
            # Check grade validity
            if 'grade' in assessment:
                grade = assessment['grade']
                valid_grades = {'A', 'B', 'C', 'D', 'F', 'A+', 'A-', 'B+', 'B-', 'C+', 'C-', 'D+', 'D-'}
                if grade not in valid_grades:
                    issues.append(ValidationIssue(
                        level=ValidationLevel.ERROR,
                        category=ValidationCategory.DATA_INTEGRITY,
                        message=f"Invalid grade: {grade}",
                        rule_id="INVALID_GRADE"
                    ))
            
            # Check overall assessment
            if 'overall_assessment' in assessment:
                assessment_val = assessment['overall_assessment']
                valid_assessments = {'PASS', 'FAIL', 'NEEDS_REVIEW'}
                if assessment_val not in valid_assessments:
                    issues.append(ValidationIssue(
                        level=ValidationLevel.ERROR,
                        category=ValidationCategory.DATA_INTEGRITY,
                        message=f"Invalid overall assessment: {assessment_val}",
                        rule_id="INVALID_ASSESSMENT"
                    ))
        
        return issues
    
    def _validate_score_consistency(self, evaluation_data: Dict[str, Any]) -> List[ValidationIssue]:
        """Validate consistency between different scoring methods"""
        issues = []
        
        # Get scores from different sections
        llm_analysis = evaluation_data.get('llm_analysis', {})
        assessment = llm_analysis.get('assessment', {})
        execution = evaluation_data.get('execution', {})
        
        numeric_score = assessment.get('score')
        grade = assessment.get('grade')
        overall_assessment = assessment.get('overall_assessment')
        execution_success = execution.get('success')
        
        # Check score-grade consistency
        if numeric_score is not None and grade is not None:
            expected_grades = {
                10: ['A+'], 9: ['A', 'A-'], 8: ['B+'], 7: ['B', 'B-'], 
                6: ['C+'], 5: ['C', 'C-'], 4: ['D+'], 3: ['D', 'D-'], 
                2: ['F'], 1: ['F']
            }
            
            if grade not in expected_grades.get(numeric_score, []):
                issues.append(ValidationIssue(
                    level=ValidationLevel.WARNING,
                    category=ValidationCategory.BUSINESS_LOGIC,
                    message=f"Score {numeric_score} and grade {grade} are inconsistent",
                    rule_id="SCORE_GRADE_MISMATCH"
                ))
        
        # Check execution success vs assessment consistency
        if execution_success is False and overall_assessment == 'PASS':
            issues.append(ValidationIssue(
                level=ValidationLevel.WARNING,
                category=ValidationCategory.BUSINESS_LOGIC,
                message="Execution failed but overall assessment is PASS",
                rule_id="EXECUTION_ASSESSMENT_MISMATCH"
            ))
        
        return issues
    
    def _calculate_data_score(self, issues: List[ValidationIssue]) -> float:
        """Calculate data validation score"""
        if not issues:
            return 1.0
        
        error_count = len([i for i in issues if i.level == ValidationLevel.ERROR])
        warning_count = len([i for i in issues if i.level == ValidationLevel.WARNING])
        
        # Heavy penalty for errors, lighter for warnings
        penalty = error_count * 0.2 + warning_count * 0.05
        score = max(0.0, 1.0 - penalty)
        
        return round(score, 3)
    
    def validate_database_integrity(self) -> ValidationResult:
        """Validate database integrity and consistency"""
        issues = []
        
        if not self.db_manager.SessionLocal:
            issues.append(ValidationIssue(
                level=ValidationLevel.ERROR,
                category=ValidationCategory.DATA_INTEGRITY,
                message="Database connection not available",
                rule_id="NO_DATABASE_CONNECTION"
            ))
            return ValidationResult(is_valid=False, issues=issues, score=0.0)
        
        try:
            session = self.db_manager.SessionLocal()
            
            # Check for orphaned records
            issues.extend(self._check_orphaned_records(session))
            
            # Check score consistency in database
            issues.extend(self._check_database_score_consistency(session))
            
            # Check for duplicate evaluations
            issues.extend(self._check_duplicate_evaluations(session))
            
            # Check timestamp consistency
            issues.extend(self._check_timestamp_consistency(session))
            
            session.close()
            
        except Exception as e:
            issues.append(ValidationIssue(
                level=ValidationLevel.ERROR,
                category=ValidationCategory.DATA_INTEGRITY,
                message=f"Database validation error: {e}",
                rule_id="DATABASE_VALIDATION_ERROR"
            ))
        
        score = self._calculate_data_score(issues)
        is_valid = len([i for i in issues if i.level == ValidationLevel.ERROR]) == 0
        
        return ValidationResult(is_valid=is_valid, issues=issues, score=score)
    
    def _check_orphaned_records(self, session) -> List[ValidationIssue]:
        """Check for orphaned records in the database"""
        issues = []
        
        # Check for evaluations without corresponding SQL files
        orphaned_evaluations = session.execute("""
            SELECT e.id, e.evaluation_uuid 
            FROM evaluations e 
            LEFT JOIN sql_files sf ON e.sql_file_id = sf.id 
            WHERE sf.id IS NULL
        """).fetchall()
        
        for eval_record in orphaned_evaluations:
            issues.append(ValidationIssue(
                level=ValidationLevel.ERROR,
                category=ValidationCategory.DATA_INTEGRITY,
                message=f"Orphaned evaluation: {eval_record.evaluation_uuid}",
                rule_id="ORPHANED_EVALUATION"
            ))
        
        return issues
    
    def _check_database_score_consistency(self, session) -> List[ValidationIssue]:
        """Check score consistency in database records"""
        issues = []
        
        # Check for score-grade mismatches in database
        inconsistent_scores = session.execute("""
            SELECT e.id, e.numeric_score, e.letter_grade, e.evaluation_uuid
            FROM evaluations e
            WHERE (
                (e.numeric_score >= 9 AND e.letter_grade NOT IN ('A', 'A+', 'A-')) OR
                (e.numeric_score = 8 AND e.letter_grade NOT IN ('B', 'B+', 'B-')) OR
                (e.numeric_score BETWEEN 6 AND 7 AND e.letter_grade NOT IN ('C', 'C+', 'C-')) OR
                (e.numeric_score BETWEEN 4 AND 5 AND e.letter_grade NOT IN ('D', 'D+', 'D-')) OR
                (e.numeric_score <= 3 AND e.letter_grade != 'F')
            )
        """).fetchall()
        
        for record in inconsistent_scores:
            issues.append(ValidationIssue(
                level=ValidationLevel.WARNING,
                category=ValidationCategory.BUSINESS_LOGIC,
                message=f"Score-grade mismatch in evaluation {record.evaluation_uuid}: score={record.numeric_score}, grade={record.letter_grade}",
                rule_id="DB_SCORE_GRADE_MISMATCH"
            ))
        
        return issues
    
    def _check_duplicate_evaluations(self, session) -> List[ValidationIssue]:
        """Check for duplicate evaluations"""
        issues = []
        
        # Find files with multiple recent evaluations (within 1 hour)
        recent_duplicates = session.execute("""
            SELECT sf.file_path, COUNT(*) as eval_count
            FROM evaluations e
            JOIN sql_files sf ON e.sql_file_id = sf.id
            WHERE e.evaluation_date >= NOW() - INTERVAL '1 hour'
            GROUP BY sf.id, sf.file_path
            HAVING COUNT(*) > 1
        """).fetchall()
        
        for duplicate in recent_duplicates:
            issues.append(ValidationIssue(
                level=ValidationLevel.WARNING,
                category=ValidationCategory.DATA_INTEGRITY,
                message=f"Multiple recent evaluations for file: {duplicate.file_path} ({duplicate.eval_count} evaluations)",
                rule_id="DUPLICATE_EVALUATIONS"
            ))
        
        return issues
    
    def _check_timestamp_consistency(self, session) -> List[ValidationIssue]:
        """Check timestamp consistency"""
        issues = []
        
        # Check for evaluations with future timestamps
        future_evaluations = session.execute("""
            SELECT e.evaluation_uuid, e.evaluation_date
            FROM evaluations e
            WHERE e.evaluation_date > NOW()
        """).fetchall()
        
        for eval_record in future_evaluations:
            issues.append(ValidationIssue(
                level=ValidationLevel.ERROR,
                category=ValidationCategory.DATA_INTEGRITY,
                message=f"Evaluation has future timestamp: {eval_record.evaluation_uuid} at {eval_record.evaluation_date}",
                rule_id="FUTURE_TIMESTAMP"
            ))
        
        return issues

class QualityAssuranceValidator:
    """Performs quality assurance checks on the evaluation system"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db_manager = db_manager
        self.logger = logging.getLogger(__name__)
    
    def validate_system_quality(self) -> ValidationResult:
        """Perform comprehensive system quality validation"""
        issues = []
        
        # Check evaluation distribution
        issues.extend(self._check_evaluation_distribution())
        
        # Check score distribution
        issues.extend(self._check_score_distribution())
        
        # Check pattern detection quality
        issues.extend(self._check_pattern_detection_quality())
        
        # Check evaluation completeness
        issues.extend(self._check_evaluation_completeness())
        
        score = self._calculate_quality_score(issues)
        is_valid = len([i for i in issues if i.level == ValidationLevel.ERROR]) == 0
        
        return ValidationResult(is_valid=is_valid, issues=issues, score=score)
    
    def _check_evaluation_distribution(self) -> List[ValidationIssue]:
        """Check if evaluations are evenly distributed across quests"""
        issues = []
        
        if not self.db_manager.SessionLocal:
            return issues
        
        try:
            session = self.db_manager.SessionLocal()
            
            # Get evaluation counts by quest
            quest_counts = session.execute("""
                SELECT q.name, q.display_name, COUNT(e.id) as evaluation_count
                FROM quests q
                LEFT JOIN evaluations e ON q.id = e.quest_id
                GROUP BY q.id, q.name, q.display_name
                ORDER BY evaluation_count
            """).fetchall()
            
            if quest_counts:
                min_count = min(row.evaluation_count for row in quest_counts)
                max_count = max(row.evaluation_count for row in quest_counts)
                
                # Flag quests with significantly fewer evaluations
                if max_count > 0 and min_count < max_count * 0.3:  # Less than 30% of max
                    low_count_quests = [row for row in quest_counts if row.evaluation_count < max_count * 0.3]
                    for quest in low_count_quests:
                        issues.append(ValidationIssue(
                            level=ValidationLevel.INFO,
                            category=ValidationCategory.BUSINESS_LOGIC,
                            message=f"Quest '{quest.display_name}' has significantly fewer evaluations ({quest.evaluation_count}) compared to others",
                            rule_id="UNEVEN_QUEST_DISTRIBUTION"
                        ))
            
            session.close()
            
        except Exception as e:
            self.logger.error(f"Error checking evaluation distribution: {e}")
        
        return issues
    
    def _check_score_distribution(self) -> List[ValidationIssue]:
        """Check if score distribution is reasonable"""
        issues = []
        
        if not self.db_manager.SessionLocal:
            return issues
        
        try:
            session = self.db_manager.SessionLocal()
            
            # Get score distribution
            score_stats = session.execute("""
                SELECT 
                    AVG(numeric_score) as avg_score,
                    STDDEV(numeric_score) as score_stddev,
                    MIN(numeric_score) as min_score,
                    MAX(numeric_score) as max_score,
                    COUNT(*) as total_evaluations
                FROM evaluations
                WHERE evaluation_date >= NOW() - INTERVAL '30 days'
            """).fetchone()
            
            if score_stats and score_stats.total_evaluations > 10:
                avg_score = float(score_stats.avg_score or 0)
                stddev = float(score_stats.score_stddev or 0)
                
                # Check for unusual score patterns
                if avg_score > 9.0:
                    issues.append(ValidationIssue(
                        level=ValidationLevel.WARNING,
                        category=ValidationCategory.BUSINESS_LOGIC,
                        message=f"Average score is very high ({avg_score:.2f}), may indicate overly lenient evaluation",
                        rule_id="HIGH_AVERAGE_SCORE"
                    ))
                elif avg_score < 3.0:
                    issues.append(ValidationIssue(
                        level=ValidationLevel.WARNING,
                        category=ValidationCategory.BUSINESS_LOGIC,
                        message=f"Average score is very low ({avg_score:.2f}), may indicate overly strict evaluation",
                        rule_id="LOW_AVERAGE_SCORE"
                    ))
                
                if stddev < 0.5:
                    issues.append(ValidationIssue(
                        level=ValidationLevel.INFO,
                        category=ValidationCategory.BUSINESS_LOGIC,
                        message=f"Score standard deviation is very low ({stddev:.2f}), scores may lack discrimination",
                        rule_id="LOW_SCORE_VARIANCE"
                    ))
            
            session.close()
            
        except Exception as e:
            self.logger.error(f"Error checking score distribution: {e}")
        
        return issues
    
    def _check_pattern_detection_quality(self) -> List[ValidationIssue]:
        """Check quality of pattern detection"""
        issues = []
        
        if not self.db_manager.SessionLocal:
            return issues
        
        try:
            session = self.db_manager.SessionLocal()
            
            # Check for files with no patterns detected
            files_without_patterns = session.execute("""
                SELECT sf.file_path, sf.filename
                FROM sql_files sf
                LEFT JOIN sql_file_patterns sfp ON sf.id = sfp.sql_file_id
                WHERE sfp.id IS NULL
            """).fetchall()
            
            for file_record in files_without_patterns:
                issues.append(ValidationIssue(
                    level=ValidationLevel.INFO,
                    category=ValidationCategory.BUSINESS_LOGIC,
                    message=f"No patterns detected for file: {file_record.filename}",
                    rule_id="NO_PATTERNS_DETECTED"
                ))
            
            # Check for patterns with very low confidence
            low_confidence_patterns = session.execute("""
                SELECT sf.filename, p.display_name, sfp.confidence_score
                FROM sql_file_patterns sfp
                JOIN sql_files sf ON sfp.sql_file_id = sf.id
                JOIN sql_patterns p ON sfp.pattern_id = p.id
                WHERE sfp.confidence_score < 0.5
            """).fetchall()
            
            for pattern_record in low_confidence_patterns:
                issues.append(ValidationIssue(
                    level=ValidationLevel.WARNING,
                    category=ValidationCategory.BUSINESS_LOGIC,
                    message=f"Low confidence pattern detection: {pattern_record.display_name} in {pattern_record.filename} (confidence: {pattern_record.confidence_score})",
                    rule_id="LOW_CONFIDENCE_PATTERN"
                ))
            
            session.close()
            
        except Exception as e:
            self.logger.error(f"Error checking pattern detection quality: {e}")
        
        return issues
    
    def _check_evaluation_completeness(self) -> List[ValidationIssue]:
        """Check completeness of evaluations"""
        issues = []
        
        if not self.db_manager.SessionLocal:
            return issues
        
        try:
            session = self.db_manager.SessionLocal()
            
            # Check for evaluations missing technical analysis
            missing_technical = session.execute("""
                SELECT e.evaluation_uuid
                FROM evaluations e
                LEFT JOIN technical_analyses ta ON e.id = ta.evaluation_id
                WHERE ta.id IS NULL
            """).fetchall()
            
            for eval_record in missing_technical:
                issues.append(ValidationIssue(
                    level=ValidationLevel.WARNING,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message=f"Evaluation missing technical analysis: {eval_record.evaluation_uuid}",
                    rule_id="MISSING_TECHNICAL_ANALYSIS"
                ))
            
            # Check for evaluations missing educational analysis
            missing_educational = session.execute("""
                SELECT e.evaluation_uuid
                FROM evaluations e
                LEFT JOIN educational_analyses ea ON e.id = ea.evaluation_id
                WHERE ea.id IS NULL
            """).fetchall()
            
            for eval_record in missing_educational:
                issues.append(ValidationIssue(
                    level=ValidationLevel.WARNING,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message=f"Evaluation missing educational analysis: {eval_record.evaluation_uuid}",
                    rule_id="MISSING_EDUCATIONAL_ANALYSIS"
                ))
            
            session.close()
            
        except Exception as e:
            self.logger.error(f"Error checking evaluation completeness: {e}")
        
        return issues
    
    def _calculate_quality_score(self, issues: List[ValidationIssue]) -> float:
        """Calculate quality assurance score"""
        if not issues:
            return 1.0
        
        # Quality score is less strict than validation score
        error_penalty = len([i for i in issues if i.level == ValidationLevel.ERROR]) * 0.15
        warning_penalty = len([i for i in issues if i.level == ValidationLevel.WARNING]) * 0.05
        info_penalty = len([i for i in issues if i.level == ValidationLevel.INFO]) * 0.02
        
        total_penalty = error_penalty + warning_penalty + info_penalty
        score = max(0.0, 1.0 - total_penalty)
        
        return round(score, 3)

# Main validation coordinator
class ValidationCoordinator:
    """Coordinates all validation activities"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.sql_validator = SQLValidator()
        self.evaluation_validator = EvaluationValidator(db_manager)
        self.qa_validator = QualityAssuranceValidator(db_manager)
        self.logger = logging.getLogger(__name__)
    
    def validate_complete_system(self) -> Dict[str, ValidationResult]:
        """Perform complete system validation"""
        results = {}
        
        try:
            # Database integrity validation
            results['database_integrity'] = self.evaluation_validator.validate_database_integrity()
            
            # System quality validation
            results['system_quality'] = self.qa_validator.validate_system_quality()
            
        except Exception as e:
            self.logger.error(f"Error in complete system validation: {e}")
            results['error'] = ValidationResult(
                is_valid=False,
                issues=[ValidationIssue(
                    level=ValidationLevel.ERROR,
                    category=ValidationCategory.DATA_INTEGRITY,
                    message=f"System validation error: {e}",
                    rule_id="SYSTEM_VALIDATION_ERROR"
                )],
                score=0.0
            )
        
        return results
    
    def validate_sql_file(self, file_path: str) -> ValidationResult:
        """Validate a single SQL file"""
        return self.sql_validator.validate_sql_file(file_path)
    
    def validate_evaluation_data(self, evaluation_data: Dict[str, Any]) -> ValidationResult:
        """Validate evaluation data"""
        return self.evaluation_validator.validate_evaluation_data(evaluation_data)