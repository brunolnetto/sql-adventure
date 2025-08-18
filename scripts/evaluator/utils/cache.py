import hashlib
import json
from pathlib import Path
from typing import Dict, Any, Optional

def _get_file_hash(file_path: Path) -> str:
    """Generate hash for file change detection"""
    content = file_path.read_text()
    return hashlib.md5(content.encode()).hexdigest()

def _get_cache_path(cache_dir: Path, file_path: Path) -> Path:
    """Get cache file path for a SQL file"""
    return cache_dir / f"{file_path.stem}_{_get_file_hash(file_path)[:8]}.json"

def _is_cached_valid(cache_dir: Path, file_path: Path) -> bool:
    """Check if cached result is valid and up-to-date"""    
    cache_path = _get_cache_path(file_path)
    if not cache_path.exists():
        return False
    
    # Check if cache is recent (within 24 hours)
    cache_age = (Path.cwd().stat().st_mtime - cache_path.stat().st_mtime) / 3600
    return cache_age < 24

def _load_cached_result(cache_dir: Path, file_path: Path) -> Optional[Dict[str, Any]]:
    """Load cached evaluation result"""
    cache_path = _get_cache_path(cache_dir, file_path)
    try:
        return json.loads(cache_path.read_text())
    except Exception:
        return None

def _save_cached_result(
    cache_dir: Path, file_path: Path, result: Dict[str, Any]
):
    """Save evaluation result to cache"""    
    cache_path = _get_cache_path(cache_dir, file_path)
    try:
        cache_path.write_text(json.dumps(result, indent=2))
    except Exception as e:
        print(f"⚠️  Failed to cache result for {file_path}: {e}")