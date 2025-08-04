# Quality Assurance Workflow

## Overview

SQL Adventure uses a **simplified, focused quality assurance approach** with streamlined scripts for better user experience and faster development.

## Simplified Validation Script

### `scripts/validate.sh` - Focused Validation with AI Context

**Two modes, clear purpose, better UX!**

```bash
# During development (FAST)
./scripts/validate.sh fast <file>

# For AI handover (CONTEXT)
./scripts/validate.sh ai <file>
```

### Modes Explained

| Mode | Purpose | Speed | What it does |
|------|---------|-------|--------------|
| `fast` | Development cycle | ⚡⚡⚡ | Syntax, structure, execution |
| `ai` | AI handover | ⚡⚡ | Fast + output capture for AI context |

## Development Workflow

### 1. During Development (Fast Mode)
```bash
# Quick check while coding
./scripts/validate.sh fast quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql
```

**Checks:**
- ✅ SQL syntax validation
- ✅ Basic structure (comments, SQL patterns)
- ✅ Execution test

### 2. For AI Analysis (AI Mode)
```bash
# Capture output for AI handover
./scripts/validate.sh ai quests/recursive-cte/01-hierarchical-graph-traversal/01-employee-hierarchy.sql
```

**Checks:**
- ✅ All fast mode checks
- ✅ Output capture and storage
- ✅ Context summary for AI evaluation

## Directory Operations

Check all files in a directory:

```bash
# Fast check all files in directory
./scripts/validate.sh fast quests/recursive-cte/01-hierarchical-graph-traversal

# AI context check all files in directory
./scripts/validate.sh ai quests/recursive-cte/01-hierarchical-graph-traversal
```

## Quality Standards

### Automated Checks (Boolean Evaluation)

1. **Syntax Validation** - SQL parses correctly
2. **Structure Check** - Has comments and SQL patterns
3. **Execution Test** - Runs without errors
4. **Performance Check** - Executes in < 1 second (full mode)

### AI Handover (Context Analysis)

1. **Output Capture** - Full query output saved
2. **Context Extraction** - Educational context and purpose
3. **Pattern Analysis** - SQL structure and logic
4. **Result Validation** - Expected vs actual results

## Integration with Git Workflow

### Pre-commit Hook (Recommended)
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check all modified SQL files
for file in $(git diff --cached --name-only --diff-filter=ACM | grep '\.sql$'); do
    if ! ./scripts/check.sh full "$file"; then
        echo "Quality check failed for $file"
        exit 1
    fi
done
```

### Development Commands
```bash
# Quick development check
./scripts/check.sh fast <file>

# Pre-commit validation
./scripts/check.sh full <file>

# AI analysis for complex queries
./scripts/check.sh ai <file>
```

## Benefits of Unified Approach

### ✅ **DRY Principle**
- **One script** instead of four separate scripts
- **Shared functions** and utilities
- **Consistent interface** across all modes

### ✅ **Lean Development**
- **Fast mode** for quick feedback during development
- **Progressive complexity** as needed
- **No over-engineering** for simple tasks

### ✅ **Flexible Workflow**
- **Mode selection** based on current needs
- **Directory support** for batch operations
- **Clear progression** from fast to comprehensive

### ✅ **Maintainable**
- **Single codebase** to maintain
- **Consistent behavior** across modes
- **Easy to extend** with new features

## Migration from Old Scripts

The following scripts have been **consolidated** into `scripts/check.sh`:

- ❌ `scripts/quality-check.sh` (730 lines) → ✅ `scripts/check.sh` (250 lines)
- ❌ `scripts/performance-test.sh` (350 lines) → ✅ `scripts/check.sh` (250 lines)  
- ❌ `scripts/regression-test.sh` (267 lines) → ✅ `scripts/check.sh` (250 lines)
- ❌ `scripts/quick-check.sh` (171 lines) → ✅ `scripts/check.sh` (250 lines)

**Total reduction: 1,518 lines → 250 lines (84% reduction!)**

## Future Enhancements

### Planned Features
- [ ] **Parallel execution** for directory checks
- [ ] **Caching** for repeated checks
- [ ] **Integration** with IDE plugins
- [ ] **Custom validation rules** per quest type

### Extensibility
The unified script is designed to be easily extended with new modes and validation types while maintaining the lean, fast approach that makes development efficient. 