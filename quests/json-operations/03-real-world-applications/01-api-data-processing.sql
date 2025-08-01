-- =====================================================
-- JSON Operations: API Data Processing
-- =====================================================
-- 
-- PURPOSE: Demonstrate real-world JSON processing techniques for handling
--          external API responses, data transformation, and integration
-- LEARNING OUTCOMES:
--   - Process external API responses and handle different formats
--   - Transform and normalize JSON data structures
--   - Handle API errors and validation responses
--   - Cache and optimize API response processing
--   - Integrate multiple API data sources
-- EXPECTED RESULTS: Process and transform API data for application use
-- DIFFICULTY: 🟡 Intermediate (10-15 min)
-- CONCEPTS: API integration, data transformation, error handling, caching, normalization

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS api_responses CASCADE;
DROP TABLE IF EXISTS weather_data CASCADE;
DROP TABLE IF EXISTS user_api_logs CASCADE;

-- Create API responses table
CREATE TABLE api_responses (
    id INT PRIMARY KEY,
    endpoint VARCHAR(200),
    response_data JSONB,
    status_code INT,
    response_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create weather data table for processed API data
CREATE TABLE weather_data (
    id INT PRIMARY KEY,
    city VARCHAR(100),
    processed_data JSONB,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create user API logs table
CREATE TABLE user_api_logs (
    id INT PRIMARY KEY,
    user_id INT,
    api_request JSONB,
    api_response JSONB,
    processing_status VARCHAR(50)
);

-- Insert sample API response data
INSERT INTO api_responses VALUES
(1, '/api/weather/current', '{
    "status": "success",
    "data": {
        "location": {
            "city": "New York",
            "country": "US",
            "coordinates": {"lat": 40.7128, "lon": -74.0060}
        },
        "current": {
            "temperature": 22.5,
            "humidity": 65,
            "description": "Partly cloudy",
            "wind_speed": 12.3,
            "pressure": 1013.2
        },
        "forecast": [
            {"date": "2024-01-15", "high": 25, "low": 18, "condition": "Sunny"},
            {"date": "2024-01-16", "high": 23, "low": 16, "condition": "Cloudy"},
            {"date": "2024-01-17", "high": 20, "low": 12, "condition": "Rain"}
        ]
    },
    "timestamp": "2024-01-15T10:30:00Z"
}', 200, '2024-01-15 10:30:00'),
(2, '/api/weather/current', '{
    "status": "error",
    "error": {
        "code": 404,
        "message": "City not found",
        "details": "Weather data unavailable for specified location"
    },
    "timestamp": "2024-01-15 10:35:00Z"
}', 404, '2024-01-15 10:35:00'),
(3, '/api/users/profile', '{
    "status": "success",
    "data": {
        "user_id": 12345,
        "profile": {
            "name": "John Doe",
            "email": "john.doe@example.com",
            "preferences": {
                "language": "en",
                "timezone": "America/New_York",
                "notifications": true
            }
        },
        "subscription": {
            "plan": "premium",
            "expires": "2024-12-31",
            "features": ["api_access", "analytics", "support"]
        }
    },
    "meta": {
        "version": "2.1",
        "generated_at": "2024-01-15T10:40:00Z"
    }
}', 200, '2024-01-15 10:40:00');

-- Insert sample user API logs
INSERT INTO user_api_logs VALUES
(1, 1001, '{
    "method": "GET",
    "endpoint": "/api/weather/current",
    "params": {"city": "New York", "units": "metric"},
    "headers": {"Authorization": "Bearer token123"}
}', '{
    "status": "success",
    "data": {"temperature": 22.5, "condition": "Partly cloudy"}
}', 'processed'),
(2, 1002, '{
    "method": "POST",
    "endpoint": "/api/users/profile",
    "body": {"name": "Jane Smith", "email": "jane@example.com"},
    "headers": {"Content-Type": "application/json"}
}', '{
    "status": "error",
    "message": "Validation failed",
    "errors": ["Email already exists"]
}', 'failed');

-- Example 1: API Response Processing and Validation
-- Process API responses and handle different status codes
SELECT 
    id,
    endpoint,
    status_code,
    CASE 
        WHEN status_code = 200 THEN 'Success'
        WHEN status_code BETWEEN 400 AND 499 THEN 'Client Error'
        WHEN status_code BETWEEN 500 AND 599 THEN 'Server Error'
        ELSE 'Unknown'
    END as status_category,
    CASE 
        WHEN response_data->>'status' = 'success' THEN 'Valid Response'
        WHEN response_data->>'status' = 'error' THEN 'Error Response'
        ELSE 'Unknown Format'
    END as response_type,
    CASE 
        WHEN response_data->>'status' = 'success' 
        THEN response_data->'data'
        ELSE response_data->'error'
    END as processed_data
FROM api_responses
ORDER BY response_time;

-- Example 2: Weather Data Transformation and Normalization
-- Transform weather API data into standardized format
SELECT 
    id,
    response_data->'data'->'location'->>'city' as city,
    jsonb_build_object(
        'current_weather', jsonb_build_object(
            'temperature', (response_data->'data'->'current'->>'temperature')::DECIMAL(4,1),
            'humidity', (response_data->'data'->'current'->>'humidity')::INT,
            'description', response_data->'data'->'current'->>'description',
            'wind_speed', (response_data->'data'->'current'->>'wind_speed')::DECIMAL(4,1)
        ),
        'forecast_summary', jsonb_build_object(
            'days_count', jsonb_array_length(response_data->'data'->'forecast'),
            'avg_high', (SELECT AVG((day->>'high')::INT) 
                        FROM jsonb_array_elements(response_data->'data'->'forecast') as day),
            'avg_low', (SELECT AVG((day->>'low')::INT) 
                       FROM jsonb_array_elements(response_data->'data'->'forecast') as day)
        ),
        'location_info', jsonb_build_object(
            'city', response_data->'data'->'location'->>'city',
            'country', response_data->'data'->'location'->>'country',
            'coordinates', response_data->'data'->'location'->'coordinates'
        )
    ) as normalized_weather_data
FROM api_responses
WHERE response_data->>'status' = 'success' 
  AND endpoint = '/api/weather/current'
ORDER BY response_time;

-- Example 3: Error Handling and Response Analysis
-- Analyze API errors and extract error information
SELECT 
    id,
    endpoint,
    status_code,
    response_data->'error'->>'code' as error_code,
    response_data->'error'->>'message' as error_message,
    response_data->'error'->>'details' as error_details,
    CASE 
        WHEN response_data->'error'->>'code' = '404' THEN 'Not Found'
        WHEN response_data->'error'->>'code' = '400' THEN 'Bad Request'
        WHEN response_data->'error'->>'code' = '500' THEN 'Server Error'
        ELSE 'Other Error'
    END as error_category,
    jsonb_build_object(
        'is_retryable', CASE 
            WHEN response_data->'error'->>'code' IN ('500', '502', '503') THEN true
            ELSE false
        END,
        'requires_user_action', CASE 
            WHEN response_data->'error'->>'code' IN ('400', '401', '403') THEN true
            ELSE false
        END
    ) as error_analysis
FROM api_responses
WHERE response_data->>'status' = 'error'
ORDER BY response_time;

-- Example 4: User API Request Processing
-- Process and analyze user API requests and responses
SELECT 
    id,
    user_id,
    api_request->>'method' as http_method,
    api_request->>'endpoint' as api_endpoint,
    processing_status,
    CASE 
        WHEN api_response->>'status' = 'success' THEN 'Success'
        WHEN api_response->>'status' = 'error' THEN 'Failed'
        ELSE 'Unknown'
    END as response_status,
    CASE 
        WHEN api_response->>'status' = 'success' 
        THEN jsonb_build_object(
            'data_extracted', true,
            'response_size', jsonb_array_length(api_response->'data'),
            'has_metadata', CASE WHEN api_response ? 'meta' THEN true ELSE false END
        )
        ELSE jsonb_build_object(
            'error_code', api_response->>'message',
            'validation_errors', api_response->'errors'
        )
    END as processing_result
FROM user_api_logs
ORDER BY id;

-- Example 5: API Data Integration and Caching
-- Integrate multiple API responses and create cached summaries
SELECT 
    'weather_api' as api_source,
    COUNT(*) as total_requests,
    COUNT(*) FILTER (WHERE response_data->>'status' = 'success') as successful_requests,
    COUNT(*) FILTER (WHERE response_data->>'status' = 'error') as failed_requests,
    jsonb_build_object(
        'success_rate', ROUND(
            (COUNT(*) FILTER (WHERE response_data->>'status' = 'success')::DECIMAL / COUNT(*)) * 100, 2
        ),
        'avg_response_time', AVG(EXTRACT(EPOCH FROM (response_time - LAG(response_time) OVER (ORDER BY response_time)))),
        'last_successful', MAX(response_time) FILTER (WHERE response_data->>'status' = 'success'),
        'common_errors', jsonb_agg(DISTINCT response_data->'error'->>'code') FILTER (WHERE response_data->>'status' = 'error')
    ) as api_metrics
FROM api_responses
WHERE endpoint = '/api/weather/current'

UNION ALL

SELECT 
    'user_api' as api_source,
    COUNT(*) as total_requests,
    COUNT(*) FILTER (WHERE api_response->>'status' = 'success') as successful_requests,
    COUNT(*) FILTER (WHERE api_response->>'status' = 'error') as failed_requests,
    jsonb_build_object(
        'success_rate', ROUND(
            (COUNT(*) FILTER (WHERE api_response->>'status' = 'success')::DECIMAL / COUNT(*)) * 100, 2
        ),
        'processing_success_rate', ROUND(
            (COUNT(*) FILTER (WHERE processing_status = 'processed')::DECIMAL / COUNT(*)) * 100, 2
        ),
        'unique_users', COUNT(DISTINCT user_id)
    ) as api_metrics
FROM user_api_logs;

-- Clean up
DROP TABLE IF EXISTS api_responses CASCADE;
DROP TABLE IF EXISTS weather_data CASCADE;
DROP TABLE IF EXISTS user_api_logs CASCADE; 