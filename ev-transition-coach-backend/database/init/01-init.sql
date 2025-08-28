-- Database initialization script for Docker
-- This script runs automatically when the PostgreSQL container starts

\echo 'Starting EV Coach Database Initialization...'

-- Create the database if it doesn't exist
SELECT 'CREATE DATABASE ev_coach_development'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ev_coach_development')\gexec

-- Connect to the database
\c ev_coach_development;

\echo 'Connected to ev_coach_development database'

-- Create schema
\i /docker-entrypoint-initdb.d/schema.sql

\echo 'Database schema created successfully'

-- Insert sample data
\i /docker-entrypoint-initdb.d/seed-data.sql

\echo 'Sample data inserted successfully'

-- Display summary
\echo '=== EV Coach Database Setup Complete ==='
SELECT 'Courses: ' || COUNT(*) FROM courses;
SELECT 'Videos: ' || COUNT(*) FROM videos;
SELECT 'Podcasts: ' || COUNT(*) FROM podcasts;
SELECT 'Sample Devices: ' || COUNT(*) FROM devices;

\echo 'Database is ready for development!'