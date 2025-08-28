-- EV Training Coach Sample Data
-- Insert sample data that matches the existing iOS app structure

-- Insert Course Categories
INSERT INTO course_categories (name, category_type, display_name, icon, description, sequence_order) VALUES
('electrical_safety', 'electrical_safety', 'High Voltage Safety', 'exclamationmark.triangle.fill', 'Essential safety protocols for working with high voltage EV systems', 1),
('electrical_fundamentals', 'electrical_fundamentals', 'Electrical Fundamentals', 'bolt.circle.fill', 'Core electrical concepts and diagnostic skills for EV technicians', 2),
('ev_system_components', 'ev_system_components', 'EV System Components', 'car.rear.and.tire.marks', 'Understanding electric vehicle system architecture and diagnostics', 3),
('charging_systems', 'charging_systems', 'EV Charging Systems', 'battery.100.bolt', 'EV charging equipment, battery management, and safety systems', 4),
('advanced_systems', 'advanced_ev_systems', 'Advanced EV Systems', 'gearshape.2.fill', 'Advanced diagnostics, energy storage, and system integration', 5);

-- Insert Courses
INSERT INTO courses (external_id, title, description, category_id, skill_level, estimated_hours, sequence_order, learning_objectives) 
SELECT 
    '1',
    'High Voltage Safety Foundation',
    'Overview of high voltage safety roles, training, and authorization in EV systems',
    cc.id,
    'beginner',
    0.773,
    1,
    ARRAY[
        'Understand EV safety pyramid and worker qualifications',
        'Identify high voltage hazards and their effects',
        'Apply electrical shock protection boundaries',
        'Select and use proper PPE with arc ratings',
        'Recognize HV components in electric vehicles'
    ]
FROM course_categories cc WHERE cc.category_type = 'electrical_safety';

INSERT INTO courses (external_id, title, description, category_id, skill_level, estimated_hours, sequence_order, learning_objectives)
SELECT 
    '2',
    'Electrical Fundamentals',
    'Core electrical concepts for EV technicians',
    cc.id,
    'beginner',
    0.517,
    2,
    ARRAY[
        'Master automotive electrical circuit fundamentals',
        'Use digital multimeters safely and accurately',
        'Diagnose electrical faults and component failures',
        'Troubleshoot circuits, relays, and motors systematically'
    ]
FROM course_categories cc WHERE cc.category_type = 'electrical_fundamentals';

INSERT INTO courses (external_id, title, description, category_id, skill_level, estimated_hours, sequence_order, learning_objectives)
SELECT 
    '3',
    'EV System Components',
    'Understanding electric vehicle system architecture',
    cc.id,
    'intermediate',
    0.215,
    3,
    ARRAY[
        'Use oscilloscopes and advanced measurement tools',
        'Diagnose CAN, LIN, and other vehicle communication networks',
        'Understand EV powertrain component interactions'
    ]
FROM course_categories cc WHERE cc.category_type = 'ev_system_components';

INSERT INTO courses (external_id, title, description, category_id, skill_level, estimated_hours, sequence_order, learning_objectives)
SELECT 
    '4',
    'EV Charging Systems',
    'EV battery systems and management',
    cc.id,
    'intermediate',
    0.255,
    4,
    ARRAY[
        'Understand EVSE types, levels, and safety features',
        'Test and troubleshoot charging systems',
        'Manage battery performance and safety protocols'
    ]
FROM course_categories cc WHERE cc.category_type = 'charging_systems';

INSERT INTO courses (external_id, title, description, category_id, skill_level, estimated_hours, sequence_order, learning_objectives)
SELECT 
    '5',
    'Advanced EV Systems',
    'Advanced diagnostics and system integration',
    cc.id,
    'advanced',
    0.410,
    5,
    ARRAY[
        'Understand EV history and environmental benefits',
        'Master battery chemistry and thermal management',
        'Diagnose motor types, controllers, and regenerative braking'
    ]
FROM course_categories cc WHERE cc.category_type = 'advanced_ev_systems';

-- Insert Videos for Course 1: High Voltage Safety Foundation
INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '1-1',
    c.id,
    '1.1 EV Safety Pyramid - Who''s Allowed to Touch',
    'Roles, responsibilities, and protocols for electrically aware, qualified, and authorized workers',
    'https://youtu.be/4KiaE9KPu1g',
    '4KiaE9KPu1g',
    370,
    1
FROM courses c WHERE c.external_id = '1';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '1-2',
    c.id,
    '1.2 High Voltage Hazards Overview',
    'Understanding risks like electric shock, arc flash, and arc blast, and their effects on the body',
    'https://youtu.be/YL8zgLZ096U',
    'YL8zgLZ096U',
    417,
    2
FROM courses c WHERE c.external_id = '1';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '1-3',
    c.id,
    '1.3 Navigating Electrical Shock Protection Boundaries',
    'Identifying and applying limited, restricted, and arc flash boundaries to prevent accidents',
    'https://youtu.be/N1dLWS57e2s',
    'N1dLWS57e2s',
    406,
    3
FROM courses c WHERE c.external_id = '1';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '1-4',
    c.id,
    '1.4 High Voltage PPE Your First Line of Defense',
    'Selecting and using proper PPE with arc ratings and hazard risk categories',
    'https://youtu.be/kVrO3nvOZXk',
    'kVrO3nvOZXk',
    415,
    4
FROM courses c WHERE c.external_id = '1';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '1-5',
    c.id,
    '1.5 Inside an Electric Car - The Journey of Energy',
    'Functions of batteries, traction motors, inverters, converters, and other HV parts',
    'https://youtu.be/b8W0H5-qRLM',
    'b8W0H5-qRLM',
    406,
    5
FROM courses c WHERE c.external_id = '1';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '1-6',
    c.id,
    '1.6 Taming the Current - EV High Voltage Safety',
    'Techniques for disabling batteries, using service disconnects, and handling HV components safely',
    'https://youtu.be/LlmbSDnSDoA',
    'LlmbSDnSDoA',
    462,
    6
FROM courses c WHERE c.external_id = '1';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '1-7',
    c.id,
    '1.7 How to Spot High Voltage Danger on an Electric Bus',
    'Identifying high voltage components in electric vehicles through various visual cues',
    'https://youtu.be/CbVm-Ey91p4',
    'CbVm-Ey91p4',
    307,
    7
FROM courses c WHERE c.external_id = '1';

-- Insert Videos for Course 2: Electrical Fundamentals
INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '2-1',
    c.id,
    '2.1 Automotive Electrical Circuits 101',
    'Fundamentals of voltage, current, resistance, and power with practical circuit labs',
    'https://youtu.be/lM8BX4JMAgo?si=Umxcgqa1KNZuoBxN',
    'lM8BX4JMAgo',
    433,
    1
FROM courses c WHERE c.external_id = '2';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '2-2',
    c.id,
    '2.2 Electrical Measurement and Digital Multimeter',
    'Safe and accurate use of digital multimeters for voltage, current, resistance, and more',
    'https://youtu.be/w8jPxtj16xc?si=lpyXJQuqIZxIimdk',
    'w8jPxtj16xc',
    461,
    2
FROM courses c WHERE c.external_id = '2';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '2-3',
    c.id,
    '2.3 Electrical Fault Analysis: Measurement and Diagnosis',
    'Diagnosing opens, shorts, high resistance, and component failures using diagrams and meters',
    'https://youtu.be/GM5LmaEVwm0?si=LFUfHB_MaBWtU8JQ',
    'GM5LmaEVwm0',
    409,
    3
FROM courses c WHERE c.external_id = '2';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '2-4',
    c.id,
    '2.4 Automotive Circuit Diagnosis and Troubleshooting',
    'Systematic troubleshooting of circuits, relays, switches, and motors using diagnostic tools',
    'https://youtu.be/jSx5H47YCWk?si=ruyCTNFVPktzla-u',
    'jSx5H47YCWk',
    551,
    4
FROM courses c WHERE c.external_id = '2';

-- Insert Videos for Course 3: EV System Components
INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '3-1',
    c.id,
    '3.1 Advanced Electrical Diagnostics',
    'Oscilloscope and advanced multimeter use, sensors, actuators, and circuit analysis',
    'https://youtu.be/Wbwm7dOQfLY?si=51XKND1jEgkoPZxW',
    'Wbwm7dOQfLY',
    391,
    1
FROM courses c WHERE c.external_id = '3';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '3-2',
    c.id,
    '3.2 Vehicle Communication Networks',
    'Diagnosis of CAN, LIN, FlexRay, MOST, and Ethernet bus systems with gateways and fiber optics',
    'https://youtu.be/Rk27qlWgPQY',
    'Rk27qlWgPQY',
    384,
    2
FROM courses c WHERE c.external_id = '3';

-- Insert Videos for Course 4: EV Charging Systems
INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '4-1',
    c.id,
    '4.1 Electric Vehicle Supply Equipment & Electric Vehicle Charging Systems',
    'Types, levels, connectors, standards, and safety features of EV charging equipments',
    'https://youtu.be/Xl4-BlPQuGE?si=H851Kr8lxMUe-AYv',
    'Xl4-BlPQuGE',
    502,
    1
FROM courses c WHERE c.external_id = '4';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '4-2',
    c.id,
    '4.2 Charging Diagnostics & Battery Management',
    'Testing, troubleshooting charging systems, and managing battery performance and safety',
    'https://youtu.be/ARAfACV7-3E?si=Yj8oKfqzqDkWPfl4',
    'ARAfACV7-3E',
    414,
    2
FROM courses c WHERE c.external_id = '4';

-- Insert Videos for Course 5: Advanced EV Systems
INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '5-1',
    c.id,
    '5.1 Introduction to Electric Vehicles',
    'History, evolution, key powertrain components, charging, and environmental benefits',
    'https://youtu.be/5dL9g8LqGVU',
    '5dL9g8LqGVU',
    459,
    1
FROM courses c WHERE c.external_id = '5';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '5-2',
    c.id,
    '5.2 EV Energy Storage Systems',
    'Battery types, chemistry, management, capacity, and thermal considerations',
    'https://youtu.be/CPIsnjd3SBU?si=xMJ4WDfb_NglCr20',
    'CPIsnjd3SBU',
    483,
    2
FROM courses c WHERE c.external_id = '5';

INSERT INTO videos (external_id, course_id, title, description, video_url, youtube_video_id, duration_seconds, sequence_order)
SELECT 
    '5-3',
    c.id,
    '5.3 EV Architecture, Motors & Controllers',
    'Powertrain layouts, motor types, controllers, and regenerative braking systems',
    'https://youtu.be/hABCuNpftUk?si=L8DZa25Q3SLUoo_G',
    'hABCuNpftUk',
    532,
    3
FROM courses c WHERE c.external_id = '5';

-- Insert Sample Podcasts
INSERT INTO podcasts (external_id, course_id, title, description, audio_url, duration_seconds, episode_number, sequence_order, show_notes)
SELECT 
    'podcast-1-1',
    c.id,
    'Understanding EV Safety Fundamentals',
    'A deep dive conversation about the core principles of electric vehicle safety, covering who can work on high voltage systems and why proper training matters.',
    'https://example.com/podcasts/ev-safety-fundamentals.mp3',
    1680,
    1,
    1,
    'In this episode, we explore the critical safety protocols every EV technician must know. Topics covered include the EV safety pyramid, worker qualifications, and real-world safety scenarios.'
FROM courses c WHERE c.external_id = '1';

INSERT INTO podcasts (external_id, course_id, title, description, audio_url, duration_seconds, episode_number, sequence_order, show_notes)
SELECT 
    'podcast-2-1',
    c.id,
    'Electrical Circuits Explained Simply',
    'Breaking down complex electrical concepts into easy-to-understand analogies and practical examples for EV technicians.',
    'https://example.com/podcasts/electrical-circuits-explained.mp3',
    1320,
    2,
    1,
    'Join us as we demystify automotive electrical systems using everyday analogies. Perfect for technicians transitioning to EV work who need to strengthen their electrical fundamentals.'
FROM courses c WHERE c.external_id = '2';

INSERT INTO podcasts (external_id, course_id, title, description, audio_url, duration_seconds, episode_number, sequence_order, show_notes)
SELECT 
    'podcast-3-1',
    c.id,
    'Advanced Diagnostics Deep Dive',
    'Expert discussion on using oscilloscopes and advanced measurement tools for EV system diagnostics.',
    'https://example.com/podcasts/advanced-diagnostics.mp3',
    1920,
    3,
    1,
    'Advanced diagnostic techniques revealed by industry experts. Learn how to use oscilloscopes, interpret waveforms, and troubleshoot complex EV communication networks.'
FROM courses c WHERE c.external_id = '3';

-- Insert Sample Quiz Questions
INSERT INTO quiz_questions (video_id, question, options, correct_answer_index, explanation, sequence_order)
SELECT 
    v.id,
    'Who is authorized to work on high voltage EV systems?',
    '["Any automotive technician", "Only electrically qualified persons", "Electrically authorized and qualified persons", "Anyone with basic training"]'::jsonb,
    2,
    'Only electrically authorized and qualified persons who have completed proper high voltage training and certification are permitted to work on EV high voltage systems.',
    1
FROM videos v WHERE v.external_id = '1-1';

INSERT INTO quiz_questions (video_id, question, options, correct_answer_index, explanation, sequence_order)
SELECT 
    v.id,
    'What is the primary purpose of the limited approach boundary?',
    '["To prevent arc flash", "To prevent electric shock", "To mark the work area", "To identify HV components"]'::jsonb,
    1,
    'The limited approach boundary is established to prevent electric shock by maintaining a safe distance from exposed energized parts.',
    1
FROM videos v WHERE v.external_id = '1-3';

INSERT INTO quiz_questions (video_id, question, options, correct_answer_index, explanation, sequence_order)
SELECT 
    v.id,
    'What does Ohm''s Law describe?',
    '["Power relationships", "The relationship between voltage, current, and resistance", "Magnetic field strength", "Battery capacity"]'::jsonb,
    1,
    'Ohm''s Law describes the fundamental relationship between voltage (V), current (I), and resistance (R) in electrical circuits: V = I × R.',
    1
FROM videos v WHERE v.external_id = '2-1';

-- Insert Sample Device and Progress Data
INSERT INTO devices (device_id, device_model, system_name, system_version, app_version, locale, timezone)
VALUES
('iPhone-Demo-001', 'iPhone 15 Pro', 'iOS', '17.2', '1.0.0', 'en_US', 'America/New_York'),
('iPhone-Demo-002', 'iPhone 14', 'iOS', '17.1', '1.0.0', 'en_US', 'America/Los_Angeles'),
('iPad-Demo-001', 'iPad Air', 'iPadOS', '17.2', '1.0.0', 'en_US', 'America/Chicago');

-- Insert Sample Video Progress
INSERT INTO video_progress (device_id, video_id, watched_seconds, total_duration, is_completed)
SELECT 
    d.id,
    v.id,
    v.duration_seconds,
    v.duration_seconds,
    true
FROM devices d, videos v 
WHERE d.device_id = 'iPhone-Demo-001' 
AND v.external_id IN ('1-1', '1-2', '1-3')
LIMIT 3;

INSERT INTO video_progress (device_id, video_id, watched_seconds, total_duration, is_completed)
SELECT 
    d.id,
    v.id,
    FLOOR(v.duration_seconds * 0.7),
    v.duration_seconds,
    false
FROM devices d, videos v 
WHERE d.device_id = 'iPhone-Demo-001' 
AND v.external_id IN ('1-4', '1-5')
LIMIT 2;

-- Insert Sample Course Progress
INSERT INTO course_progress (device_id, course_id, videos_completed, total_videos, completion_percentage, total_watch_time_seconds)
SELECT 
    d.id,
    c.id,
    3,
    7,
    ROUND((3.0 / 7 * 100)::numeric, 2),
    1293 -- Sum of completed video durations
FROM devices d, courses c 
WHERE d.device_id = 'iPhone-Demo-001' AND c.external_id = '1';

-- Insert Sample AI Interactions
INSERT INTO ai_interactions (device_id, course_id, video_id, question, context, response, response_time_ms)
SELECT 
    d.id,
    c.id,
    v.id,
    'What PPE is required for working on high voltage systems?',
    'Course: High Voltage Safety Foundation, Video: PPE Requirements',
    'When working on high voltage EV systems, you need class 0 or higher insulating gloves, safety glasses, arc-rated clothing, and insulated tools. The specific PPE level depends on the voltage and arc flash hazard analysis.',
    2150
FROM devices d, courses c, videos v
WHERE d.device_id = 'iPhone-Demo-001' 
AND c.external_id = '1' 
AND v.external_id = '1-4';

-- Insert Sample Analytics Events
INSERT INTO analytics_events (device_id, event_type, session_id, parameters, device_info)
SELECT 
    d.id,
    'app_launched',
    'session-demo-001',
    '{"first_launch": false}'::jsonb,
    '{"device_model": "iPhone 15 Pro", "system_version": "17.2", "app_version": "1.0.0"}'::jsonb
FROM devices d WHERE d.device_id = 'iPhone-Demo-001';

INSERT INTO analytics_events (device_id, event_type, session_id, parameters)
SELECT 
    d.id,
    'video_started',
    'session-demo-001',
    '{"video_id": "1-1", "course_id": "1", "title": "EV Safety Pyramid"}'::jsonb
FROM devices d WHERE d.device_id = 'iPhone-Demo-001';

INSERT INTO analytics_events (device_id, event_type, session_id, parameters)
SELECT 
    d.id,
    'video_completed',
    'session-demo-001',
    '{"video_id": "1-1", "course_id": "1", "watch_time": 370, "total_duration": 370}'::jsonb
FROM devices d WHERE d.device_id = 'iPhone-Demo-001';

-- Insert Sample Learning Sessions
INSERT INTO learning_sessions (device_id, session_type, started_at, ended_at, content_items_consumed, videos_watched, ai_questions_asked)
SELECT 
    d.id,
    'video',
    CURRENT_TIMESTAMP - INTERVAL '45 minutes',
    CURRENT_TIMESTAMP - INTERVAL '15 minutes',
    3,
    ARRAY[v1.id, v2.id, v3.id],
    1
FROM devices d,
     (SELECT id FROM videos WHERE external_id = '1-1') v1,
     (SELECT id FROM videos WHERE external_id = '1-2') v2,
     (SELECT id FROM videos WHERE external_id = '1-3') v3
WHERE d.device_id = 'iPhone-Demo-001';

-- Insert Sample Learning Streaks
INSERT INTO learning_streaks (device_id, current_streak, longest_streak, last_study_date, total_study_days)
SELECT 
    d.id,
    5,
    12,
    CURRENT_DATE,
    23
FROM devices d WHERE d.device_id = 'iPhone-Demo-001';