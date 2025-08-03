-- Data Modeling Quest: Healthcare Data Model
-- PURPOSE: Demonstrate healthcare data modeling with patient records and medical data
-- DIFFICULTY: Advanced (20-25 min)
-- CONCEPTS: Healthcare modeling, patient records, medical data, HIPAA compliance

-- Example 1: Core Healthcare Entities
-- Demonstrate core healthcare data model

-- Patients and Demographics
CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    patient_number VARCHAR(20) UNIQUE NOT NULL,
    mrn VARCHAR(20) UNIQUE, -- Medical Record Number
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other', 'unknown')),
    race VARCHAR(50),
    ethnicity VARCHAR(50),
    marital_status VARCHAR(20),
    primary_language VARCHAR(50) DEFAULT 'English',
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relationship VARCHAR(50),
    insurance_provider VARCHAR(100),
    insurance_policy_number VARCHAR(50),
    insurance_group_number VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE patient_addresses (
    address_id INT PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(patient_id),
    address_type VARCHAR(20) NOT NULL CHECK (address_type IN ('home', 'work', 'billing', 'mailing')),
    is_primary BOOLEAN DEFAULT false,
    street_address VARCHAR(200) NOT NULL,
    street_address2 VARCHAR(200),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) DEFAULT 'USA',
    phone VARCHAR(20),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(patient_id, address_type, is_primary)
);

-- Healthcare Providers
CREATE TABLE providers (
    provider_id INT PRIMARY KEY,
    provider_number VARCHAR(20) UNIQUE NOT NULL,
    npi VARCHAR(20) UNIQUE, -- National Provider Identifier
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    title VARCHAR(50), -- Dr., RN, etc.
    specialty VARCHAR(100),
    license_number VARCHAR(50),
    license_state VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    location VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE provider_departments (
    provider_id INT REFERENCES providers(provider_id),
    department_id INT REFERENCES departments(department_id),
    role VARCHAR(50), -- 'attending', 'resident', 'nurse', etc.
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    is_primary BOOLEAN DEFAULT false,
    PRIMARY KEY (provider_id, department_id, role)
);

-- Medical Records
CREATE TABLE encounters (
    encounter_id INT PRIMARY KEY,
    patient_id INT NOT NULL REFERENCES patients(patient_id),
    provider_id INT REFERENCES providers(provider_id),
    department_id INT REFERENCES departments(department_id),
    encounter_type VARCHAR(50) NOT NULL CHECK (encounter_type IN ('office_visit', 'emergency', 'inpatient', 'outpatient', 'telehealth')),
    encounter_date TIMESTAMP NOT NULL,
    chief_complaint TEXT,
    diagnosis TEXT,
    treatment_plan TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vital_signs (
    vital_id INT PRIMARY KEY,
    encounter_id INT NOT NULL REFERENCES encounters(encounter_id),
    patient_id INT NOT NULL REFERENCES patients(patient_id),
    vital_date TIMESTAMP NOT NULL,
    temperature_f DECIMAL(4,1),
    blood_pressure_systolic INT,
    blood_pressure_diastolic INT,
    heart_rate INT,
    respiratory_rate INT,
    oxygen_saturation DECIMAL(4,1),
    height_cm DECIMAL(5,1),
    weight_kg DECIMAL(5,1),
    bmi DECIMAL(4,1),
    pain_scale INT CHECK (pain_scale >= 0 AND pain_scale <= 10),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE medications (
    medication_id INT PRIMARY KEY,
    medication_name VARCHAR(200) NOT NULL,
    generic_name VARCHAR(200),
    medication_class VARCHAR(100),
    dosage_form VARCHAR(50), -- tablet, liquid, injection, etc.
    strength VARCHAR(50), -- 500mg, 10mg/ml, etc.
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY,
    encounter_id INT NOT NULL REFERENCES encounters(encounter_id),
    patient_id INT NOT NULL REFERENCES patients(patient_id),
    provider_id INT NOT NULL REFERENCES providers(provider_id),
    medication_id INT NOT NULL REFERENCES medications(medication_id),
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration VARCHAR(100), -- 7 days, 30 days, etc.
    quantity_prescribed INT,
    quantity_dispensed INT,
    instructions TEXT,
    prescribed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'discontinued', 'expired')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO patients VALUES
(1, 'PAT001', 'MRN001', 'John', 'Smith', '1980-05-15', 'male', 'White', 'Non-Hispanic', 'Married', 'English', 'Jane Smith', '555-1234', 'Spouse', 'Blue Cross', 'POL001', 'GRP001', true),
(2, 'PAT002', 'MRN002', 'Sarah', 'Johnson', '1992-08-22', 'female', 'Black', 'Non-Hispanic', 'Single', 'English', 'Robert Johnson', '555-5678', 'Father', 'Aetna', 'POL002', 'GRP002', true),
(3, 'PAT003', 'MRN003', 'Michael', 'Brown', '1975-03-10', 'male', 'Hispanic', 'Hispanic', 'Divorced', 'Spanish', 'Maria Brown', '555-9012', 'Sister', 'Cigna', 'POL003', 'GRP003', true);

INSERT INTO patient_addresses VALUES
(1, 1, 'home', true, '123 Main St', NULL, 'New York', 'NY', '10001', 'USA', '555-1234', 'john.smith@email.com'),
(2, 2, 'home', true, '456 Oak Ave', 'Apt 2B', 'Los Angeles', 'CA', '90210', 'USA', '555-5678', 'sarah.johnson@email.com'),
(3, 3, 'home', true, '789 Pine St', NULL, 'Chicago', 'IL', '60601', 'USA', '555-9012', 'michael.brown@email.com');

INSERT INTO providers VALUES
(1, 'PROV001', 'NPI001', 'Dr. Alice', 'Wilson', 'MD', 'Internal Medicine', 'LIC001', 'NY', '555-1001', 'alice.wilson@hospital.com', true),
(2, 'PROV002', 'NPI002', 'Dr. Bob', 'Davis', 'MD', 'Cardiology', 'LIC002', 'CA', '555-1002', 'bob.davis@hospital.com', true),
(3, 'PROV003', 'NPI003', 'Dr. Carol', 'Miller', 'MD', 'Pediatrics', 'LIC003', 'IL', '555-1003', 'carol.miller@hospital.com', true);

INSERT INTO departments VALUES
(1, 'Internal Medicine', 'IM', 'General internal medicine services', 'Building A, Floor 2', '555-2001', true),
(2, 'Cardiology', 'CARD', 'Cardiovascular services', 'Building B, Floor 1', '555-2002', true),
(3, 'Pediatrics', 'PED', 'Pediatric care services', 'Building A, Floor 1', '555-2003', true);

INSERT INTO provider_departments VALUES
(1, 1, 'attending', '2020-01-01', NULL, true),
(2, 2, 'attending', '2018-03-15', NULL, true),
(3, 3, 'attending', '2019-06-10', NULL, true);

INSERT INTO encounters VALUES
(1, 1, 1, 1, 'office_visit', '2024-01-15 10:30:00', 'Chest pain and shortness of breath', 'Hypertension, possible angina', 'Prescribe blood pressure medication, schedule follow-up', 'completed'),
(2, 2, 2, 2, 'office_visit', '2024-01-16 14:15:00', 'Annual checkup', 'Healthy', 'Continue current medications, annual blood work', 'completed'),
(3, 3, 3, 3, 'office_visit', '2024-01-17 09:45:00', 'Fever and cough', 'Upper respiratory infection', 'Prescribe antibiotics, rest and fluids', 'completed');

INSERT INTO vital_signs VALUES
(1, 1, 1, '2024-01-15 10:30:00', 98.6, 140, 90, 85, 18, 98.0, 175.0, 80.0, 26.1, 3, 'Patient reports mild chest discomfort'),
(2, 2, 2, '2024-01-16 14:15:00', 98.2, 120, 80, 72, 16, 99.0, 165.0, 60.0, 22.0, 0, 'All vitals within normal range'),
(3, 3, 3, '2024-01-17 09:45:00', 101.2, 118, 78, 88, 20, 97.0, 180.0, 85.0, 26.2, 4, 'Elevated temperature, increased heart rate');

INSERT INTO medications VALUES
(1, 'Lisinopril', 'Lisinopril', 'ACE Inhibitor', 'tablet', '10mg', true),
(2, 'Amlodipine', 'Amlodipine', 'Calcium Channel Blocker', 'tablet', '5mg', true),
(3, 'Amoxicillin', 'Amoxicillin', 'Antibiotic', 'capsule', '500mg', true),
(4, 'Ibuprofen', 'Ibuprofen', 'NSAID', 'tablet', '400mg', true);

INSERT INTO prescriptions VALUES
(1, 1, 1, 1, 1, '10mg', 'Once daily', '30 days', 30, 30, 'Take in the morning with food', '2024-01-15 10:30:00', '2024-01-15', '2024-02-14', 'active'),
(2, 1, 1, 1, 2, '5mg', 'Once daily', '30 days', 30, 30, 'Take in the evening', '2024-01-15 10:30:00', '2024-01-15', '2024-02-14', 'active'),
(3, 3, 3, 3, 3, '500mg', 'Three times daily', '7 days', 21, 21, 'Take with food', '2024-01-17 09:45:00', '2024-01-17', '2024-01-24', 'active');

-- Example 2: Patient Analytics and Reporting
-- Demonstrate healthcare analytics

-- Patient demographics analysis
SELECT 
    gender,
    COUNT(*) as patient_count,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth))), 1) as avg_age,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM patients
WHERE is_active = true
GROUP BY gender
ORDER BY patient_count DESC;

-- Provider workload analysis
SELECT 
    p.first_name || ' ' || p.last_name as provider_name,
    p.specialty,
    d.department_name,
    COUNT(e.encounter_id) as total_encounters,
    COUNT(DISTINCT e.patient_id) as unique_patients,
    ROUND(AVG(EXTRACT(EPOCH FROM (e.encounter_date - LAG(e.encounter_date) OVER (PARTITION BY p.provider_id ORDER BY e.encounter_date))) / 3600), 2) as avg_hours_between_encounters
FROM providers p
LEFT JOIN provider_departments pd ON p.provider_id = pd.provider_id AND pd.is_primary = true
LEFT JOIN departments d ON pd.department_id = d.department_id
LEFT JOIN encounters e ON p.provider_id = e.provider_id
WHERE p.is_active = true
AND e.encounter_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.provider_id, p.first_name, p.last_name, p.specialty, d.department_name
ORDER BY total_encounters DESC;

-- Vital signs trends analysis
WITH vital_trends AS (
    SELECT 
        patient_id,
        vital_date,
        blood_pressure_systolic,
        blood_pressure_diastolic,
        heart_rate,
        temperature_f,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY vital_date) as reading_number
    FROM vital_signs
    WHERE blood_pressure_systolic IS NOT NULL
    AND vital_date >= CURRENT_DATE - INTERVAL '90 days'
)
SELECT 
    p.first_name || ' ' || p.last_name as patient_name,
    vt.vital_date,
    vt.blood_pressure_systolic,
    vt.blood_pressure_diastolic,
    vt.heart_rate,
    vt.temperature_f,
    CASE 
        WHEN vt.blood_pressure_systolic >= 140 OR vt.blood_pressure_diastolic >= 90 THEN 'High'
        WHEN vt.blood_pressure_systolic < 90 OR vt.blood_pressure_diastolic < 60 THEN 'Low'
        ELSE 'Normal'
    END as bp_status,
    CASE 
        WHEN vt.heart_rate > 100 THEN 'Tachycardia'
        WHEN vt.heart_rate < 60 THEN 'Bradycardia'
        ELSE 'Normal'
    END as hr_status
FROM vital_trends vt
JOIN patients p ON vt.patient_id = p.patient_id
ORDER BY p.last_name, vt.vital_date;

-- Example 3: Medication Management
-- Demonstrate medication tracking and management

-- Active prescriptions by patient
SELECT 
    p.first_name || ' ' || p.last_name as patient_name,
    m.medication_name,
    m.medication_class,
    pr.dosage,
    pr.frequency,
    pr.start_date,
    pr.end_date,
    pr.status,
    CASE 
        WHEN pr.end_date < CURRENT_DATE THEN 'Expired'
        WHEN pr.end_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'Expiring Soon'
        ELSE 'Active'
    END as prescription_status
FROM prescriptions pr
JOIN patients p ON pr.patient_id = p.patient_id
JOIN medications m ON pr.medication_id = m.medication_id
WHERE pr.status = 'active'
ORDER BY p.last_name, pr.end_date;

-- Medication adherence analysis
WITH prescription_analysis AS (
    SELECT 
        pr.patient_id,
        pr.medication_id,
        pr.quantity_prescribed,
        pr.quantity_dispensed,
        pr.start_date,
        pr.end_date,
        EXTRACT(DAYS FROM (pr.end_date - pr.start_date)) as days_prescribed,
        CASE 
            WHEN pr.frequency LIKE '%daily%' THEN 1
            WHEN pr.frequency LIKE '%twice%' THEN 2
            WHEN pr.frequency LIKE '%three%' THEN 3
            ELSE 1
        END as doses_per_day
    FROM prescriptions pr
    WHERE pr.status = 'active'
    AND pr.end_date >= CURRENT_DATE
)
SELECT 
    p.first_name || ' ' || p.last_name as patient_name,
    m.medication_name,
    pa.quantity_prescribed,
    pa.quantity_dispensed,
    pa.days_prescribed,
    pa.doses_per_day,
    (pa.days_prescribed * pa.doses_per_day) as expected_doses,
    ROUND((pa.quantity_dispensed::DECIMAL / (pa.days_prescribed * pa.doses_per_day)) * 100, 2) as adherence_percentage,
    CASE 
        WHEN (pa.quantity_dispensed::DECIMAL / (pa.days_prescribed * pa.doses_per_day)) >= 0.8 THEN 'Good'
        WHEN (pa.quantity_dispensed::DECIMAL / (pa.days_prescribed * pa.doses_per_day)) >= 0.6 THEN 'Fair'
        ELSE 'Poor'
    END as adherence_status
FROM prescription_analysis pa
JOIN patients p ON pa.patient_id = p.patient_id
JOIN medications m ON pa.medication_id = m.medication_id
ORDER BY adherence_percentage;

-- Example 4: Clinical Decision Support
-- Demonstrate clinical decision support queries

-- Patients with high blood pressure
SELECT 
    p.first_name || ' ' || p.last_name as patient_name,
    p.date_of_birth,
    vs.vital_date,
    vs.blood_pressure_systolic,
    vs.blood_pressure_diastolic,
    CASE 
        WHEN vs.blood_pressure_systolic >= 180 OR vs.blood_pressure_diastolic >= 110 THEN 'Stage 3 Hypertension'
        WHEN vs.blood_pressure_systolic >= 160 OR vs.blood_pressure_diastolic >= 100 THEN 'Stage 2 Hypertension'
        WHEN vs.blood_pressure_systolic >= 140 OR vs.blood_pressure_diastolic >= 90 THEN 'Stage 1 Hypertension'
        WHEN vs.blood_pressure_systolic >= 130 OR vs.blood_pressure_diastolic >= 80 THEN 'Elevated'
        ELSE 'Normal'
    END as bp_classification,
    CASE 
        WHEN vs.blood_pressure_systolic >= 180 OR vs.blood_pressure_diastolic >= 110 THEN 'Immediate medical attention required'
        WHEN vs.blood_pressure_systolic >= 160 OR vs.blood_pressure_diastolic >= 100 THEN 'Schedule follow-up within 1 week'
        WHEN vs.blood_pressure_systolic >= 140 OR vs.blood_pressure_diastolic >= 90 THEN 'Monitor and lifestyle changes'
        ELSE 'Continue monitoring'
    END as recommendation
FROM vital_signs vs
JOIN patients p ON vs.patient_id = p.patient_id
WHERE vs.blood_pressure_systolic >= 130 OR vs.blood_pressure_diastolic >= 80
AND vs.vital_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY vs.blood_pressure_systolic DESC, vs.blood_pressure_diastolic DESC;

-- Drug interaction check
WITH patient_medications AS (
    SELECT DISTINCT
        pr.patient_id,
        pr.medication_id,
        m.medication_name,
        m.medication_class
    FROM prescriptions pr
    JOIN medications m ON pr.medication_id = m.medication_id
    WHERE pr.status = 'active'
)
SELECT 
    p.first_name || ' ' || p.last_name as patient_name,
    STRING_AGG(pm.medication_name, ', ' ORDER BY pm.medication_name) as current_medications,
    COUNT(pm.medication_id) as medication_count,
    CASE 
        WHEN COUNT(pm.medication_id) >= 5 THEN 'High risk - Multiple medications'
        WHEN COUNT(pm.medication_id) >= 3 THEN 'Moderate risk - Review needed'
        ELSE 'Low risk'
    END as polypharmacy_risk
FROM patient_medications pm
JOIN patients p ON pm.patient_id = p.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(pm.medication_id) >= 2
ORDER BY medication_count DESC;

-- Example 5: Quality Metrics and Reporting
-- Demonstrate healthcare quality metrics

-- Readmission risk analysis
WITH encounter_analysis AS (
    SELECT 
        e.patient_id,
        e.encounter_date,
        e.encounter_type,
        e.diagnosis,
        LAG(e.encounter_date) OVER (PARTITION BY e.patient_id ORDER BY e.encounter_date) as previous_encounter_date,
        EXTRACT(DAYS FROM (e.encounter_date - LAG(e.encounter_date) OVER (PARTITION BY e.patient_id ORDER BY e.encounter_date))) as days_since_previous
    FROM encounters e
    WHERE e.status = 'completed'
)
SELECT 
    p.first_name || ' ' || p.last_name as patient_name,
    ea.encounter_date,
    ea.encounter_type,
    ea.diagnosis,
    ea.days_since_previous,
    CASE 
        WHEN ea.days_since_previous <= 30 THEN 'High Risk'
        WHEN ea.days_since_previous <= 90 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as readmission_risk,
    CASE 
        WHEN ea.days_since_previous <= 30 THEN 'Schedule follow-up within 1 week'
        WHEN ea.days_since_previous <= 90 THEN 'Schedule follow-up within 2 weeks'
        ELSE 'Standard follow-up'
    END as recommendation
FROM encounter_analysis ea
JOIN patients p ON ea.patient_id = p.patient_id
WHERE ea.days_since_previous IS NOT NULL
AND ea.days_since_previous <= 90
ORDER BY ea.days_since_previous;

-- Provider performance metrics
SELECT 
    p.first_name || ' ' || p.last_name as provider_name,
    p.specialty,
    COUNT(e.encounter_id) as total_encounters,
    COUNT(DISTINCT e.patient_id) as unique_patients,
    ROUND(AVG(EXTRACT(EPOCH FROM (e.encounter_date - LAG(e.encounter_date) OVER (PARTITION BY p.provider_id ORDER BY e.encounter_date))) / 3600), 2) as avg_hours_between_encounters,
    COUNT(pr.prescription_id) as prescriptions_written,
    ROUND(COUNT(pr.prescription_id)::DECIMAL / COUNT(e.encounter_id), 2) as prescriptions_per_encounter
FROM providers p
LEFT JOIN encounters e ON p.provider_id = e.provider_id
LEFT JOIN prescriptions pr ON e.encounter_id = pr.encounter_id
WHERE p.is_active = true
AND e.encounter_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY p.provider_id, p.first_name, p.last_name, p.specialty
ORDER BY total_encounters DESC;

-- Clean up
DROP TABLE IF EXISTS prescriptions CASCADE;
DROP TABLE IF EXISTS medications CASCADE;
DROP TABLE IF EXISTS vital_signs CASCADE;
DROP TABLE IF EXISTS encounters CASCADE;
DROP TABLE IF EXISTS provider_departments CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS providers CASCADE;
DROP TABLE IF EXISTS patient_addresses CASCADE;
DROP TABLE IF EXISTS patients CASCADE; 