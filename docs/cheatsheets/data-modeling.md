# Data Modeling Cheatsheet 🏗️

Your complete guide to database design patterns, normalization, and schema optimization for building robust, scalable data architectures.

## 🎯 **Core Principles**

### **1. Normalization Patterns**

#### **First Normal Form (1NF)**
```sql
-- ❌ BEFORE: Unnormalized
CREATE TABLE orders (
    order_id INT,
    customer_name VARCHAR(100),
    items TEXT -- "item1,item2,item3"
);

-- ✅ AFTER: 1NF
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_name VARCHAR(100)
);

CREATE TABLE order_items (
    order_id INT,
    item_name VARCHAR(100),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
```

#### **Second Normal Form (2NF)**
```sql
-- ❌ BEFORE: Partial dependency
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    product_name VARCHAR(100), -- Depends only on product_id
    quantity INT,
    price DECIMAL(10,2)
);

-- ✅ AFTER: 2NF
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10,2)
);

CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

#### **Third Normal Form (3NF)**
```sql
-- ❌ BEFORE: Transitive dependency
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    state_tax_rate DECIMAL(5,4) -- Depends on state, not customer_id
);

-- ✅ AFTER: 3NF
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    zip_code VARCHAR(10)
);

CREATE TABLE zip_codes (
    zip_code VARCHAR(10) PRIMARY KEY,
    city VARCHAR(50),
    state VARCHAR(50)
);

CREATE TABLE states (
    state VARCHAR(50) PRIMARY KEY,
    state_tax_rate DECIMAL(5,4)
);
```

### **2. Denormalization Strategies**

#### **Performance Denormalization**
```sql
-- Add computed columns for frequently accessed data
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2),
    item_count INT, -- Denormalized for performance
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Update triggers to maintain denormalized data
CREATE OR REPLACE FUNCTION update_order_summary()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders 
    SET total_amount = (
        SELECT SUM(quantity * unit_price) 
        FROM order_items 
        WHERE order_id = NEW.order_id
    ),
    item_count = (
        SELECT COUNT(*) 
        FROM order_items 
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### **Analytics Denormalization**
```sql
-- Create fact table for analytics
CREATE TABLE sales_facts (
    sale_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    store_id INT,
    sale_date DATE,
    quantity INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    -- Denormalized dimensions for faster queries
    customer_name VARCHAR(100),
    product_name VARCHAR(100),
    store_name VARCHAR(100),
    region VARCHAR(50),
    category VARCHAR(50)
);
```

### **3. Schema Design Patterns**

#### **Entity Relationship Design**
```sql
-- One-to-Many Relationship
CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100)
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Many-to-Many Relationship
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100)
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100)
);

CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    enrollment_date DATE,
    grade CHAR(1),
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
```

#### **Inheritance Patterns**
```sql
-- Single Table Inheritance
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_type VARCHAR(20), -- 'customer', 'employee', 'admin'
    email VARCHAR(100),
    password_hash VARCHAR(255),
    -- Customer-specific fields
    customer_level VARCHAR(20),
    -- Employee-specific fields
    employee_id VARCHAR(20),
    department VARCHAR(50),
    -- Admin-specific fields
    admin_level VARCHAR(20)
);

-- Class Table Inheritance
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email VARCHAR(100),
    password_hash VARCHAR(255)
);

CREATE TABLE customers (
    user_id INT PRIMARY KEY,
    customer_level VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE employees (
    user_id INT PRIMARY KEY,
    employee_id VARCHAR(20),
    department VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);
```

### **4. Data Integrity Constraints**

#### **Check Constraints**
```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) CHECK (price > 0),
    category VARCHAR(50) CHECK (category IN ('electronics', 'clothing', 'books')),
    stock_quantity INT CHECK (stock_quantity >= 0),
    created_date DATE DEFAULT CURRENT_DATE,
    CONSTRAINT valid_price_range CHECK (price BETWEEN 0.01 AND 999999.99)
);
```

#### **Unique Constraints**
```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE
);

-- Composite unique constraint
CREATE TABLE course_sections (
    course_id INT,
    section_number INT,
    semester VARCHAR(20),
    year INT,
    UNIQUE(course_id, section_number, semester, year)
);
```

#### **Foreign Key Constraints**
```sql
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- Self-referencing foreign key
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    manager_id INT,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);
```

### **5. Schema Evolution Patterns**

#### **Adding New Columns**
```sql
-- Add nullable column (safe)
ALTER TABLE customers ADD COLUMN phone VARCHAR(20);

-- Add column with default value
ALTER TABLE products ADD COLUMN is_active BOOLEAN DEFAULT true;

-- Add computed column
ALTER TABLE orders ADD COLUMN total_amount DECIMAL(10,2);
UPDATE orders SET total_amount = (
    SELECT SUM(quantity * unit_price) 
    FROM order_items 
    WHERE order_id = orders.order_id
);
```

#### **Modifying Existing Columns**
```sql
-- Extend column size (safe)
ALTER TABLE products ALTER COLUMN product_name TYPE VARCHAR(200);

-- Change column type (requires data validation)
ALTER TABLE products ALTER COLUMN price TYPE DECIMAL(12,2);

-- Add NOT NULL constraint
ALTER TABLE customers ALTER COLUMN email SET NOT NULL;
```

#### **Table Refactoring**
```sql
-- Split table
CREATE TABLE customer_profiles (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE customer_preferences (
    customer_id INT PRIMARY KEY,
    newsletter_subscription BOOLEAN DEFAULT false,
    marketing_consent BOOLEAN DEFAULT false,
    FOREIGN KEY (customer_id) REFERENCES customer_profiles(customer_id)
);

-- Migrate data
INSERT INTO customer_profiles (customer_id, first_name, last_name, email)
SELECT customer_id, first_name, last_name, email FROM customers;

INSERT INTO customer_preferences (customer_id, newsletter_subscription, marketing_consent)
SELECT customer_id, newsletter_subscription, marketing_consent FROM customers;
```

## 🏗️ **Real-World Patterns**

### **E-commerce Schema**
```sql
-- Core entities
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100),
    parent_category_id INT,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) CHECK (price > 0),
    category_id INT,
    stock_quantity INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    total_amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT CHECK (quantity > 0),
    unit_price DECIMAL(10,2),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

### **Healthcare Schema**
```sql
CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    contact_phone VARCHAR(20)
);

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    specialization VARCHAR(100),
    license_number VARCHAR(50) UNIQUE
);

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'scheduled',
    notes TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE medical_records (
    record_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    diagnosis TEXT,
    treatment TEXT,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);
```

## 📊 **Performance Optimization**

### **Indexing Strategies**
```sql
-- Primary key indexes (automatic)
CREATE TABLE products (
    product_id INT PRIMARY KEY, -- Indexed automatically
    product_name VARCHAR(200)
);

-- Single column indexes
CREATE INDEX idx_products_name ON products(product_name);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_price ON products(price);

-- Composite indexes
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_order_items_order_product ON order_items(order_id, product_id);

-- Partial indexes
CREATE INDEX idx_active_products ON products(product_name) WHERE is_active = true;
CREATE INDEX idx_recent_orders ON orders(order_date) WHERE order_date >= CURRENT_DATE - INTERVAL '30 days';

-- Expression indexes
CREATE INDEX idx_products_name_lower ON products(LOWER(product_name));
CREATE INDEX idx_customers_email_domain ON customers(SUBSTRING(email FROM '@' FOR 50));
```

### **Partitioning Strategies**
```sql
-- Range partitioning by date
CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- List partitioning by category
CREATE TABLE products (
    product_id INT,
    product_name VARCHAR(200),
    category VARCHAR(50)
) PARTITION BY LIST (category);

CREATE TABLE products_electronics PARTITION OF products
    FOR VALUES IN ('electronics', 'computers', 'phones');

CREATE TABLE products_clothing PARTITION OF products
    FOR VALUES IN ('clothing', 'shoes', 'accessories');
```

## 🔧 **Best Practices**

### **Naming Conventions**
```sql
-- Tables: plural, lowercase, underscores
CREATE TABLE customer_orders ();

-- Columns: lowercase, underscores, descriptive
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    unit_price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes: descriptive with table prefix
CREATE INDEX idx_products_name ON products(product_name);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Constraints: descriptive names
ALTER TABLE products ADD CONSTRAINT chk_positive_price 
    CHECK (price > 0);
```

### **Data Types**
```sql
-- Use appropriate data types
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY, -- Auto-incrementing integer
    email VARCHAR(255) UNIQUE, -- Email addresses
    password_hash CHAR(60), -- bcrypt hash
    is_active BOOLEAN DEFAULT true, -- True/false flags
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamps
    profile_data JSONB -- Flexible data structure
);
```

### **Documentation**
```sql
-- Add comments to tables and columns
COMMENT ON TABLE customers IS 'Customer information and profiles';
COMMENT ON COLUMN customers.email IS 'Unique email address for login';
COMMENT ON COLUMN customers.created_at IS 'Timestamp when customer was registered';

-- Document constraints
COMMENT ON CONSTRAINT chk_positive_price ON products IS 'Ensure product prices are positive';
```

## 🚀 **Common Patterns**

### **Audit Trail**
```sql
CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    action VARCHAR(20), -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### **Soft Deletes**
```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Query to exclude soft-deleted records
SELECT * FROM products WHERE is_deleted = false;
```

### **Version Control**
```sql
CREATE TABLE documents (
    document_id INT PRIMARY KEY,
    title VARCHAR(200),
    content TEXT,
    version INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50)
);

-- Keep version history
CREATE TABLE document_versions (
    document_id INT,
    version INT,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50),
    PRIMARY KEY (document_id, version)
);
```

---

## 🔬 **Advanced Patterns**

### **Hierarchical Data Modeling**
```sql
-- Employee hierarchy with self-referencing foreign key
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100),
    manager_id INT,
    level INT DEFAULT 0,
    path TEXT,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- Recursive query to build hierarchy
WITH RECURSIVE hierarchy AS (
    SELECT employee_id, name, manager_id, 0 as level, ARRAY[name] as path
    FROM employees WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT e.employee_id, e.name, e.manager_id, h.level + 1, h.path || e.name
    FROM employees e
    INNER JOIN hierarchy h ON e.manager_id = h.employee_id
)
SELECT level, name, array_to_string(path, ' → ') as hierarchy_path
FROM hierarchy ORDER BY level, name;
```

### **Audit Trail Pattern**
```sql
-- Audit trail table for tracking changes
CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    action VARCHAR(20), -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger function for audit trail
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), current_user);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), current_user);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, changed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), current_user);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

### **Soft Delete Pattern**
```sql
-- Soft delete implementation
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(200),
    price DECIMAL(10,2),
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP,
    deleted_by VARCHAR(50)
);

-- Soft delete function
CREATE OR REPLACE FUNCTION soft_delete_product(product_id_param INT, deleted_by_param VARCHAR(50))
RETURNS VOID AS $$
BEGIN
    UPDATE products 
    SET is_deleted = true, 
        deleted_at = CURRENT_TIMESTAMP,
        deleted_by = deleted_by_param
    WHERE product_id = product_id_param;
END;
$$ LANGUAGE plpgsql;

-- Query to exclude soft-deleted records
SELECT * FROM products WHERE is_deleted = false;
```

---

*Follow this cheatsheet to design robust, scalable database schemas! 🏗️* 