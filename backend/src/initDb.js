const db = require('./db');
require('dotenv').config();

const initDatabase = async () => {
  console.log('Initializing database...');
  
  try {
    // Create tables
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        full_name VARCHAR(200) NOT NULL,
        role VARCHAR(20) NOT NULL DEFAULT 'employee',
        email VARCHAR(200),
        phone VARCHAR(20),
        salary DECIMAL(12,2) DEFAULT 0,
        department VARCHAR(100),
        position VARCHAR(100),
        join_date DATE DEFAULT CURRENT_DATE,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✓ Users table created');

    await db.query(`
      CREATE TABLE IF NOT EXISTS attendance (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        date DATE NOT NULL,
        clock_in TIME,
        clock_out TIME,
        status VARCHAR(20) DEFAULT 'present',
        remarks TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, date)
      );
    `);
    console.log('✓ Attendance table created');

    await db.query(`
      CREATE TABLE IF NOT EXISTS payroll (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        period VARCHAR(7) NOT NULL,
        basic_salary DECIMAL(12,2) NOT NULL,
        allowances DECIMAL(12,2) DEFAULT 0,
        deductions DECIMAL(12,2) DEFAULT 0,
        total_salary DECIMAL(12,2) NOT NULL,
        payment_date DATE,
        status VARCHAR(20) DEFAULT 'pending',
        total_working_days INTEGER,
        total_present INTEGER,
        total_absent INTEGER,
        total_late INTEGER,
        total_half_days INTEGER,
        remarks TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, period)
      );
    `);
    console.log('✓ Payroll table created');

    console.log('Database initialization complete!');
    process.exit(0);
  } catch (error) {
    console.error('Database initialization failed:', error);
    process.exit(1);
  }
};

initDatabase();