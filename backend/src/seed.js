const db = require('./db');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const seedDatabase = async () => {
  console.log('Seeding database...');

  try {
    // Check if admin already exists
    const existingAdmin = await db.query('SELECT * FROM users WHERE username = $1', ['admin']);
    if (existingAdmin.rows.length > 0) {
      console.log('✓ Data already seeded');
      process.exit(0);
    }

    const hashedAdminPw = await bcrypt.hash('admin123', 10);
    const hashedEmpPw = await bcrypt.hash('emp123', 10);

    // Insert admin
    await db.query(`
      INSERT INTO users (username, password, full_name, role, email, phone, salary, department, position, join_date)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    `, ['admin', hashedAdminPw, 'System Admin', 'admin', 'admin@company.com', '1234567890', 50000, 'Management', 'Administrator', '2026-01-01']);
    console.log('✓ Admin user created');

    // Insert employee
    const empResult = await db.query(`
      INSERT INTO users (username, password, full_name, role, email, phone, salary, department, position, join_date)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING id
    `, ['employee1', hashedEmpPw, 'John Doe', 'employee', 'john@company.com', '9876543210', 30000, 'Development', 'Developer', '2026-02-01']);
    console.log('✓ Employee user created');

    // Insert sample attendance for current month
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const empId = empResult.rows[0].id;

    for (let day = 1; day <= Math.min(today.getDate(), 28); day++) {
      const dateStr = `${year}-${month}-${String(day).padStart(2, '0')}`;
      const isWeekend = new Date(dateStr).getDay() === 0 || new Date(dateStr).getDay() === 6;
      if (isWeekend) continue;

      const status = day <= 20 ? 'present' : (day === 22 ? 'absent' : (day === 23 ? 'late' : 'present'));
      const clockIn = day <= 22 ? '09:00:00' : '09:30:00';
      const clockOut = '18:00:00';

      await db.query(`
        INSERT INTO attendance (user_id, date, clock_in, clock_out, status)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (user_id, date) DO NOTHING
      `, [empId, dateStr, clockIn, clockOut, status]);
    }
    console.log('✓ Sample attendance data created');

    console.log('Database seeding complete!');
    process.exit(0);
  } catch (error) {
    console.error('Database seeding failed:', error);
    process.exit(1);
  }
};

seedDatabase();