const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const DATA_FILE = path.join(__dirname, '..', 'data.json');

let defaultData = null;

// Initialize default data with proper hashes
async function initDefaultData() {
  const adminHash = await bcrypt.hash('admin123', 10);
  const empHash = await bcrypt.hash('emp123', 10);

  defaultData = {
    users: [
      {
        id: 1,
        username: 'admin',
        password: adminHash,
        full_name: 'System Admin',
        role: 'admin',
        email: 'admin@company.com',
        phone: '1234567890',
        salary: 50000,
        department: 'Management',
        position: 'Administrator',
        join_date: '2026-01-01',
        is_active: true,
        created_at: new Date().toISOString(),
      },
      {
        id: 2,
        username: 'employee1',
        password: empHash,
        full_name: 'John Doe',
        role: 'employee',
        email: 'john@company.com',
        phone: '9876543210',
        salary: 30000,
        department: 'Development',
        position: 'Developer',
        join_date: '2026-02-01',
        is_active: true,
        created_at: new Date().toISOString(),
      },
    ],
    attendance: [],
    payroll: [],
    nextIds: { users: 3, attendance: 1, payroll: 1 },
  };
}

function loadData() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      const raw = fs.readFileSync(DATA_FILE, 'utf8');
      const parsed = JSON.parse(raw);
      if (parsed && parsed.users && parsed.users.length > 0) {
        return parsed;
      }
    }
  } catch (e) {
    console.warn('Data file corrupted, resetting...');
  }
  return null;
}

function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

let _data = null;

async function getData() {
  if (_data) return _data;
  if (!defaultData) await initDefaultData();
  _data = loadData() || JSON.parse(JSON.stringify(defaultData));
  if (!fs.existsSync(DATA_FILE)) {
    saveData(_data);
  }
  return _data;
}

module.exports = {
  query: (callback) => {
    const data = _data || loadData() || JSON.parse(JSON.stringify(defaultData));
    const result = callback(data);
    _data = data;
    saveData(data);
    return result;
  },
  readOnly: (callback) => {
    const data = _data || loadData() || JSON.parse(JSON.stringify(defaultData));
    return callback(data);
  },
  initDefaultData,
};