const express = require('express');
const cors = require('cors');
const db = require('./db');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const attendanceRoutes = require('./routes/attendance');
const payrollRoutes = require('./routes/payroll');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/payroll', payrollRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

async function start() {
  await db.initDefaultData();
  // Initialize data store
  db.readOnly(() => {});
  // Delete old data.json to regenerate with proper hashes
  const fs = require('fs');
  const path = require('path');
  const dataFile = path.join(__dirname, '..', 'data.json');
  if (fs.existsSync(dataFile)) {
    fs.unlinkSync(dataFile);
  }
  db.readOnly(() => {});
  
  app.listen(PORT, () => {
    console.log(`Payroll & Attendance API running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/api/health`);
    console.log('Login: admin / admin123 or employee1 / emp123');
  });
}

start();
