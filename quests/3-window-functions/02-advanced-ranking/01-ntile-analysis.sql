-- =====================================================
-- Window Functions quest: NTILE Analysis and Advanced Ranking
-- =====================================================

-- PURPOSE: Demonstrate advanced ranking techniques using NTILE function for creating
--          equal-sized groups and multiple criteria ranking for business analytics
-- LEARNING OUTCOMES: Students will understand how to use NTILE() for creating
--                    performance tiers, ranking with multiple criteria, and advanced
--                    business analytics patterns
-- EXPECTED RESULTS:
-- 1. Performance tiers created using NTILE(4) for equal-sized groups
-- 2. Multi-criteria ranking with sales amount and customer satisfaction
-- 3. Top N students identified by subject with multiple ranking criteria
-- 4. Salary quartiles calculated within each department
-- 5. Business insights from tiered performance analysis
-- DIFFICULTY: 🟡 Intermediate (10-20 min)
-- CONCEPTS: NTILE(), RANK(), DENSE_RANK(), PARTITION BY, multiple ORDER BY criteria, performance tiers

-- Clean up existing tables (idempotent)
DROP TABLE IF EXISTS employee_performance CASCADE;
DROP TABLE IF EXISTS student_scores CASCADE;
DROP TABLE IF EXISTS product_sales CASCADE;
DROP TABLE IF EXISTS department_salaries CASCADE;

-- Create employee performance table
CREATE TABLE employee_performance (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    sales_amount DECIMAL(10, 2),
    customer_satisfaction DECIMAL(3, 2),
    efficiency_score DECIMAL(3, 2)
);

-- Insert sample data
INSERT INTO employee_performance VALUES
(1, 'Alice Johnson', 'Sales', 50000.00, 4.8, 0.92),
(2, 'Bob Smith', 'Sales', 45000.00, 4.5, 0.88),
(3, 'Carol Davis', 'Sales', 60000.00, 4.2, 0.85),
(4, 'David Wilson', 'Sales', 35000.00, 4.9, 0.90),
(5, 'Eve Brown', 'Sales', 55000.00, 4.6, 0.87),
(6, 'Frank Miller', 'Marketing', 40000.00, 4.7, 0.89),
(7, 'Grace Taylor', 'Marketing', 48000.00, 4.4, 0.86),
(8, 'Henry Anderson', 'Marketing', 52000.00, 4.3, 0.84),
(9, 'Ivy Martinez', 'Marketing', 38000.00, 4.8, 0.91),
(10, 'Jack Garcia', 'Marketing', 46000.00, 4.5, 0.88);

-- Example 1: NTILE for Performance Tiers
-- Create performance tiers (Top, High, Medium, Low) based on sales amount
SELECT
    employee_id,
    name,
    department,
    sales_amount,
    NTILE(4) OVER (ORDER BY sales_amount DESC) AS performance_tier,
    CASE
        WHEN NTILE(4) OVER (ORDER BY sales_amount DESC) = 1 THEN 'Top Performer'
        WHEN
            NTILE(4) OVER (ORDER BY sales_amount DESC) = 2
            THEN 'High Performer'
        WHEN
            NTILE(4) OVER (ORDER BY sales_amount DESC) = 3
            THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS tier_description
FROM employee_performance
ORDER BY sales_amount DESC;

-- Example 2: Ranking with Multiple Criteria
-- Rank employees by sales amount, then by customer satisfaction (tie-breaker)
SELECT
    employee_id,
    name,
    department,
    sales_amount,
    customer_satisfaction,
    RANK()
        OVER (ORDER BY sales_amount DESC, customer_satisfaction DESC)
        AS overall_rank,
    DENSE_RANK()
        OVER (ORDER BY sales_amount DESC, customer_satisfaction DESC)
        AS dense_rank
FROM employee_performance
ORDER BY overall_rank;

-- Create student scores table
CREATE TABLE student_scores (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    subject VARCHAR(50),
    score INT,
    attendance_percentage DECIMAL(5, 2)
);

-- Insert sample data
INSERT INTO student_scores VALUES
(1, 'Alex', 'Math', 85, 95.5),
(2, 'Beth', 'Math', 92, 88.0),
(3, 'Chris', 'Math', 78, 92.5),
(4, 'Dana', 'Math', 95, 85.0),
(5, 'Evan', 'Math', 88, 90.5),
(6, 'Fiona', 'Science', 82, 94.0),
(7, 'George', 'Science', 89, 87.5),
(8, 'Helen', 'Science', 91, 91.0),
(9, 'Ian', 'Science', 76, 89.5),
(10, 'Julia', 'Science', 94, 93.0);

-- Example 3: Top N Students by Subject
-- Find top 3 students in each subject based on score and attendance
WITH ranked_students AS (
    SELECT
        student_id,
        name,
        subject,
        score,
        attendance_percentage,
        ROW_NUMBER()
            OVER (
                PARTITION BY subject ORDER BY score DESC, attendance_percentage DESC
            )
            AS subject_rank
    FROM student_scores
)
SELECT
    student_id,
    name,
    subject,
    score,
    attendance_percentage,
    subject_rank
FROM ranked_students
WHERE subject_rank <= 3
ORDER BY subject, subject_rank;

-- Create department salaries table
CREATE TABLE department_salaries (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    years_experience INT
);

-- Insert sample data
INSERT INTO department_salaries VALUES
(1, 'Alice', 'Engineering', 75000, 3),
(2, 'Bob', 'Engineering', 85000, 5),
(3, 'Carol', 'Engineering', 65000, 2),
(4, 'David', 'Engineering', 95000, 7),
(5, 'Eve', 'Engineering', 70000, 4),
(6, 'Frank', 'Sales', 60000, 3),
(7, 'Grace', 'Sales', 70000, 5),
(8, 'Henry', 'Sales', 55000, 2),
(9, 'Ivy', 'Sales', 80000, 6),
(10, 'Jack', 'Sales', 65000, 4),
(11, 'Kate', 'Marketing', 65000, 3),
(12, 'Liam', 'Marketing', 75000, 5),
(13, 'Mia', 'Marketing', 60000, 2),
(14, 'Noah', 'Marketing', 80000, 6),
(15, 'Olivia', 'Marketing', 70000, 4);

-- Example 4: Salary Quartiles by Department
-- Create salary quartiles within each department
SELECT
    employee_id,
    name,
    department,
    salary,
    years_experience,
    NTILE(4)
        OVER (PARTITION BY department ORDER BY salary DESC)
        AS salary_quartile,
    CASE
        WHEN
            NTILE(4) OVER (PARTITION BY department ORDER BY salary DESC) = 1
            THEN 'Top 25%'
        WHEN
            NTILE(4) OVER (PARTITION BY department ORDER BY salary DESC) = 2
            THEN 'Upper Middle 25%'
        WHEN
            NTILE(4) OVER (PARTITION BY department ORDER BY salary DESC) = 3
            THEN 'Lower Middle 25%'
        ELSE 'Bottom 25%'
    END AS quartile_description,
    ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS dept_avg_salary
FROM department_salaries
ORDER BY department, salary_quartile;

-- Clean up
DROP TABLE IF EXISTS employee_performance CASCADE;
DROP TABLE IF EXISTS student_scores CASCADE;
DROP TABLE IF EXISTS department_salaries CASCADE;
