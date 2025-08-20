#!/usr/bin/env python3
"""
Static SQL Pattern definitions for SQL Adventure evaluator.
"""

SQL_PATTERNS = [
    # DDL Patterns
    {
        "name": "table_creation",
        "display_name": "Table Creation",
        "description": "Creating tables with CREATE TABLE statements",
        "category": "DDL",
        "complexity_level": "Basic"
    },
    {
        "name": "primary_key_definition",
        "display_name": "Primary Key Definition",
        "description": "Defining primary keys in table schemas",
        "category": "DDL",
        "complexity_level": "Basic"
    },
    {
        "name": "foreign_key_constraints",
        "display_name": "Foreign Key Constraints",
        "description": "Implementing foreign key relationships",
        "category": "DDL",
        "complexity_level": "Intermediate"
    },
    {
        "name": "check_constraints",
        "display_name": "Check Constraints",
        "description": "Adding validation rules with CHECK constraints",
        "category": "DDL",
        "complexity_level": "Intermediate"
    },
    {
        "name": "index_creation",
        "display_name": "Index Creation",
        "description": "Creating indexes for performance optimization",
        "category": "DDL",
        "complexity_level": "Intermediate"
    },
    
    # DML Patterns
    {
        "name": "basic_insert",
        "display_name": "Basic Insert",
        "description": "Simple INSERT statements for data insertion",
        "category": "DML",
        "complexity_level": "Basic"
    },
    {
        "name": "bulk_insert",
        "display_name": "Bulk Insert",
        "description": "Inserting multiple rows efficiently",
        "category": "DML",
        "complexity_level": "Intermediate"
    },
    {
        "name": "conditional_updates",
        "display_name": "Conditional Updates",
        "description": "UPDATE statements with WHERE conditions",
        "category": "DML",
        "complexity_level": "Intermediate"
    },
    
    # DQL Patterns
    {
        "name": "basic_select",
        "display_name": "Basic Select",
        "description": "Simple SELECT queries",
        "category": "DQL",
        "complexity_level": "Basic"
    },
    {
        "name": "joins",
        "display_name": "Table Joins",
        "description": "Joining multiple tables (INNER, LEFT, RIGHT, FULL)",
        "category": "DQL",
        "complexity_level": "Intermediate"
    },
    {
        "name": "subqueries",
        "display_name": "Subqueries",
        "description": "Nested queries for complex data retrieval",
        "category": "DQL",
        "complexity_level": "Intermediate"
    },
    {
        "name": "aggregation",
        "display_name": "Aggregation Functions",
        "description": "Using COUNT, SUM, AVG, MIN, MAX functions",
        "category": "DQL",
        "complexity_level": "Intermediate"
    },
    {
        "name": "group_by",
        "display_name": "GROUP BY Clauses",
        "description": "Grouping data for aggregate calculations",
        "category": "DQL",
        "complexity_level": "Intermediate"
    },
    {
        "name": "having_clause",
        "display_name": "HAVING Clause",
        "description": "Filtering grouped data with HAVING",
        "category": "DQL",
        "complexity_level": "Intermediate"
    },
    
    # Analytics Patterns
    {
        "name": "window_functions",
        "display_name": "Window Functions",
        "description": "ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, etc.",
        "category": "ANALYTICS",
        "complexity_level": "Advanced"
    },
    {
        "name": "ranking_functions",
        "display_name": "Ranking Functions", 
        "description": "ROW_NUMBER, RANK, DENSE_RANK for data ranking",
        "category": "ANALYTICS",
        "complexity_level": "Advanced"
    },
    {
        "name": "lag_lead_functions",
        "display_name": "LAG/LEAD Functions",
        "description": "Accessing previous/next row values",
        "category": "ANALYTICS",
        "complexity_level": "Advanced"
    },
    {
        "name": "aggregate_windows",
        "display_name": "Aggregate Window Functions",
        "description": "SUM, AVG, COUNT with OVER clause",
        "category": "ANALYTICS",
        "complexity_level": "Advanced"
    },
    
    # Recursive Patterns
    {
        "name": "recursive_cte",
        "display_name": "Recursive CTE",
        "description": "Common Table Expressions with recursion",
        "category": "RECURSIVE",
        "complexity_level": "Expert"
    },
    {
        "name": "hierarchical_queries",
        "display_name": "Hierarchical Queries",
        "description": "Querying tree-like data structures",
        "category": "RECURSIVE",
        "complexity_level": "Expert"
    },
    {
        "name": "graph_traversal",
        "display_name": "Graph Traversal",
        "description": "Traversing graph structures with SQL",
        "category": "RECURSIVE",
        "complexity_level": "Expert"
    },
    
    # JSON Patterns
    {
        "name": "json_extraction",
        "display_name": "JSON Data Extraction",
        "description": "Extracting values from JSON columns",
        "category": "JSON",
        "complexity_level": "Advanced"
    },
    {
        "name": "json_aggregation",
        "display_name": "JSON Aggregation",
        "description": "Creating JSON objects/arrays from query results",
        "category": "JSON",
        "complexity_level": "Advanced"
    },
    {
        "name": "json_path_queries",
        "display_name": "JSON Path Queries",
        "description": "Complex JSON path expressions",
        "category": "JSON",
        "complexity_level": "Expert"
    }
]
