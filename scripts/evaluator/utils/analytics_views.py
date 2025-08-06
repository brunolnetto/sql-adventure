#!/usr/bin/env python3
"""
Database Views and Analytics Functions for SQL Adventure AI Evaluator
Provides comprehensive reporting and analysis capabilities
"""

from sqlalchemy import text
from typing import Dict, Any, List
try:
    from ..core.database_manager import DatabaseManager
except ImportError:
    # Fallback for direct execution
    from core.database_manager import DatabaseManager

class AnalyticsViewManager:
    """Manages database views and analytics functions"""
    
    def __init__(self, db_manager: DatabaseManager):
        self.db_manager = db_manager
    
    def create_analytics_views(self):
        """Create all analytics views and functions"""
        if not self.db_manager.engine:
            print("❌ Database not connected")
            return False
        
        try:
            with self.db_manager.engine.connect() as conn:
                # Create evaluation summary view
                self._create_evaluation_summary_view(conn)
                
                # Create quest performance view
                self._create_quest_performance_view(conn)
                
                # Create pattern analysis view
                self._create_pattern_analysis_view(conn)
                
                # Create file progress view
                self._create_file_progress_view(conn)
                
                # Create recommendations dashboard view
                self._create_recommendations_dashboard_view(conn)
                
                # Create analytics functions
                self._create_analytics_functions(conn)
                
                conn.commit()
                print("✅ Analytics views and functions created successfully")
                return True
                
        except Exception as e:
            print(f"❌ Error creating analytics views: {e}")
            return False
    
    def _create_evaluation_summary_view(self, conn):
        """Create evaluation summary view"""
        view_sql = """
        CREATE OR REPLACE VIEW evaluation_summary AS
        SELECT 
            e.id as evaluation_id,
            e.evaluation_uuid,
            e.evaluation_date,
            q.name as quest_name,
            q.display_name as quest_display_name,
            sc.name as subcategory_name,
            sc.display_name as subcategory_display_name,
            sf.filename,
            sf.file_path,
            e.overall_assessment,
            e.numeric_score,
            e.letter_grade,
            e.execution_success,
            e.execution_time_ms,
            e.output_lines,
            e.result_sets,
            e.rows_affected,
            e.error_count,
            e.warning_count,
            e.evaluator_model,
            ta.syntax_score,
            ta.logic_score,
            ta.quality_score,
            ta.performance_score,
            ea.difficulty_level as assessed_difficulty,
            ea.estimated_time_minutes,
            ea.clarity_score,
            ea.relevance_score,
            ea.engagement_score,
            ea.progression_score,
            -- Pattern counts
            (SELECT COUNT(*) FROM evaluation_patterns ep WHERE ep.evaluation_id = e.id) as pattern_count,
            -- Recommendation counts
            (SELECT COUNT(*) FROM recommendations r WHERE r.evaluation_id = e.id) as recommendation_count,
            -- High priority recommendation count
            (SELECT COUNT(*) FROM recommendations r WHERE r.evaluation_id = e.id AND r.priority = 'High') as high_priority_recommendations
        FROM evaluations e
        JOIN sql_files sf ON e.sql_file_id = sf.id
        JOIN subcategories sc ON sf.subcategory_id = sc.id
        JOIN quests q ON e.quest_id = q.id
        LEFT JOIN technical_analyses ta ON e.id = ta.evaluation_id
        LEFT JOIN educational_analyses ea ON e.id = ea.evaluation_id
        ORDER BY e.evaluation_date DESC;
        """
        
        conn.execute(text(view_sql))
    
    def _create_quest_performance_view(self, conn):
        """Create quest performance analysis view"""
        view_sql = """
        CREATE OR REPLACE VIEW quest_performance AS
        SELECT 
            q.id as quest_id,
            q.name as quest_name,
            q.display_name as quest_display_name,
            q.difficulty_level as quest_difficulty,
            q.order_index,
            
            -- File counts
            COUNT(DISTINCT sf.id) as total_files,
            COUNT(DISTINCT e.id) as total_evaluations,
            
            -- Success metrics
            COUNT(CASE WHEN e.execution_success = true THEN 1 END) as successful_executions,
            ROUND(
                COUNT(CASE WHEN e.execution_success = true THEN 1 END)::numeric / 
                NULLIF(COUNT(e.id), 0) * 100, 2
            ) as success_rate,
            
            -- Score metrics
            ROUND(AVG(e.numeric_score), 2) as avg_score,
            MIN(e.numeric_score) as min_score,
            MAX(e.numeric_score) as max_score,
            ROUND(STDDEV(e.numeric_score), 2) as score_stddev,
            
            -- Grade distribution
            COUNT(CASE WHEN e.letter_grade IN ('A', 'A+', 'A-') THEN 1 END) as grade_a_count,
            COUNT(CASE WHEN e.letter_grade IN ('B', 'B+', 'B-') THEN 1 END) as grade_b_count,
            COUNT(CASE WHEN e.letter_grade IN ('C', 'C+', 'C-') THEN 1 END) as grade_c_count,
            COUNT(CASE WHEN e.letter_grade IN ('D', 'D+', 'D-') THEN 1 END) as grade_d_count,
            COUNT(CASE WHEN e.letter_grade = 'F' THEN 1 END) as grade_f_count,
            
            -- Performance metrics
            ROUND(AVG(e.execution_time_ms), 2) as avg_execution_time_ms,
            ROUND(AVG(e.output_lines), 2) as avg_output_lines,
            ROUND(AVG(e.error_count), 2) as avg_error_count,
            
            -- Educational metrics
            ROUND(AVG(ea.estimated_time_minutes), 2) as avg_estimated_time,
            ROUND(AVG(ea.clarity_score), 2) as avg_clarity_score,
            ROUND(AVG(ea.relevance_score), 2) as avg_relevance_score,
            
            -- Latest evaluation
            MAX(e.evaluation_date) as latest_evaluation_date,
            COUNT(CASE WHEN e.evaluation_date >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as evaluations_last_7_days,
            COUNT(CASE WHEN e.evaluation_date >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as evaluations_last_30_days
            
        FROM quests q
        LEFT JOIN subcategories sc ON q.id = sc.quest_id
        LEFT JOIN sql_files sf ON sc.id = sf.subcategory_id
        LEFT JOIN evaluations e ON sf.id = e.sql_file_id
        LEFT JOIN educational_analyses ea ON e.id = ea.evaluation_id
        GROUP BY q.id, q.name, q.display_name, q.difficulty_level, q.order_index
        ORDER BY q.order_index;
        """
        
        conn.execute(text(view_sql))
    
    def _create_pattern_analysis_view(self, conn):
        """Create SQL pattern analysis view"""
        view_sql = """
        CREATE OR REPLACE VIEW pattern_analysis AS
        SELECT 
            p.id as pattern_id,
            p.name as pattern_name,
            p.display_name as pattern_display_name,
            p.category as pattern_category,
            p.complexity_level,
            
            -- File associations
            COUNT(DISTINCT sfp.sql_file_id) as files_using_pattern,
            ROUND(AVG(sfp.confidence_score), 3) as avg_file_confidence,
            
            -- Evaluation associations
            COUNT(DISTINCT ep.evaluation_id) as evaluations_using_pattern,
            ROUND(AVG(ep.confidence_score), 3) as avg_eval_confidence,
            
            -- Usage quality analysis
            COUNT(CASE WHEN ep.usage_quality = 'Excellent' THEN 1 END) as excellent_usage,
            COUNT(CASE WHEN ep.usage_quality = 'Good' THEN 1 END) as good_usage,
            COUNT(CASE WHEN ep.usage_quality = 'Fair' THEN 1 END) as fair_usage,
            COUNT(CASE WHEN ep.usage_quality = 'Poor' THEN 1 END) as poor_usage,
            
            -- Performance correlation
            ROUND(AVG(CASE WHEN ep.evaluation_id IS NOT NULL THEN e.numeric_score END), 2) as avg_score_when_used,
            ROUND(AVG(CASE WHEN ep.evaluation_id IS NOT NULL THEN e.execution_time_ms END), 2) as avg_execution_time_when_used,
            
            -- Quest distribution
            STRING_AGG(DISTINCT q.display_name, ', ' ORDER BY q.display_name) as used_in_quests,
            
            -- Recent usage
            MAX(ep.created_at) as last_detected_date,
            COUNT(CASE WHEN ep.created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as detections_last_30_days
            
        FROM sql_patterns p
        LEFT JOIN sql_file_patterns sfp ON p.id = sfp.pattern_id
        LEFT JOIN evaluation_patterns ep ON p.id = ep.pattern_id
        LEFT JOIN evaluations e ON ep.evaluation_id = e.id
        LEFT JOIN sql_files sf ON e.sql_file_id = sf.id
        LEFT JOIN subcategories sc ON sf.subcategory_id = sc.id
        LEFT JOIN quests q ON sc.quest_id = q.id
        GROUP BY p.id, p.name, p.display_name, p.category, p.complexity_level
        ORDER BY COUNT(DISTINCT ep.evaluation_id) DESC, p.name;
        """
        
        conn.execute(text(view_sql))
    
    def _create_file_progress_view(self, conn):
        """Create file progress tracking view"""
        view_sql = """
        CREATE OR REPLACE VIEW file_progress AS
        SELECT 
            sf.id as file_id,
            sf.filename,
            sf.file_path,
            sf.display_name,
            sf.created_at as file_created_at,
            sf.last_modified,
            q.name as quest_name,
            q.display_name as quest_display_name,
            sc.name as subcategory_name,
            sc.display_name as subcategory_display_name,
            
            -- Evaluation history
            COUNT(e.id) as total_evaluations,
            MAX(e.evaluation_date) as last_evaluation_date,
            
            -- Latest evaluation details
            (SELECT e2.overall_assessment FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.evaluation_date DESC LIMIT 1) as latest_assessment,
            (SELECT e2.numeric_score FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.evaluation_date DESC LIMIT 1) as latest_score,
            (SELECT e2.letter_grade FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.evaluation_date DESC LIMIT 1) as latest_grade,
            (SELECT e2.execution_success FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.evaluation_date DESC LIMIT 1) as latest_execution_success,
            
            -- Score trends
            CASE 
                WHEN COUNT(e.id) >= 2 THEN
                    (SELECT e_latest.numeric_score FROM evaluations e_latest 
                     WHERE e_latest.sql_file_id = sf.id 
                     ORDER BY e_latest.evaluation_date DESC LIMIT 1) -
                    (SELECT e_prev.numeric_score FROM evaluations e_prev 
                     WHERE e_prev.sql_file_id = sf.id 
                     ORDER BY e_prev.evaluation_date DESC LIMIT 1 OFFSET 1)
                ELSE NULL
            END as score_trend,
            
            -- Pattern complexity
            (SELECT COUNT(*) FROM sql_file_patterns sfp2 
             JOIN sql_patterns p2 ON sfp2.pattern_id = p2.id 
             WHERE sfp2.sql_file_id = sf.id) as pattern_count,
            (SELECT STRING_AGG(p2.complexity_level, ', ') FROM sql_file_patterns sfp2 
             JOIN sql_patterns p2 ON sfp2.pattern_id = p2.id 
             WHERE sfp2.sql_file_id = sf.id) as pattern_complexities,
            
            -- Content hash for change detection
            sf.content_hash,
            
            -- Status classification
            CASE 
                WHEN COUNT(e.id) = 0 THEN 'Never Evaluated'
                WHEN MAX(e.evaluation_date) < CURRENT_DATE - INTERVAL '30 days' THEN 'Outdated'
                WHEN (SELECT e2.overall_assessment FROM evaluations e2 
                      WHERE e2.sql_file_id = sf.id 
                      ORDER BY e2.evaluation_date DESC LIMIT 1) = 'PASS' THEN 'Passing'
                WHEN (SELECT e2.overall_assessment FROM evaluations e2 
                      WHERE e2.sql_file_id = sf.id 
                      ORDER BY e2.evaluation_date DESC LIMIT 1) = 'FAIL' THEN 'Failing'
                ELSE 'Needs Review'
            END as status
            
        FROM sql_files sf
        JOIN subcategories sc ON sf.subcategory_id = sc.id
        JOIN quests q ON sc.quest_id = q.id
        LEFT JOIN evaluations e ON sf.id = e.sql_file_id
        GROUP BY sf.id, sf.filename, sf.file_path, sf.display_name, sf.created_at, 
                 sf.last_modified, sf.content_hash, q.name, q.display_name, 
                 sc.name, sc.display_name
        ORDER BY q.order_index, sc.order_index, sf.filename;
        """
        
        conn.execute(text(view_sql))
    
    def _create_recommendations_dashboard_view(self, conn):
        """Create recommendations dashboard view"""
        view_sql = """
        CREATE OR REPLACE VIEW recommendations_dashboard AS
        SELECT 
            r.id as recommendation_id,
            r.category,
            r.priority,
            r.recommendation_text,
            r.implementation_effort,
            r.expected_impact,
            r.created_at as recommendation_date,
            
            -- Evaluation context
            e.evaluation_uuid,
            e.overall_assessment,
            e.numeric_score,
            e.letter_grade,
            e.execution_success,
            
            -- File context
            sf.filename,
            sf.file_path,
            q.name as quest_name,
            q.display_name as quest_display_name,
            sc.name as subcategory_name,
            sc.display_name as subcategory_display_name,
            
            -- Technical scores
            ta.syntax_score,
            ta.logic_score,
            ta.quality_score,
            ta.performance_score,
            
            -- Priority scoring for dashboard
            CASE 
                WHEN r.priority = 'High' AND r.expected_impact = 'High' THEN 10
                WHEN r.priority = 'High' AND r.expected_impact = 'Medium' THEN 8
                WHEN r.priority = 'High' AND r.expected_impact = 'Low' THEN 6
                WHEN r.priority = 'Medium' AND r.expected_impact = 'High' THEN 7
                WHEN r.priority = 'Medium' AND r.expected_impact = 'Medium' THEN 5
                WHEN r.priority = 'Medium' AND r.expected_impact = 'Low' THEN 3
                WHEN r.priority = 'Low' AND r.expected_impact = 'High' THEN 4
                WHEN r.priority = 'Low' AND r.expected_impact = 'Medium' THEN 2
                ELSE 1
            END as priority_score
            
        FROM recommendations r
        JOIN evaluations e ON r.evaluation_id = e.id
        JOIN sql_files sf ON e.sql_file_id = sf.id
        JOIN subcategories sc ON sf.subcategory_id = sc.id
        JOIN quests q ON sc.quest_id = q.id
        LEFT JOIN technical_analyses ta ON e.id = ta.evaluation_id
        ORDER BY priority_score DESC, r.created_at DESC;
        """
        
        conn.execute(text(view_sql))
    
    def _create_analytics_functions(self, conn):
        """Create analytics functions"""
        
        # Function to get quest statistics
        function_sql = """
        CREATE OR REPLACE FUNCTION get_quest_statistics(quest_name_param VARCHAR DEFAULT NULL)
        RETURNS TABLE(
            quest_name VARCHAR,
            total_files BIGINT,
            total_evaluations BIGINT,
            success_rate NUMERIC,
            avg_score NUMERIC,
            latest_evaluation TIMESTAMP
        ) AS $$
        BEGIN
            RETURN QUERY
            SELECT 
                qp.quest_name::VARCHAR,
                qp.total_files,
                qp.total_evaluations,
                qp.success_rate,
                qp.avg_score,
                qp.latest_evaluation_date
            FROM quest_performance qp
            WHERE quest_name_param IS NULL OR qp.quest_name = quest_name_param;
        END;
        $$ LANGUAGE plpgsql;
        """
        
        conn.execute(text(function_sql))
        
        # Function to get pattern usage trends
        trend_function_sql = """
        CREATE OR REPLACE FUNCTION get_pattern_usage_trends(days_param INTEGER DEFAULT 30)
        RETURNS TABLE(
            pattern_name VARCHAR,
            usage_count BIGINT,
            avg_confidence NUMERIC,
            trend VARCHAR
        ) AS $$
        BEGIN
            RETURN QUERY
            WITH recent_usage AS (
                SELECT 
                    p.name,
                    COUNT(ep.id) as recent_count,
                    AVG(ep.confidence_score) as recent_confidence
                FROM sql_patterns p
                LEFT JOIN evaluation_patterns ep ON p.id = ep.pattern_id
                LEFT JOIN evaluations e ON ep.evaluation_id = e.id
                WHERE e.evaluation_date >= CURRENT_DATE - INTERVAL '%s days'
                GROUP BY p.id, p.name
            ),
            previous_usage AS (
                SELECT 
                    p.name,
                    COUNT(ep.id) as previous_count
                FROM sql_patterns p
                LEFT JOIN evaluation_patterns ep ON p.id = ep.pattern_id
                LEFT JOIN evaluations e ON ep.evaluation_id = e.id
                WHERE e.evaluation_date >= CURRENT_DATE - INTERVAL '%s days' 
                  AND e.evaluation_date < CURRENT_DATE - INTERVAL '%s days'
                GROUP BY p.id, p.name
            )
            SELECT 
                ru.name::VARCHAR,
                ru.recent_count,
                ROUND(ru.recent_confidence, 3),
                CASE 
                    WHEN pu.previous_count IS NULL OR pu.previous_count = 0 THEN 'New'
                    WHEN ru.recent_count > pu.previous_count THEN 'Increasing'
                    WHEN ru.recent_count < pu.previous_count THEN 'Decreasing'
                    ELSE 'Stable'
                END::VARCHAR as trend
            FROM recent_usage ru
            LEFT JOIN previous_usage pu ON ru.name = pu.name
            ORDER BY ru.recent_count DESC;
        END;
        $$ LANGUAGE plpgsql;
        """
        
        conn.execute(text(trend_function_sql % (days_param, days_param * 2, days_param)))
        
        # Function to get improvement opportunities
        improvement_function_sql = """
        CREATE OR REPLACE FUNCTION get_improvement_opportunities(score_threshold INTEGER DEFAULT 6)
        RETURNS TABLE(
            file_path VARCHAR,
            filename VARCHAR,
            quest_name VARCHAR,
            latest_score INTEGER,
            latest_grade VARCHAR,
            recommendation_count BIGINT,
            high_priority_recommendations BIGINT,
            primary_issues TEXT
        ) AS $$
        BEGIN
            RETURN QUERY
            SELECT 
                fp.file_path::VARCHAR,
                fp.filename::VARCHAR,
                fp.quest_name::VARCHAR,
                fp.latest_score,
                fp.latest_grade::VARCHAR,
                fp.total_evaluations,
                COALESCE((
                    SELECT COUNT(*) 
                    FROM recommendations_dashboard rd 
                    WHERE rd.file_path = fp.file_path 
                    AND rd.priority = 'High'
                ), 0) as high_priority_recs,
                COALESCE((
                    SELECT STRING_AGG(DISTINCT rd.category, ', ')
                    FROM recommendations_dashboard rd 
                    WHERE rd.file_path = fp.file_path 
                    AND rd.priority IN ('High', 'Medium')
                ), 'No specific issues identified')::TEXT as primary_issues
            FROM file_progress fp
            WHERE fp.latest_score IS NOT NULL 
              AND fp.latest_score <= score_threshold
              AND fp.status NOT IN ('Never Evaluated', 'Outdated')
            ORDER BY fp.latest_score ASC, high_priority_recs DESC;
        END;
        $$ LANGUAGE plpgsql;
        """
        
        conn.execute(text(improvement_function_sql))
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """Get comprehensive dashboard data"""
        if not self.db_manager.SessionLocal:
            return {}
        
        try:
            session = self.db_manager.SessionLocal()
            
            # Get overall summary
            summary_query = text("""
                SELECT 
                    COUNT(DISTINCT sf.id) as total_files,
                    COUNT(DISTINCT e.id) as total_evaluations,
                    COUNT(DISTINCT q.id) as total_quests,
                    ROUND(AVG(e.numeric_score), 2) as overall_avg_score,
                    COUNT(CASE WHEN e.execution_success = true THEN 1 END)::float / 
                    NULLIF(COUNT(e.id), 0) * 100 as overall_success_rate,
                    COUNT(CASE WHEN e.evaluation_date >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as evaluations_last_week,
                    COUNT(CASE WHEN r.priority = 'High' THEN 1 END) as high_priority_recommendations
                FROM sql_files sf
                LEFT JOIN evaluations e ON sf.id = e.sql_file_id
                LEFT JOIN subcategories sc ON sf.subcategory_id = sc.id
                LEFT JOIN quests q ON sc.quest_id = q.id
                LEFT JOIN recommendations r ON e.id = r.evaluation_id
            """)
            
            summary_result = session.execute(summary_query).fetchone()
            
            # Get quest performance
            quest_performance = session.execute(text("SELECT * FROM quest_performance")).fetchall()
            
            # Get recent evaluations
            recent_evaluations = session.execute(text("""
                SELECT * FROM evaluation_summary 
                ORDER BY evaluation_date DESC 
                LIMIT 10
            """)).fetchall()
            
            # Get top patterns
            top_patterns = session.execute(text("""
                SELECT pattern_name, pattern_display_name, evaluations_using_pattern, avg_eval_confidence
                FROM pattern_analysis 
                WHERE evaluations_using_pattern > 0
                ORDER BY evaluations_using_pattern DESC 
                LIMIT 10
            """)).fetchall()
            
            # Get improvement opportunities
            improvements = session.execute(text("""
                SELECT * FROM get_improvement_opportunities(6) LIMIT 10
            """)).fetchall()
            
            session.close()
            
            return {
                'summary': {
                    'total_files': summary_result.total_files or 0,
                    'total_evaluations': summary_result.total_evaluations or 0,
                    'total_quests': summary_result.total_quests or 0,
                    'overall_avg_score': float(summary_result.overall_avg_score or 0),
                    'overall_success_rate': float(summary_result.overall_success_rate or 0),
                    'evaluations_last_week': summary_result.evaluations_last_week or 0,
                    'high_priority_recommendations': summary_result.high_priority_recommendations or 0
                },
                'quest_performance': [dict(row._mapping) for row in quest_performance],
                'recent_evaluations': [dict(row._mapping) for row in recent_evaluations],
                'top_patterns': [dict(row._mapping) for row in top_patterns],
                'improvement_opportunities': [dict(row._mapping) for row in improvements]
            }
            
        except Exception as e:
            print(f"❌ Error getting dashboard data: {e}")
            return {'error': str(e)}
    
    def get_detailed_analytics(self, quest_name: str = None, days: int = 30) -> Dict[str, Any]:
        """Get detailed analytics for a specific quest or overall"""
        if not self.db_manager.SessionLocal:
            return {}
        
        try:
            session = self.db_manager.SessionLocal()
            
            # Build base filter
            date_filter = f"AND e.evaluation_date >= CURRENT_DATE - INTERVAL '{days} days'"
            quest_filter = f"AND q.name = '{quest_name}'" if quest_name else ""
            
            # Score distribution
            score_dist_query = text(f"""
                SELECT 
                    e.letter_grade,
                    COUNT(*) as count,
                    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 1) as percentage
                FROM evaluations e
                JOIN sql_files sf ON e.sql_file_id = sf.id
                JOIN subcategories sc ON sf.subcategory_id = sc.id
                JOIN quests q ON sc.quest_id = q.id
                WHERE 1=1 {date_filter} {quest_filter}
                GROUP BY e.letter_grade
                ORDER BY 
                    CASE e.letter_grade 
                        WHEN 'A+' THEN 1 WHEN 'A' THEN 2 WHEN 'A-' THEN 3
                        WHEN 'B+' THEN 4 WHEN 'B' THEN 5 WHEN 'B-' THEN 6
                        WHEN 'C+' THEN 7 WHEN 'C' THEN 8 WHEN 'C-' THEN 9
                        WHEN 'D+' THEN 10 WHEN 'D' THEN 11 WHEN 'D-' THEN 12
                        WHEN 'F' THEN 13 ELSE 14
                    END
            """)
            
            score_distribution = session.execute(score_dist_query).fetchall()
            
            # Pattern usage over time
            pattern_trends_query = text(f"""
                SELECT 
                    DATE(e.evaluation_date) as evaluation_date,
                    p.category,
                    COUNT(DISTINCT ep.id) as pattern_usage_count
                FROM evaluations e
                JOIN evaluation_patterns ep ON e.id = ep.evaluation_id
                JOIN sql_patterns p ON ep.pattern_id = p.id
                JOIN sql_files sf ON e.sql_file_id = sf.id
                JOIN subcategories sc ON sf.subcategory_id = sc.id
                JOIN quests q ON sc.quest_id = q.id
                WHERE 1=1 {date_filter} {quest_filter}
                GROUP BY DATE(e.evaluation_date), p.category
                ORDER BY evaluation_date, p.category
            """)
            
            pattern_trends = session.execute(pattern_trends_query).fetchall()
            
            # Performance metrics over time
            performance_query = text(f"""
                SELECT 
                    DATE(e.evaluation_date) as evaluation_date,
                    COUNT(*) as evaluation_count,
                    ROUND(AVG(e.numeric_score), 2) as avg_score,
                    ROUND(AVG(e.execution_time_ms), 2) as avg_execution_time,
                    COUNT(CASE WHEN e.execution_success = true THEN 1 END)::float / 
                    NULLIF(COUNT(*), 0) * 100 as success_rate
                FROM evaluations e
                JOIN sql_files sf ON e.sql_file_id = sf.id
                JOIN subcategories sc ON sf.subcategory_id = sc.id
                JOIN quests q ON sc.quest_id = q.id
                WHERE 1=1 {date_filter} {quest_filter}
                GROUP BY DATE(e.evaluation_date)
                ORDER BY evaluation_date
            """)
            
            performance_trends = session.execute(performance_query).fetchall()
            
            session.close()
            
            return {
                'period_days': days,
                'quest_filter': quest_name,
                'score_distribution': [dict(row._mapping) for row in score_distribution],
                'pattern_trends': [dict(row._mapping) for row in pattern_trends],
                'performance_trends': [dict(row._mapping) for row in performance_trends]
            }
            
        except Exception as e:
            print(f"❌ Error getting detailed analytics: {e}")
            return {'error': str(e)}