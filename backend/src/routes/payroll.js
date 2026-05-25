const express = require('express');
const db = require('../db');
const { authenticate, isAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/payroll
router.get('/', authenticate, async (req, res) => {
  try {
    const { userId, period } = req.query;
    const records = db.readOnly(data => {
      let list = [...data.payroll];
      if (req.user.role !== 'admin') {
        list = list.filter(p => p.user_id === req.user.id);
      } else if (userId) {
        list = list.filter(p => p.user_id === parseInt(userId));
      }
      if (period) list = list.filter(p => p.period === period);
      return list.sort((a, b) => b.period?.localeCompare(a.period) || 0).map(p => ({
        id: p.id, userId: p.user_id,
        userName: data.users.find(u => u.id === p.user_id)?.full_name || '',
        period: p.period, basicSalary: p.basic_salary,
        allowances: p.allowances, deductions: p.deductions,
        totalSalary: p.total_salary, paymentDate: p.payment_date,
        status: p.status, totalWorkingDays: p.total_working_days,
        totalPresent: p.total_present, totalAbsent: p.total_absent,
        totalLate: p.total_late, totalHalfDays: p.total_half_days,
        remarks: p.remarks,
      }));
    });
    res.json(records);
  } catch (error) {
    console.error('Get payroll error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/payroll/generate
router.post('/generate', authenticate, isAdmin, async (req, res) => {
  try {
    const { period } = req.body;
    if (!period) return res.status(400).json({ error: 'Period required (YYYY-MM)' });

    const result = db.query(data => {
      const employees = data.users.filter(u => u.role === 'employee' && u.is_active);
      let generated = 0;

      for (const emp of employees) {
        const exists = data.payroll.find(p => p.user_id === emp.id && p.period === period);
        if (exists) continue;

        const attendanceRecords = data.attendance.filter(a =>
          a.user_id === emp.id && a.date?.startsWith(period)
        );
        const presentCount = attendanceRecords.filter(a => a.status === 'present').length;
        const absentCount = attendanceRecords.filter(a => a.status === 'absent').length;
        const basicSalary = emp.salary || 0;
        const workingDays = 22;
        const dailyRate = workingDays > 0 ? basicSalary / workingDays : 0;
        const totalSalary = presentCount * dailyRate;
        const deductions = absentCount * dailyRate;

        data.payroll.push({
          id: data.nextIds.payroll++,
          user_id: emp.id, period, basic_salary: basicSalary,
          allowances: 0, deductions, total_salary: totalSalary,
          payment_date: null, status: 'pending',
          total_working_days: workingDays, total_present: presentCount,
          total_absent: absentCount, total_late: 0, total_half_days: 0,
          remarks: null,
        });
        generated++;
      }
      return generated;
    });

    res.json({ message: `Generated ${result} payroll records`, count: result });
  } catch (error) {
    console.error('Generate payroll error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/payroll/:id/pay
router.put('/:id/pay', authenticate, isAdmin, async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const today = new Date().toISOString().split('T')[0];

    const found = db.query(data => {
      const p = data.payroll.find(x => x.id === id);
      if (!p || p.status !== 'pending') return null;
      p.status = 'paid';
      p.payment_date = today;
      return p;
    });

    if (!found) return res.status(404).json({ error: 'Payroll not found or already paid' });
    res.json({ message: 'Payroll marked as paid' });
  } catch (error) {
    console.error('Pay payroll error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;