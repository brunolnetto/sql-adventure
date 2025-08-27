#!/usr/bin/env python3
"""
Simple SQL Runner for SQL Adventure
Executes SQL files without evaluation overhead for faster iteration
"""

import os
import sys
import asyncio
import json
from pathlib import Path
from datetime import datetime

# Add the evaluator directory to the path for module imports
evaluator_dir = Path(__file__).parent / "evaluator"
sys.path.insert(0, str(evaluator_dir))

# Import database manager
from evaluator.database.manager import DatabaseManager

class SimpleSQLRunner:
    """Simple SQL execution without evaluation"""

    def __init__(self, quiet_mode=False):
        self.db_manager = None
        self.quiet_mode = quiet_mode
        self.total_files = 0
        self.successful_files = 0
        self.failed_files = 0

    async def initialize(self):
        """Initialize database connection"""
        try:
            # Use quests database (execution sandbox)
            self.db_manager = DatabaseManager(database_type="quests")
            if not self.quiet_mode:
                print("✅ Database connection established")
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            sys.exit(1)

    async def run_sql_file(self, file_path: str):
        """Execute a single SQL file"""
        self.total_files += 1

        try:
            if not self.quiet_mode:
                print(f"📄 Executing: {file_path}")

            # Clean up execution sandbox before each run
            if self.db_manager:
                tables_dropped = self.db_manager.drop_all_tables()
                if tables_dropped > 0 and not self.quiet_mode:
                    print(f"🧹 Cleaned up {tables_dropped} tables from previous runs")

            # Read SQL file
            with open(file_path, 'r') as f:
                sql_content = f.read()

            # Execute SQL
            result = await self.db_manager._execute_sql(sql_content)

            # Display results based on mode
            if result['success']:
                self.successful_files += 1
                if not self.quiet_mode:
                    print("✅ Execution successful")
                    print(f"   📊 Statements run: {result['statements_run']}")
                    print(f"   📈 Result sets: {result['result_sets']}")
                    print(f"   ⚡ Execution time: {result['execution_time_ms']}ms")
            else:
                self.failed_files += 1
                print(f"❌ FAILED: {file_path}")
                if result['errors'] > 0:
                    print(f"   � Errors: {result['errors']}")
                    # Always print detailed error messages for debugging
                    for error_msg in result['error_messages']:
                        print(f"   🚨 {error_msg}")
                if result['warnings'] > 0:
                    print(f"   ⚠️  Warnings: {result['warnings']}")
                    # Always print detailed warning messages for debugging
                    for warning_msg in result['warning_messages']:
                        print(f"   ⚠️  {warning_msg}")

        except Exception as e:
            self.failed_files += 1
            print(f"❌ ERROR in {file_path}: {e}")

    async def run_multiple_files(self, file_paths: list):
        """Execute multiple SQL files with minimal output"""
        print(f"� Processing {len(file_paths)} SQL files...")

        for file_path in file_paths:
            if os.path.exists(file_path):
                await self.run_sql_file(file_path)
            else:
                print(f"❌ File not found: {file_path}")

        # Summary
        print(f"\n📊 Summary:")
        print(f"   📁 Total files: {self.total_files}")
        print(f"   ✅ Successful: {self.successful_files}")
        print(f"   ❌ Failed: {self.failed_files}")

    async def cleanup(self):
        """Clean up database connection"""
        if self.db_manager:
            # Optionally clean up tables between runs
            pass

def find_sql_files(directory: str):
    """Find all SQL files in directory recursively"""
    sql_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.sql'):
                sql_files.append(os.path.join(root, file))
    return sorted(sql_files)

async def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/run_sql.py <sql_file> [sql_file2] ...")
        print("   or: python3 scripts/run_sql.py --dir <directory>")
        print("   or: python3 scripts/run_sql.py --quiet <sql_file> [sql_file2] ...")
        sys.exit(1)

    quiet_mode = '--quiet' in sys.argv
    if quiet_mode:
        sys.argv.remove('--quiet')

    if sys.argv[1] == '--dir':
        if len(sys.argv) < 3:
            print("Usage: python3 scripts/run_sql.py --dir <directory>")
            sys.exit(1)
        directory = sys.argv[2]
        file_paths = find_sql_files(directory)
        if not file_paths:
            print(f"❌ No SQL files found in {directory}")
            sys.exit(1)
    else:
        file_paths = sys.argv[1:]

    runner = SimpleSQLRunner(quiet_mode=quiet_mode)
    await runner.initialize()

    try:
        if len(file_paths) == 1:
            # Single file - show detailed output
            await runner.run_sql_file(file_paths[0])
        else:
            # Multiple files - show only errors/warnings
            await runner.run_multiple_files(file_paths)
    finally:
        await runner.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
