const express = require('express');
const router = express.Router();

// Function to extract YouTube video ID from URL
function extractYouTubeVideoId(url) {
  if (!url) return null;
  
  const patterns = [
    /(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/,
    /^([a-zA-Z0-9_-]{11})$/ // Direct video ID
  ];
  
  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) return match[1];
  }
  
  return null;
}

// Comprehensive course data with real YouTube video links
const sampleCourses = [
  {
    id: "course-1",
    title: "High Voltage Safety Foundation",
    description: "Overview of high voltage safety roles, training, and authorization in EV systems",
    level: "Level 1",
    estimatedHours: 0.773,
    thumbnailUrl: null,
    sequenceOrder: 1,
    videos: [
      {
        id: "1-1",
        title: "1.1 EV Safety Pyramid - Who's Allowed to Touch",
        description: "Roles, responsibilities, and protocols for electrically aware, qualified, and authorized workers",
        duration: 370, // 6:10 in seconds
        videoUrl: "https://youtu.be/4KiaE9KPu1g",
        muxPlaybackId: "Tkk1BFdFi1hlKZSMqosuhoNExgghDyqv5rBMup02bSes",
        sequenceOrder: 1,
        courseId: "course-1"
      },
      {
        id: "1-2",
        title: "1.2 High Voltage Hazards Overview",
        description: "Understanding risks like electric shock, arc flash, and arc blast, and their effects on the body",
        duration: 417, // 6:57 in seconds
        videoUrl: "https://youtu.be/YL8zgLZ096U",
        muxPlaybackId: "zTOywHrdACjLFt35Qv802wk8BN8m8gV7C01flvbPQrOCw",
        sequenceOrder: 2,
        courseId: "course-1"
      },
      {
        id: "1-3",
        title: "1.3 Navigating Electrical Shock Protection Boundaries",
        description: "Identifying and applying limited, restricted, and arc flash boundaries to prevent accidents",
        duration: 406, // 6:46 in seconds
        videoUrl: "https://youtu.be/N1dLWS57e2s",
        muxPlaybackId: "ng2Lphh1xBIphzI2CQ5M7g1Qbg34ZhbP3Cqqn49srug",
        sequenceOrder: 3,
        courseId: "course-1"
      },
      {
        id: "1-4",
        title: "1.4 High Voltage PPE  Your First Line of Defense",
        description: "Selecting and using proper PPE with arc ratings and hazard risk categories",
        duration: 415, // 6:55 in seconds
        videoUrl: "https://youtu.be/kVrO3nvOZXk",
        muxPlaybackId: "hTtD008sNmMbyP00QYvJFEuAXCHZK8yZKru01o02UNQSSSg",
        sequenceOrder: 4,
        courseId: "course-1"
      },
      {
        id: "1-5",
        title: "1.5 Inside an Electric Car - The Journey of Energy",
        description: "Functions of batteries, traction motors, inverters, converters, and other HV parts",
        duration: 406, // 6:46 in seconds
        videoUrl: "https://youtu.be/b8W0H5-qRLM",
        muxPlaybackId: "JXcV75OWRVKHtfj021f023vzwQfzlap72PiBBlR3uXj3c",
        sequenceOrder: 5,
        courseId: "course-1"
      },
      {
        id: "1-6",
        title: "1.6 Taming the Current - EV High Voltage Safety",
        description: "Techniques for disabling batteries, using service disconnects, and handling HV components safely",
        duration: 462, // 7:42 in seconds
        videoUrl: "https://youtu.be/LlmbSDnSDoA",
        muxPlaybackId: "vF4SD1tvGyldj2OegjU02uUJQrJN61Xom9q5hPdyATtA",
        sequenceOrder: 6,
        courseId: "course-1"
      },
      {
        id: "1-7",
        title: "1.7 How to Spot High Voltage Danger on an Electric Bus",
        description: "Identifying high voltage components in electric vehicles through various visual cues",
        duration: 307, // 5:07 in seconds
        videoUrl: "https://youtu.be/CbVm-Ey91p4",
        muxPlaybackId: "nGTcPZf7kKNws7E5ScALwqsZGeasrtv6mG5rWVmWFFg",
        sequenceOrder: 7,
        courseId: "course-1"
      }
    ]
  },
  {
    id: "course-2",
    title: "Electrical Fundamentals",
    description: "Core electrical concepts for EV technicians",
    level: "Level 1", 
    estimatedHours: 0.517,
    thumbnailUrl: null,
    sequenceOrder: 2,
    videos: [
      {
        id: "2-1",
        title: "2.1 Automotive Electrical Circuits 101",
        description: "Fundamentals of voltage, current, resistance, and power with practical circuit labs",
        duration: 433, // 7:13 in seconds
        videoUrl: "https://youtu.be/nOIeEFK29Dk",
        muxPlaybackId: "QusmX4rnjbcR7VeSS2ayv68HfKWWRr4pfhPnDZtuFRk",
        sequenceOrder: 1,
        courseId: "course-2"
      },
      {
        id: "2-2",
        title: "2.2 Electrical Measurement and Digital Multimeter",
        description: "Safe and accurate use of digital multimeters for voltage, current, resistance, and more",
        duration: 461, // 7:41 in seconds
        videoUrl: "https://youtu.be/AsAm7REAfpE",
        muxPlaybackId: "1dFD00lw01Gq3PRPqwtHSCA01goWEwPQEVDpzFSHbOFGFE",
        sequenceOrder: 2,
        courseId: "course-2"
      },
      {
        id: "2-3",
        title: "2.3 Electrical Fault Analysis: Measurement and Diagnosis",
        description: "Diagnosing opens, shorts, high resistance, and component failures using diagrams and meters",
        duration: 409, // 6:49 in seconds
        videoUrl: "https://youtu.be/a4VWxBun4KQ",
        muxPlaybackId: "LS8wrghx0067Y3iq5eEGIQby6F6eAK00sDIaKc01G8y01rU",
        sequenceOrder: 3,
        courseId: "course-2"
      },
      {
        id: "2-4",
        title: "2.4 Automotive Circuit Diagnosis and Troubleshooting",
        description: "Systematic troubleshooting of circuits, relays, switches, and motors using diagnostic tools",
        duration: 551, // 9:11 in seconds
        videoUrl: "https://youtu.be/R0IRO66lsjo",
        muxPlaybackId: "h4gzIGHOnWcgYbxds9NWp1i2mO4vF868zEbaOiWNvqY",
        sequenceOrder: 4,
        courseId: "course-2"
      }
    ]
  },
  {
    id: "course-3",
    title: "EV System Components",
    description: "Understanding electric vehicle system architecture",
    level: "Level 2",
    estimatedHours: 0.215,
    thumbnailUrl: null,
    sequenceOrder: 3,
    videos: [
      {
        id: "3-1",
        title: "3.1 Advanced Electrical Diagnostics",
        description: "Oscilloscope and advanced multimeter use, sensors, actuators, and circuit analysis",
        duration: 391, // 6:31 in seconds
        videoUrl: "https://youtu.be/Z46KIZb1HHI",
        muxPlaybackId: "gaTm8cYuz022rhJIcA7Yslt702ymomEMGI1lbtgqFdE7M",
        sequenceOrder: 1,
        courseId: "course-3"
      },
      {
        id: "3-2",
        title: "3.2 Vehicle Communication Networks",
        description: "Diagnosis of CAN, LIN, FlexRay, MOST, and Ethernet bus systems with gateways and fiber optics",
        duration: 384, // 6:24 in seconds
        videoUrl: "https://youtu.be/gPw-OlOD4wI",
        muxPlaybackId: "82yTeh3aNElJUpkUx02qkrofHkca2jDTFNiubKwsxSdQ",
        sequenceOrder: 2,
        courseId: "course-3"
      }
    ]
  },
  {
    id: "course-4",
    title: "EV Charging Systems",
    description: "EV battery systems and management",
    level: "Level 2",
    estimatedHours: 0.255,
    thumbnailUrl: null,
    sequenceOrder: 4,
    videos: [
      {
        id: "4-1",
        title: "4.1 Electric Vehicle Supply Equipment & Electric Vehicle Charging Systems",
        description: "Types, levels, connectors, standards, and safety features of EV charging equipments",
        duration: 502, // 8:22 in seconds
        videoUrl: "https://youtu.be/6Jqi2FKVVf4",
        muxPlaybackId: "eyxc02bMePOacn01xCfvITF700nhQnryDFPwcOKP9v8dTo",
        sequenceOrder: 1,
        courseId: "course-4"
      },
      {
        id: "4-2",
        title: "4.2 Charging Diagnostics & Battery Management",
        description: "Testing, troubleshooting charging systems, and managing battery performance and safety",
        duration: 414, // 6:54 in seconds
        videoUrl: "https://youtu.be/rm6aSXFCQNg",
        muxPlaybackId: "14xiAykKQqGSiLOsjrFotxVe3miIbLk8sAOb02fcbjlo",
        sequenceOrder: 2,
        courseId: "course-4"
      }
    ]
  },
  {
    id: "course-5",
    title: "Advanced EV Systems",
    description: "Advanced diagnostics and system integration",
    level: "Level 3",
    estimatedHours: 0.410,
    thumbnailUrl: null,
    sequenceOrder: 5,
    videos: [
      {
        id: "5-1",
        title: "5.1 Introduction to Electric Vehicles",
        description: "History, evolution, key powertrain components, charging, and environmental benefits",
        duration: 459, // 7:39 in seconds
        videoUrl: "https://youtu.be/R0lxSpGDrRU",
        muxPlaybackId: "kM1To00cnB8up4CYm01IxH02m93Rg6mm5gNJiKqGy5s1a8",
        sequenceOrder: 1,
        courseId: "course-5"
      },
      {
        id: "5-2",
        title: "5.2 EV Energy Storage Systems",
        description: "Battery types, chemistry, management, capacity, and thermal considerations",
        duration: 483, // 8:03 in seconds
        videoUrl: "https://youtu.be/pFRJioF3lkk",
        muxPlaybackId: "h2doMoMMh5YcMJj79QX1LTzoxxcSEnvBWD7xH00f5JJA",
        sequenceOrder: 2,
        courseId: "course-5"
      },
      {
        id: "5-3",
        title: "5.3 EV Architecture, Motors & Controllers",
        description: "Powertrain layouts, motor types, controllers, and regenerative braking systems",
        duration: 532, // 8:52 in seconds
        videoUrl: "https://youtu.be/ZI0fzy8tUH8",
        muxPlaybackId: "fjsvFA01kKjP9100EKhNFfMllpQsaPilkUiopwbSe5QrM",
        sequenceOrder: 3,
        courseId: "course-5"
      }
    ]
  }
];

// GET /api/courses - Get all courses (with mux support v1.0.1)
router.get('/', async (req, res) => {
  try {
    // Process courses to add YouTube video IDs and preserve muxPlaybackId
    const processedCourses = sampleCourses.map(course => ({
      ...course,
      videos: course.videos.map(video => ({
        ...video,
        youtubeVideoId: extractYouTubeVideoId(video.videoUrl),
        muxPlaybackId: video.muxPlaybackId // Explicitly preserve muxPlaybackId
      }))
    }));
    
    res.json({ courses: processedCourses });
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
    
    // Process course to add YouTube video IDs and preserve muxPlaybackId
    const processedCourse = {
      ...course,
      videos: course.videos.map(video => ({
        ...video,
        youtubeVideoId: extractYouTubeVideoId(video.videoUrl),
        muxPlaybackId: video.muxPlaybackId // Explicitly preserve muxPlaybackId
      }))
    };
    
    res.json(processedCourse);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch course' });
  }
});

module.exports = router;
