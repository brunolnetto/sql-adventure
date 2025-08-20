import os
from pydantic_ai import Agent
from config import EvaluationConfig

config = EvaluationConfig()

# Ensure OpenAI API key is available as environment variable for pydantic_ai
if config.openai_api_key and not os.getenv("OPENAI_API_KEY"):
    os.environ["OPENAI_API_KEY"] = config.openai_api_key

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

quest_summary_agent = Agent(
    config.model_name,
    output_type=str,
    system_prompt="""
    You are an expert SQL instructor. Your task is to analyze aggregated quest content 
    and generate a succinct but elucidative description of what the quest covers.
    
    Focus on:
    - What SQL concepts and techniques are taught
    - The learning progression and practical outcomes
    - Key skills students will develop
    
    Keep descriptions concise but informative (2-3 sentences maximum).
    """
)