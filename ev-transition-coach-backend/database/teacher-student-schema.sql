-- MindSherpa Teacher-Student Multi-Device Database Schema
-- SQLite compatible for rapid development

-- Schools and Teachers
CREATE TABLE IF NOT EXISTS schools (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    district TEXT,
    program TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS teachers (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    teacher_code TEXT UNIQUE NOT NULL,
    class_code TEXT UNIQUE,
    department TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (school_id) REFERENCES schools(id)
);

-- Students and Devices (Many-to-Many relationship)
CREATE TABLE IF NOT EXISTS students (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    teacher_id TEXT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    class_code TEXT,
    joined_at TEXT DEFAULT (datetime('now')),
    last_active TEXT,
    FOREIGN KEY (school_id) REFERENCES schools(id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(id),
    UNIQUE(email, teacher_id) -- Prevent duplicate emails within same teacher's class
);

CREATE TABLE IF NOT EXISTS devices (
    device_id TEXT PRIMARY KEY,
    student_id TEXT,
    device_name TEXT,
    platform TEXT, -- 'android' or 'ios'
    app_version TEXT,
    first_seen TEXT DEFAULT (datetime('now')),
    last_seen TEXT DEFAULT (datetime('now')),
    is_active INTEGER DEFAULT 1,
    FOREIGN KEY (student_id) REFERENCES students(id)
);

-- Progress Tracking per Device
CREATE TABLE IF NOT EXISTS video_progress (
    id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    student_id TEXT,
    video_id TEXT NOT NULL,
    course_id TEXT NOT NULL,
    last_position_sec INTEGER DEFAULT 0,
    watched_sec INTEGER DEFAULT 0,
    total_duration_sec INTEGER NOT NULL,
    progress_percentage INTEGER DEFAULT 0,
    completed INTEGER DEFAULT 0,
    completed_at TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (device_id) REFERENCES devices(device_id),
    FOREIGN KEY (student_id) REFERENCES students(id),
    UNIQUE(device_id, video_id)
);

CREATE TABLE IF NOT EXISTS daily_activity (
    id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    student_id TEXT,
    activity_date TEXT NOT NULL,
    total_watched_sec INTEGER DEFAULT 0,
    videos_completed INTEGER DEFAULT 0,
    videos_started INTEGER DEFAULT 0,
    xp_earned INTEGER DEFAULT 0,
    streak_count INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (device_id) REFERENCES devices(device_id),
    FOREIGN KEY (student_id) REFERENCES students(id),
    UNIQUE(device_id, activity_date)
);

CREATE TABLE IF NOT EXISTS student_certificates (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL,
    course_id TEXT NOT NULL,
    course_title TEXT NOT NULL,
    completed_date TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    approved_by TEXT,
    approved_date TEXT,
    certificate_data TEXT, -- JSON string
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (approved_by) REFERENCES teachers(id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_video_progress_device ON video_progress(device_id);
CREATE INDEX IF NOT EXISTS idx_video_progress_student ON video_progress(student_id);
CREATE INDEX IF NOT EXISTS idx_video_progress_updated ON video_progress(updated_at);
CREATE INDEX IF NOT EXISTS idx_daily_activity_device_date ON daily_activity(device_id, activity_date);
CREATE INDEX IF NOT EXISTS idx_daily_activity_student_date ON daily_activity(student_id, activity_date);
CREATE INDEX IF NOT EXISTS idx_students_teacher ON students(teacher_id);
CREATE INDEX IF NOT EXISTS idx_devices_student ON devices(student_id);
CREATE INDEX IF NOT EXISTS idx_certificates_student ON student_certificates(student_id);

-- Sample Data
INSERT OR IGNORE INTO schools (id, name, district, program) VALUES
('fallbrook-hs', 'Fallbrook High School', 'Fallbrook Union HSD', 'CTE Transportation Technology');

INSERT OR IGNORE INTO teachers (id, school_id, name, email, teacher_code, class_code, department) VALUES
('teacher-djohnson', 'fallbrook-hs', 'Dennis Johnson', 'djohnson@fuhsd.net', 'TEACH001', 'T5T4Y9', 'Transportation Technology');

-- Sample students with multiple devices
INSERT OR IGNORE INTO students (id, school_id, teacher_id, first_name, last_name, email, class_code, last_active) VALUES
('student-abigail-clark', 'fallbrook-hs', 'teacher-djohnson', 'Abigail', 'Clark', 'aclark@student.fuhsd.net', 'T5T4Y9', '2024-01-15 10:30:00'),
('student-addison-edwards', 'fallbrook-hs', 'teacher-djohnson', 'Addison', 'Edwards', 'aedwards@student.fuhsd.net', 'T5T4Y9', '2024-01-15 14:22:00'),
('student-adrian-cox', 'fallbrook-hs', 'teacher-djohnson', 'Adrian', 'Cox', 'acox@student.fuhsd.net', 'T5T4Y9', '2024-01-15 09:15:00'),
('student-alex-rodriguez', 'fallbrook-hs', 'teacher-djohnson', 'Alex', 'Rodriguez', 'arodriguez@student.fuhsd.net', 'T5T4Y9', '2024-01-15 12:45:00'),
('student-alexander-scott', 'fallbrook-hs', 'teacher-djohnson', 'Alexander', 'Scott', 'ascott@student.fuhsd.net', 'T5T4Y9', '2024-01-14 16:30:00');

-- Sample devices for students (multiple devices per student possible)
INSERT OR IGNORE INTO devices (device_id, student_id, device_name, platform, app_version, last_seen) VALUES
('android-device-001', 'student-abigail-clark', 'Samsung Galaxy S23', 'android', '1.2.0', '2024-01-15 10:30:00'),
('ios-device-001', 'student-addison-edwards', 'iPhone 14', 'ios', '1.2.0', '2024-01-15 14:22:00'),
('android-device-002', 'student-adrian-cox', 'Google Pixel 7', 'android', '1.2.0', '2024-01-15 09:15:00'),
('ios-device-002', 'student-alex-rodriguez', 'iPad Air', 'ios', '1.2.0', '2024-01-15 12:45:00'),
('android-device-003', 'student-alexander-scott', 'OnePlus 11', 'android', '1.1.8', '2024-01-14 16:30:00');

-- Sample video progress data
INSERT OR IGNORE INTO video_progress (id, device_id, student_id, video_id, course_id, last_position_sec, watched_sec, total_duration_sec, progress_percentage, completed, updated_at) VALUES
('progress-001', 'android-device-001', 'student-abigail-clark', 'video-hv-001', 'course-hv-safety', 1200, 1800, 1920, 94, 1, '2024-01-15 10:30:00'),
('progress-002', 'ios-device-001', 'student-addison-edwards', 'video-hv-001', 'course-hv-safety', 340, 450, 1920, 23, 0, '2024-01-15 14:22:00'),
('progress-003', 'android-device-002', 'student-adrian-cox', 'video-hv-002', 'course-hv-safety', 890, 1200, 1440, 83, 0, '2024-01-15 09:15:00'),
('progress-004', 'ios-device-002', 'student-alex-rodriguez', 'video-hv-001', 'course-hv-safety', 1800, 1920, 1920, 100, 1, '2024-01-15 12:45:00'),
('progress-005', 'android-device-003', 'student-alexander-scott', 'video-ef-001', 'course-electrical-fundamentals', 560, 720, 2160, 33, 0, '2024-01-14 16:30:00');

-- Sample daily activity
INSERT OR IGNORE INTO daily_activity (id, device_id, student_id, activity_date, total_watched_sec, videos_completed, videos_started, xp_earned) VALUES
('activity-001', 'android-device-001', 'student-abigail-clark', '2024-01-15', 1800, 1, 1, 150),
('activity-002', 'ios-device-001', 'student-addison-edwards', '2024-01-15', 450, 0, 1, 45),
('activity-003', 'android-device-002', 'student-adrian-cox', '2024-01-15', 1200, 0, 1, 80),
('activity-004', 'ios-device-002', 'student-alex-rodriguez', '2024-01-15', 1920, 1, 1, 200),
('activity-005', 'android-device-003', 'student-alexander-scott', '2024-01-14', 720, 0, 1, 60);