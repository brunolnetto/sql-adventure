# Git Workflow for Scoped, Small Commits 🚀

This document outlines the Git workflow setup for maintaining scoped, small commits with consistent timing and concise messages.

## 🎯 **Goals**

1. **Scoped Commits** - Each commit addresses a single, well-defined change
2. **Small Commits** - Keep commits as small as possible while remaining meaningful
3. **Time Consistency** - Regular, consistent commit timing
4. **Concise Messages** - Clear, brief commit messages following conventions

## ⚙️ **Configuration Setup**

### 1. **Commit Message Template**
- **File**: `.gitmessage`
- **Purpose**: Enforces consistent commit message format
- **Format**: `<type>(<scope>): <subject>`

### 2. **Git Configuration**
```bash
# Commit template
git config --local commit.template .gitmessage

# Editor (VS Code)
git config --local core.editor "code --wait"

# Verbose commits (shows diff)
git config --local commit.verbose true

# Rebase on pull (cleaner history)
git config --local pull.rebase true
```

## 📝 **Commit Message Format**

### **Structure**
```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### **Types**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting, etc.)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks
- `perf` - Performance improvements
- `ci` - CI/CD changes
- `build` - Build system changes

### **Scopes** (Project-specific)
- `sql` - SQL examples/queries
- `docs` - Documentation
- `docker` - Docker configuration
- `scripts` - Scripts and automation
- `config` - Configuration files
- `ui` - User interface
- `api` - API changes
- `db` - Database changes

### **Rules**
- Keep subject line under 50 characters
- Use imperative mood ("add" not "added")
- Don't end with period
- Be specific and concise

### **Examples**
```bash
feat(sql): add recursive CTE cheatsheet
fix(docs): correct typo in learning path
docs(sql): improve example documentation
refactor(scripts): simplify docker setup
test(sql): add validation for CTE examples
chore(docker): update postgres version
perf(sql): optimize query performance
ci(scripts): add automated testing
```

## 🔧 **Workflow Script**

### **Usage**
```bash
# Show current status
./scripts/git-workflow.sh status

# Stage files interactively
./scripts/git-workflow.sh stage

# Create a scoped commit (opens editor)
./scripts/git-workflow.sh commit

# Quick commit with message
./scripts/git-workflow.sh quick-commit "feat(sql): add new example"

# Show recent commit history
./scripts/git-workflow.sh history

# Check commit message format
./scripts/git-workflow.sh check-format

# Show help
./scripts/git-workflow.sh help
```

### **Features**
- **Interactive staging** - Choose which files to stage
- **Format validation** - Check if commit messages follow conventions
- **Colored output** - Easy-to-read status information
- **Error handling** - Prevents invalid operations

## 📋 **Best Practices**

### **1. Commit Frequency**
- **Small changes**: Commit immediately after completing a small feature/fix
- **Regular intervals**: Aim for commits every 30-60 minutes of active work
- **Logical breaks**: Commit at natural stopping points

### **2. Commit Size**
- **Single responsibility**: Each commit should do one thing well
- **Reviewable**: Changes should be easy to review in isolation
- **Revertable**: Should be able to revert without breaking other features

### **3. Staging Strategy**
```bash
# Interactive staging (recommended)
./scripts/git-workflow.sh stage

# Or manual staging
git add -p  # Stage specific hunks
git add file1.sql file2.md  # Stage specific files
git add .  # Stage all changes (use sparingly)
```

### **4. Commit Workflow**
```bash
# 1. Check status
./scripts/git-workflow.sh status

# 2. Stage changes
./scripts/git-workflow.sh stage

# 3. Create commit
./scripts/git-workflow.sh commit

# 4. Verify format
./scripts/git-workflow.sh check-format
```

## 🕒 **Time Consistency**

### **Commit Timing Guidelines**
- **Morning**: Review and commit yesterday's work
- **Mid-morning**: Commit after completing a feature
- **Lunch**: Commit before break
- **Afternoon**: Commit after completing a task
- **End of day**: Final commit with any remaining changes

### **Time-based Commit Messages**
```bash
# Morning commits
feat(sql): add employee hierarchy example
docs(sql): update cheatsheet with new patterns

# Mid-day commits
fix(docs): correct typo in learning path
refactor(scripts): improve docker setup

# End-of-day commits
chore(docs): finalize documentation updates
test(sql): add validation for all examples
```

## 🔍 **Quality Checks**

### **Pre-commit Checklist**
- [ ] Changes are focused and logical
- [ ] Commit message follows format
- [ ] Subject line is under 50 characters
- [ ] No debugging code or temporary files
- [ ] Tests pass (if applicable)

### **Post-commit Verification**
```bash
# Check last commit format
./scripts/git-workflow.sh check-format

# Review commit history
./scripts/git-workflow.sh history

# Verify changes
git show --stat HEAD
```

## 🚫 **What to Avoid**

### **Anti-patterns**
- ❌ **Large commits** - Multiple unrelated changes
- ❌ **Vague messages** - "fix stuff" or "update things"
- ❌ **Inconsistent timing** - Random commit intervals
- ❌ **Debug commits** - Committing temporary debugging code
- ❌ **WIP commits** - Committing incomplete work

### **Bad Examples**
```bash
# ❌ Too vague
git commit -m "fix stuff"

# ❌ Too long
git commit -m "fix(docs): correct multiple typos and formatting issues in the comprehensive documentation"

# ❌ No scope
git commit -m "feat: add new feature"

# ❌ Wrong mood
git commit -m "feat(sql): added new example"
```

## 📚 **Additional Resources**

- **Conventional Commits**: https://www.conventionalcommits.org/
- **Git Best Practices**: https://git-scm.com/book/en/v2
- **Commit Message Guidelines**: https://chris.beams.io/posts/git-commit/

---

*Follow this workflow to maintain clean, scoped, and consistent Git history! 🚀* 