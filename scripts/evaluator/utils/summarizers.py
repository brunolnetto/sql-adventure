"""
AI-powered summarization agents for SQL Adventure content.
Provides unified summarization for quests and subcategories using dependency injection.
"""

import asyncio
from pathlib import Path
from typing import Optional
from utils.discovery import MetadataExtractor


# =============================================================================
# QUEST SUMMARIZATION
# =============================================================================

async def generate_quest_description_ai(aggregated_content: str) -> str:
    """
    Generate AI-powered quest description from aggregated content.
    
    Args:
        aggregated_content: All quest content (headers, subcategories, patterns) as single text
        
    Returns:
        Succinct but elucidative quest description
    """
    try:
        from core.agents import quest_summary_agent
        
        prompt = f"""
        Analyze this SQL quest content and generate a succinct description:
        
        {aggregated_content}
        
        Generate a 2-3 sentence description that clearly explains what this quest teaches 
        and what practical skills students will develop.
        """
        
        result = await quest_summary_agent.run(prompt)
        return result.data.strip()
    except Exception as e:
        print(f"⚠️  AI quest summarization failed: {e}")
        return generate_quest_description_fallback(aggregated_content)


def generate_quest_description_fallback(aggregated_content: str) -> str:
    """
    Generate fallback quest description when AI is unavailable.
    
    Args:
        aggregated_content: All quest content as single text
        
    Returns:
        Basic quest description
    """
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


# =============================================================================
# SUBCATEGORY SUMMARIZATION
# =============================================================================

async def generate_subcategory_description_ai(subcategory_path: Path) -> str:
    """
    Generate a subcategory description using AI analysis of SQL files.
    
    Args:
        subcategory_path: Path to the subcategory directory
        
    Returns:
        AI-generated description of the subcategory content
    """
    try:
        from core.agents import subcategory_summary_agent
        
        # Collect content from all SQL files in the subcategory
        file_info = []
        
        for sql_file in subcategory_path.glob('*.sql'):
            try:
                content = sql_file.read_text(encoding='utf-8', errors='ignore')
                
                # Extract metadata from the file header
                metadata = MetadataExtractor.parse_header(content)
                
                # Get purpose and concepts if available
                purpose = metadata.get('purpose', '')
                concepts = metadata.get('concepts', '')
                
                file_info.append({
                    'filename': sql_file.name,
                    'purpose': purpose,
                    'concepts': concepts,
                    'content_preview': content[:500]  # First 500 chars for context
                })
                
            except Exception as e:
                print(f"⚠️  Error reading {sql_file}: {e}")
        
        if not file_info:
            return generate_subcategory_description_fallback(subcategory_path)
        
        # Prepare context for AI agent
        context = f"Subcategory: {subcategory_path.name}\n\n"
        context += f"Contains {len(file_info)} SQL exercise files:\n\n"
        
        for info in file_info:
            context += f"• {info['filename']}\n"
            if info['purpose']:
                context += f"  Purpose: {info['purpose']}\n"
            if info['concepts']:
                context += f"  Concepts: {info['concepts']}\n"
            context += "\n"
        
        # Ask AI to generate description
        description = await subcategory_summary_agent.run(
            f"Analyze this SQL subcategory and generate a concise description:\n\n{context}"
        )
        return description.data.strip()
        
    except Exception as e:
        print(f"⚠️  AI subcategory description generation failed: {e}")
        return generate_subcategory_description_fallback(subcategory_path)


async def estimate_subcategory_time(subcategory_path: Path) -> int:
    """
    Estimate the time needed to complete a subcategory based on SQL content complexity.
    
    Args:
        subcategory_path: Path to the subcategory directory
        
    Returns:
        Estimated time in minutes
    """
    sql_files = list(subcategory_path.glob('*.sql'))
    total_estimated_time = 0
    
    for sql_file in sql_files:
        try:
            content = sql_file.read_text(encoding='utf-8', errors='ignore')
            
            # Count significant lines (non-comment, non-empty)
            significant_lines = len([
                line for line in content.splitlines() 
                if line.strip() and not line.strip().startswith('--')
            ])
            
            # Estimate based on complexity indicators
            complexity_score = 0
            content_lower = content.lower()
            
            # Basic patterns (1 point each)
            basic_patterns = ['select', 'insert', 'update', 'delete', 'create table']
            complexity_score += sum(1 for pattern in basic_patterns if pattern in content_lower)
            
            # Intermediate patterns (2 points each)
            intermediate_patterns = ['join', 'group by', 'having', 'subquery', 'case when']
            complexity_score += sum(2 for pattern in intermediate_patterns if pattern in content_lower)
            
            # Advanced patterns (3 points each)
            advanced_patterns = ['window function', 'cte', 'recursive', 'partition by', 'json']
            complexity_score += sum(3 for pattern in advanced_patterns if pattern in content_lower)
            
            # Expert patterns (5 points each)
            expert_patterns = ['trigger', 'procedure', 'function', 'array_agg', 'lateral']
            complexity_score += sum(5 for pattern in expert_patterns if pattern in content_lower)
            
            # Time estimation formula: base time + complexity + length factor
            base_time = 5  # minimum 5 minutes per file
            complexity_time = complexity_score * 2  # 2 minutes per complexity point
            length_factor = min(20, significant_lines * 0.5)  # up to 20 minutes for length
            
            file_estimated_time = int(base_time + complexity_time + length_factor)
            total_estimated_time += file_estimated_time
            
        except Exception as e:
            # Fallback: 10 minutes per file if analysis fails
            total_estimated_time += 10
    
    # Overall subcategory adjustment
    if not sql_files:
        return 15  # default for empty subcategories
    
    # Add review/understanding time (20% of total)
    total_estimated_time = int(total_estimated_time * 1.2)
    
    # Reasonable bounds: 10-120 minutes
    return max(10, min(120, total_estimated_time))


def generate_subcategory_description_fallback(subcategory_path: Path) -> str:
    """
    Generate a fallback description based on subcategory name and file count.
    
    Args:
        subcategory_path: Path to the subcategory directory
        
    Returns:
        Simple description based on subcategory structure
    """
    sql_files = list(subcategory_path.glob('*.sql'))
    file_count = len(sql_files)
    
    # Extract display name from directory name
    display_name = ' '.join(word.capitalize() for word in subcategory_path.name.split('-')[1:])
    
    if file_count == 0:
        return f"Training exercises focused on {display_name.lower()}"
    elif file_count == 1:
        return f"Essential {display_name.lower()} concepts and techniques"
    elif file_count <= 3:
        return f"Comprehensive {display_name.lower()} training with {file_count} practical exercises"
    else:
        return f"In-depth {display_name.lower()} mastery through {file_count} progressive exercises"


# =============================================================================
# UNIFIED INTERFACE FUNCTIONS
# =============================================================================

def generate_quest_description(aggregated_content: str) -> str:
    """
    Generate a quest description using AI when available, fallback otherwise.
    
    Args:
        aggregated_content: All quest content as single text
        
    Returns:
        Generated quest description string
    """
    try:
        # Try AI generation first
        loop = asyncio.get_event_loop()
        return loop.run_until_complete(generate_quest_description_ai(aggregated_content))
    except Exception:
        # Fallback to simple description
        return generate_quest_description_fallback(aggregated_content)


def generate_subcategory_description(subcategory_path: Path) -> str:
    """
    Generate a subcategory description using AI when available, fallback otherwise.
    
    Args:
        subcategory_path: Path to the subcategory directory
        
    Returns:
        Generated description string
    """
    try:
        # Try AI generation first
        loop = asyncio.get_event_loop()
        return loop.run_until_complete(generate_subcategory_description_ai(subcategory_path))
    except Exception:
        # Fallback to simple description
        return generate_subcategory_description_fallback(subcategory_path)
