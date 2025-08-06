-- Data Modeling Quest: Entity-Relationship Modeling
-- PURPOSE: Demonstrate ER modeling principles and relationship types
-- DIFFICULTY: 🟡 Intermediate (15-20 min)
-- CONCEPTS: ER modeling, relationship types, cardinality, weak entities, associative entities

-- Example 1: University ER Model
-- Demonstrate a comprehensive university database with various relationship types

-- Strong Entities (independent entities)
CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) UNIQUE NOT NULL,
    department_code VARCHAR(10) UNIQUE NOT NULL,
    building VARCHAR(50),
    phone VARCHAR(20),
    budget DECIMAL(12, 2),
    established_date DATE
);

CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    date_of_birth DATE,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    graduation_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (
        status IN ('active', 'graduated', 'withdrawn', 'suspended')
    )
);

CREATE TABLE faculty (
    faculty_id INT PRIMARY KEY,
    employee_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hire_date DATE DEFAULT CURRENT_DATE,
    salary DECIMAL(10, 2),
    rank VARCHAR(20) CHECK (
        rank IN ('assistant', 'associate', 'full', 'emeritus')
    ),
    status VARCHAR(20) DEFAULT 'active' CHECK (
        status IN ('active', 'retired', 'terminated')
    )
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(200) NOT NULL,
    credits INT NOT NULL CHECK (credits > 0),
    description TEXT,
    prerequisites TEXT,
    is_active BOOLEAN DEFAULT true
);

-- Weak Entities (dependent on strong entities)
CREATE TABLE sections (
    section_id INT PRIMARY KEY,
    course_id INT NOT NULL REFERENCES courses (course_id),
    section_number VARCHAR(10) NOT NULL,
    semester VARCHAR(20) NOT NULL,
    year INT NOT NULL,
    capacity INT DEFAULT 30,
    enrolled_count INT DEFAULT 0,
    room_number VARCHAR(20),
    building VARCHAR(50),
    start_time TIME,
    end_time TIME,
    days_of_week VARCHAR(20), -- 'MWF', 'TTh', etc.
    UNIQUE (course_id, section_number, semester, year)
);

CREATE TABLE student_addresses (
    address_id INT PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students (student_id),
    address_type VARCHAR(20) NOT NULL CHECK (
        address_type IN ('permanent', 'temporary', 'mailing')
    ),
    street_address VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    is_current BOOLEAN DEFAULT true,
    UNIQUE (student_id, address_type, is_current)
);

-- One-to-Many Relationships
CREATE TABLE faculty_departments (
    faculty_id INT REFERENCES faculty (faculty_id),
    department_id INT REFERENCES departments (department_id),
    appointment_type VARCHAR(20) DEFAULT 'primary' CHECK (
        appointment_type IN ('primary', 'secondary', 'adjunct')
    ),
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    PRIMARY KEY (faculty_id, department_id, appointment_type)
);

-- Many-to-Many Relationships (Associative Entities)
CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT NOT NULL REFERENCES students (student_id),
    section_id INT NOT NULL REFERENCES sections (section_id),
    enrollment_date DATE DEFAULT CURRENT_DATE,
    grade VARCHAR(2),
    grade_points DECIMAL(3, 2),
    status VARCHAR(20) DEFAULT 'enrolled' CHECK (
        status IN ('enrolled', 'dropped', 'withdrawn', 'completed')
    ),
    UNIQUE (student_id, section_id)
);

CREATE TABLE course_prerequisites (
    prerequisite_id INT PRIMARY KEY,
    course_id INT NOT NULL REFERENCES courses (course_id),
    prerequisite_course_id INT NOT NULL REFERENCES courses (course_id),
    minimum_grade VARCHAR(2) DEFAULT 'C',
    is_required BOOLEAN DEFAULT true,
    UNIQUE (course_id, prerequisite_course_id)
);

-- Insert sample data
INSERT INTO departments VALUES
(
    1,
    'Computer Science',
    'CS',
    'Engineering Building',
    '555-1000',
    500000.00,
    '1990-01-01'
),
(
    2,
    'Mathematics',
    'MATH',
    'Science Building',
    '555-1001',
    300000.00,
    '1985-01-01'
),
(
    3,
    'Business Administration',
    'BUS',
    'Business Building',
    '555-1002',
    400000.00,
    '1988-01-01'
);

INSERT INTO students VALUES
(
    1,
    'S2024001',
    'Alice',
    'Johnson',
    'alice.johnson@university.edu',
    '2000-05-15',
    '2024-01-15',
    null,
    'active'
),
(
    2,
    'S2024002',
    'Bob',
    'Smith',
    'bob.smith@university.edu',
    '1999-08-22',
    '2024-01-15',
    null,
    'active'
),
(
    3,
    'S2024003',
    'Carol',
    'Davis',
    'carol.davis@university.edu',
    '2001-03-10',
    '2024-01-15',
    null,
    'active'
);

INSERT INTO faculty VALUES
(
    1,
    'F2024001',
    'Dr. John',
    'Wilson',
    'john.wilson@university.edu',
    '2020-08-15',
    75000.00,
    'associate',
    'active'
),
(
    2,
    'F2024002',
    'Dr. Sarah',
    'Brown',
    'sarah.brown@university.edu',
    '2018-01-10',
    85000.00,
    'full',
    'active'
),
(
    3,
    'F2024003',
    'Dr. Michael',
    'Lee',
    'michael.lee@university.edu',
    '2022-03-20',
    65000.00,
    'assistant',
    'active'
);

INSERT INTO courses VALUES
(
    1,
    'CS101',
    'Introduction to Computer Science',
    3,
    'Basic concepts of programming and computer science',
    null,
    true
),
(
    2,
    'CS201',
    'Data Structures and Algorithms',
    3,
    'Advanced programming concepts and algorithm design',
    'CS101',
    true
),
(
    3,
    'MATH101',
    'Calculus I',
    4,
    'Introduction to differential calculus',
    null,
    true
),
(
    4,
    'BUS101',
    'Introduction to Business',
    3,
    'Fundamental business concepts and practices',
    null,
    true
);

INSERT INTO sections VALUES
(
    1,
    1,
    '001',
    'Spring',
    2024,
    30,
    25,
    '101',
    'Engineering Building',
    '09:00:00',
    '10:15:00',
    'MWF'
),
(
    2,
    1,
    '002',
    'Spring',
    2024,
    30,
    28,
    '102',
    'Engineering Building',
    '10:30:00',
    '11:45:00',
    'MWF'
),
(
    3,
    2,
    '001',
    'Spring',
    2024,
    25,
    20,
    '201',
    'Engineering Building',
    '13:00:00',
    '14:15:00',
    'TTh'
),
(
    4,
    3,
    '001',
    'Spring',
    2024,
    35,
    30,
    '301',
    'Science Building',
    '09:00:00',
    '10:50:00',
    'MWF'
);

INSERT INTO student_addresses VALUES
(1, 1, 'permanent', '123 Main St', 'New York', 'NY', '10001', 'USA', true),
(
    2,
    1,
    'temporary',
    '456 Campus Ave',
    'University City',
    'NY',
    '10002',
    'USA',
    true
),
(3, 2, 'permanent', '789 Oak St', 'Los Angeles', 'CA', '90210', 'USA', true);

INSERT INTO faculty_departments VALUES
(1, 1, 'primary', '2020-08-15', null),
(2, 1, 'primary', '2018-01-10', null),
(3, 2, 'primary', '2022-03-20', null),
(1, 2, 'secondary', '2021-01-15', null);

INSERT INTO enrollments VALUES
(1, 1, 1, '2024-01-15', 'A', 4.00, 'enrolled'),
(2, 1, 3, '2024-01-15', 'B', 3.00, 'enrolled'),
(3, 2, 1, '2024-01-15', 'A-', 3.67, 'enrolled'),
(4, 2, 4, '2024-01-15', 'B+', 3.33, 'enrolled'),
(5, 3, 2, '2024-01-15', 'A', 4.00, 'enrolled');

INSERT INTO course_prerequisites VALUES
(1, 2, 1, 'C', true);

-- Example 2: Relationship Analysis Queries
-- Demonstrate how to analyze different relationship types

-- One-to-Many: Department to Faculty
SELECT
    d.department_name,
    COUNT(fd.faculty_id) AS faculty_count,
    STRING_AGG(f.first_name || ' ' || f.last_name, ', ' ORDER BY f.last_name)
        AS faculty_members
FROM departments AS d
LEFT JOIN
    faculty_departments AS fd
    ON d.department_id = fd.department_id AND fd.appointment_type = 'primary'
LEFT JOIN faculty AS f ON fd.faculty_id = f.faculty_id
GROUP BY d.department_id, d.department_name
ORDER BY faculty_count DESC;

-- Many-to-Many: Students to Courses through Enrollments
SELECT
    s.first_name || ' ' || s.last_name AS student_name,
    COUNT(DISTINCT sec.course_id) AS courses_enrolled,
    STRING_AGG(c.course_name, ', ' ORDER BY c.course_name) AS enrolled_courses,
    ROUND(AVG(e.grade_points), 2) AS avg_gpa
FROM students AS s
LEFT JOIN enrollments AS e ON s.student_id = e.student_id
LEFT JOIN sections AS sec ON e.section_id = sec.section_id
LEFT JOIN courses AS c ON sec.course_id = c.course_id
GROUP BY s.student_id, s.first_name, s.last_name
ORDER BY avg_gpa DESC NULLS LAST;

-- Weak Entity: Sections dependent on Courses
SELECT
    c.course_code,
    c.course_name,
    COUNT(sec.section_id) AS section_count,
    SUM(sec.enrolled_count) AS total_enrolled,
    ROUND(AVG(sec.enrolled_count::DECIMAL / sec.capacity), 2) AS avg_utilization
FROM courses AS c
LEFT JOIN sections AS sec ON c.course_id = sec.course_id
WHERE c.is_active = true
GROUP BY c.course_id, c.course_code, c.course_name
ORDER BY total_enrolled DESC;

-- Example 3: Complex Relationship Queries
-- Demonstrate complex ER relationship analysis

-- Faculty teaching load analysis
SELECT
    d.department_name,
    f.first_name || ' ' || f.last_name AS faculty_name,
    COUNT(DISTINCT sec.section_id) AS sections_teaching,
    COUNT(DISTINCT e.student_id) AS total_students,
    ROUND(AVG(e.grade_points), 2) AS avg_student_gpa
FROM faculty AS f
INNER JOIN
    faculty_departments AS fd
    ON f.faculty_id = fd.faculty_id AND fd.appointment_type = 'primary'
INNER JOIN departments AS d ON fd.department_id = d.department_id
-- Assuming faculty_id in sections
LEFT JOIN sections AS sec ON f.faculty_id = sec.faculty_id
LEFT JOIN enrollments AS e ON sec.section_id = e.section_id
WHERE f.status = 'active'
GROUP BY f.faculty_id, f.first_name, f.last_name, d.department_name
ORDER BY total_students DESC;

-- Student academic progress tracking
WITH student_progress AS (
    SELECT
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        COUNT(DISTINCT sec.course_id) AS courses_completed,
        SUM(c.credits) AS total_credits,
        ROUND(AVG(e.grade_points), 2) AS cumulative_gpa,
        MIN(e.enrollment_date) AS first_enrollment,
        MAX(e.enrollment_date) AS last_enrollment
    FROM students AS s
    LEFT JOIN
        enrollments AS e
        ON s.student_id = e.student_id AND e.status = 'completed'
    LEFT JOIN sections AS sec ON e.section_id = sec.section_id
    LEFT JOIN courses AS c ON sec.course_id = c.course_id
    GROUP BY s.student_id, s.first_name, s.last_name
)

SELECT
    student_name,
    courses_completed,
    total_credits,
    cumulative_gpa,
    CASE
        WHEN total_credits >= 120 THEN 'Graduation Eligible'
        WHEN total_credits >= 90 THEN 'Senior'
        WHEN total_credits >= 60 THEN 'Junior'
        WHEN total_credits >= 30 THEN 'Sophomore'
        ELSE 'Freshman'
    END AS academic_standing
FROM student_progress
ORDER BY cumulative_gpa DESC NULLS LAST;

-- Example 4: ER Model Validation
-- Demonstrate data integrity and relationship validation

-- Check for orphaned records (referential integrity)
SELECT
    'Students without addresses' AS issue,
    COUNT(*) AS count
FROM students AS s
LEFT JOIN student_addresses AS sa ON s.student_id = sa.student_id
WHERE sa.address_id IS null
UNION ALL
SELECT
    'Faculty without departments' AS issue,
    COUNT(*) AS count
FROM faculty AS f
LEFT JOIN faculty_departments AS fd ON f.faculty_id = fd.faculty_id
WHERE fd.faculty_id IS null
UNION ALL
SELECT
    'Sections without enrollments' AS issue,
    COUNT(*) AS count
FROM sections AS sec
LEFT JOIN enrollments AS e ON sec.section_id = e.section_id
WHERE e.enrollment_id IS null;

-- Validate relationship cardinality
SELECT
    'One-to-Many validation' AS validation_type,
    CASE
        WHEN
            COUNT(*) > 1
            THEN 'VIOLATION: Student has multiple current permanent addresses'
        ELSE 'OK'
    END AS status
FROM student_addresses
WHERE address_type = 'permanent' AND is_current = true
GROUP BY student_id
HAVING COUNT(*) > 1;

-- Example 5: ER Model Evolution
-- Demonstrate how to evolve the ER model over time

-- Add new entity: Research Projects
CREATE TABLE research_projects (
    project_id INT PRIMARY KEY,
    project_title VARCHAR(200) NOT NULL,
    project_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12, 2),
    status VARCHAR(20) DEFAULT 'active' CHECK (
        status IN ('active', 'completed', 'suspended', 'cancelled')
    )
);

-- Add new relationship: Faculty-Project (Many-to-Many)
CREATE TABLE faculty_projects (
    faculty_id INT REFERENCES faculty (faculty_id),
    project_id INT REFERENCES research_projects (project_id),
    role VARCHAR(50) NOT NULL, -- 'PI', 'Co-PI', 'Researcher', 'Student'
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    hours_per_week DECIMAL(4, 2),
    PRIMARY KEY (faculty_id, project_id, role)
);

-- Add new relationship: Student-Project (Many-to-Many)
CREATE TABLE student_projects (
    student_id INT REFERENCES students (student_id),
    project_id INT REFERENCES research_projects (project_id),
    role VARCHAR(50) NOT NULL, -- 'Research Assistant', 'Student Researcher'
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    hours_per_week DECIMAL(4, 2),
    academic_credit BOOLEAN DEFAULT false,
    PRIMARY KEY (student_id, project_id, role)
);

-- Insert sample research data
INSERT INTO research_projects VALUES
(
    1,
    'Machine Learning in Education',
    'ML-EDU-2024',
    'Applying ML techniques to improve student learning outcomes',
    '2024-01-01',
    '2025-12-31',
    150000.00,
    'active'
),
(
    2,
    'Database Performance Optimization',
    'DB-PERF-2024',
    'Research on optimizing database queries for large datasets',
    '2024-03-01',
    '2024-12-31',
    75000.00,
    'active'
);

INSERT INTO faculty_projects VALUES
(1, 1, 'PI', '2024-01-01', '2025-12-31', 20.0),
(2, 1, 'Co-PI', '2024-01-01', '2025-12-31', 15.0),
(1, 2, 'PI', '2024-03-01', '2024-12-31', 10.0);

INSERT INTO student_projects VALUES
(1, 1, 'Research Assistant', '2024-01-15', '2025-12-31', 10.0, true),
(2, 2, 'Student Researcher', '2024-03-15', '2024-12-31', 8.0, false);

-- Query the evolved ER model
SELECT
    p.project_title,
    p.budget,
    COUNT(DISTINCT fp.faculty_id) AS faculty_count,
    COUNT(DISTINCT sp.student_id) AS student_count,
    ROUND(
        p.budget
        / (COUNT(DISTINCT fp.faculty_id) + COUNT(DISTINCT sp.student_id)),
        2
    ) AS budget_per_participant
FROM research_projects AS p
LEFT JOIN faculty_projects AS fp ON p.project_id = fp.project_id
LEFT JOIN student_projects AS sp ON p.project_id = sp.project_id
WHERE p.status = 'active'
GROUP BY p.project_id, p.project_title, p.budget
ORDER BY budget_per_participant DESC;

-- Clean up
DROP TABLE IF EXISTS student_projects CASCADE;
DROP TABLE IF EXISTS faculty_projects CASCADE;
DROP TABLE IF EXISTS research_projects CASCADE;
DROP TABLE IF EXISTS course_prerequisites CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS faculty_departments CASCADE;
DROP TABLE IF EXISTS student_addresses CASCADE;
DROP TABLE IF EXISTS sections CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS faculty CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
