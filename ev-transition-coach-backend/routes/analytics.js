const express = require('express');
const router = express.Router();

// In-memory storage for analytics events (in production, use a database)
let analyticsEvents = [];
const maxStoredEvents = 10000;

// POST /api/analytics/events - Store analytics events
router.post('/events', async (req, res) => {
    try {
        const events = req.body;
        
        if (!Array.isArray(events)) {
            return res.status(400).json({ error: 'Expected an array of events' });
        }
        
        // Add server timestamp
        const enrichedEvents = events.map(event => ({
            ...event,
            serverTimestamp: new Date(),
            userAgent: req.headers['user-agent'] || 'Unknown',
            ipAddress: req.ip || req.connection.remoteAddress || 'Unknown'
        }));
        
        // Store events
        analyticsEvents.push(...enrichedEvents);
        
        // Limit storage size
        if (analyticsEvents.length > maxStoredEvents) {
            analyticsEvents = analyticsEvents.slice(-maxStoredEvents);
        }
        
        console.log(`📊 Analytics: Received ${events.length} events from device ${events[0]?.deviceId || 'unknown'}`);
        
        res.json({ 
            success: true, 
            eventsReceived: events.length,
            totalStoredEvents: analyticsEvents.length
        });
        
    } catch (error) {
        console.error('Analytics error:', error);
        res.status(500).json({ error: 'Failed to store analytics events' });
    }
});

// GET /api/analytics/events - Get analytics events (for development/debugging)
router.get('/events', async (req, res) => {
    try {
        const { deviceId, eventType, limit = 100 } = req.query;
        
        let filteredEvents = analyticsEvents;
        
        if (deviceId) {
            filteredEvents = filteredEvents.filter(event => event.deviceId === deviceId);
        }
        
        if (eventType) {
            filteredEvents = filteredEvents.filter(event => event.eventType === eventType);
        }
        
        // Get most recent events first
        filteredEvents = filteredEvents
            .sort((a, b) => new Date(b.serverTimestamp) - new Date(a.serverTimestamp))
            .slice(0, parseInt(limit));
        
        res.json({
            events: filteredEvents,
            totalEvents: analyticsEvents.length,
            filteredCount: filteredEvents.length
        });
        
    } catch (error) {
        console.error('Analytics retrieval error:', error);
        res.status(500).json({ error: 'Failed to retrieve analytics events' });
    }
});

// GET /api/analytics/summary - Get analytics summary
router.get('/summary', async (req, res) => {
    try {
        const { deviceId } = req.query;
        
        let events = analyticsEvents;
        if (deviceId) {
            events = events.filter(event => event.deviceId === deviceId);
        }
        
        // Calculate summary metrics
        const summary = {
            totalEvents: events.length,
            uniqueDevices: [...new Set(events.map(e => e.deviceId))].length,
            eventTypes: {},
            deviceActivity: {},
            timeRange: {
                earliest: events.length > 0 ? new Date(Math.min(...events.map(e => new Date(e.timestamp)))) : null,
                latest: events.length > 0 ? new Date(Math.max(...events.map(e => new Date(e.timestamp)))) : null
            }
        };
        
        // Count events by type
        events.forEach(event => {
            summary.eventTypes[event.eventType] = (summary.eventTypes[event.eventType] || 0) + 1;
            summary.deviceActivity[event.deviceId] = (summary.deviceActivity[event.deviceId] || 0) + 1;
        });
        
        res.json(summary);
        
    } catch (error) {
        console.error('Analytics summary error:', error);
        res.status(500).json({ error: 'Failed to generate analytics summary' });
    }
});

// GET /api/analytics/learning-patterns - Get learning behavior insights
router.get('/learning-patterns', async (req, res) => {
    try {
        const { deviceId } = req.query;
        
        let events = analyticsEvents;
        if (deviceId) {
            events = events.filter(event => event.deviceId === deviceId);
        }
        
        // Analyze learning patterns
        const videoEvents = events.filter(e => e.eventType.includes('video'));
        const podcastEvents = events.filter(e => e.eventType.includes('podcast'));
        const aiEvents = events.filter(e => e.eventType.includes('ai'));
        
        const patterns = {
            contentPreference: {
                videoEvents: videoEvents.length,
                podcastEvents: podcastEvents.length,
                aiInteractions: aiEvents.length
            },
            completionRates: {
                videosStarted: events.filter(e => e.eventType === 'video_started').length,
                videosCompleted: events.filter(e => e.eventType === 'video_completed').length,
                podcastsStarted: events.filter(e => e.eventType === 'podcast_started').length,
                podcastsCompleted: events.filter(e => e.eventType === 'podcast_completed').length
            },
            engagementMetrics: {
                averageSessionDuration: calculateAverageSessionDuration(events),
                mostActiveHours: getMostActiveHours(events),
                studyStreaks: getStudyStreaks(events)
            }
        };
        
        res.json(patterns);
        
    } catch (error) {
        console.error('Learning patterns error:', error);
        res.status(500).json({ error: 'Failed to analyze learning patterns' });
    }
});

// Helper functions
function calculateAverageSessionDuration(events) {
    const sessionEvents = events.filter(e => e.eventType === 'session_ended');
    if (sessionEvents.length === 0) return 0;
    
    const totalDuration = sessionEvents.reduce((sum, event) => {
        return sum + (event.parameters?.duration || 0);
    }, 0);
    
    return totalDuration / sessionEvents.length;
}

function getMostActiveHours(events) {
    const hourCounts = {};
    
    events.forEach(event => {
        const hour = new Date(event.timestamp).getHours();
        hourCounts[hour] = (hourCounts[hour] || 0) + 1;
    });
    
    return Object.entries(hourCounts)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 3)
        .map(([hour, count]) => ({ hour: parseInt(hour), eventCount: count }));
}

function getStudyStreaks(events) {
    const streakEvents = events.filter(e => e.eventType === 'learning_streak_updated');
    const currentStreak = streakEvents.length > 0 ? 
        Math.max(...streakEvents.map(e => e.parameters?.streak_days || 0)) : 0;
    
    return {
        currentStreak,
        streakUpdates: streakEvents.length
    };
}

module.exports = router;