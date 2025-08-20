"""
Unified agent orchestration for SQL evaluation pipeline.
Simplifies agent coordination and provides a single entry point.
"""

from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from datetime import datetime
from .agents import intent_agent, sql_instructor_agent, quality_assessor_agent, quest_summary_agent
from .models import EvaluationResult, Intent, LLMAnalysis
import asyncio


@dataclass
class EvaluationContext:
    """Context object passed between agents"""
    sql_content: str
    quest_name: str
    metadata: Dict[str, Any]
    patterns: List[str] = None
    difficulty: str = "Intermediate"


class AgentOrchestrator:
    """
    Simplified agent orchestration with pipeline pattern.
    Handles agent coordination, error recovery, and result aggregation.
    """
    
    def __init__(self):
        self.agents = {
            "intent": intent_agent,
            "instructor": sql_instructor_agent,
            "quality": quality_assessor_agent,
            "summary": quest_summary_agent
        }
        self.pipeline_steps = ["intent", "instructor", "quality"]
    
    async def evaluate_sql(self, context: EvaluationContext) -> EvaluationResult:
        """
        Run the complete evaluation pipeline.
        
        Args:
            context: Evaluation context with SQL content and metadata
            
        Returns:
            Complete evaluation result
        """
        results = {}
        
        for step in self.pipeline_steps:
            try:
                results[step] = await self._run_agent_step(step, context, results)
            except Exception as e:
                print(f"⚠️  Agent {step} failed: {e}")
                results[step] = self._get_fallback_result(step, context)
        
        return self._aggregate_results(context, results)
    
    async def _run_agent_step(self, step: str, context: EvaluationContext, previous_results: Dict) -> Any:
        """Run a single agent step with context awareness"""
        agent = self.agents[step]
        
        if step == "intent":
            return await self._run_intent_analysis(agent, context)
        elif step == "instructor":
            return await self._run_instructor_analysis(agent, context, previous_results.get("intent"))
        elif step == "quality":
            return await self._run_quality_assessment(agent, context, previous_results)
    
    async def _run_intent_analysis(self, agent, context: EvaluationContext) -> Intent:
        """Run intent analysis with standardized prompt"""
        prompt = f"""
        Analyze this SQL exercise for educational intent:
        
        Quest: {context.quest_name}
        Difficulty: {context.difficulty}
        
        SQL Code:
        {context.sql_content}
        
        Metadata: {context.metadata}
        
        Provide comprehensive educational intent analysis.
        """
        return await agent.run(prompt, output_type=Intent)
    
    async def _run_instructor_analysis(self, agent, context: EvaluationContext, intent: Optional[Intent]) -> LLMAnalysis:
        """Run instructor analysis with intent context"""
        intent_context = f"Educational Intent: {intent.detailed_purpose}" if intent else ""
        
        prompt = f"""
        Analyze this SQL code from an educational perspective:
        
        {intent_context}
        
        SQL Code:
        {context.sql_content}
        
        Provide technical and educational analysis.
        """
        return await agent.run(prompt, output_type=LLMAnalysis)
    
    async def _run_quality_assessment(self, agent, context: EvaluationContext, previous_results: Dict) -> Any:
        """Run quality assessment with full context"""
        prompt = f"""
        Assess the quality of this SQL exercise:
        
        Context: {context.quest_name}
        Intent: {previous_results.get('intent', {}).get('detailed_purpose', 'Unknown')}
        Technical Analysis: {previous_results.get('instructor', {}).get('technical_analysis', 'None')}
        
        SQL Code:
        {context.sql_content}
        
        Provide comprehensive quality assessment.
        """
        return await agent.run(prompt)
    
    def _get_fallback_result(self, step: str, context: EvaluationContext) -> Any:
        """Provide fallback results when agents fail"""
        fallbacks = {
            "intent": Intent(
                detailed_purpose=f"SQL exercise in {context.quest_name}",
                educational_context="Database training",
                real_world_applicability="General SQL skills",
                specific_skills=["SQL basics"]
            ),
            "instructor": {"analysis": "Basic SQL analysis", "difficulty": context.difficulty},
            "quality": {"grade": "C", "feedback": "Automated assessment unavailable"}
        }
        return fallbacks.get(step, {})
    
    def _aggregate_results(self, context: EvaluationContext, results: Dict) -> EvaluationResult:
        """Aggregate all agent results into final evaluation"""
        return EvaluationResult(
            metadata=context.metadata,
            intent=results.get("intent"),
            llm_analysis=results.get("instructor"),
            quality_assessment=results.get("quality"),
            evaluated_at=datetime.now()
        )


# Simplified interface for the evaluator
async def evaluate_sql_simple(sql_content: str, quest_name: str, metadata: Dict[str, Any]) -> EvaluationResult:
    """
    Simplified single-function interface for SQL evaluation.
    
    Usage:
        result = await evaluate_sql_simple(sql_code, "data-modeling", {"difficulty": "Advanced"})
    """
    orchestrator = AgentOrchestrator()
    context = EvaluationContext(
        sql_content=sql_content,
        quest_name=quest_name,
        metadata=metadata
    )
    return await orchestrator.evaluate_sql(context)
