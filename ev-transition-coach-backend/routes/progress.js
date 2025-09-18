const express = require('express');
const router = express.Router();
const database = require('../database/db');

// POST /api/progress/register-device - Register a new device
router.post('/register-device', async (req, res) => {
  try {
    const { deviceId, platform, appVersion, deviceName } = req.body;

    if (!deviceId || !platform) {
      return res.status(400).json({
        error: 'Missing required fields: deviceId, platform'
      });
    }

    await database.initialize();
    const result = await database.registerDevice(deviceId, platform, appVersion, deviceName);

    res.json({
      success: true,
      deviceId,
      message: 'Device registered successfully'
    });

  } catch (error) {
    console.error('Device registration error:', error);
    res.status(500).json({
      error: 'Failed to register device',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST /api/progress/join-class - Link device to student via class code
router.post('/join-class', async (req, res) => {
  try {
    const { deviceId, classCode, firstName, lastName, email } = req.body;

    if (!deviceId || !classCode || !firstName || !lastName) {
      return res.status(400).json({
        error: 'Missing required fields: deviceId, classCode, firstName, lastName'
      });
    }

    await database.initialize();
    const result = await database.linkDeviceToStudent(deviceId, classCode, firstName, lastName, email);

    res.json({
      success: true,
      studentId: result.studentId,
      teacherId: result.teacherId,
      schoolId: result.schoolId,
      classDetails: result.classDetails,
      message: `Successfully joined class ${classCode}`
    });

  } catch (error) {
    console.error('Class join error:', error);

    // Check if it's a "Class does not exist" error
    if (error.message && error.message.includes('This Class does not exist')) {
      return res.status(404).json({
        error: 'This Class does not exist',
        success: false
      });
    }

    res.status(500).json({
      error: 'Failed to join class',
      success: false,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST /api/progress/video - Update video progress
router.post('/video', async (req, res) => {
  try {
    const {
      videoId,
      deviceId,
      watchedSeconds,
      totalDuration,
      isCompleted,
      courseId,
      lastPosition
    } = req.body;

    if (!videoId || !deviceId || watchedSeconds === undefined || !totalDuration) {
      return res.status(400).json({
        error: 'Missing required fields: videoId, deviceId, watchedSeconds, totalDuration'
      });
    }

    // Ensure database is initialized
    await database.initialize();

    // Register device if not exists
    await database.registerDevice(deviceId, 'unknown', '1.0.0');

    // Update video progress in database
    const result = await database.updateVideoProgress(
      deviceId,
      videoId,
      courseId || 'unknown',
      lastPosition || watchedSeconds,
      Math.floor(watchedSeconds),
      Math.floor(totalDuration),
      isCompleted
    );

    const progressData = {
      videoId,
      deviceId,
      watchedSeconds: Math.floor(watchedSeconds),
      totalDuration: Math.floor(totalDuration),
      progressPercentage: result.progressPercentage,
      isCompleted: result.completed,
      lastWatchedAt: new Date().toISOString(),
      courseId
    };

    res.json({
      success: true,
      progress: progressData,
      message: result.completed ? 'Video completed!' : 'Progress saved'
    });

  } catch (error) {
    console.error('Video progress update error:', error);
    res.status(500).json({
      error: 'Failed to update video progress',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST /api/progress/podcast - Update podcast progress  
router.post('/podcast', async (req, res) => {
  try {
    const { 
      podcastId, 
      deviceId, 
      playbackPosition, 
      totalDuration, 
      isCompleted, 
      courseId 
    } = req.body;

    if (!podcastId || !deviceId || playbackPosition === undefined || !totalDuration) {
      return res.status(400).json({ 
        error: 'Missing required fields: podcastId, deviceId, playbackPosition, totalDuration' 
      });
    }

    // Calculate progress percentage
    const progressPercentage = Math.min(100, Math.max(0, (playbackPosition / totalDuration) * 100));
    const completed = isCompleted || progressPercentage >= 95;

    const progressData = {
      podcastId,
      deviceId,
      playbackPosition: Math.floor(playbackPosition),
      totalDuration: Math.floor(totalDuration),
      progressPercentage: Math.floor(progressPercentage),
      isCompleted: completed,
      lastPlayedAt: new Date().toISOString(),
      courseId
    };

    console.log(`🎧 Podcast Progress Update:`, progressData);

    res.json({
      success: true,
      progress: progressData,
      message: completed ? 'Podcast completed!' : 'Progress saved'
    });

  } catch (error) {
    console.error('Podcast progress update error:', error);
    res.status(500).json({ 
      error: 'Failed to update podcast progress',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/progress/device/:deviceId - Get all progress for a device
router.get('/device/:deviceId', async (req, res) => {
  try {
    const { deviceId } = req.params;

    if (!deviceId) {
      return res.status(400).json({ error: 'Device ID is required' });
    }

    // In a real implementation, you would query the database
    // For now, return sample progress data
    const progressData = {
      deviceId,
      videoProgress: {},
      podcastProgress: {},
      completedVideos: [],
      completedPodcasts: [],
      totalWatchTime: 0,
      coursesStarted: [],
      lastSync: new Date().toISOString()
    };

    console.log(`📊 Progress sync for device: ${deviceId}`);

    res.json({
      success: true,
      progress: progressData
    });

  } catch (error) {
    console.error('Progress retrieval error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve progress',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET /api/progress/course/:courseId/:deviceId - Get course-specific progress
router.get('/course/:courseId/:deviceId', async (req, res) => {
  try {
    const { courseId, deviceId } = req.params;

    if (!courseId || !deviceId) {
      return res.status(400).json({ error: 'Course ID and Device ID are required' });
    }

    // In a real implementation, query database for course progress
    const courseProgress = {
      courseId,
      deviceId,
      videosCompleted: 0,
      totalVideos: 0,
      podcastsCompleted: 0, 
      totalPodcasts: 0,
      overallProgress: 0,
      totalWatchTime: 0,
      startedAt: null,
      lastActivity: null,
      isCompleted: false
    };

    console.log(`📚 Course progress for ${courseId}, device: ${deviceId}`);

    res.json({
      success: true,
      courseProgress
    });

  } catch (error) {
    console.error('Course progress retrieval error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve course progress',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST /api/progress/sync - Bulk sync progress data
router.post('/sync', async (req, res) => {
  try {
    const { deviceId, progressData } = req.body;

    if (!deviceId || !progressData) {
      return res.status(400).json({ error: 'Device ID and progress data required' });
    }

    // In a real implementation, you would:
    // 1. Validate all progress entries
    // 2. Bulk insert/update to database
    // 3. Handle conflicts (server vs client timestamps)
    // 4. Return updated progress data

    console.log(`🔄 Bulk progress sync for device: ${deviceId}`);
    console.log(`   Video entries: ${Object.keys(progressData.videoProgress || {}).length}`);
    console.log(`   Podcast entries: ${Object.keys(progressData.podcastProgress || {}).length}`);

    res.json({
      success: true,
      message: 'Progress synced successfully',
      syncedAt: new Date().toISOString(),
      conflicts: [], // Any items that couldn't be synced
      updated: progressData // Echo back the data for now
    });

  } catch (error) {
    console.error('Progress sync error:', error);
    res.status(500).json({ 
      error: 'Failed to sync progress',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// DELETE /api/progress/device/:deviceId - Clear all progress for device
router.delete('/device/:deviceId', async (req, res) => {
  try {
    const { deviceId } = req.params;

    if (!deviceId) {
      return res.status(400).json({ error: 'Device ID is required' });
    }

    // In a real implementation, delete all progress records for device
    console.log(`🗑️ Clearing all progress for device: ${deviceId}`);

    res.json({
      success: true,
      message: 'All progress cleared successfully',
      clearedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('Progress clear error:', error);
    res.status(500).json({ 
      error: 'Failed to clear progress',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;