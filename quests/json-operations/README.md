# JSON Operations Quest 🎯

Master modern PostgreSQL JSON operations for handling semi-structured data and API responses.

## 📊 Overview

- **12 Examples** across 4 categories
- **Difficulty**: Beginner → Advanced
- **Status**: ✅ Complete
- **Time**: 5-20 min per example

## 🚀 Quick Start

```bash
# Start environment
docker-compose up -d

# Run all examples
./scripts/run-examples.sh quest json-operations

# Run specific category
./scripts/run-examples.sh quest json-operations 01-basic-json
```

## 📚 Categories

### **01-basic-json/** 🟢 **Beginner**
- `01-json-parsing.sql` - JSON parsing and extraction (3 examples)
- `02-json-generation.sql` - JSON object and array generation (4 examples)
- `03-json-validation.sql` - JSON validation and error handling (4 examples)

### **02-json-queries/** 🟡 **Intermediate**
- `01-nested-extraction.sql` - Deep nested JSON extraction (5 examples)
- `02-array-operations.sql` - JSON array manipulation (5 examples)
- `03-json-aggregation.sql` - JSON aggregation and analysis (5 examples)

### **03-real-world-applications/** 🟡 **Intermediate**
- `01-api-data-processing.sql` - API response processing (5 examples)
- `02-configuration-management.sql` - Configuration management (5 examples)
- `03-log-analysis.sql` - Log parsing and analysis (5 examples)

### **04-advanced-patterns/** 🔴 **Advanced**
- `01-json-schema-validation.sql` - Advanced schema validation (5 examples)
- `02-json-transformation.sql` - JSON transformation patterns (5 examples)
- `03-json-performance.sql` - JSON performance optimization (5 examples)

## 🎯 Learning Path

### **🟢 Beginner (Start Here)**
1. `01-json-parsing.sql` - Extract values from JSON objects
2. `02-json-generation.sql` - Generate JSON from relational data
3. `03-json-validation.sql` - Validate JSON structure and content

### **🟡 Intermediate**
1. `01-nested-extraction.sql` - Deep nested JSON extraction
2. `02-array-operations.sql` - Array manipulation and filtering
3. `03-json-aggregation.sql` - JSON aggregation and analysis
4. `01-api-data-processing.sql` - Handle external API responses

### **🔴 Advanced**
1. `02-configuration-management.sql` - Dynamic configuration management
2. `03-log-analysis.sql` - Log parsing and pattern recognition
3. `01-json-schema-validation.sql` - Advanced validation techniques
4. `02-json-transformation.sql` - Data transformation patterns

## 🔧 Key Concepts

```sql
-- Extraction operators
SELECT 
    data->'user'->>'name' as user_name,           -- Extract as text
    data->'user'->'preferences' as preferences,   -- Extract as JSON
    data#>>'{user,email}' as email               -- Path extraction

-- Generation functions
SELECT 
    jsonb_build_object('id', id, 'name', name) as user_json,
    jsonb_agg(jsonb_build_object('id', id)) as user_array

-- Array operations
SELECT 
    jsonb_array_elements(tags) as individual_tag,
    jsonb_array_length(tags) as tag_count
```

## 🛠️ Key PostgreSQL JSON Functions

### **Extraction**
- `->` - Extract JSON object (returns JSON)
- `->>` - Extract JSON object as text (returns TEXT)
- `#>` - Extract JSON object at path (returns JSON)
- `#>>` - Extract JSON object at path as text (returns TEXT)

### **Generation**
- `jsonb_build_object()` - Build JSON objects
- `jsonb_agg()` - Aggregate values into JSON arrays
- `jsonb_object_agg()` - Aggregate key-value pairs
- `to_jsonb()` - Convert values to JSONB

### **Validation**
- `jsonb_typeof()` - Get JSON value type
- `jsonb_array_length()` - Get array length
- `jsonb_object_keys()` - Get object keys

## 🏢 Real-World Applications

- **Web Applications**: API response handling, user preferences, dynamic forms
- **Data Integration**: External API integration, data transformation, ETL processes
- **Analytics**: Semi-structured data analysis, log analysis, event tracking
- **Content Management**: Document storage, metadata management, search optimization

---

*Ready to master JSON operations? Start with [Basic JSON](./01-basic-json/)! 🚀* 