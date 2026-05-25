const express = require('express');
const db = require('../db');
const { authenticate, isAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/attendance
router.get('/', authenticate, async (req, res) => {
  try {
    const { userId, month } = req.query;
    const records = db.readOnly(data => {
      let list = [...data.attendance];
      if (req.user.role !== 'admin') {
        list = list.filter(a => a.user_id === req.user.id);
      } else if (userId) {
        list = list.filter(a => a.user_id === parseInt(userId));
      }
      if (month) {
        list = list.filter(a => a.date && a.date.startsWith(month));
      }
      return list.sort((a, b) => b.date?.localeCompare(a.date) || 0).map(a => ({
        id: a.id, userId: a.user_id,
        userName: data.users.find(u => u.id === a.user_id)?.full_name || '',
        date: a.date, clockIn: a.clock_in, clockOut: a.clock_out,
        status: a.status, remarks: a.remarks,
      }));
    });
    res.json(records);
  } catch (error) {
    console.error('Get attendance error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/attendance/clockin
router.post('/clockin', authenticate, async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const now = new Date().toTimeString().split(' ')[0];

    const result = db.query(data => {
      const existing = data.attendance.find(a => a.user_id === req.user.id && a.date === today);
      if (existing) return { error: 'Already clocked in today' };
      const record = {
        id: data.nextIds.attendance++,
        user_id: req.user.id,
        date: today,
        clock_in: now,
        clock_out: null,
        status: 'present',
        remarks: null,
      };
      data.attendance.push(record);
      return record;
    });

    if (result.error) return res.status(400).json(result);
    res.status(201).json({
      id: result.id, userId: result.user_id, date: result.date,
      clockIn: result.clock_in, clockOut: result.clock_out,
      status: result.status, remarks: result.remarks,
    });
  } catch (error) {
    console.error('Clock in error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/attendance/clockout
router.post('/clockout', authenticate, async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const now = new Date().toTimeString().split(' ')[0];

    const result = db.query(data => {
      const existing = data.attendance.find(a => a.user_id === req.user.id && a.date === today);
      if (!existing) return { error: 'Please clock in first' };
      if (existing.clock_out) return { error: 'Already clocked out today' };
      existing.clock_out = now;
      return existing;
    });

    if (result.error) return res.status(400).json(result);
    res.json({
      id: result.id, userId: result.user_id, date: result.date,
      clockIn: result.clock_in, clockOut: result.clock_out,
      status: result.status, remarks: result.remarks,
    });
  } catch (error) {
    console.error('Clock out error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/attendance/:id
router.put('/:id', authenticate, isAdmin, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const { status, remarks } = req.body;
    const result = db.query(data => {
      const a = data.attendance.find(x => x.id === id);
      if (!a) return null;
      if (status) a.status = status;
      if (remarks !== undefined) a.remarks = remarks;
      return a;
    });
    if (!result) return res.status(404).json({ error: 'Record not found' });
    res.json({
      id: result.id, userId: result.user_id, date: result.date,
      clockIn: result.clock_in, clockOut: result.clock_out,
      status: result.status, remarks: result.remarks,
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/attendance/stats/:userId/:month
router.get('/stats/:userId/:month', authenticate, async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    const month = req.params.month;
    const stats = db.readOnly(data => {
      const records = data.attendance.filter(a => a.user_id === userId && a.date?.startsWith(month));
      const result = { present: 0, absent: 0, late: 0, leave: 0, 'half-day': 0 };
      records.forEach(a => { if (result[a.status] !== undefined) result[a.status]++; });
      return result;
    });
    res.json(stats);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;