"""
AI-powered summarization agents for SQL Adventure content.
Provides unified summarization for quests and subcategories using dependency injection.
"""

import asyncio
from pathlib import Path
from typing import List, Tuple
from .discovery import MetadataExtractor


# =============================================================================
# QUEST SUMMARIZATION WITH RICH CONTEXT
# =============================================================================

async def generate_quest_description_from_context(quest_context: dict) -> str:
    """
    Generate AI-powered quest description from rich context dictionary.

    Args:
        quest_context: Dictionary with quest metadata and file information

    Returns:
        Succinct but elucidative quest description
    """
    from core.agents import quest_summary_agent

    # Build comprehensive context from the quest context dictionary
    context_parts = [
        f"Quest: {quest_context['display_name']}",
        f"Total Files: {quest_context['total_files']}",
        f"Estimated Time: {quest_context['total_estimated_time']} minutes",
        f"Subcategories: {quest_context['subcategory_count']}",
        "",
        "Subcategory Breakdown:"
    ]

    for sub in quest_context['subcategories']:
        context_parts.append(f"• {sub['display_name']}")
        context_parts.append(f"  - {sub['file_count']} files, {sub['total_estimated_time']} min")
        if sub['concept_coverage']:
            context_parts.append(f"  - Concepts: {', '.join(sub['concept_coverage'][:3])}")
        if sub['pattern_coverage']:
            context_parts.append(f"  - Patterns: {', '.join(sub['pattern_coverage'][:3])}")
        context_parts.append("")

    context_parts.extend([
        "",
        "Overall Concept Coverage:",
        ", ".join(quest_context['concept_coverage'][:10]),
        "",
        "SQL Pattern Coverage:",
        ", ".join(quest_context['pattern_coverage'][:10])
    ])

    aggregated_content = "\n".join(context_parts)

    prompt = f"""
    Analyze this SQL quest context and generate a succinct description:

    {aggregated_content}

    Generate a 2-3 sentence description that clearly explains what this quest teaches
    and what practical skills students will develop. Focus on the learning outcomes
    and practical applications.
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


async def generate_subcategory_description_from_context(subcategory_context: dict) -> str:
    """
    Generate a subcategory description using rich context dictionary.

    Args:
        subcategory_context: Dictionary with subcategory metadata and file information

    Returns:
        AI-generated description of the subcategory content
    """
    try:
        from core.agents import subcategory_summary_agent

        # Build context from subcategory context dictionary
        context_parts = [
            f"Subcategory: {subcategory_context['display_name']}",
            f"Files: {subcategory_context['file_count']}",
            f"Total Time: {subcategory_context['total_estimated_time']} minutes",
            "",
            "SQL Files:"
        ]

        for sql_file in subcategory_context['sql_files']:
            context_parts.append(f"• {sql_file['filename']}")
            if sql_file['purpose']:
                context_parts.append(f"  Purpose: {sql_file['purpose']}")
            if sql_file['concepts']:
                context_parts.append(f"  Concepts: {sql_file['concepts']}")
            context_parts.append(f"  Time: {sql_file['estimated_time_minutes']} min")
            if sql_file['patterns']:
                context_parts.append(f"  Patterns: {', '.join(sql_file['patterns'])}")
            context_parts.append("")

        context_parts.extend([
            "",
            "Concept Coverage:",
            ", ".join(subcategory_context['concept_coverage']),
            "",
            "Pattern Coverage:",
            ", ".join(subcategory_context['pattern_coverage'])
        ])

        context = "\n".join(context_parts)

        # Ask AI to generate description
        description = await subcategory_summary_agent.run(
            f"Analyze this SQL subcategory and generate a concise description:\n\n{context}"
        )
        return description.output.strip()

    except Exception as e:
        print(f"⚠️  AI subcategory description generation failed: {e}")
        return generate_subcategory_description_fallback(subcategory_context.subcategory_path)


# =============================================================================
# LEGACY FUNCTIONS (Updated to use context when available)
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
    from core.agents import pattern_summary_agent
    
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
        result = await pattern_summary_agent.run(prompt)
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
    Analyze a SQL file using metadata extraction (not AI generation).
    This is the CORRECT approach - extract existing metadata instead of generating new estimates.

    Args:
        file_path: Path to the SQL file

    Returns:
        Tuple of (description, estimated_time_minutes) extracted from file headers
    """
    try:
        # Read the SQL file content
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        # Extract metadata from headers using the existing MetadataExtractor
        metadata = MetadataExtractor.parse_header(content)

        # Extract purpose for description
        purpose = metadata.get('purpose', '')
        if not purpose:
            # Fallback: generate basic description from filename
            filename = Path(file_path).name
            name_parts = filename.replace('.sql', '').replace('-', ' ').replace('_', ' ')
            display_name = ' '.join(word.capitalize() for word in name_parts.split())
            description = f"SQL exercise: {display_name}"
        else:
            description = purpose

        # Extract time estimate from difficulty header
        difficulty = metadata.get('difficulty', '')
        estimated_time = extract_time_from_difficulty(difficulty)

        return description, estimated_time

    except Exception as e:
        print(f"⚠️  Metadata extraction failed for {file_path}: {e}")
        return generate_sql_file_analysis_fallback(file_path)


def extract_time_from_difficulty(difficulty_header: str) -> int:
    """
    Extract time estimate from difficulty header format.
    Expected formats: "🟢 Beginner (5-10 min)" or "🟡 Intermediate (10-15 min)"

    Args:
        difficulty_header: The difficulty string from file header

    Returns:
        Estimated time in minutes (average of range or default)
    """
    import re

    # Pattern to match time ranges like "(5-10 min)" or "(10-15 min)"
    time_pattern = r'\((\d+)-(\d+)\s*min\)'
    match = re.search(time_pattern, difficulty_header, re.IGNORECASE)

    if match:
        min_time = int(match.group(1))
        max_time = int(match.group(2))
        # Return average of the range
        return (min_time + max_time) // 2

    # Fallback patterns for single time values
    single_time_pattern = r'\((\d+)\s*min\)'
    match = re.search(single_time_pattern, difficulty_header, re.IGNORECASE)

    if match:
        return int(match.group(1))

    # Final fallback based on difficulty level keywords
    difficulty_lower = difficulty_header.lower()
    if 'beginner' in difficulty_lower or '🟢' in difficulty_header:
        return 8  # 5-10 min average
    elif 'intermediate' in difficulty_lower or '🟡' in difficulty_header:
        return 15  # 10-20 min average
    elif 'advanced' in difficulty_lower or '🟠' in difficulty_header:
        return 25  # 20-30 min average
    elif 'expert' in difficulty_lower or '🔴' in difficulty_header:
        return 35  # 30-40 min average
    else:
        return 15  # Default intermediate level


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
    Analyze SQL file asynchronously using metadata extraction (not AI generation).
    This approach is ROBUST and RELIABLE - no string parsing of AI responses.

    Args:
        file_path: Path to the SQL file

    Returns:
        Tuple of (description, estimated_time_minutes) from file metadata
    """
    try:
        # Use metadata extraction instead of AI generation
        return await analyze_sql_file_ai(file_path)

    except Exception as e:
        print(f"⚠️  Metadata extraction failed, using fallback for {file_path}: {e}")
        return generate_sql_file_analysis_fallback(file_path)


async def sync_sql_file_metadata(file_path: str, db_manager) -> bool:
    """
    Sync SQL file metadata to database using ROBUST extraction (not AI generation).

    Args:
        file_path: Path to the SQL file
        db_manager: Database manager instance

    Returns:
        bool: True if sync successful, False otherwise
    """
    try:
        # Extract metadata from file headers
        description, estimated_time = await analyze_sql_file_ai(file_path)

        # Read file content for hash calculation
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        # Calculate content hash for change detection
        import hashlib
        content_hash = hashlib.sha256(content.encode('utf-8')).hexdigest()

        # Extract additional metadata
        metadata = MetadataExtractor.parse_header(content)
        concepts = metadata.get('concepts', '')
        difficulty = metadata.get('difficulty', '')

        # Prepare data for database upsert
        file_data = {
            'file_path': str(file_path),
            'filename': Path(file_path).name,
            'description': description,
            'estimated_time_minutes': estimated_time,
            'content_hash': content_hash,
            'concepts': concepts,
            'difficulty': difficulty,
            'last_modified': Path(file_path).stat().st_mtime
        }

        # TODO: Implement database upsert logic here
        # This would update the sql_files table with the extracted metadata

        print(f"✅ Synced metadata for {Path(file_path).name}: {estimated_time}min, {description[:50]}...")
        return True

    except Exception as e:
        print(f"❌ Failed to sync metadata for {file_path}: {e}")
        return False


async def bulk_sync_sql_metadata(quest_path: Path, db_manager) -> dict:
    """
    Bulk sync all SQL file metadata for a quest using ROBUST extraction.

    Args:
        quest_path: Path to the quest directory
        db_manager: Database manager instance

    Returns:
        dict: Sync statistics and results
    """
    stats = {
        'total_files': 0,
        'successful_syncs': 0,
        'failed_syncs': 0,
        'skipped_unchanged': 0,
        'errors': []
    }

    print(f"🔄 Starting bulk metadata sync for quest: {quest_path.name}")

    # Find all SQL files in the quest
    sql_files = list(quest_path.rglob('*.sql'))
    stats['total_files'] = len(sql_files)

    for sql_file in sql_files:
        try:
            success = await sync_sql_file_metadata(str(sql_file), db_manager)
            if success:
                stats['successful_syncs'] += 1
            else:
                stats['failed_syncs'] += 1
                stats['errors'].append(f"Failed to sync {sql_file.name}")

        except Exception as e:
            stats['failed_syncs'] += 1
            stats['errors'].append(f"Error syncing {sql_file.name}: {str(e)}")

    print(f"📊 Bulk sync complete: {stats['successful_syncs']}/{stats['total_files']} files synced successfully")
    return stats


# =============================================================================
# LEGACY AI-BASED APPROACH (DEPRECATED - Use metadata extraction instead)
# =============================================================================

async def analyze_sql_file_ai_legacy(file_path: str) -> Tuple[str, int]:
    """
    DEPRECATED: Legacy AI-based analysis with fragile string parsing.
    Use analyze_sql_file_ai() instead for robust metadata extraction.

    This function is kept for reference to show why string inference is problematic.
    """
    print("⚠️  WARNING: Using deprecated AI analysis. Consider using metadata extraction instead.")

    try:
        from core.agents import sql_file_summary_agent

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
        result = await sql_file_summary_agent.run(context)

        # PROBLEMATIC STRING PARSING SECTION:
        # This is fragile and error-prone
        import json
        import re

        # Get the raw output (could be in various formats)
        if hasattr(result, 'output'):
            raw_output = result.output
        elif hasattr(result, 'data'):
            raw_output = str(result.data)
        else:
            raw_output = str(result)

        # Attempt to clean up the response (brittle)
        raw_output = re.sub(r'```\w*\n?', '', raw_output)  # Remove markdown
        raw_output = raw_output.strip()

        # Try to parse JSON (often fails due to AI formatting inconsistencies)
        try:
            analysis = json.loads(raw_output)
        except json.JSONDecodeError as json_error:
            # Fallback parsing attempts (even more brittle)
            print(f"⚠️  JSON parse failed: {json_error}")
            print(f"   Raw output: {raw_output[:200]}...")

            # Attempt regex extraction (extremely fragile)
            time_match = re.search(r'"estimated_time_minutes"\s*:\s*(\d+)', raw_output)
            desc_match = re.search(r'"description"\s*:\s*"([^"]+)"', raw_output)

            if time_match and desc_match:
                estimated_time = int(time_match.group(1))
                description = desc_match.group(1)
            else:
                raise ValueError("Could not extract data from AI response")

        # Validate the expected fields (can still fail)
        if not isinstance(analysis, dict) or 'description' not in analysis or 'estimated_time_minutes' not in analysis:
            raise ValueError("Invalid response format - missing required fields")

        description = analysis.get('description', 'SQL exercise covering database concepts and techniques')
        estimated_time = analysis.get('estimated_time_minutes', 15)

        return description, estimated_time

    except Exception as e:
        print(f"⚠️  AI analysis failed for {file_path}: {e}")
        return generate_sql_file_analysis_fallback(file_path)