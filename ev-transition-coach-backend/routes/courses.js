const express = require('express');
const router = express.Router();

// Comprehensive course data with real YouTube video links
const sampleCourses = [
  {
    id: "1",
    title: "High Voltage Safety Foundation",
    description: "Essential safety training for working with high voltage EV systems",
    level: "Level 1",
    estimatedHours: 4.5,
    thumbnailUrl: null,
    sequenceOrder: 1,
    videos: [
      {
        id: "1-1",
        title: "1.1 EV Safety Pyramid - Who's Allowed to Touch",
        description: "Understanding personnel qualifications for HV work",
        duration: 370, // 6:10 in seconds
        videoUrl: "https://youtu.be/4KiaE9KPu1g",
        sequenceOrder: 1,
        courseId: "1"
      },
      {
        id: "1-2", 
        title: "1.2 High Voltage Hazards Overview",
        description: "Understanding electrical dangers in EVs",
        duration: 417, // 6:57 in seconds
        videoUrl: "https://youtu.be/YL8zgLZ096U",
        sequenceOrder: 2,
        courseId: "1"
      },
      {
        id: "1-3",
        title: "1.3 Navigating Electrical Shock Protection Boundaries",
        description: "Required PPE for EV high voltage work",
        duration: 406, // 6:46 in seconds
        videoUrl: "https://youtu.be/N1dLWS57e2s",
        sequenceOrder: 3,
        courseId: "1"
      },
      {
        id: "1-4",
        title: "1.4 High Voltage PPE  Your First Line of Defense",
        description: "LOTO procedures for EV systems",
        duration: 413, // 6:53 in seconds
        videoUrl: "https://youtu.be/kVrO3nvOZXk",
        sequenceOrder: 4,
        courseId: "1"
      },
      {
        id: "1-5",
        title: "1.5 Inside an Electric Car - The Journey of Energy",
        description: "What to do in emergency situations",
        duration: 406, // 6:46 in seconds
        videoUrl: "https://youtu.be/b8W0H5-qRLM",
        sequenceOrder: 5,
        courseId: "1"
      },
      {
        id: "1-6",
        title: "1.6 Taming the Current - EV High Voltage Safety",
        description: "Verifying safe conditions before work",
        duration: 462, // 7:42 in seconds
        videoUrl: "https://youtu.be/LlmbSDnSDoA",
        sequenceOrder: 6,
        courseId: "1"
      },
      {
        id: "1-7",
        title: "1.7 How to Spot High Voltage Danger on an Electric Bus",
        description: "Review of safety protocols and best practices",
        duration: 307, // 5:07 in seconds
        videoUrl: "https://youtu.be/CbVm-Ey91p4",
        sequenceOrder: 7,
        courseId: "1"
      }
    ]
  },
  {
    id: "2",
    title: "Electrical Fundamentals",
    description: "Core electrical concepts for EV technicians",
    level: "Level 1", 
    estimatedHours: 2.5,
    thumbnailUrl: null,
    sequenceOrder: 2,
    videos: [
      {
        id: "2-1",
        title: "Basic Circuit Components & Configuration",
        description: "Understanding electrical components and circuits",
        duration: 900, // 15 minutes
        videoUrl: "https://youtu.be/lM8BX4JMAgo?si=Umxcgqa1KNZuoBxN",
        sequenceOrder: 1,
        courseId: "2"
      },
      {
        id: "2-2",
        title: "Voltage, Current, and Resistance",
        description: "Fundamental electrical principles",
        duration: 720, // 12 minutes
        videoUrl: "https://youtu.be/w8jPxtj16xc?si=lpyXJQuqIZxIimdk",
        sequenceOrder: 2,
        courseId: "2"
      },
      {
        id: "2-3",
        title: "AC vs DC Power Systems",
        description: "Understanding alternating and direct current",
        duration: 840, // 14 minutes
        videoUrl: "https://youtu.be/GM5LmaEVwm0?si=LFUfHB_MaBWtU8JQ",
        sequenceOrder: 3,
        courseId: "2"
      },
      {
        id: "2-4",
        title: "Electrical Testing and Measurement",
        description: "Using multimeters and testing equipment",
        duration: 1020, // 17 minutes
        videoUrl: "https://youtu.be/jSx5H47YCWk?si=ruyCTNFVPktzla-u",
        sequenceOrder: 4,
        courseId: "2"
      }
    ]
  },
  {
    id: "3",
    title: "EV System Components",
    description: "Understanding electric vehicle system architecture",
    level: "Level 2",
    estimatedHours: 1.2,
    thumbnailUrl: null,
    sequenceOrder: 3,
    videos: [
      {
        id: "3-1",
        title: "EV Architecture Overview",
        description: "Complete overview of electric vehicle systems",
        duration: 1200, // 20 minutes
        videoUrl: "https://youtu.be/Wbwm7dOQfLY?si=51XKND1jEgkoPZxW",
        sequenceOrder: 1,
        courseId: "3"
      }
    ]
  },
  {
    id: "4",
    title: "Battery Technology",
    description: "EV battery systems and management",
    level: "Level 2",
    estimatedHours: 1.8,
    thumbnailUrl: null,
    sequenceOrder: 4,
    videos: [
      {
        id: "4-1",
        title: "Battery Types and Chemistry",
        description: "Understanding different EV battery technologies",
        duration: 960, // 16 minutes
        videoUrl: "https://youtu.be/Xl4-BlPQuGE?si=H851Kr8lxMUe-AYv",
        sequenceOrder: 1,
        courseId: "4"
      },
      {
        id: "4-2",
        title: "Battery Management Systems",
        description: "BMS operation and diagnostics",
        duration: 900, // 15 minutes
        videoUrl: "https://youtu.be/ARAfACV7-3E?si=Yj8oKfqzqDkWPfl4",
        sequenceOrder: 2,
        courseId: "4"
      }
    ]
  },
  {
    id: "5",
    title: "Advanced EV Systems",
    description: "Advanced diagnostics and system integration",
    level: "Level 3",
    estimatedHours: 2.0,
    thumbnailUrl: null,
    sequenceOrder: 5,
    videos: [
      {
        id: "5-2",
        title: "Motor Control Systems",
        description: "Electric motor control and inverter systems",
        duration: 1080, // 18 minutes
        videoUrl: "https://youtu.be/CPIsnjd3SBU?si=xMJ4WDfb_NglCr20",
        sequenceOrder: 2,
        courseId: "5"
      },
      {
        id: "5-3",
        title: "Charging Systems and Infrastructure",
        description: "EV charging technology and installation",
        duration: 1020, // 17 minutes
        videoUrl: "https://youtu.be/hABCuNpftUk?si=L8DZa25Q3SLUoo_G",
        sequenceOrder: 3,
        courseId: "5"
      }
    ]
  }
];

// GET /api/courses - Get all courses
router.get('/', async (req, res) => {
  try {
    res.json({ courses: sampleCourses });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch courses' });
  }
});

// GET /api/courses/:id - Get specific course with videos
router.get('/:id', async (req, res) => {
  try {
    const courseId = req.params.id;
    const course = sampleCourses.find(c => c.id === courseId);
    
    if (!course) {
      return res.status(404).json({ error: 'Course not found' });
    }
    
    res.json(course);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch course' });
  }
});

module.exports = router;
