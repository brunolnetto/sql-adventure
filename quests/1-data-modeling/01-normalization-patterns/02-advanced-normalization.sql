-- Data Modeling Quest: Advanced Normalization
-- PURPOSE: Demonstrate BCNF and higher normal forms with simple examples
-- DIFFICULTY: 🔴 Advanced (15-20 min)
-- CONCEPTS: BCNF, 4NF, 5NF, multivalued dependencies

-- Example 1: Boyce-Codd Normal Form (BCNF)
-- Eliminate anomalies where determinant is not a candidate key

-- Table violating BCNF
CREATE TABLE course_enrollments (
    student_id INT,
    course_id INT,
    instructor_id INT,
    instructor_name VARCHAR(100), -- Depends on instructor_id, not the full key
    semester VARCHAR(20),
    grade CHAR(2),
    PRIMARY KEY (student_id, course_id, semester)
);

-- Insert sample data
INSERT INTO course_enrollments VALUES
(1, 101, 1, 'Dr. Smith', 'Fall 2024', 'A'),
(1, 102, 2, 'Dr. Johnson', 'Fall 2024', 'B'),
(2, 101, 1, 'Dr. Smith', 'Fall 2024', 'A-');

-- Normalized to BCNF
CREATE TABLE instructors (
    instructor_id INT PRIMARY KEY,
    instructor_name VARCHAR(100)
);

CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    instructor_id INT REFERENCES instructors (instructor_id),
    semester VARCHAR(20),
    grade CHAR(2),
    PRIMARY KEY (student_id, course_id, semester)
);

-- Insert normalized data
INSERT INTO instructors VALUES
(1, 'Dr. Smith'),
(2, 'Dr. Johnson');

INSERT INTO enrollments VALUES
(1, 101, 1, 'Fall 2024', 'A'),
(1, 102, 2, 'Fall 2024', 'B'),
(2, 101, 1, 'Fall 2024', 'A-');

-- Example 2: Fourth Normal Form (4NF)
-- Eliminate multivalued dependencies

-- Table violating 4NF (multivalued dependency)
CREATE TABLE employee_skills_locations (
    employee_id INT,
    skill VARCHAR(100),
    location VARCHAR(100),
    PRIMARY KEY (employee_id, skill, location)
);

-- Insert sample data showing multivalued dependency
INSERT INTO employee_skills_locations VALUES
(1, 'SQL', 'New York'),
(1, 'SQL', 'Remote'),
(1, 'Python', 'New York'),
(1, 'Python', 'Remote'),
(2, 'Java', 'Los Angeles'),
(2, 'Java', 'Remote');

-- Normalized to 4NF
CREATE TABLE employee_skills (
    employee_id INT,
    skill VARCHAR(100),
    PRIMARY KEY (employee_id, skill)
);

CREATE TABLE employee_locations (
    employee_id INT,
    location VARCHAR(100),
    PRIMARY KEY (employee_id, location)
);

-- Insert normalized data
INSERT INTO employee_skills VALUES
(1, 'SQL'),
(1, 'Python'),
(2, 'Java');

INSERT INTO employee_locations VALUES
(1, 'New York'),
(1, 'Remote'),
(2, 'Los Angeles'),
(2, 'Remote');

-- Example 3: Fifth Normal Form (5NF)
-- Eliminate join dependencies

-- Table violating 5NF (join dependency)
CREATE TABLE supplier_parts_projects (
    supplier_id INT,
    part_id INT,
    project_id INT,
    quantity INT,
    PRIMARY KEY (supplier_id, part_id, project_id)
);

-- Normalized to 5NF
CREATE TABLE supplier_parts (
    supplier_id INT,
    part_id INT,
    PRIMARY KEY (supplier_id, part_id)
);

CREATE TABLE supplier_projects (
    supplier_id INT,
    project_id INT,
    PRIMARY KEY (supplier_id, project_id)
);

CREATE TABLE part_projects (
    part_id INT,
    project_id INT,
    quantity INT,
    PRIMARY KEY (part_id, project_id)
);

-- Insert sample data
INSERT INTO supplier_parts VALUES
(1, 101),
(1, 102),
(2, 101);

INSERT INTO supplier_projects VALUES
(1, 201),
(1, 202),
(2, 201);

INSERT INTO part_projects VALUES
(101, 201, 100),
(101, 202, 50),
(102, 201, 75);

-- Query to reconstruct original data
SELECT
    sp.supplier_id,
    pp.part_id,
    spr.project_id,
    pp.quantity
FROM supplier_parts AS sp
INNER JOIN part_projects AS pp ON sp.part_id = pp.part_id
INNER JOIN supplier_projects
    AS spr ON sp.supplier_id = spr.supplier_id
AND pp.project_id = spr.project_id;

-- Clean up
DROP TABLE IF EXISTS course_enrollments CASCADE;
DROP TABLE IF EXISTS instructors CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS employee_skills_locations CASCADE;
DROP TABLE IF EXISTS employee_skills CASCADE;
DROP TABLE IF EXISTS employee_locations CASCADE;
DROP TABLE IF EXISTS supplier_parts_projects CASCADE;
DROP TABLE IF EXISTS supplier_parts CASCADE;
DROP TABLE IF EXISTS supplier_projects CASCADE;
DROP TABLE IF EXISTS part_projects CASCADE;
