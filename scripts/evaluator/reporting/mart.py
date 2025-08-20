#!/usr/bin/env python3
"""
Database Views and Analytics Functions for SQL Adventure AI Evaluator
Provides comprehensive reporting and analysis capabilities
"""

from sqlalchemy import text
from typing import Dict, Any, List

from database.manager import DatabaseManager

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
            e.last_evaluated as evaluation_date,
            q.name as quest_name,
            q.display_name as quest_display_name,
            sc.name as subcategory_name,
            sc.display_name as subcategory_display_name,
            sf.filename,
            sf.file_path,
            e.overall_assessment,
            e.numeric_score,
            e.letter_grade,
            em.execution_success,
            em.execution_time_ms,
            em.output_lines,
            em.result_sets,
            em.rows_affected,
            em.error_count,
            em.warning_count,
            e.evaluator_model,
            a.technical_score,
            a.educational_score,
            a.difficulty_level as assessed_difficulty,
            a.estimated_time_minutes,
            -- Pattern counts (from JSONB field)
            COALESCE(json_array_length(e.detected_patterns), 0) as pattern_count,
            -- Recommendation counts
            (SELECT COUNT(*) FROM recommendations r WHERE r.evaluation_id = e.id) as recommendation_count,
            -- High priority recommendation count
            (SELECT COUNT(*) FROM recommendations r WHERE r.evaluation_id = e.id AND r.priority = 'High') as high_priority_recommendations
        FROM evaluations e
        JOIN sql_files sf ON e.sql_file_id = sf.id
        JOIN subcategories sc ON sf.subcategory_id = sc.id
        JOIN quests q ON e.quest_id = q.id
        LEFT JOIN execution_metadata em ON e.id = em.evaluation_id
        LEFT JOIN analyses a ON e.id = a.evaluation_id
        ORDER BY evaluation_date DESC;
        """
        
        conn.execute(text(view_sql))
    
    def _create_quest_performance_view(self, conn):
        """Create quest performance analytics view"""
        quest_performance_sql = """
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
            
            -- Success metrics (from execution_metadata)
            COUNT(CASE WHEN em.execution_success = true THEN 1 END) as successful_executions,
            ROUND(
                COUNT(CASE WHEN em.execution_success = true THEN 1 END)::numeric / 
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
            
            -- Performance metrics (from execution_metadata)
            ROUND(AVG(em.execution_time_ms), 2) as avg_execution_time_ms,
            ROUND(AVG(em.output_lines), 2) as avg_output_lines,
            ROUND(AVG(em.error_count), 2) as avg_error_count,
            
            -- Educational metrics (from analysis)
            ROUND(AVG(a.estimated_time_minutes), 2) as avg_estimated_time,
            ROUND(AVG(a.educational_score), 2) as avg_educational_score,
            
            -- Latest evaluation
            MAX(e.last_evaluated) as latest_evaluation_date,
            COUNT(CASE WHEN e.last_evaluated >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as evaluations_last_7_days,
            COUNT(CASE WHEN e.last_evaluated >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as evaluations_last_30_days
            
        FROM quests q
        LEFT JOIN subcategories sc ON q.id = sc.quest_id
        LEFT JOIN sql_files sf ON sc.id = sf.subcategory_id
        LEFT JOIN evaluations e ON sf.id = e.sql_file_id
        LEFT JOIN execution_metadata em ON e.id = em.evaluation_id
        LEFT JOIN analyses a ON e.id = a.evaluation_id
        GROUP BY q.id, q.name, q.display_name, q.difficulty_level, q.order_index
        ORDER BY q.order_index;
        """
        
        conn.execute(text(quest_performance_sql))
    
    def _create_pattern_analysis_view(self, conn):
        """Create pattern analysis view (simplified for JSON type)"""
        pattern_analysis_sql = """
        CREATE OR REPLACE VIEW pattern_analysis AS
        SELECT 
            p.id,
            p.name as pattern_name,
            p.display_name as pattern_display_name,
            p.category,
            p.complexity_level,
            
            -- Count evaluations using this pattern (simplified approach)
            (
                SELECT COUNT(*)
                FROM evaluations e
                WHERE e.detected_patterns IS NOT NULL
                AND e.detected_patterns::text LIKE '%"' || p.name || '"%'
            ) as evaluations_using_pattern,
            
            -- Performance when pattern is used (simplified)
            (
                SELECT ROUND(AVG(e.numeric_score), 2)
                FROM evaluations e
                WHERE e.detected_patterns IS NOT NULL
                AND e.detected_patterns::text LIKE '%"' || p.name || '"%'
            ) as avg_score_when_used,
            
            -- Average confidence (placeholder - would need proper JSON parsing)
            (
                SELECT ROUND(AVG(e.numeric_score), 2) / 10.0  -- Normalized confidence estimate
                FROM evaluations e
                WHERE e.detected_patterns IS NOT NULL
                AND e.detected_patterns::text LIKE '%"' || p.name || '"%'
            ) as avg_eval_confidence,
            
            -- Pattern quality analysis (based on grades)
            (
                SELECT COUNT(*)
                FROM evaluations e
                WHERE e.detected_patterns IS NOT NULL
                AND e.detected_patterns::text LIKE '%"' || p.name || '"%'
                AND e.letter_grade IN ('A+', 'A', 'A-')
            ) as excellent_usage,
            
            (
                SELECT COUNT(*)
                FROM evaluations e
                WHERE e.detected_patterns IS NOT NULL
                AND e.detected_patterns::text LIKE '%"' || p.name || '"%'
                AND e.letter_grade IN ('B+', 'B', 'B-')
            ) as good_usage,
            
            -- Quest distribution
            (
                SELECT string_agg(DISTINCT q.display_name, ', ')
                FROM evaluations e
                JOIN sql_files sf ON e.sql_file_id = sf.id
                JOIN subcategories sc ON sf.subcategory_id = sc.id
                JOIN quests q ON sc.quest_id = q.id
                WHERE e.detected_patterns IS NOT NULL
                AND e.detected_patterns::text LIKE '%"' || p.name || '"%'
            ) as used_in_quests,
            
            -- Recent usage
            (
                SELECT MAX(e.last_evaluated)
                FROM evaluations e
                WHERE e.detected_patterns IS NOT NULL
                AND e.detected_patterns::text LIKE '%"' || p.name || '"%'
            ) as last_detected_date
            
        FROM sql_patterns p
        ORDER BY evaluations_using_pattern DESC NULLS LAST, p.name;
        """
        
        conn.execute(text(pattern_analysis_sql))
    
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
            MAX(e.last_evaluated) as last_evaluation_date,
            
            -- Latest evaluation details
            (SELECT e2.overall_assessment FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.last_evaluated DESC LIMIT 1) as latest_assessment,
            (SELECT e2.numeric_score FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.last_evaluated DESC LIMIT 1) as latest_score,
            (SELECT e2.letter_grade FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.last_evaluated DESC LIMIT 1) as latest_grade,
            (SELECT em2.execution_success FROM evaluations e2 
             LEFT JOIN execution_metadata em2 ON e2.id = em2.evaluation_id
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.last_evaluated DESC LIMIT 1) as latest_execution_success,
            
            -- Score trends
            CASE 
                WHEN COUNT(e.id) >= 2 THEN
                    (SELECT e_latest.numeric_score FROM evaluations e_latest 
                     WHERE e_latest.sql_file_id = sf.id 
                     ORDER BY e_latest.last_evaluated DESC LIMIT 1) -
                    (SELECT e_prev.numeric_score FROM evaluations e_prev 
                     WHERE e_prev.sql_file_id = sf.id 
                     ORDER BY e_prev.last_evaluated DESC LIMIT 1 OFFSET 1)
                ELSE NULL
            END as score_trend,
            
            -- Pattern complexity (from JSON patterns in latest evaluation)
            (SELECT COALESCE(json_array_length(e2.detected_patterns), 0) FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.last_evaluated DESC LIMIT 1) as pattern_count,
            
            -- Extract pattern complexities from latest evaluation's JSON
            (SELECT CASE 
                WHEN e2.detected_patterns IS NOT NULL 
                THEN 'Mixed' -- Simplified since JSON patterns don't include complexity directly
                ELSE 'None'
            END FROM evaluations e2 
             WHERE e2.sql_file_id = sf.id 
             ORDER BY e2.last_evaluated DESC LIMIT 1) as pattern_complexities,
            
            -- Content hash for change detection
            sf.content_hash,
            
            -- Status classification
            CASE 
                WHEN COUNT(e.id) = 0 THEN 'Never Evaluated'
                WHEN MAX(e.last_evaluated) < CURRENT_DATE - INTERVAL '30 days' THEN 'Outdated'
                WHEN (SELECT e2.overall_assessment FROM evaluations e2 
                      WHERE e2.sql_file_id = sf.id 
                      ORDER BY e2.last_evaluated DESC LIMIT 1) = 'PASS' THEN 'Passing'
                WHEN (SELECT e2.overall_assessment FROM evaluations e2 
                      WHERE e2.sql_file_id = sf.id 
                      ORDER BY e2.last_evaluated DESC LIMIT 1) = 'FAIL' THEN 'Failing'
                ELSE 'Needs Review'
            END as status
            
        FROM sql_files sf
        JOIN subcategories sc ON sf.subcategory_id = sc.id
        JOIN quests q ON sc.quest_id = q.id
        LEFT JOIN evaluations e ON sf.id = e.sql_file_id
        GROUP BY sf.id, sf.filename, sf.file_path, sf.display_name, sf.created_at, 
                 sf.last_modified, sf.content_hash, q.name, q.display_name, q.order_index,
                 sc.name, sc.display_name, sc.order_index
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
            e.id as evaluation_id,
            e.overall_assessment,
            e.numeric_score,
            e.letter_grade,
            em.execution_success,
            
            -- File context
            sf.filename,
            sf.file_path,
            q.name as quest_name,
            q.display_name as quest_display_name,
            sc.name as subcategory_name,
            sc.display_name as subcategory_display_name,
            
            -- Technical scores
            a.technical_score,
            a.educational_score,
            
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
        LEFT JOIN execution_metadata em ON e.id = em.evaluation_id
        LEFT JOIN analyses a ON e.id = a.evaluation_id
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
        
        # Function to get pattern usage trends - simplified for JSON patterns
        trend_function_sql = """
        CREATE OR REPLACE FUNCTION get_pattern_usage_trends(days_param INTEGER DEFAULT 30)
        RETURNS TABLE(
            pattern_name VARCHAR,
            usage_count BIGINT,
            avg_quality_score NUMERIC,
            trend VARCHAR
        ) AS $$
        BEGIN
            RETURN QUERY
            WITH recent_usage AS (
                SELECT 
                    p.name,
                    (
                        SELECT COUNT(*)
                        FROM analyses a
                        JOIN evaluations e ON a.evaluation_id = e.id
                        WHERE JSON_CONTAINS(a.detected_patterns, JSON_QUOTE(p.name))
                        AND e.evaluation_date >= CURRENT_DATE - (days_param || ' days')::INTERVAL
                    ) as recent_count
                FROM sql_patterns p
            ),
            previous_usage AS (
                SELECT 
                    p.name,
                    (
                        SELECT COUNT(*)
                        FROM analyses a
                        JOIN evaluations e ON a.evaluation_id = e.id
                        WHERE JSON_CONTAINS(a.detected_patterns, JSON_QUOTE(p.name))
                        AND e.evaluation_date >= CURRENT_DATE - (days_param * 2 || ' days')::INTERVAL
                        AND e.evaluation_date < CURRENT_DATE - (days_param || ' days')::INTERVAL
                    ) as previous_count
                FROM sql_patterns p
            )
            SELECT 
                ru.name::VARCHAR,
                ru.recent_count,
                3.0::NUMERIC,  -- Simplified since we don't track confidence anymore
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
        
        conn.execute(text(trend_function_sql))

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
    
    def get_comprehensive_summary(self) -> Dict[str, Any]:
        """Get comprehensive system summary with enhanced insights"""
        if not self.db_manager.SessionLocal:
            return {'error': 'Database connection not available'}
        
        try:
            session = self.db_manager.SessionLocal()
            
            # Enhanced summary with more detailed metrics
            summary_query = text("""
                WITH quest_stats AS (
                    SELECT 
                        q.id as quest_id,
                        q.name as quest_name,
                        q.display_name as quest_display_name,
                        COUNT(DISTINCT sc.id) as subcategory_count,
                        COUNT(DISTINCT sf.id) as file_count,
                        COUNT(DISTINCT e.id) as evaluation_count,
                        ROUND(AVG(e.numeric_score), 2) as avg_score,
                        COUNT(CASE WHEN em.execution_success = true THEN 1 END)::float / 
                        NULLIF(COUNT(e.id), 0) * 100 as success_rate,
                        MAX(e.last_evaluated) as last_evaluated
                    FROM quests q
                    LEFT JOIN subcategories sc ON q.id = sc.quest_id
                    LEFT JOIN sql_files sf ON sc.id = sf.subcategory_id
                    LEFT JOIN evaluations e ON sf.id = e.sql_file_id
                    LEFT JOIN execution_metadata em ON e.id = em.evaluation_id
                    GROUP BY q.id, q.name, q.display_name
                ),
                pattern_stats AS (
                    SELECT 
                        COUNT(DISTINCT sp.id) as total_patterns,
                        COUNT(DISTINCT sp.category) as pattern_categories,
                        COUNT(DISTINCT e.id) as analyses_with_patterns
                    FROM sql_patterns sp
                    LEFT JOIN evaluations e ON e.detected_patterns::text LIKE '%"' || sp.name || '"%'
                ),
                recent_activity AS (
                    SELECT 
                        COUNT(CASE WHEN e.last_evaluated >= CURRENT_DATE - INTERVAL '1 day' THEN 1 END) as evals_last_day,
                        COUNT(CASE WHEN e.last_evaluated >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as evals_last_week,
                        COUNT(CASE WHEN e.last_evaluated >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as evals_last_month
                    FROM evaluations e
                ),
                quality_metrics AS (
                    SELECT 
                        COUNT(CASE WHEN e.letter_grade IN ('A+', 'A', 'A-') THEN 1 END) as excellent_evaluations,
                        COUNT(CASE WHEN e.letter_grade IN ('B+', 'B', 'B-') THEN 1 END) as good_evaluations,
                        COUNT(CASE WHEN e.letter_grade IN ('C+', 'C', 'C-') THEN 1 END) as fair_evaluations,
                        COUNT(CASE WHEN e.letter_grade IN ('D+', 'D', 'D-', 'F') THEN 1 END) as poor_evaluations,
                        COUNT(DISTINCT CASE WHEN r.priority = 'High' THEN e.id END) as high_priority_issues,
                        COUNT(DISTINCT CASE WHEN r.priority = 'Medium' THEN e.id END) as medium_priority_issues
                    FROM evaluations e
                    LEFT JOIN recommendations r ON e.id = r.evaluation_id
                )
                SELECT 
                    (SELECT COUNT(*) FROM quests) as total_quests,
                    (SELECT COUNT(*) FROM subcategories) as total_subcategories,
                    (SELECT COUNT(*) FROM sql_files) as total_sql_files,
                    (SELECT COUNT(*) FROM evaluations) as total_evaluations,
                    (SELECT ROUND(AVG(numeric_score), 2) FROM evaluations WHERE numeric_score IS NOT NULL) as overall_avg_score,
                    (SELECT COUNT(*)::float / NULLIF((SELECT COUNT(*) FROM evaluations), 0) * 100 
                     FROM evaluations e JOIN execution_metadata em ON e.id = em.evaluation_id 
                     WHERE em.execution_success = true) as overall_success_rate,
                    ps.total_patterns,
                    ps.pattern_categories,
                    ps.analyses_with_patterns,
                    ra.evals_last_day,
                    ra.evals_last_week,
                    ra.evals_last_month,
                    qm.excellent_evaluations,
                    qm.good_evaluations,
                    qm.fair_evaluations,
                    qm.poor_evaluations,
                    qm.high_priority_issues,
                    qm.medium_priority_issues
                FROM pattern_stats ps, recent_activity ra, quality_metrics qm
            """)
            
            summary_result = session.execute(summary_query).fetchone()
            
            # Get quest breakdown
            quest_breakdown_query = text("""
                SELECT 
                    q.name as quest_name,
                    q.display_name as quest_display_name,
                    COUNT(DISTINCT sc.id) as subcategory_count,
                    COUNT(DISTINCT sf.id) as file_count,
                    COUNT(DISTINCT e.id) as evaluation_count,
                    ROUND(AVG(e.numeric_score), 2) as avg_score,
                    COUNT(CASE WHEN em.execution_success = true THEN 1 END)::float / 
                    NULLIF(COUNT(e.id), 0) * 100 as success_rate,
                    MAX(e.last_evaluated) as last_evaluated,
                    COUNT(CASE WHEN e.letter_grade IN ('A+', 'A', 'A-') THEN 1 END) as excellent_count,
                    COUNT(CASE WHEN r.priority = 'High' THEN 1 END) as high_priority_issues
                FROM quests q
                LEFT JOIN subcategories sc ON q.id = sc.quest_id
                LEFT JOIN sql_files sf ON sc.id = sf.subcategory_id
                LEFT JOIN evaluations e ON sf.id = e.sql_file_id
                LEFT JOIN execution_metadata em ON e.id = em.evaluation_id
                LEFT JOIN recommendations r ON e.id = r.evaluation_id
                GROUP BY q.id, q.name, q.display_name
                ORDER BY q.name
            """)
            
            quest_breakdown = session.execute(quest_breakdown_query).fetchall()
            
            # Get top performing files
            top_performers_query = text("""
                SELECT 
                    sf.file_path as relative_path,
                    q.display_name as quest_name,
                    sc.name as subcategory_name,
                    e.letter_grade,
                    e.numeric_score,
                    e.last_evaluated as evaluation_date,
                    em.execution_time_ms,
                    CASE 
                        WHEN e.detected_patterns IS NOT NULL 
                        THEN json_array_length(e.detected_patterns)
                        ELSE 0
                    END as pattern_count
                FROM sql_files sf
                JOIN evaluations e ON sf.id = e.sql_file_id
                JOIN subcategories sc ON sf.subcategory_id = sc.id
                JOIN quests q ON sc.quest_id = q.id
                LEFT JOIN execution_metadata em ON e.id = em.evaluation_id
                WHERE e.letter_grade IN ('A+', 'A', 'A-')
                ORDER BY e.numeric_score DESC, e.last_evaluated DESC
                LIMIT 10
            """)
            
            top_performers = session.execute(top_performers_query).fetchall()
            
            # Get pattern insights
            pattern_insights_query = text("""
                SELECT 
                    sp.display_name,
                    sp.category,
                    sp.complexity_level,
                    COUNT(CASE WHEN e.detected_patterns::text LIKE '%"' || sp.name || '"%' THEN 1 END) as usage_count,
                    ROUND(AVG(CASE WHEN e.detected_patterns::text LIKE '%"' || sp.name || '"%' THEN e.numeric_score END), 2) as avg_score_when_used
                FROM sql_patterns sp
                LEFT JOIN evaluations e ON e.detected_patterns IS NOT NULL
                GROUP BY sp.id, sp.display_name, sp.category, sp.complexity_level
                HAVING COUNT(CASE WHEN e.detected_patterns::text LIKE '%"' || sp.name || '"%' THEN 1 END) > 0
                ORDER BY usage_count DESC, avg_score_when_used DESC
                LIMIT 10
            """)
            
            pattern_insights = session.execute(pattern_insights_query).fetchall()
            
            session.close()
            
            # Calculate additional insights
            total_evals = summary_result.total_evaluations or 0
            excellent_percentage = round((summary_result.excellent_evaluations or 0) / max(total_evals, 1) * 100, 1)
            active_percentage = round((summary_result.evals_last_week or 0) / max(total_evals, 1) * 100, 1) if total_evals > 0 else 0
            
            return {
                'system_overview': {
                    'total_quests': summary_result.total_quests or 0,
                    'total_subcategories': summary_result.total_subcategories or 0,
                    'total_sql_files': summary_result.total_sql_files or 0,
                    'total_evaluations': total_evals,
                    'total_patterns': summary_result.total_patterns or 0,
                    'pattern_categories': summary_result.pattern_categories or 0
                },
                'quality_metrics': {
                    'overall_avg_score': float(summary_result.overall_avg_score or 0),
                    'overall_success_rate': round(float(summary_result.overall_success_rate or 0), 1),
                    'excellent_evaluations': summary_result.excellent_evaluations or 0,
                    'excellent_percentage': excellent_percentage,
                    'good_evaluations': summary_result.good_evaluations or 0,
                    'fair_evaluations': summary_result.fair_evaluations or 0,
                    'poor_evaluations': summary_result.poor_evaluations or 0,
                    'high_priority_issues': summary_result.high_priority_issues or 0,
                    'medium_priority_issues': summary_result.medium_priority_issues or 0
                },
                'activity_metrics': {
                    'evaluations_last_day': summary_result.evals_last_day or 0,
                    'evaluations_last_week': summary_result.evals_last_week or 0,
                    'evaluations_last_month': summary_result.evals_last_month or 0,
                    'recent_activity_percentage': active_percentage
                },
                'quest_breakdown': [dict(row._mapping) for row in quest_breakdown],
                'top_performers': [dict(row._mapping) for row in top_performers],
                'pattern_insights': [dict(row._mapping) for row in pattern_insights],
                'insights': {
                    'most_active_quest': max(quest_breakdown, key=lambda x: x.evaluation_count or 0).quest_display_name if quest_breakdown else 'None',
                    'highest_scoring_quest': max(quest_breakdown, key=lambda x: x.avg_score or 0).quest_display_name if quest_breakdown else 'None',
                    'patterns_with_analysis': summary_result.analyses_with_patterns or 0,
                    'system_health': 'Excellent' if excellent_percentage > 70 else 'Good' if excellent_percentage > 50 else 'Needs Improvement'
                }
            }
            
        except Exception as e:
            print(f"❌ Error getting comprehensive summary: {e}")
            return {'error': str(e)}

    def get_dashboard_data(self) -> Dict[str, Any]:
        """Get comprehensive dashboard data"""
        if not self.db_manager.SessionLocal:
            return {}
        
        try:
            # Get the enhanced comprehensive summary
            comprehensive_data = self.get_comprehensive_summary()
            if 'error' in comprehensive_data:
                return comprehensive_data
            
            session = self.db_manager.SessionLocal()
            
            # Get recent evaluations
            recent_evaluations = session.execute(text("""
                SELECT * FROM evaluation_summary 
                ORDER BY evaluation_date DESC 
                LIMIT 10
            """)).fetchall()
            
            # Get improvement opportunities
            improvements = session.execute(text("""
                SELECT * FROM get_improvement_opportunities(6) LIMIT 10
            """)).fetchall()
            
            session.close()
            
            # Combine comprehensive summary with dashboard specific data
            return {
                **comprehensive_data,
                'recent_evaluations': [dict(row._mapping) for row in recent_evaluations],
                'improvement_opportunities': [dict(row._mapping) for row in improvements]
            }
            
        except Exception as e:
            print(f"❌ Error getting dashboard data: {e}")
            return {'error': str(e)}
            
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
            date_filter = f"AND e.last_evaluated >= CURRENT_DATE - INTERVAL '{days} days'"
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
            
            # Pattern usage over time - simplified for JSON patterns
            pattern_trends_query = text(f"""
                SELECT 
                    DATE(e.last_evaluated) as evaluation_date,
                    'Mixed' as category,  -- Simplified since we don't have pattern categories in JSON
                    COUNT(DISTINCT e.id) as pattern_usage_count
                FROM evaluations e
                JOIN analyses a ON e.id = a.evaluation_id
                JOIN sql_files sf ON e.sql_file_id = sf.id
                JOIN subcategories sc ON sf.subcategory_id = sc.id
                JOIN quests q ON sc.quest_id = q.id
                WHERE e.detected_patterns IS NOT NULL 
                AND json_array_length(e.detected_patterns) > 0
                {date_filter} {quest_filter}
                GROUP BY DATE(e.last_evaluated)
                ORDER BY evaluation_date
            """)
            
            pattern_trends = session.execute(pattern_trends_query).fetchall()
            
            # Performance metrics over time
            performance_query = text(f"""
                SELECT 
                    DATE(e.last_evaluated) as evaluation_date,
                    COUNT(*) as evaluation_count,
                    ROUND(AVG(e.numeric_score), 2) as avg_score,
                    ROUND(AVG(em.execution_time_ms), 2) as avg_execution_time,
                    COUNT(CASE WHEN em.execution_success = true THEN 1 END)::float / 
                    NULLIF(COUNT(*), 0) * 100 as success_rate
                FROM evaluations e
                JOIN sql_files sf ON e.sql_file_id = sf.id
                JOIN subcategories sc ON sf.subcategory_id = sc.id
                JOIN quests q ON sc.quest_id = q.id
                LEFT JOIN execution_metadata em ON e.id = em.evaluation_id
                WHERE 1=1 {date_filter} {quest_filter}
                GROUP BY DATE(e.last_evaluated)
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