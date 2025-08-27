"""
AI-powered summarization agents for SQL Adventure content.
Provides unified summarization for quests and subcategories using dependency injection.
"""

import asyncio
from pathlib import Path
from typing import List, Tuple
from .discovery import MetadataExtractor


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
    from core.agents import quest_summary_agent

    prompt = f"""
    Analyze this SQL quest content and generate a succinct description:

    {aggregated_content}

    Generate a 2-3 sentence description that clearly explains what this quest teaches
    and what practical skills students will develop.
    """

    try:
        # Add timeout protection to prevent hanging on slow AI calls
        result = await asyncio.wait_for(quest_summary_agent.run(prompt), timeout=5.0)  # 5 second timeout
        return result.output.strip()
    except asyncio.TimeoutError:
        print("⚠️  AI quest description timeout, using fallback")
        raise Exception("Timeout")
    except Exception as e:
        print(f"⚠️  AI quest description error: {e}")
        raise


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
        if any(keyword in line_lower for keyword in [
            'modeling', 'performance', 'window', 'json', 'recursive', 'normalization'
        ]):
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
        return description.output.strip()
        
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

async def generate_quest_description_async(quest_name: str, subcategories: List[Tuple[str, str, str, str, int]]) -> str:
    """
    Generate quest description using AI agent if available, fallback to content-based method otherwise.
    Async version for use in async contexts.
    """
    try:
        # Aggregate all quest content into a single text
        aggregated_content = f"Quest: {quest_name}\n"

        # Add subcategory information
        if subcategories:
            aggregated_content += "Subcategories:\n"
            for sub_name, display_name, difficulty, description, order in subcategories:
                aggregated_content += f"- {display_name} ({difficulty}): {description}\n"

        # Try AI description first
        try:
            description = await generate_quest_description_ai(aggregated_content)
            return description
        except Exception as e:
            print(f"⚠️  AI quest description failed: {e}")
            # Fallback to simple description
            return generate_quest_description_fallback(aggregated_content)

    except Exception:
        # Final fallback to previous content-based method
        if not subcategories:
            quest_type = '-'.join(quest_name.split('-')[1:])
            return f"SQL {quest_type.replace('-', ' ')} exercises and concepts"
        subcategory_names = [display_name for _, display_name, _, _, _ in subcategories]
        if len(subcategory_names) == 1:
            return f"Focused training on {subcategory_names[0].lower()}"
        elif len(subcategory_names) <= 3:
            return f"Comprehensive coverage of {', '.join(subcategory_names).lower()}"
        else:
            primary_topics = subcategory_names[:2]
            remaining_count = len(subcategory_names) - 2
            return f"In-depth exploration of {', '.join(primary_topics).lower()} and {remaining_count} additional topics"


def generate_quest_description(quest_name: str, subcategories: List[Tuple[str, str, str, str, int]]) -> str:
    """
    Generate quest description using AI agent if available, fallback to content-based method otherwise.
    Sync wrapper that handles both sync and async contexts.
    """
    try:
        import asyncio

        # Check if we're already in an async context
        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                # We're in an async context, create a task
                import nest_asyncio
                nest_asyncio.apply()
                return loop.run_until_complete(generate_quest_description_async(quest_name, subcategories))
        except RuntimeError:
            # No event loop, create a new one
            pass

        # Create new event loop for sync context
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            return loop.run_until_complete(generate_quest_description_async(quest_name, subcategories))
        finally:
            loop.close()

    except ImportError:
        # nest_asyncio not available, fallback to sync method
        print("⚠️  nest_asyncio not available, using fallback description")
        return generate_quest_description_fallback(f"Quest: {quest_name}")
    except Exception as e:
        print(f"⚠️  Error in quest description generation: {e}")
        return generate_quest_description_fallback(f"Quest: {quest_name}")


async def generate_subcategory_description_async(subcategory_path: Path) -> str:
    """
    Generate a subcategory description using AI analysis of SQL files.
    Async version for use in async contexts.
    
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
        return description.output.strip()
        
    except Exception as e:
        print(f"⚠️  AI subcategory description generation failed: {e}")
        return generate_subcategory_description_fallback(subcategory_path)


def generate_subcategory_description(subcategory_path: Path) -> str:
    """
    Generate a subcategory description using AI when available, fallback otherwise.
    Sync wrapper that handles both sync and async contexts.
    
    Args:
        subcategory_path: Path to the subcategory directory
        
    Returns:
        Generated description string
    """
    try:
        import asyncio

        # Check if we're already in an async context
        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                # We're in an async context, use nest_asyncio if available
                try:
                    import nest_asyncio
                    nest_asyncio.apply()
                    return loop.run_until_complete(generate_subcategory_description_async(subcategory_path))
                except ImportError:
                    # nest_asyncio not available, use fallback
                    return generate_subcategory_description_fallback(subcategory_path)
        except RuntimeError:
            # No event loop, create a new one
            pass

        # Create new event loop for sync context
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            return loop.run_until_complete(generate_subcategory_description_async(subcategory_path))
        finally:
            loop.close()

    except Exception as e:
        print(f"⚠️  Error in subcategory description generation: {e}")
        return generate_subcategory_description_fallback(subcategory_path)

async def generate_sql_pattern_description(pattern_name: str, context: dict) -> str:
    from core.agents import pattern_description_agent
    
    # Create prompt for AI analysis
    prompt = f"""
    Analyze this SQL pattern and create an educational description:
    
    Pattern: {pattern_name.replace('_', ' ').title()}
    Technical Description: {context['base_description']}
    Examples: {'; '.join(context['examples'][:2])}
    Category: {context['category']}
    Complexity: {context['complexity']}
    
    Create a comprehensive description that explains:
    1. What this pattern accomplishes
    2. When developers should use it
    3. Its practical value in real applications
    
    Keep it concise but educational (2-3 sentences).
    """
    
    try:
        result = await pattern_description_agent.run(prompt)
        ai_description = result.data if hasattr(result, 'data') else str(result)
    except Exception as e:
        print(f"⚠️  AI generation failed for {pattern_name}: {e}")
        ai_description = context['base_description']
        
    return ai_description


# =============================================================================
# SQL FILE ANALYSIS
# =============================================================================

async def analyze_sql_file_ai(file_path: str) -> Tuple[str, int]:
    """
    Analyze a SQL file using AI to generate description and time estimate.
    
    Args:
        file_path: Path to the SQL file
        
    Returns:
        Tuple of (description, estimated_time_minutes)
    """
    try:
        from core.agents import sql_file_summarizer_agent
        
        # Read the SQL file content
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Extract metadata from headers
        metadata = MetadataExtractor.parse_header(content)
        
        # Prepare context for AI analysis
        context = f"""
        SQL File: {Path(file_path).name}
        
        Header Metadata:
        {chr(10).join(f"{k}: {v}" for k, v in metadata.items()) if metadata else "No metadata found"}
        
        SQL Content:
        {content[:2000]}  # Limit content for AI processing
        """
        
        # Get AI analysis
        result = await sql_file_summarizer_agent.run(context)
        
        # Parse the JSON response
        try:
            import json
            import re
            
            # Get the raw output
            if hasattr(result, 'output'):
                raw_output = result.output
            elif hasattr(result, 'data'):
                raw_output = str(result.data)
            else:
                raw_output = str(result)
            
            # Strip markdown code blocks if present
            raw_output = re.sub(r'```\w*\n?', '', raw_output)
            raw_output = raw_output.strip()
            
            # Parse JSON
            analysis = json.loads(raw_output)
            
            # Validate the expected fields
            if not isinstance(analysis, dict) or 'description' not in analysis or 'estimated_time_minutes' not in analysis:
                raise ValueError("Invalid response format - missing required fields")
                
        except (json.JSONDecodeError, AttributeError, ValueError) as e:
            print(f"⚠️  Failed to parse AI response: {e}")
            print(f"   Raw output: {raw_output[:200]}...")
            analysis = {
                'description': 'SQL exercise covering database concepts and techniques',
                'estimated_time_minutes': 15
            }
        
        description = analysis.get('description', 'SQL exercise covering database concepts and techniques')
        estimated_time = analysis.get('estimated_time_minutes', 15)
        
        return description, estimated_time
        
    except Exception as e:
        print(f"⚠️  AI analysis failed for {file_path}: {e}")
        return generate_sql_file_analysis_fallback(file_path)


def generate_sql_file_analysis_fallback(file_path: str) -> Tuple[str, int]:
    """
    Generate fallback description and time estimate for SQL file when AI is unavailable.
    
    Args:
        file_path: Path to the SQL file
        
    Returns:
        Tuple of (description, estimated_time_minutes)
    """
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Extract filename for basic description
        filename = Path(file_path).name
        name_parts = filename.replace('.sql', '').replace('-', ' ').replace('_', ' ')
        display_name = ' '.join(word.capitalize() for word in name_parts.split())
        
        # Basic time estimation based on content complexity
        lines = content.splitlines()
        significant_lines = len([line for line in lines if line.strip() and not line.strip().startswith('--')])
        
        # Simple complexity scoring
        content_lower = content.lower()
        complexity_score = 0
        
        # Basic patterns (1 point each)
        basic_patterns = ['select', 'insert', 'update', 'delete', 'create table']
        complexity_score += sum(1 for pattern in basic_patterns if pattern in content_lower)
        
        # Intermediate patterns (2 points each)  
        intermediate_patterns = ['join', 'group by', 'having', 'subquery', 'case when']
        complexity_score += sum(2 for pattern in intermediate_patterns if pattern in content_lower)
        
        # Advanced patterns (3 points each)
        advanced_patterns = ['window function', 'cte', 'recursive', 'partition by', 'json']
        complexity_score += sum(3 for pattern in advanced_patterns if pattern in content_lower)
        
        # Time estimation: base time + complexity + length factor
        base_time = 5
        complexity_time = complexity_score * 1
        length_factor = min(15, significant_lines * 0.3)
        
        estimated_time = int(base_time + complexity_time + length_factor)
        estimated_time = max(5, min(45, estimated_time))  # Bounds: 5-45 minutes
        
        description = f"SQL exercise: {display_name}"
        
        return description, estimated_time
        
    except Exception as e:
        print(f"⚠️  Fallback analysis failed for {file_path}: {e}")
        return "SQL exercise covering database concepts", 15


async def analyze_sql_file_async(file_path: str) -> Tuple[str, int]:
    """
    Analyze SQL file asynchronously, using AI if available, fallback otherwise.
    Uses smart sampling to prioritize AI for key files and static analysis for others.

    Args:
        file_path: Path to the SQL file

    Returns:
        Tuple of (description, estimated_time_minutes)
    """
    import hashlib

    # Smart sampling: Use AI for ~10% of files based on filename hash for consistency
    file_hash = hashlib.md5(str(file_path).encode()).hexdigest()
    use_ai = int(file_hash[:8], 16) % 10 == 0  # ~10% of files get AI analysis

    if not use_ai:
        # Use fast static analysis for most files
        return generate_sql_file_analysis_fallback(file_path)

    try:
        # Try AI analysis first with reduced timeout for better performance
        try:
            result = await asyncio.wait_for(analyze_sql_file_ai(file_path), timeout=2.0)  # 2 second timeout
            return result
        except asyncio.TimeoutError:
            print(f"⚠️  AI analysis timeout for {file_path}, using fallback")
            return generate_sql_file_analysis_fallback(file_path)
    except Exception as e:
        print(f"⚠️  AI analysis failed, using fallback for {file_path}: {e}")
        return generate_sql_file_analysis_fallback(file_path)


def analyze_sql_file(file_path: str) -> Tuple[str, int]:
    """
    Analyze SQL file with sync wrapper for both sync and async contexts.
    
    Args:
        file_path: Path to the SQL file
        
    Returns:
        Tuple of (description, estimated_time_minutes)
    """
    try:
        # Check if we're already in an async context
        try:
            loop = asyncio.get_running_loop()
            # We're in an async context, create a task
            import nest_asyncio
            nest_asyncio.apply()
            return loop.create_task(analyze_sql_file_async(file_path))
        except RuntimeError:
            # Not in an async context, create new event loop
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            try:
                return loop.run_until_complete(analyze_sql_file_async(file_path))
            finally:
                loop.close()
    except ImportError:
        # nest_asyncio not available, use fallback
        print("⚠️  nest_asyncio not available, using fallback analysis")
        return generate_sql_file_analysis_fallback(file_path)
    except Exception as e:
        print(f"⚠️  Error in SQL file analysis: {e}")
        return generate_sql_file_analysis_fallback(file_path)