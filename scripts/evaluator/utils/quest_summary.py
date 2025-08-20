"""
Simple, agnostic quest summarizer.
Takes aggregated text content and returns a succinct but elucidative summary.
Uses dependency injection to avoid circular imports.
"""

from typing import Optional


def _generate_fallback_description(content: str) -> str:
    """Generate simple fallback description when AI is unavailable."""
    lines = content.split('\n')
    topics = []
    for line in lines[:10]:
        if any(keyword in line.lower() for keyword in ['modeling', 'performance', 'window', 'json', 'recursive']):
            topics.append(line.strip())
    
    if topics:
        return f"SQL training covering {', '.join(topics[:3])} and related database concepts."
    else:
        return "Comprehensive SQL training covering essential database concepts and practical skills."


async def generate_quest_description_ai(aggregated_content: str) -> str:
    """
    Generate AI-powered quest description from aggregated content.
    Uses dependency injection to get the agent.
    
    Args:
        aggregated_content: All quest content (headers, subcategories, patterns) as single text
        
    Returns:
        Succinct but elucidative quest description
    """
    try:
        # Use dependency injection to avoid circular imports
        from ..core.container import get_quest_summary_agent
        agent = get_quest_summary_agent()
        
        prompt = f"""
        Analyze this SQL quest content and generate a succinct description:
        
        {aggregated_content}
        
        Generate a 2-3 sentence description that clearly explains what this quest teaches 
        and what practical skills students will develop.
        """
        
        result = await agent.run(prompt)
        return result.data
    except Exception as e:
        print(f"⚠️  AI summarization failed: {e}")
        return _generate_fallback_description(aggregated_content)


def generate_quest_description_fallback(aggregated_content: str) -> str:
    """
    Generate fallback quest description when AI is unavailable.
    
    Args:
        aggregated_content: All quest content as single text
        
    Returns:
        Basic quest description
    """
    # Extract key information from aggregated content
    lines = aggregated_content.split('\n')
    topics = []
    quest_type = "SQL"
    
    for line in lines[:20]:  # Check first 20 lines
        line_lower = line.lower()
        if any(keyword in line_lower for keyword in ['modeling', 'performance', 'window', 'json', 'recursive', 'normalization']):
            topics.append(line.strip()[:50])  # Truncate long lines
        if 'quest:' in line_lower or 'title:' in line_lower:
            quest_type = line.split(':')[-1].strip()
    
    if topics:
        return f"Comprehensive {quest_type} training covering {', '.join(topics[:3])} and related SQL concepts."
    else:
        return f"SQL training module covering essential database concepts and practical skills."
