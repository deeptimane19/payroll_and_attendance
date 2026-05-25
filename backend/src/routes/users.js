const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { authenticate, isAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/users
router.get('/', authenticate, isAdmin, async (req, res) => {
  try {
    const users = db.readOnly(data => 
      data.users.filter(u => u.role === 'employee').map(u => ({
        id: u.id, username: u.username, fullName: u.full_name,
        role: u.role, email: u.email, phone: u.phone,
        salary: u.salary, department: u.department,
        position: u.position, joinDate: u.join_date, isActive: u.is_active,
      }))
    );
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/users
router.post('/', authenticate, isAdmin, async (req, res) => {
  try {
    const { username, password, fullName, email, phone, salary, department, position } = req.body;
    if (!username || !password || !fullName) {
      return res.status(400).json({ error: 'Username, password, and full name required' });
    }

    const existing = db.readOnly(data => data.users.find(u => u.username === username));
    if (existing) return res.status(409).json({ error: 'Username already exists' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = db.query(data => {
      const u = {
        id: data.nextIds.users++,
        username, password: hashedPassword, full_name: fullName,
        role: 'employee', email: email || null, phone: phone || null,
        salary: salary || 0, department: department || null,
        position: position || null, join_date: new Date().toISOString().split('T')[0],
        is_active: true, created_at: new Date().toISOString(),
      };
      data.users.push(u);
      return u;
    });

    res.status(201).json({
      id: user.id, username: user.username, fullName: user.full_name,
      role: user.role, email: user.email, phone: user.phone,
      salary: user.salary, department: user.department,
      position: user.position, joinDate: user.join_date,
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/users/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const { fullName, email, phone, salary, department, position } = req.body;

    if (req.user.role !== 'admin' && req.user.id !== id) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const updated = db.query(data => {
      const idx = data.users.findIndex(u => u.id === id);
      if (idx === -1) return null;
      const u = data.users[idx];
      if (fullName !== undefined) u.full_name = fullName;
      if (email !== undefined) u.email = email;
      if (phone !== undefined) u.phone = phone;
      if (salary !== undefined) u.salary = salary;
      if (department !== undefined) u.department = department;
      if (position !== undefined) u.position = position;
      return u;
    });

    if (!updated) return res.status(404).json({ error: 'User not found' });
    const u = updated;
    res.json({
      id: u.id, username: u.username, fullName: u.full_name, role: u.role,
      email: u.email, phone: u.phone, salary: u.salary,
      department: u.department, position: u.position,
      joinDate: u.join_date, isActive: u.is_active,
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/users/:id
router.delete('/:id', authenticate, isAdmin, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    db.query(data => {
      data.users = data.users.filter(u => u.id !== id);
      data.attendance = data.attendance.filter(a => a.user_id !== id);
      data.payroll = data.payroll.filter(p => p.user_id !== id);
    });
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;