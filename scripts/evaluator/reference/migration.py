#!/usr/bin/env python3
"""
Migration Script for SQL Adventure AI Evaluator
Migrates data from old schema to new normalized database structure
"""

import os
import json
import logging
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
from pathlib import Path
import hashlib
import asyncio

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

try:
    from ..core.models import (
        Base, Quest, Subcategory, SQLFile, SQLPattern, SQLFilePattern,
        Evaluation, TechnicalAnalysis, EducationalAnalysis, ExecutionDetail,
        EvaluationPattern, Recommendation, EvaluationSession
    )
    from ..core.database_manager import DatabaseManager
    from ..core.config import get_config, ConfigManager
    from ..core.validation import ValidationCoordinator
except ImportError:
    # Fallback for direct execution
    from core.models import (
        Base, Quest, Subcategory, SQLFile, SQLPattern, SQLFilePattern,
        Evaluation, TechnicalAnalysis, EducationalAnalysis, ExecutionDetail,
        EvaluationPattern, Recommendation, EvaluationSession
    )
    from core.database_manager import DatabaseManager
    from core.config import get_config, ConfigManager
    from core.validation import ValidationCoordinator

class MigrationError(Exception):
    """Custom exception for migration errors"""
    pass

class LegacyDataMigrator:
    """Migrates data from legacy formats to new normalized schema"""
    
    def __init__(self, config=None):
        self.config = config or get_config()
        self.logger = logging.getLogger(__name__)
        
        # Initialize database managers
        self.new_db = DatabaseManager()
        self.old_db = None
        
        # Initialize validation
        self.validator = ValidationCoordinator(self.new_db)
        
        # Migration statistics
        self.stats = {
            'files_processed': 0,
            'evaluations_migrated': 0,
            'patterns_detected': 0,
            'errors': 0,
            'warnings': 0,
            'start_time': None,
            'end_time': None
        }
    
    def migrate_complete_system(self, legacy_data_path: str = None, 
                              json_evaluations_path: str = "ai-evaluations") -> Dict[str, Any]:
        """Perform complete system migration"""
        self.stats['start_time'] = datetime.now()
        
        try:
            self.logger.info("🚀 Starting complete system migration")
            
            # Step 1: Setup new database
            self._setup_new_database()
            
            # Step 2: Migrate SQL files and detect patterns
            self._migrate_sql_files()
            
            # Step 3: Migrate JSON evaluation files
            if os.path.exists(json_evaluations_path):
                self._migrate_json_evaluations(json_evaluations_path)
            
            # Step 4: Migrate legacy database if exists
            if legacy_data_path and os.path.exists(legacy_data_path):
                self._migrate_legacy_database(legacy_data_path)
            
            # Step 5: Create analytics views
            self._create_analytics_views()
            
            # Step 6: Validate migration
            validation_results = self._validate_migration()
            
            self.stats['end_time'] = datetime.now()
            duration = self.stats['end_time'] - self.stats['start_time']
            
            self.logger.info(f"✅ Migration completed in {duration}")
            
            return {
                'success': True,
                'stats': self.stats,
                'duration_seconds': duration.total_seconds(),
                'validation_results': validation_results
            }
            
        except Exception as e:
            self.stats['end_time'] = datetime.now()
            self.stats['errors'] += 1
            self.logger.error(f"❌ Migration failed: {e}")
            
            return {
                'success': False,
                'error': str(e),
                'stats': self.stats
            }
    
    def _setup_new_database(self):
        """Setup the new normalized database"""
        self.logger.info("📝 Setting up new database schema")
        
        if not self.new_db.engine:
            raise MigrationError("Failed to connect to new database")
        
        # Create all tables
        Base.metadata.create_all(bind=self.new_db.engine)
        
        # Initialize reference data
        self.new_db._initialize_data()
        
        self.logger.info("✅ New database schema created and initialized")
    
    def _migrate_sql_files(self):
        """Migrate SQL files from the quest directory structure"""
        self.logger.info("📁 Migrating SQL files and detecting patterns")
        
        quest_path = Path("quests")
        if not quest_path.exists():
            self.logger.warning(f"⚠️  Quest directory not found: {quest_path}")
            return
        
        sql_files = list(quest_path.rglob("*.sql"))
        self.logger.info(f"Found {len(sql_files)} SQL files to migrate")
        
        for sql_file in sql_files:
            try:
                self._migrate_single_sql_file(str(sql_file))
                self.stats['files_processed'] += 1
                
                if self.stats['files_processed'] % 10 == 0:
                    self.logger.info(f"Processed {self.stats['files_processed']}/{len(sql_files)} files")
                    
            except Exception as e:
                self.logger.error(f"❌ Error migrating {sql_file}: {e}")
                self.stats['errors'] += 1
        
        self.logger.info(f"✅ Migrated {self.stats['files_processed']} SQL files")
    
    def _migrate_single_sql_file(self, file_path: str):
        """Migrate a single SQL file to the database"""
        # Use the enhanced database manager to create/update the SQL file record
        sql_file = self.new_db.get_or_create_sql_file(file_path)
        
        if sql_file:
            # Count patterns detected
            if sql_file.sql_patterns:
                self.stats['patterns_detected'] += len(sql_file.sql_patterns)
        else:
            raise MigrationError(f"Failed to create SQL file record for {file_path}")
    
    def _migrate_json_evaluations(self, json_path: str):
        """Migrate JSON evaluation files to normalized database"""
        self.logger.info(f"📊 Migrating JSON evaluations from {json_path}")
        
        json_files = list(Path(json_path).rglob("*.json"))
        self.logger.info(f"Found {len(json_files)} JSON evaluation files")
        
        for json_file in json_files:
            try:
                self._migrate_single_json_evaluation(json_file)
                self.stats['evaluations_migrated'] += 1
                
                if self.stats['evaluations_migrated'] % 50 == 0:
                    self.logger.info(f"Migrated {self.stats['evaluations_migrated']}/{len(json_files)} evaluations")
                    
            except Exception as e:
                self.logger.error(f"❌ Error migrating evaluation {json_file}: {e}")
                self.stats['errors'] += 1
        
        self.logger.info(f"✅ Migrated {self.stats['evaluations_migrated']} evaluations")
    
    def _migrate_single_json_evaluation(self, json_file: Path):
        """Migrate a single JSON evaluation file"""
        try:
            with open(json_file, 'r') as f:
                evaluation_data = json.load(f)
        except Exception as e:
            raise MigrationError(f"Failed to read JSON file {json_file}: {e}")
        
        # Validate the evaluation data
        validation_result = self.validator.validate_evaluation_data(evaluation_data)
        if not validation_result.is_valid:
            self.logger.warning(f"⚠️  Validation issues in {json_file}: {validation_result.summary()}")
            self.stats['warnings'] += 1
        
        # Extract file path from evaluation data
        file_path = evaluation_data.get('metadata', {}).get('full_path')
        if not file_path:
            raise MigrationError(f"No file path found in evaluation data: {json_file}")
        
        # Get or create the SQL file record
        sql_file = self.new_db.get_or_create_sql_file(file_path)
        if not sql_file:
            raise MigrationError(f"Failed to find SQL file record for {file_path}")
        
        # Save the evaluation using the enhanced database manager
        evaluation = self.new_db.save_evaluation(evaluation_data, sql_file)
        if not evaluation:
            raise MigrationError(f"Failed to save evaluation for {file_path}")
    
    def _migrate_legacy_database(self, legacy_db_path: str):
        """Migrate data from legacy database format"""
        self.logger.info(f"🗃️  Migrating legacy database from {legacy_db_path}")
        
        try:
            # Connect to legacy database
            legacy_engine = create_engine(f"sqlite:///{legacy_db_path}")
            LegacySession = sessionmaker(bind=legacy_engine)
            legacy_session = LegacySession()
            
            # Check if legacy database has the old evaluation table
            try:
                legacy_evaluations = legacy_session.execute(text("""
                    SELECT * FROM evaluations 
                    ORDER BY generated_at DESC
                """)).fetchall()
                
                self.logger.info(f"Found {len(legacy_evaluations)} legacy evaluations")
                
                for legacy_eval in legacy_evaluations:
                    try:
                        self._migrate_legacy_evaluation(legacy_eval)
                        self.stats['evaluations_migrated'] += 1
                    except Exception as e:
                        self.logger.error(f"❌ Error migrating legacy evaluation {legacy_eval.id}: {e}")
                        self.stats['errors'] += 1
                
            except Exception:
                self.logger.info("No legacy evaluations table found, skipping")
            
            legacy_session.close()
            
        except Exception as e:
            self.logger.error(f"❌ Failed to connect to legacy database: {e}")
            self.stats['errors'] += 1
    
    def _migrate_legacy_evaluation(self, legacy_eval):
        """Migrate a single legacy evaluation record"""
        # Convert legacy evaluation to new format
        # This is a simplified conversion - you may need to adjust based on your legacy schema
        
        evaluation_data = {
            'metadata': {
                'generated': legacy_eval.generated_at.isoformat() if hasattr(legacy_eval, 'generated_at') else datetime.now().isoformat(),
                'file': getattr(legacy_eval, 'filename', 'unknown.sql'),
                'quest': getattr(legacy_eval, 'quest_name', 'unknown'),
                'full_path': getattr(legacy_eval, 'file_path', 'unknown.sql')
            },
            'intent': {
                'purpose': getattr(legacy_eval, 'purpose', 'Unknown purpose'),
                'difficulty': getattr(legacy_eval, 'difficulty_level', 'Beginner'),
                'concepts': getattr(legacy_eval, 'concepts', 'SQL fundamentals'),
                'sql_patterns': []
            },
            'execution': {
                'success': getattr(legacy_eval, 'execution_success', True),
                'output_lines': getattr(legacy_eval, 'output_lines', 0),
                'errors': getattr(legacy_eval, 'errors', 0),
                'warnings': getattr(legacy_eval, 'warnings', 0),
                'result_sets': getattr(legacy_eval, 'result_sets', 0),
                'raw_output': getattr(legacy_eval, 'raw_output', ''),
                'execution_time_ms': 0,
                'rows_affected': 0,
                'statement_results': []
            },
            'llm_analysis': {
                'technical_analysis': {
                    'syntax_correctness': getattr(legacy_eval, 'syntax_correctness', 'Good'),
                    'logical_structure': getattr(legacy_eval, 'logical_structure', 'Well structured'),
                    'code_quality': getattr(legacy_eval, 'code_quality', 'Good quality'),
                    'performance_notes': getattr(legacy_eval, 'performance_notes', '')
                },
                'educational_analysis': {
                    'learning_value': getattr(legacy_eval, 'learning_value', 'Educational'),
                    'difficulty_level': getattr(legacy_eval, 'difficulty_level', 'Beginner'),
                    'time_estimate': getattr(legacy_eval, 'time_estimate', '15 minutes'),
                    'prerequisites': []
                },
                'assessment': {
                    'grade': getattr(legacy_eval, 'grade', 'B'),
                    'score': getattr(legacy_eval, 'score', 7),
                    'overall_assessment': getattr(legacy_eval, 'overall_assessment', 'PASS')
                },
                'recommendations': []
            },
            'enhanced_intent': {
                'detailed_purpose': getattr(legacy_eval, 'purpose', 'Educational SQL example'),
                'educational_context': 'Legacy migration',
                'real_world_applicability': 'General SQL knowledge',
                'specific_skills': []
            }
        }
        
        # Get or create SQL file
        file_path = evaluation_data['metadata']['full_path']
        sql_file = self.new_db.get_or_create_sql_file(file_path)
        
        if sql_file:
            # Save the migrated evaluation
            evaluation = self.new_db.save_evaluation(evaluation_data, sql_file)
            if not evaluation:
                raise MigrationError(f"Failed to save migrated evaluation for {file_path}")
        else:
            self.logger.warning(f"⚠️  Could not find/create SQL file for {file_path}")
    
    def _create_analytics_views(self):
        """Create analytics views and functions"""
        self.logger.info("📈 Creating analytics views and functions")
        
        try:
            from .analytics_views import AnalyticsViewManager
            
            analytics_manager = AnalyticsViewManager(self.new_db)
            success = analytics_manager.create_analytics_views()
            
            if success:
                self.logger.info("✅ Analytics views created successfully")
            else:
                self.logger.warning("⚠️  Some analytics views may not have been created")
                self.stats['warnings'] += 1
                
        except Exception as e:
            self.logger.error(f"❌ Error creating analytics views: {e}")
            self.stats['errors'] += 1
    
    def _validate_migration(self) -> Dict[str, Any]:
        """Validate the migrated data"""
        self.logger.info("✅ Validating migration results")
        
        try:
            # Perform comprehensive validation
            validation_results = self.validator.validate_complete_system()
            
            # Log validation summary
            for component, result in validation_results.items():
                if result.is_valid:
                    self.logger.info(f"✅ {component}: Valid (score: {result.score})")
                else:
                    error_count = len(result.get_errors())
                    warning_count = len(result.get_warnings())
                    self.logger.warning(f"⚠️  {component}: {error_count} errors, {warning_count} warnings (score: {result.score})")
            
            return {
                'validation_passed': all(result.is_valid for result in validation_results.values()),
                'component_results': {
                    component: {
                        'valid': result.is_valid,
                        'score': result.score,
                        'issues': len(result.issues)
                    }
                    for component, result in validation_results.items()
                }
            }
            
        except Exception as e:
            self.logger.error(f"❌ Validation failed: {e}")
            return {
                'validation_passed': False,
                'error': str(e)
            }
    
    def create_migration_backup(self, backup_path: str = "migration_backup"):
        """Create a backup of current data before migration"""
        self.logger.info(f"💾 Creating migration backup at {backup_path}")
        
        backup_dir = Path(backup_path)
        backup_dir.mkdir(exist_ok=True)
        
        # Backup timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Backup existing evaluations directory
        eval_dir = Path("ai-evaluations")
        if eval_dir.exists():
            backup_eval_dir = backup_dir / f"ai-evaluations_{timestamp}"
            import shutil
            shutil.copytree(eval_dir, backup_eval_dir)
            self.logger.info(f"✅ Backed up evaluations to {backup_eval_dir}")
        
        # Backup configuration
        config_backup = backup_dir / f"config_{timestamp}.json"
        try:
            self.config.save_to_file(str(config_backup), include_secrets=False)
            self.logger.info(f"✅ Backed up configuration to {config_backup}")
        except Exception as e:
            self.logger.warning(f"⚠️  Could not backup configuration: {e}")
        
        return str(backup_dir)
    
    def generate_migration_report(self) -> str:
        """Generate a detailed migration report"""
        report_lines = [
            "# SQL Adventure AI Evaluator Migration Report",
            f"Generated: {datetime.now().isoformat()}",
            "",
            "## Migration Summary",
            f"- Start Time: {self.stats['start_time']}",
            f"- End Time: {self.stats['end_time']}",
            f"- Duration: {self.stats['end_time'] - self.stats['start_time'] if self.stats['end_time'] else 'In progress'}",
            "",
            "## Statistics",
            f"- Files Processed: {self.stats['files_processed']}",
            f"- Evaluations Migrated: {self.stats['evaluations_migrated']}",
            f"- Patterns Detected: {self.stats['patterns_detected']}",
            f"- Errors: {self.stats['errors']}",
            f"- Warnings: {self.stats['warnings']}",
            "",
            "## Migration Status",
            f"- Success Rate: {((self.stats['files_processed'] + self.stats['evaluations_migrated'] - self.stats['errors']) / max(1, self.stats['files_processed'] + self.stats['evaluations_migrated'])) * 100:.1f}%",
            "",
            "## Next Steps",
            "1. Review any errors or warnings in the logs",
            "2. Test the new system with sample evaluations",
            "3. Update any scripts or integrations to use the new database",
            "4. Consider archiving old evaluation files after verification",
            ""
        ]
        
        return "\n".join(report_lines)

class ConfigurationMigrator:
    """Migrates configuration from old format to new format"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def migrate_env_to_config(self, output_path: str = "evaluator_config.json") -> bool:
        """Migrate environment variables to configuration file"""
        self.logger.info("🔧 Migrating environment configuration to file")
        
        try:
            # Load configuration from environment
            config = ConfigManager.load_config()
            
            # Save to file (without secrets for security)
            config.save_to_file(output_path, include_secrets=False)
            
            self.logger.info(f"✅ Configuration saved to {output_path}")
            self.logger.info("📝 Please edit the configuration file and add your API keys and database credentials")
            
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Configuration migration failed: {e}")
            return False
    
    def validate_configuration(self) -> Dict[str, Any]:
        """Validate current configuration"""
        self.logger.info("✅ Validating configuration")
        
        try:
            config = get_config()
            validation_errors = config.validate()
            env_check = ConfigManager.validate_environment()
            
            return {
                'config_valid': len(validation_errors) == 0,
                'validation_errors': validation_errors,
                'environment_ready': env_check['ready'],
                'environment_issues': env_check['issues']
            }
            
        except Exception as e:
            return {
                'config_valid': False,
                'error': str(e)
            }

# CLI interface for migration
async def main():
    """Main migration CLI interface"""
    import argparse
    
    parser = argparse.ArgumentParser(description="SQL Adventure AI Evaluator Migration Tool")
    parser.add_argument("--action", choices=['migrate', 'backup', 'validate', 'config'], 
                       default='migrate', help="Migration action to perform")
    parser.add_argument("--legacy-db", help="Path to legacy database file")
    parser.add_argument("--json-path", default="ai-evaluations", 
                       help="Path to JSON evaluation files")
    parser.add_argument("--backup-path", default="migration_backup",
                       help="Path for migration backup")
    parser.add_argument("--config-output", default="evaluator_config.json",
                       help="Output path for configuration file")
    parser.add_argument("--verbose", "-v", action="store_true",
                       help="Enable verbose logging")
    
    args = parser.parse_args()
    
    # Setup logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    
    logger = logging.getLogger(__name__)
    
    if args.action == 'migrate':
        logger.info("🚀 Starting complete migration")
        
        migrator = LegacyDataMigrator()
        
        # Create backup first
        backup_path = migrator.create_migration_backup(args.backup_path)
        
        # Perform migration
        result = migrator.migrate_complete_system(
            legacy_data_path=args.legacy_db,
            json_evaluations_path=args.json_path
        )
        
        # Generate report
        report = migrator.generate_migration_report()
        report_path = f"{args.backup_path}/migration_report.md"
        with open(report_path, 'w') as f:
            f.write(report)
        
        logger.info(f"📊 Migration report saved to {report_path}")
        
        if result['success']:
            logger.info("✅ Migration completed successfully!")
        else:
            logger.error(f"❌ Migration failed: {result.get('error', 'Unknown error')}")
            
    elif args.action == 'backup':
        logger.info("💾 Creating backup")
        
        migrator = LegacyDataMigrator()
        backup_path = migrator.create_migration_backup(args.backup_path)
        logger.info(f"✅ Backup created at {backup_path}")
        
    elif args.action == 'validate':
        logger.info("✅ Validating system")
        
        # Validate configuration
        config_migrator = ConfigurationMigrator()
        config_result = config_migrator.validate_configuration()
        
        if config_result['config_valid'] and config_result['environment_ready']:
            logger.info("✅ Configuration and environment are valid")
        else:
            logger.warning("⚠️  Configuration or environment issues found")
            if config_result.get('validation_errors'):
                logger.warning(f"Config errors: {config_result['validation_errors']}")
            if config_result.get('environment_issues'):
                logger.warning(f"Environment issues: {config_result['environment_issues']}")
        
        # Validate database if possible
        try:
            db_manager = DatabaseManager()
            validator = ValidationCoordinator(db_manager)
            validation_results = validator.validate_complete_system()
            
            for component, result in validation_results.items():
                if result.is_valid:
                    logger.info(f"✅ {component}: Valid")
                else:
                    logger.warning(f"⚠️  {component}: Issues found")
                    
        except Exception as e:
            logger.warning(f"⚠️  Could not validate database: {e}")
            
    elif args.action == 'config':
        logger.info("🔧 Migrating configuration")
        
        config_migrator = ConfigurationMigrator()
        success = config_migrator.migrate_env_to_config(args.config_output)
        
        if success:
            logger.info("✅ Configuration migration completed")
        else:
            logger.error("❌ Configuration migration failed")

if __name__ == "__main__":
    asyncio.run(main())