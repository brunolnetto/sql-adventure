from pydantic_ai import Agent
from ..config import EvaluationConfig

config = EvaluationConfig()

intent_agent =  Agent(
    config.model_name,
    system_prompt="You are an expert in educational content analysis and curriculum design."
)

sql_instructor_agent = Agent(
    config.model_name,
    system_prompt="You are an expert SQL instructor and educational content analyst."
)

quality_assessor_agent = Agent(
    config.model_name,
    system_prompt="You are an expert in educational content quality assessment and improvement."
)