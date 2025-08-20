import os
from pydantic_ai import Agent
from config import EvaluationConfig

config = EvaluationConfig()

# Ensure OpenAI API key is available as environment variable for pydantic_ai
if config.openai_api_key and not os.getenv("OPENAI_API_KEY"):
    os.environ["OPENAI_API_KEY"] = config.openai_api_key

intent_agent =  Agent(
    config.model_name,
    system_prompt="You are an expert in educational content analysis and curriculum design.",
    retries=3,
    output_retries=5
)

sql_instructor_agent = Agent(
    config.model_name,
    system_prompt="You are an expert SQL instructor and educational content analyst.",
    retries=3,
    output_retries=5
)

quality_assessor_agent = Agent(
    config.model_name,
    system_prompt="You are an expert in educational content quality assessment and improvement.",
    retries=3,
    output_retries=5
)

quest_summary_agent = Agent(
    config.model_name,
    output_type=str,
    retries=3,
    output_retries=5,
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

subcategory_summary_agent = Agent(
    config.model_name,
    output_type=str,
    retries=3,
    output_retries=5,
    system_prompt="""
    You are an expert SQL instructor. Your task is to analyze SQL files from a subcategory 
    and generate a concise, informative description of what this subcategory teaches.
    
    Focus on:
    - The specific SQL concepts covered in the files
    - The practical skills students will learn
    - How these exercises build understanding
    
    Be succinct but descriptive (1-2 sentences maximum).
    Avoid generic phrases - be specific about the SQL techniques taught.
    """
)

pattern_description_agent = Agent(
    config.model_name,
    output_type=str,
    retries=3,
    output_retries=5,
    system_prompt="""
    You are an expert SQL educator and pattern analyst. Your task is to analyze SQL patterns 
    and create comprehensive, educational descriptions that help learners understand:
    
    1. What the pattern does technically
    2. When and why to use it  
    3. Common variations and best practices
    4. Real-world applications and examples
    
    Write descriptions that are:
    - Clear and educational for SQL learners
    - Technically accurate
    - Practical with real-world context
    - 2-3 sentences maximum but information-rich
    
    Focus on the learning value and practical applications of each SQL pattern.
    """
)