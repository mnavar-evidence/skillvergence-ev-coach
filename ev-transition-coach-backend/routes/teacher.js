const express = require('express');
const router = express.Router();
const database = require('../database/db');

// POST /api/teacher/validate-code - Validate teacher access code
router.post('/validate-code', async (req, res) => {
  try {
    const { code, schoolId } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        error: 'Teacher code is required'
      });
    }

    await database.initialize();

    // Find teacher by teacher_code
    const teacher = await database.get(`
      SELECT t.*, s.name as school_name, s.program
      FROM teachers t
      JOIN schools s ON t.school_id = s.id
      WHERE t.teacher_code = ?
    `, [code.toUpperCase()]);

    if (!teacher) {
      return res.status(401).json({
        success: false,
        error: 'Invalid teacher access code'
      });
    }

    // Generate class code if teacher doesn't have one
    let classCode = teacher.class_code;
    if (!classCode) {
      classCode = generateClassCode();
      await database.run(
        'UPDATE teachers SET class_code = ? WHERE id = ?',
        [classCode, teacher.id]
      );
    }

    res.json({
      success: true,
      teacher: {
        id: teacher.id,
        name: teacher.name,
        email: teacher.email,
        school: teacher.school_name,
        department: teacher.department,
        program: teacher.program,
        classCode: classCode
      }
    });

  } catch (error) {
    console.error('Teacher validation error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to validate teacher code',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Helper function to generate class codes
function generateClassCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// Database already required at top of file

// All data now fetched from database via database.js module

// Old route removed - using database-based route above

// Get school configuration
router.get('/school/:schoolId/config', async (req, res) => {
  try {
    const { schoolId } = req.params;

    await database.initialize();
    const result = await database.getSchoolConfig(schoolId);

    res.json(result);
  } catch (error) {
    console.error('School config error:', error);
    res.status(500).json({
      error: 'Failed to get school configuration',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get student roster
router.get('/school/:schoolId/students', async (req, res) => {
  try {
    const { schoolId } = req.params;

    await database.initialize();

    // For demo purposes, use the sample teacher ID
    // In production, you'd get this from the authenticated teacher session
    const teacherId = schoolId === 'fallbrook-hs' ? 'teacher-djohnson' : `teacher-${schoolId}`;
    const result = await database.getStudentRoster(teacherId);

    res.json(result);
  } catch (error) {
    console.error('Student roster error:', error);
    res.status(500).json({
      error: 'Failed to get student roster',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get certificates for review
router.get('/school/:schoolId/certificates', async (req, res) => {
  try {
    const { schoolId } = req.params;
    const { status = 'all' } = req.query;

    await database.initialize();

    // For demo purposes, use the sample teacher ID
    const teacherId = schoolId === 'fallbrook-hs' ? 'teacher-djohnson' : `teacher-${schoolId}`;
    const result = await database.getCertificates(teacherId, status);

    res.json(result);
  } catch (error) {
    console.error('Certificates error:', error);
    res.status(500).json({
      error: 'Failed to get certificates',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Approve/reject certificate
router.post('/certificates/:certId/approve', async (req, res) => {
  try {
    const { certId } = req.params;
    const { action, teacherId } = req.body; // action: 'approve' or 'reject'

    if (!['approve', 'reject'].includes(action) || !teacherId) {
      return res.status(400).json({ error: 'Invalid action or missing teacher ID' });
    }

    await database.initialize();

    const certificate = await database.updateCertificateStatus(certId, action, teacherId);
    if (!certificate) {
      return res.status(404).json({ error: 'Certificate not found' });
    }

    res.json({
      success: true,
      certificate
    });
  } catch (error) {
    console.error('Certificate approval error:', error);
    res.status(500).json({
      error: 'Failed to update certificate',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get code usage analytics
router.get('/school/:schoolId/code-usage', async (req, res) => {
  try {
    await database.initialize();

    // Mock code usage data (until we have real tracking)
    const codeUsage = {
      basicCodes: 5,
      premiumCodes: 3,
      friendCodes: 2
    };

    res.json({
      usage: codeUsage,
      generatedCodes: {
        basic: Array.from({ length: 5 }, (_, i) => `B${10000 + i}`),
        premium: Array.from({ length: 3 }, (_, i) => `P${20000 + i}`)
      }
    });
  } catch (error) {
    console.error('Code usage error:', error);
    res.status(500).json({
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Generate new access codes
router.post('/school/:schoolId/generate-codes', (req, res) => {
  try {
    const { type, count } = req.body; // type: 'basic' or 'premium'

    if (!['basic', 'premium'].includes(type) || !count || count <= 0) {
      return res.status(400).json({ error: 'Invalid code type or count' });
    }

    const prefix = type === 'basic' ? 'B' : 'P';
    const codes = Array.from({ length: count }, (_, i) => {
      const random = Math.floor(Math.random() * 90000) + 10000;
      return `${prefix}${random}`;
    });

    res.json({
      success: true,
      codes,
      type,
      count: codes.length,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    console.error('Code generation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get detailed student progress
router.get('/students/:studentId/progress', async (req, res) => {
  try {
    const { studentId } = req.params;

    await database.initialize();

    // Get student data from database
    const student = await database.get(`
      SELECT * FROM students WHERE id = ?
    `, [studentId]);

    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    // Get student's devices to show platform information
    const devices = await database.all(`
      SELECT device_id, device_name, platform, app_version, last_seen, is_active
      FROM devices
      WHERE student_id = ?
      ORDER BY last_seen DESC
    `, [studentId]);

    // Get real progress data from database
    const dailyActivity = await database.all(`
      SELECT activity_date, total_watched_sec, videos_completed, videos_started, xp_earned, streak_count
      FROM daily_activity
      WHERE student_id = ?
      ORDER BY activity_date DESC
    `, [studentId]);

    const videoProgress = await database.all(`
      SELECT course_id, video_id, progress_percentage, completed, watched_sec, total_duration_sec
      FROM video_progress
      WHERE student_id = ?
      ORDER BY course_id, video_id
    `, [studentId]);

    // Calculate real student metrics
    const totalXP = dailyActivity.reduce((sum, day) => sum + day.xp_earned, 0);
    const currentLevel = Math.floor(totalXP / 100) + 1; // 100 XP per level
    const totalWatchedMinutes = dailyActivity.reduce((sum, day) => sum + Math.floor(day.total_watched_sec / 60), 0);
    const maxStreak = Math.max(...dailyActivity.map(day => day.streak_count), 0);

    // Group video progress by course and calculate course completion
    const courseMap = {};
    videoProgress.forEach(video => {
      if (!courseMap[video.course_id]) {
        courseMap[video.course_id] = {
          courseId: video.course_id,
          videos: [],
          totalVideos: 0,
          completedVideos: 0,
          totalWatchedSec: 0,
          totalDurationSec: 0
        };
      }
      courseMap[video.course_id].videos.push(video);
      courseMap[video.course_id].totalVideos++;
      if (video.completed) courseMap[video.course_id].completedVideos++;
      courseMap[video.course_id].totalWatchedSec += video.watched_sec;
      courseMap[video.course_id].totalDurationSec += video.total_duration_sec;
    });

    // Convert course map to progress array with real names
    const courseNames = {
      'course-hv-safety': '1.0 High Voltage Vehicle Safety',
      'course-electrical-fundamentals': '2.0 Electrical Level 1 - Medium Heavy Duty',
      'course-advanced-ev': '3.0 Electrical Level 2 - Medium Heavy Duty',
      'course-ev-charging': '4.0 Electric Vehicle Supply Equipment',
      'course-ev-components': '5.0 Introduction to Electric Vehicles'
    };

    const courseProgress = Object.values(courseMap).map(course => ({
      courseId: course.courseId,
      courseName: courseNames[course.courseId] || course.courseId,
      progress: course.totalDurationSec > 0 ? Math.round((course.totalWatchedSec / course.totalDurationSec) * 100) : 0,
      completedVideos: course.completedVideos,
      totalVideos: course.totalVideos,
      timeSpent: Math.floor(course.totalWatchedSec / 60)
    }));

    // Calculate week activity for last few weeks
    const weeklyActivity = dailyActivity
      .filter(day => day.activity_date >= '2024-01-01') // Filter recent activity
      .slice(0, 4) // Last 4 entries
      .map(day => ({
        week: day.activity_date,
        xpEarned: day.xp_earned,
        timeSpent: Math.floor(day.total_watched_sec / 60)
      }));

    // Generate achievements based on real progress
    const achievements = [];
    if (videoProgress.some(v => v.completed)) {
      achievements.push({ title: 'First Video Complete', earnedDate: '2024-01-15T00:00:00Z' });
    }
    if (maxStreak > 0) {
      achievements.push({ title: `${maxStreak} Day Streak`, earnedDate: '2024-01-15T00:00:00Z' });
    }
    if (totalXP >= 100) {
      achievements.push({ title: 'Level Up!', earnedDate: '2024-01-15T00:00:00Z' });
    }

    const detailedProgress = {
      student: {
        id: student.id,
        name: `${student.first_name} ${student.last_name}`,
        email: student.email,
        courseLevel: totalXP < 100 ? 'Beginner' : totalXP < 500 ? 'Intermediate' : 'Advanced',
        totalXP: totalXP,
        currentLevel: currentLevel,
        completedCourses: courseProgress.filter(c => c.progress >= 100).length,
        lastActive: student.last_active || 'No activity',
        streak: maxStreak
      },
      devices: devices.map(device => ({
        deviceId: device.device_id,
        deviceName: device.device_name,
        platform: device.platform,
        appVersion: device.app_version,
        lastSeen: device.last_seen,
        isActive: device.is_active === 1
      })),
      courseProgress: courseProgress,
      weeklyActivity: weeklyActivity,
      achievements: achievements
    };

    res.json(detailedProgress);
  } catch (error) {
    console.error('Student progress error:', error);
    res.status(500).json({
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;