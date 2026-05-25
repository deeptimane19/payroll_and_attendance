const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { authenticate } = require('../middleware/auth');
require('dotenv').config();

const router = express.Router();

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const user = db.readOnly(data => {
      return data.users.find(u => u.username === username && u.is_active);
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        fullName: user.full_name,
        role: user.role,
        email: user.email,
        phone: user.phone,
        salary: user.salary,
        department: user.department,
        position: user.position,
        joinDate: user.join_date,
        isActive: user.is_active,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { username, password, fullName, email, phone, department, position } = req.body;

    if (!username || !password || !fullName) {
      return res.status(400).json({ error: 'Username, password, and full name required' });
    }

    const existing = db.readOnly(data => data.users.find(u => u.username === username));
    if (existing) {
      return res.status(409).json({ error: 'Username already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = db.query(data => {
      const user = {
        id: data.nextIds.users++,
        username,
        password: hashedPassword,
        full_name: fullName,
        role: 'employee',
        email: email || null,
        phone: phone || null,
        salary: 0,
        department: department || null,
        position: position || null,
        join_date: new Date().toISOString().split('T')[0],
        is_active: true,
        created_at: new Date().toISOString(),
      };
      data.users.push(user);
      return user;
    });

    const token = jwt.sign(
      { id: newUser.id, username: newUser.username, role: newUser.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    res.status(201).json({
      token,
      user: {
        id: newUser.id,
        username: newUser.username,
        fullName: newUser.full_name,
        role: newUser.role,
        email: newUser.email,
        phone: newUser.phone,
        department: newUser.department,
        position: newUser.position,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/auth/me
router.get('/me', authenticate, async (req, res) => {
  try {
    const user = db.readOnly(data => data.users.find(u => u.id === req.user.id));
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({
      id: user.id, username: user.username, fullName: user.full_name,
      role: user.role, email: user.email, phone: user.phone,
      salary: user.salary, department: user.department,
      position: user.position, joinDate: user.join_date, isActive: user.is_active,
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;