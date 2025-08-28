-- EV Training Coach Database Schema
-- PostgreSQL Database Schema for EV Technician Training Platform

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Custom Types
CREATE TYPE skill_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');
CREATE TYPE course_category AS ENUM (
    'electrical_safety', 
    'electrical_fundamentals', 
    'ev_system_components', 
    'battery_technology', 
    'advanced_ev_systems',
    'charging_systems'
);
CREATE TYPE event_type AS ENUM (
    'app_launched', 'session_started', 'session_ended',
    'video_started', 'video_paused', 'video_resumed', 'video_completed', 'video_skipped',
    'podcast_started', 'podcast_paused', 'podcast_resumed', 'podcast_completed', 'podcast_skipped',
    'quiz_started', 'quiz_answered', 'quiz_completed', 'quiz_retaken',
    'ai_question_asked', 'ai_response_received', 'ai_quick_question_used',
    'course_started', 'course_completed', 'course_progress_updated',
    'tab_switched', 'screen_viewed', 'action_performed',
    'study_session_started', 'study_session_ended', 'learning_streak_updated', 'achievement_unlocked'
);

-- Device Tracking Table
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id VARCHAR(255) UNIQUE NOT NULL,
    device_model VARCHAR(100),
    system_name VARCHAR(50),
    system_version VARCHAR(20),
    app_version VARCHAR(20),
    build_number VARCHAR(20),
    locale VARCHAR(10),
    timezone VARCHAR(50),
    first_launch_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Course Categories Table
CREATE TABLE course_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    category_type course_category NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    icon VARCHAR(50) NOT NULL,
    description TEXT,
    sequence_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Courses Table
CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(50) UNIQUE NOT NULL, -- For compatibility with existing iOS app
    title VARCHAR(200) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES course_categories(id) ON DELETE SET NULL,
    skill_level skill_level DEFAULT 'beginner',
    estimated_hours DECIMAL(4,2) DEFAULT 0,
    thumbnail_url TEXT,
    sequence_order INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT true,
    prerequisites TEXT[], -- Array of prerequisite course IDs
    learning_objectives TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Videos Table
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(50) UNIQUE NOT NULL, -- For compatibility (e.g., "1-1", "1-2")
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    youtube_video_id VARCHAR(20), -- Extracted from URL
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    thumbnail_url TEXT,
    sequence_order INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT true,
    transcript TEXT,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Podcasts Table
CREATE TABLE podcasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(50) UNIQUE NOT NULL,
    course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    audio_url TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    thumbnail_url TEXT,
    episode_number INTEGER,
    sequence_order INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT true,
    published_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    transcript TEXT,
    show_notes TEXT,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Quiz Questions Table
CREATE TABLE quiz_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of answer options
    correct_answer_index INTEGER NOT NULL,
    explanation TEXT,
    points INTEGER DEFAULT 1,
    sequence_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Progress Tables
CREATE TABLE video_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    watched_seconds INTEGER DEFAULT 0,
    total_duration INTEGER NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completion_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN total_duration > 0 THEN (watched_seconds::decimal / total_duration * 100)
            ELSE 0
        END
    ) STORED,
    first_watched_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_watched_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    watch_count INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id, video_id)
);

CREATE TABLE podcast_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    podcast_id UUID REFERENCES podcasts(id) ON DELETE CASCADE,
    playback_position INTEGER DEFAULT 0,
    total_duration INTEGER NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    completion_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN total_duration > 0 THEN (playback_position::decimal / total_duration * 100)
            ELSE 0
        END
    ) STORED,
    first_played_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_played_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    play_count INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id, podcast_id)
);

CREATE TABLE course_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    videos_completed INTEGER DEFAULT 0,
    total_videos INTEGER DEFAULT 0,
    podcasts_completed INTEGER DEFAULT 0,
    total_podcasts INTEGER DEFAULT 0,
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    total_watch_time_seconds INTEGER DEFAULT 0,
    first_started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id, course_id)
);

-- Quiz Attempts Table
CREATE TABLE quiz_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    quiz_question_id UUID REFERENCES quiz_questions(id) ON DELETE CASCADE,
    answer_index INTEGER NOT NULL,
    is_correct BOOLEAN NOT NULL,
    time_spent_seconds INTEGER DEFAULT 0,
    attempt_number INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI Interactions Table
CREATE TABLE ai_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
    video_id UUID REFERENCES videos(id) ON DELETE SET NULL,
    question TEXT NOT NULL,
    context TEXT,
    response TEXT,
    response_time_ms INTEGER,
    is_quick_question BOOLEAN DEFAULT false,
    question_category VARCHAR(50),
    satisfaction_rating INTEGER CHECK (satisfaction_rating BETWEEN 1 AND 5),
    feedback TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Analytics Events Table
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    event_type event_type NOT NULL,
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(100),
    parameters JSONB DEFAULT '{}',
    device_info JSONB DEFAULT '{}',
    user_agent TEXT,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Learning Sessions Table
CREATE TABLE learning_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    session_type VARCHAR(20) NOT NULL, -- 'video', 'podcast', 'mixed'
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN ended_at IS NOT NULL THEN EXTRACT(EPOCH FROM (ended_at - started_at))::INTEGER
            ELSE NULL
        END
    ) STORED,
    content_items_consumed INTEGER DEFAULT 0,
    courses_accessed UUID[],
    videos_watched UUID[],
    podcasts_listened UUID[],
    ai_questions_asked INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Learning Streaks Table
CREATE TABLE learning_streaks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_study_date DATE,
    streak_start_date DATE,
    total_study_days INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id)
);

-- Indexes for Performance
CREATE INDEX idx_devices_device_id ON devices(device_id);
CREATE INDEX idx_devices_last_active ON devices(last_active_at);

CREATE INDEX idx_courses_external_id ON courses(external_id);
CREATE INDEX idx_courses_category ON courses(category_id);
CREATE INDEX idx_courses_published ON courses(is_published);

CREATE INDEX idx_videos_external_id ON videos(external_id);
CREATE INDEX idx_videos_course ON videos(course_id);
CREATE INDEX idx_videos_published ON videos(is_published);

CREATE INDEX idx_podcasts_external_id ON podcasts(external_id);
CREATE INDEX idx_podcasts_course ON podcasts(course_id);

CREATE INDEX idx_video_progress_device ON video_progress(device_id);
CREATE INDEX idx_video_progress_video ON video_progress(video_id);
CREATE INDEX idx_video_progress_completed ON video_progress(is_completed);

CREATE INDEX idx_podcast_progress_device ON podcast_progress(device_id);
CREATE INDEX idx_podcast_progress_podcast ON podcast_progress(podcast_id);

CREATE INDEX idx_course_progress_device ON course_progress(device_id);
CREATE INDEX idx_course_progress_course ON course_progress(course_id);

CREATE INDEX idx_analytics_events_device ON analytics_events(device_id);
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_timestamp ON analytics_events(event_timestamp);
CREATE INDEX idx_analytics_events_session ON analytics_events(session_id);

CREATE INDEX idx_ai_interactions_device ON ai_interactions(device_id);
CREATE INDEX idx_ai_interactions_course ON ai_interactions(course_id);
CREATE INDEX idx_ai_interactions_created ON ai_interactions(created_at);

-- Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON devices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_videos_updated_at BEFORE UPDATE ON videos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_podcasts_updated_at BEFORE UPDATE ON podcasts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_video_progress_updated_at BEFORE UPDATE ON video_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_podcast_progress_updated_at BEFORE UPDATE ON podcast_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_course_progress_updated_at BEFORE UPDATE ON course_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_learning_sessions_updated_at BEFORE UPDATE ON learning_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_learning_streaks_updated_at BEFORE UPDATE ON learning_streaks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Views for Common Queries
CREATE VIEW course_completion_stats AS
SELECT 
    c.id as course_id,
    c.title as course_title,
    COUNT(DISTINCT cp.device_id) as total_learners,
    COUNT(DISTINCT CASE WHEN cp.is_completed THEN cp.device_id END) as completed_learners,
    ROUND(AVG(cp.completion_percentage), 2) as avg_completion_percentage,
    ROUND(AVG(cp.total_watch_time_seconds) / 60.0, 2) as avg_watch_time_minutes
FROM courses c
LEFT JOIN course_progress cp ON c.id = cp.course_id
WHERE c.is_published = true
GROUP BY c.id, c.title;

CREATE VIEW video_engagement_stats AS
SELECT 
    v.id as video_id,
    v.title as video_title,
    c.title as course_title,
    COUNT(DISTINCT vp.device_id) as total_viewers,
    COUNT(DISTINCT CASE WHEN vp.is_completed THEN vp.device_id END) as completed_viewers,
    ROUND(AVG(vp.completion_percentage), 2) as avg_completion_percentage,
    ROUND(AVG(vp.watched_seconds) / 60.0, 2) as avg_watch_time_minutes,
    ROUND(AVG(vp.watch_count), 2) as avg_replays
FROM videos v
JOIN courses c ON v.course_id = c.id
LEFT JOIN video_progress vp ON v.id = vp.video_id
WHERE v.is_published = true
GROUP BY v.id, v.title, c.title;

CREATE VIEW device_learning_summary AS
SELECT 
    d.device_id,
    d.device_model,
    d.first_launch_at,
    d.last_active_at,
    COUNT(DISTINCT cp.course_id) as courses_started,
    COUNT(DISTINCT CASE WHEN cp.is_completed THEN cp.course_id END) as courses_completed,
    COUNT(DISTINCT vp.video_id) as videos_watched,
    COUNT(DISTINCT CASE WHEN vp.is_completed THEN vp.video_id END) as videos_completed,
    COUNT(DISTINCT pp.podcast_id) as podcasts_listened,
    COUNT(DISTINCT ai.id) as ai_interactions,
    COALESCE(ls.current_streak, 0) as current_learning_streak
FROM devices d
LEFT JOIN course_progress cp ON d.id = cp.device_id
LEFT JOIN video_progress vp ON d.id = vp.device_id
LEFT JOIN podcast_progress pp ON d.id = pp.device_id
LEFT JOIN ai_interactions ai ON d.id = ai.device_id
LEFT JOIN learning_streaks ls ON d.id = ls.device_id
GROUP BY d.id, d.device_id, d.device_model, d.first_launch_at, d.last_active_at, ls.current_streak;