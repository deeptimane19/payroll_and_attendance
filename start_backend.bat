@echo off
cd /d "D:\Deepti_Payroll\payroll_and_attendance-master\payroll_and_attendance-master"
start /B "" "C:\Program Files\nodejs\node.exe" backend\src\index.js
echo Backend started on port 3000