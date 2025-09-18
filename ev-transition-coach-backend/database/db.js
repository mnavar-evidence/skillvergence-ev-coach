const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

class Database {
  constructor() {
    this.db = null;
    this.isInitialized = false;
  }

  async initialize() {
    if (this.isInitialized) return;

    try {
      // Create database directory if it doesn't exist
      const dbDir = path.join(__dirname);
      if (!fs.existsSync(dbDir)) {
        fs.mkdirSync(dbDir, { recursive: true });
      }

      // Initialize SQLite database
      const dbPath = path.join(dbDir, 'mindsherpa.db');
      this.db = new sqlite3.Database(dbPath);

      // Enable foreign keys
      await this.run('PRAGMA foreign_keys = ON');

      // Load and execute schema
      const schemaPath = path.join(__dirname, 'teacher-student-schema.sql');
      const schema = fs.readFileSync(schemaPath, 'utf8');

      // Split and execute each statement
      const statements = schema.split(';').filter(stmt => stmt.trim().length > 0);
      for (const statement of statements) {
        await this.run(statement);
      }

      this.isInitialized = true;
      console.log('✅ Database initialized successfully');

    } catch (error) {
      console.error('❌ Database initialization failed:', error);
      throw error;
    }
  }

  // Promisify sqlite3 methods
  run(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params, function(error) {
        if (error) reject(error);
        else resolve({ id: this.lastID, changes: this.changes });
      });
    });
  }

  get(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.get(sql, params, (error, row) => {
        if (error) reject(error);
        else resolve(row);
      });
    });
  }

  all(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.all(sql, params, (error, rows) => {
        if (error) reject(error);
        else resolve(rows);
      });
    });
  }

  // Student and Device Management
  async registerDevice(deviceId, platform, appVersion, deviceName = null) {
    try {
      const now = new Date().toISOString();
      await this.run(`
        INSERT OR REPLACE INTO devices
        (device_id, device_name, platform, app_version, first_seen, last_seen, is_active)
        VALUES (?, ?, ?, ?,
          COALESCE((SELECT first_seen FROM devices WHERE device_id = ?), ?),
          ?, 1)
      `, [deviceId, deviceName, platform, appVersion, deviceId, now, now]);

      console.log(`📱 Device registered: ${deviceId} (${platform})`);
      return { success: true };
    } catch (error) {
      console.error('❌ Device registration failed:', error);
      throw error;
    }
  }

  async generateUniqueStudentId(firstName, lastName, email = null, deviceId = null) {
    try {
      const crypto = require('crypto');

      // Create hash from email + device ID for guaranteed uniqueness
      if (email && deviceId) {
        const hashInput = `${email}-${deviceId}`;
        const hash = crypto.createHash('md5').update(hashInput).digest('hex').slice(0, 8);
        return `student-${hash}`;
      }

      // Fallback: device-based ID if no email
      if (deviceId) {
        const deviceHash = crypto.createHash('md5').update(deviceId).digest('hex').slice(0, 8);
        return `student-device-${deviceHash}`;
      }

      // Ultimate fallback: name + timestamp (shouldn't happen in normal flow)
      const timestamp = Date.now().toString().slice(-6);
      const baseName = `${firstName.toLowerCase()}-${lastName.toLowerCase()}`;
      return `student-${baseName}-${timestamp}`;

    } catch (error) {
      console.error('❌ Student ID generation failed:', error);
      // Emergency fallback
      const timestamp = Date.now().toString().slice(-6);
      return `student-${firstName.toLowerCase()}-${lastName.toLowerCase()}-${timestamp}`;
    }
  }

  async linkDeviceToStudent(deviceId, classCode, firstName, lastName, email = null) {
    try {
      // Find teacher and school details by class code
      const teacherData = await this.get(`
        SELECT t.id, t.school_id, t.name, t.email, s.program,
               s.name as school_name
        FROM teachers t
        JOIN schools s ON t.school_id = s.id
        WHERE t.class_code = ?
      `, [classCode]);

      if (!teacherData) {
        throw new Error(`This Class does not exist`);
      }

      const now = new Date().toISOString();

      // DUPLICATE PREVENTION: Check for existing student by email first
      let existingStudent = null;
      if (email) {
        existingStudent = await this.get(`
          SELECT id, first_name, last_name, school_id, teacher_id
          FROM students
          WHERE email = ? AND teacher_id = ?
        `, [email, teacherData.id]);
      }

      let studentId;

      if (existingStudent) {
        // MERGE: Use existing student, update info if needed
        studentId = existingStudent.id;
        console.log(`🔗 Found existing student with email ${email}: ${existingStudent.first_name} ${existingStudent.last_name}`);

        // Update student info with latest details
        await this.run(`
          UPDATE students
          SET first_name = ?, last_name = ?, last_active = ?
          WHERE id = ?
        `, [firstName, lastName, now, studentId]);

        // MERGE DEVICE ACTIVITY: Link any unlinked device activity to this student
        await this.mergeUnlinkedDeviceActivity(deviceId, studentId);

      } else {
        // CREATE NEW: Generate unique ID and create new student
        studentId = await this.generateUniqueStudentId(firstName, lastName, email, deviceId);

        await this.run(`
          INSERT INTO students
          (id, school_id, teacher_id, first_name, last_name, email, class_code, joined_at, last_active)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [studentId, teacherData.school_id, teacherData.id, firstName, lastName, email, classCode, now, now]);

        console.log(`👥 Created new student: ${firstName} ${lastName} (${studentId})`);
      }

      // Link device to student (always update this)
      await this.run(
        'UPDATE devices SET student_id = ?, last_seen = ? WHERE device_id = ?',
        [studentId, now, deviceId]
      );

      console.log(`📱 Device ${deviceId} linked to student: ${firstName} ${lastName} (${studentId})`);

      return {
        success: true,
        studentId,
        teacherId: teacherData.id,
        schoolId: teacherData.school_id,
        classDetails: {
          teacherName: teacherData.name,
          teacherEmail: teacherData.email,
          schoolName: teacherData.school_name,
          programName: teacherData.program,
          classCode: classCode
        }
      };

    } catch (error) {
      console.error('❌ Device-student linking failed:', error);
      throw error;
    }
  }

  // HELPER: Merge unlinked device activity to existing student
  async mergeUnlinkedDeviceActivity(deviceId, studentId) {
    try {
      // Update any daily_activity records with no student_id for this device
      const result = await this.run(`
        UPDATE daily_activity
        SET student_id = ?
        WHERE device_id = ? AND student_id IS NULL
      `, [studentId, deviceId]);

      if (result.changes > 0) {
        console.log(`🔄 Merged ${result.changes} unlinked activity records for device ${deviceId} to student ${studentId}`);
      }

      // Update any video_progress records with no student_id for this device
      const videoResult = await this.run(`
        UPDATE video_progress
        SET student_id = ?
        WHERE device_id = ? AND student_id IS NULL
      `, [studentId, deviceId]);

      if (videoResult.changes > 0) {
        console.log(`🎥 Merged ${videoResult.changes} unlinked video progress records for device ${deviceId} to student ${studentId}`);
      }

    } catch (error) {
      console.error('❌ Failed to merge unlinked device activity:', error);
      // Don't throw - this is cleanup, not critical
    }
  }

  // Progress Tracking
  async updateVideoProgress(deviceId, videoId, courseId, lastPositionSec, watchedSec, totalDurationSec, completed = false) {
    try {
      const now = new Date().toISOString();
      const progressPercentage = totalDurationSec > 0 ? Math.floor((watchedSec / totalDurationSec) * 100) : 0;
      const isCompleted = completed || progressPercentage >= 85;

      // Get student ID from device
      const device = await this.get('SELECT student_id FROM devices WHERE device_id = ?', [deviceId]);
      const studentId = device?.student_id;

      const progressId = `progress-${deviceId}-${videoId}`.replace(/[^a-zA-Z0-9-]/g, '-');

      await this.run(`
        INSERT OR REPLACE INTO video_progress
        (id, device_id, student_id, video_id, course_id, last_position_sec, watched_sec,
         total_duration_sec, progress_percentage, completed, completed_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        progressId, deviceId, studentId, videoId, courseId, lastPositionSec, watchedSec,
        totalDurationSec, progressPercentage, isCompleted ? 1 : 0,
        isCompleted ? now : null, now
      ]);

      // Update daily activity
      if (watchedSec > 0) {
        await this.updateDailyActivity(deviceId, studentId, watchedSec, isCompleted ? 1 : 0);
      }

      // Check for course completion and create certificate if needed
      if (isCompleted && studentId) {
        await this.checkCourseCompletionAndCreateCertificate(studentId, courseId);
      }

      console.log(`📺 Progress updated: ${deviceId} - ${videoId} (${progressPercentage}%)`);
      return {
        success: true,
        progressPercentage,
        completed: isCompleted
      };

    } catch (error) {
      console.error('❌ Video progress update failed:', error);
      throw error;
    }
  }

  async updateDailyActivity(deviceId, studentId, additionalWatchedSec, videosCompleted = 0) {
    try {
      const today = new Date().toISOString().split('T')[0];
      const activityId = `activity-${deviceId}-${today}`;

      await this.run(`
        INSERT OR REPLACE INTO daily_activity
        (id, device_id, student_id, activity_date, total_watched_sec, videos_completed, videos_started, xp_earned)
        VALUES (?, ?, ?, ?,
          COALESCE((SELECT total_watched_sec FROM daily_activity WHERE device_id = ? AND activity_date = ?), 0) + ?,
          COALESCE((SELECT videos_completed FROM daily_activity WHERE device_id = ? AND activity_date = ?), 0) + ?,
          COALESCE((SELECT videos_started FROM daily_activity WHERE device_id = ? AND activity_date = ?), 0) + 1,
          COALESCE((SELECT xp_earned FROM daily_activity WHERE device_id = ? AND activity_date = ?), 0) + ?
        )
      `, [
        activityId, deviceId, studentId, today,
        deviceId, today, additionalWatchedSec,
        deviceId, today, videosCompleted,
        deviceId, today,
        deviceId, today, Math.floor(additionalWatchedSec / 10) // 1 XP per 10 seconds
      ]);

    } catch (error) {
      console.error('❌ Daily activity update failed:', error);
    }
  }

  // Teacher Dashboard Queries
  async getStudentRoster(teacherId) {
    try {
      const students = await this.all(`
        SELECT
          s.id,
          s.first_name || ' ' || s.last_name as name,
          s.email,
          s.last_active,
          COUNT(DISTINCT d.device_id) as device_count,
          COALESCE(SUM(da.total_watched_sec), 0) as total_watch_time,
          COALESCE(SUM(da.videos_completed), 0) as completed_courses,
          COALESCE(SUM(da.xp_earned), 0) as total_xp,
          MAX(vp.updated_at) as last_video_activity,
          (julianday('now') - julianday(MAX(COALESCE(vp.updated_at, s.last_active)))) as days_since_active
        FROM students s
        LEFT JOIN devices d ON s.id = d.student_id
        LEFT JOIN video_progress vp ON s.id = vp.student_id
        LEFT JOIN daily_activity da ON s.id = da.student_id
        WHERE s.teacher_id = ?
        GROUP BY s.id
        ORDER BY s.last_active DESC
      `, [teacherId]);

      // Calculate activity status and levels
      const studentsWithStats = students.map(student => ({
        id: student.id,
        name: student.name,
        email: student.email,
        courseLevel: student.completed_courses > 3 ? 'Advanced' :
                    student.completed_courses > 1 ? 'Intermediate' : 'Beginner',
        totalXP: Math.floor(student.total_xp),
        currentLevel: Math.min(Math.floor(student.total_xp / 1000) + 1, 4),
        completedCourses: student.completed_courses,
        lastActive: this.formatLastActive(student.days_since_active),
        streak: Math.max(0, 7 - Math.floor(student.days_since_active)),
        isActive: student.days_since_active < 1,
        needsAttention: student.days_since_active > 7 || student.total_xp < 100
      }));

      // Calculate summary
      const summary = {
        totalStudents: students.length,
        activeToday: studentsWithStats.filter(s => s.isActive).length,
        avgXP: studentsWithStats.length > 0 ?
          Math.floor(studentsWithStats.reduce((sum, s) => sum + s.totalXP, 0) / studentsWithStats.length) : 0,
        totalCompletedCourses: studentsWithStats.reduce((sum, s) => sum + s.completedCourses, 0),
      };

      summary.avgCompletionRate = await this.getAdvancedCourseCompletionRate(teacherId);

      return { students: studentsWithStats, summary };

    } catch (error) {
      console.error('❌ Student roster query failed:', error);
      throw error;
    }
  }

  async getAdvancedCourseCompletionRate(teacherId) {
    try {
      // Count approved certificates for advanced courses
      const approvedCertificates = await this.all(`
        SELECT COUNT(*) as approved_count
        FROM student_certificates
        WHERE status = 'approved'
        AND approved_by = ?
      `, [teacherId]);

      // Count total students for this teacher
      const students = await this.all(`
        SELECT COUNT(*) as student_count
        FROM students
        WHERE teacher_id = ?
      `, [teacherId]);

      // Get total number of advanced courses from config
      const totalCoursesConfig = await this.get(`
        SELECT value
        FROM app_config
        WHERE key = 'total_courses'
      `);

      const approvedCount = approvedCertificates[0]?.approved_count || 0;
      const studentCount = students[0]?.student_count || 0;
      const totalCourses = parseInt(totalCoursesConfig?.value || '5');

      const totalPossible = studentCount * totalCourses;

      return totalPossible > 0 ? Math.floor((approvedCount / totalPossible) * 100) : 0;

    } catch (error) {
      console.error('❌ Advanced course completion rate calculation failed:', error);
      return 0;
    }
  }

  async getSchoolConfig(schoolId) {
    try {
      const school = await this.get(`
        SELECT s.*, t.name as instructor_name, t.email as instructor_email, t.department
        FROM schools s
        LEFT JOIN teachers t ON s.id = t.school_id
        WHERE s.id = ?
        LIMIT 1
      `, [schoolId]);

      if (!school) {
        throw new Error(`School not found: ${schoolId}`);
      }

      return {
        school: {
          id: school.id,
          name: school.name,
          district: school.district,
          program: school.program,
          instructor: {
            id: `teacher-${schoolId}`,
            name: school.instructor_name,
            email: school.instructor_email,
            department: school.department
          },
          xpThreshold: 50,
          bulkLicenses: 100,
          districtLicenses: 500
        }
      };

    } catch (error) {
      console.error('❌ School config query failed:', error);
      throw error;
    }
  }

  async getCertificates(teacherId, status = 'all') {
    try {
      let sql = `
        SELECT
          sc.id,
          sc.student_id as studentId,
          s.first_name || ' ' || s.last_name as studentName,
          sc.course_title as courseTitle,
          sc.completed_date as completedDate,
          sc.status,
          sc.approved_by as approvedBy,
          sc.approved_date as approvedDate
        FROM student_certificates sc
        JOIN students s ON sc.student_id = s.id
        WHERE s.teacher_id = ?
      `;

      const params = [teacherId];

      if (status !== 'all') {
        sql += ' AND sc.status = ?';
        params.push(status);
      }

      sql += ' ORDER BY sc.completed_date DESC';

      const certificates = await this.all(sql, params);

      // Calculate summary
      const allCerts = await this.all(`
        SELECT status FROM student_certificates sc
        JOIN students s ON sc.student_id = s.id
        WHERE s.teacher_id = ?
      `, [teacherId]);

      const summary = {
        total: allCerts.length,
        pending: allCerts.filter(c => c.status === 'pending').length,
        approved: allCerts.filter(c => c.status === 'approved').length,
        rejected: allCerts.filter(c => c.status === 'rejected').length
      };

      return { certificates, summary };

    } catch (error) {
      console.error('❌ Certificate query failed:', error);
      throw error;
    }
  }

  async updateCertificateStatus(certId, action, teacherId) {
    try {
      const status = action === 'approve' ? 'approved' : 'rejected';
      const now = new Date().toISOString();

      await this.run(`
        UPDATE student_certificates
        SET status = ?, approved_by = ?, approved_date = ?
        WHERE id = ?
      `, [status, teacherId, now, certId]);

      const certificate = await this.get(`
        SELECT
          sc.id,
          sc.student_id as studentId,
          s.first_name || ' ' || s.last_name as studentName,
          sc.course_title as courseTitle,
          sc.completed_date as completedDate,
          sc.status,
          sc.approved_by as approvedBy,
          sc.approved_date as approvedDate
        FROM student_certificates sc
        JOIN students s ON sc.student_id = s.id
        WHERE sc.id = ?
      `, [certId]);

      return certificate;

    } catch (error) {
      console.error('❌ Certificate update failed:', error);
      throw error;
    }
  }

  async checkCourseCompletionAndCreateCertificate(studentId, courseId) {
    try {
      // Define course requirements (minimum completed modules to earn certificate)
      // All 5 advanced courses award certificates: 1.0 through 5.0
      const courseRequirements = {
        'course-hv-safety': { minVideos: 7, title: '1.0 High Voltage Vehicle Safety Certificate' },
        'course-electrical-fundamentals': { minVideos: 4, title: '2.0 Electrical Level 1 - Medium Heavy Duty Certificate' },
        'course-advanced-ev': { minVideos: 2, title: '3.0 Electrical Level 2 - Medium Heavy Duty Certificate' },
        'course-ev-charging': { minVideos: 2, title: '4.0 Electric Vehicle Supply Equipment Certificate' },
        'course-ev-components': { minVideos: 3, title: '5.0 Introduction to Electric Vehicles Certificate' }
      };

      const requirement = courseRequirements[courseId];
      if (!requirement) {
        console.log(`📜 No certificate requirement defined for course: ${courseId}`);
        return;
      }

      // Check if student has already earned this certificate
      const existingCert = await this.get(`
        SELECT id FROM student_certificates
        WHERE student_id = ? AND course_id = ?
      `, [studentId, courseId]);

      if (existingCert) {
        console.log(`📜 Certificate already exists for student ${studentId} in course ${courseId}`);
        return;
      }

      // Count completed videos in this course for this student
      const completedVideos = await this.get(`
        SELECT COUNT(*) as count
        FROM video_progress
        WHERE student_id = ? AND course_id = ? AND completed = 1
      `, [studentId, courseId]);

      if (completedVideos.count >= requirement.minVideos) {
        // Student has completed enough videos, create certificate
        const now = new Date().toISOString();
        const certId = `cert-${studentId}-${courseId}-${Date.now()}`;

        await this.run(`
          INSERT INTO student_certificates
          (id, student_id, course_id, course_title, completed_date, status, certificate_data)
          VALUES (?, ?, ?, ?, ?, 'pending', ?)
        `, [
          certId, studentId, courseId, requirement.title, now,
          JSON.stringify({
            completedVideos: completedVideos.count,
            earnedDate: now,
            courseId: courseId
          })
        ]);

        console.log(`🎉 Certificate earned! Student ${studentId} completed ${courseId} - ${requirement.title}`);
        console.log(`📋 Certificate ${certId} created with status 'pending' - awaiting instructor approval`);

        return {
          success: true,
          certificateId: certId,
          title: requirement.title,
          status: 'pending'
        };
      } else {
        console.log(`📊 Student ${studentId} progress: ${completedVideos.count}/${requirement.minVideos} videos completed in ${courseId}`);
      }

    } catch (error) {
      console.error('❌ Certificate check/creation failed:', error);
    }
  }

  formatLastActive(daysSince) {
    if (daysSince < 0.02) return 'Just now';
    if (daysSince < 0.04) return 'Few minutes ago';
    if (daysSince < 1) return `${Math.floor(daysSince * 24)} hours ago`;
    if (daysSince < 2) return 'Yesterday';
    if (daysSince < 7) return `${Math.floor(daysSince)} days ago`;
    if (daysSince < 30) return `${Math.floor(daysSince / 7)} weeks ago`;
    return `${Math.floor(daysSince / 30)} months ago`;
  }

  async close() {
    if (this.db) {
      return new Promise((resolve) => {
        this.db.close((error) => {
          if (error) console.error('❌ Database close error:', error);
          else console.log('✅ Database connection closed');
          resolve();
        });
      });
    }
  }
}

// Singleton instance
const database = new Database();

module.exports = database;