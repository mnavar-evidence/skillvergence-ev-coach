const express = require('express');
const router = express.Router();
const database = require('../database/db');

// School activation and setup endpoints

// SCHOOL ACTIVATION DATA STRUCTURE
// This defines what data is needed to activate a new school

const schoolActivationTemplate = {
  // 1. BASIC SCHOOL INFORMATION
  schoolInfo: {
    id: "unique_school_identifier",          // e.g., "fallbrook_high", "mission_bay_high"
    name: "School Name",                     // e.g., "Fallbrook High School"
    district: "District Name",               // e.g., "Fallbrook Union High School District"
    address: {
      street: "123 School St",
      city: "City Name",
      state: "CA",
      zipCode: "92028"
    },
    phone: "(760) 555-0123",
    website: "https://school.edu",
    type: "public",                          // "public", "private", "charter"
    enrollment: 1200                         // Total school enrollment
  },

  // 2. PROGRAM CONFIGURATION
  program: {
    name: "CTE Pathway: Transportation Technology",  // Program name
    department: "Career Technical Education",        // Department
    pathwayCode: "TRANSPORT_TECH",                  // Internal pathway identifier
    industryArea: "Transportation, Distribution & Logistics",
    certificationPartner: "NATEF",                  // Certification body
    programLength: "3_years",                       // "1_year", "2_years", "3_years"
    creditsOffered: 15                              // Total CTE credits
  },

  // 3. INSTRUCTOR/TEACHER INFORMATION
  instructor: {
    id: "teacher_unique_id",
    name: "Teacher Full Name",
    email: "teacher@school.edu",
    phone: "(760) 555-0124",
    department: "Career Technical Education",
    yearsExperience: 15,
    certifications: [
      "ASE Master Technician",
      "NATEF Instructor Certification",
      "CTE Teaching Credential"
    ],
    teacherCode: "T12345"                    // UNIQUE teacher access code
  },

  // 4. LICENSING & ACCESS CONFIGURATION
  licensing: {
    bulkLicenses: 250,                       // Number of student licenses purchased
    districtLicenses: 2500,                  // Total district-wide licenses
    licenseType: "school_bulk",              // "individual", "school_bulk", "district_wide"
    purchaseDate: "2024-09-01",
    expirationDate: "2025-08-31",
    renewalDate: "2025-06-01",               // When renewal process starts
    costPerLicense: 12.50,                   // Annual cost per student
    totalCost: 3125.00                       // 250 × $12.50
  },

  // 5. CURRICULUM SETTINGS
  curriculum: {
    xpThreshold: 50,                         // XP required before paywall
    coursesOffered: [
      "1.0 High Voltage Vehicle Safety",
      "2.0 Electrical Level 1 - Medium Heavy Duty",
      "3.0 Electrical Level 2 - Medium Heavy Duty",
      "4.0 Electric Vehicle Supply Equipment",
      "5.0 Introduction to Electric Vehicles"
    ],
    certificationLevels: [
      { level: "Foundation", coursesRequired: 1 },
      { level: "Associate", coursesRequired: 2 },
      { level: "Professional", coursesRequired: 4 },
      { level: "Certified", coursesRequired: 5 }
    ],
    allowPremiumIndividualPurchase: false,   // Block $49 individual purchase
    friendCodeEnabled: true,                 // Enable viral referral system
    autoApprovalThreshold: 85                // Auto-approve certificates above 85%
  },

  // 6. ADMINISTRATIVE SETTINGS
  adminSettings: {
    schoolYear: "2024-2025",
    semester: "fall",                        // "fall", "spring", "summer", "year_round"
    classSchedule: [
      { period: 1, time: "08:00-09:30", days: ["M", "W", "F"] },
      { period: 2, time: "10:00-11:30", days: ["T", "TH"] }
    ],
    gradingScale: "traditional",             // "traditional", "standards_based"
    reportingPeriods: 4,                     // Number of grading periods
    parentPortalEnabled: true,               // Enable parent progress access
    sisIntegration: "none"                   // "none", "canvas", "google_classroom", "schoology"
  },

  // 7. NOTIFICATION PREFERENCES
  notifications: {
    emailNotifications: true,
    weeklyReports: true,
    lowEngagementAlerts: true,
    certificateApprovalRequired: true,
    parentProgressReports: "weekly",         // "daily", "weekly", "monthly", "quarterly"
    adminEmail: "admin@fuhsd.net",
    techSupportEmail: "tech@fuhsd.net"
  },

  // 8. SECURITY & COMPLIANCE
  security: {
    ferpaCompliant: true,
    dataRetentionPolicy: "7_years",          // How long to keep student data
    exportRestrictions: ["pii_masked"],      // Data export limitations
    auditLogging: true,
    requirePasswordReset: false,
    sessionTimeout: 480,                     // Minutes (8 hours)
    ipWhitelist: []                          // Restrict access to specific IPs
  },

  // 9. INTEGRATION SETTINGS
  integrations: {
    lmsIntegration: "none",                  // "canvas", "blackboard", "moodle", "none"
    sisIntegration: "none",                  // "powerschool", "infinite_campus", "skyward", "none"
    ssoProvider: "none",                     // "google", "microsoft", "okta", "none"
    gradebookSync: false,
    rosterSync: false,
    singleSignOn: false
  },

  // 10. BILLING & SUBSCRIPTION
  billing: {
    subscriptionTier: "school_premium",      // "school_basic", "school_premium", "district_enterprise"
    billingCycle: "annual",                  // "monthly", "annual"
    paymentMethod: "invoice",                // "credit_card", "ach", "invoice", "purchase_order"
    invoiceEmail: "accounting@fuhsd.net",
    purchaseOrderRequired: true,
    autoRenewal: true,
    earlyRenewalDiscount: 10                 // Percentage discount for early renewal
  }
};

// POST: Create/activate a new school
router.post('/activate', async (req, res) => {
  try {
    const schoolData = req.body;

    // Validate required fields
    const requiredFields = [
      'schoolInfo.id',
      'schoolInfo.name',
      'schoolInfo.district',
      'instructor.name',
      'instructor.email',
      'instructor.teacherCode',
      'licensing.bulkLicenses',
      'curriculum.xpThreshold'
    ];

    for (const field of requiredFields) {
      const value = field.split('.').reduce((obj, key) => obj?.[key], schoolData);
      if (!value) {
        return res.status(400).json({
          error: `Missing required field: ${field}`,
          template: schoolActivationTemplate
        });
      }
    }

    // Generate unique access codes for the school
    const generatedCodes = {
      basicCodes: generateCodes('B', schoolData.licensing.bulkLicenses),
      premiumCodes: generateCodes('P', Math.floor(schoolData.licensing.bulkLicenses * 0.1)), // 10% premium codes
      teacherCodes: [schoolData.instructor.teacherCode]
    };

    // Create school activation record
    const activationRecord = {
      ...schoolData,
      generatedCodes,
      activationDate: new Date().toISOString(),
      status: 'active',
      lastUpdated: new Date().toISOString(),
      createdBy: req.body.createdBy || 'system'
    };

    // TODO: Save to database
    // await db.schools.create(activationRecord);

    res.json({
      success: true,
      message: 'School activated successfully',
      schoolId: schoolData.schoolInfo.id,
      teacherCode: schoolData.instructor.teacherCode,
      generatedCodes: {
        basicCodesCount: generatedCodes.basicCodes.length,
        premiumCodesCount: generatedCodes.premiumCodes.length,
        sampleBasicCodes: generatedCodes.basicCodes.slice(0, 5),
        samplePremiumCodes: generatedCodes.premiumCodes.slice(0, 3)
      },
      activationDate: activationRecord.activationDate,
      nextSteps: [
        'Share teacher code with instructor',
        'Distribute basic access codes to students',
        'Configure LMS integration if needed',
        'Schedule teacher training session',
        'Set up progress monitoring'
      ]
    });

  } catch (error) {
    console.error('School activation error:', error);
    res.status(500).json({
      error: 'Failed to activate school',
      details: error.message
    });
  }
});

// GET: School activation template
router.get('/template', (req, res) => {
  res.json({
    message: 'Use this template to activate a new school',
    template: schoolActivationTemplate,
    requiredFields: [
      'schoolInfo.id',
      'schoolInfo.name',
      'schoolInfo.district',
      'instructor.name',
      'instructor.email',
      'instructor.teacherCode',
      'licensing.bulkLicenses',
      'curriculum.xpThreshold'
    ],
    examples: {
      exampleSchool: {
        schoolInfo: {
          id: "example_school",
          name: "Example High School",
          district: "Example School District"
        },
        instructor: {
          name: "Teacher Name",
          email: "teacher@example.edu",
          teacherCode: "T00000"
        },
        licensing: {
          bulkLicenses: 100
        },
        curriculum: {
          xpThreshold: 50
        }
      }
    }
  });
});

// GET: List all activated schools
router.get('/schools', (req, res) => {
  // TODO: Implement proper database query
  const mockSchools = [];

  res.json({
    schools: mockSchools,
    total: mockSchools.length
  });
});

// Helper function to generate access codes
function generateCodes(prefix, count) {
  const codes = [];
  for (let i = 0; i < count; i++) {
    const randomNum = Math.floor(Math.random() * 90000) + 10000;
    codes.push(`${prefix}${randomNum}`);
  }
  return codes;
}

// POST: Onboard new school - Simple 5-field input
router.post('/onboard', async (req, res) => {
  try {
    const { schoolName, programName, teacherName, teacherEmail, classCode } = req.body;

    // Validate required fields
    if (!schoolName || !programName || !teacherName || !teacherEmail || !classCode) {
      return res.status(400).json({
        success: false,
        error: 'All 5 fields required: schoolName, programName, teacherName, teacherEmail, classCode'
      });
    }

    await database.initialize();

    // Generate unique Teacher Access Code
    const teacherAccessCode = await generateUniqueTeacherCode();

    // Generate school ID from school name
    const schoolId = schoolName.toLowerCase()
      .replace(/[^a-z0-9\s]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');

    // Generate teacher ID
    const teacherId = `teacher-${teacherName.toLowerCase().replace(/\s+/g, '-')}`;

    // Insert school record first (teachers reference schools)
    console.log(`Creating school: ${schoolId}`);
    await database.run(`
      INSERT INTO schools (id, name, district, program, created_at)
      VALUES (?, ?, '', ?, datetime('now'))
    `, [schoolId, schoolName, programName]);

    // Check if teacher already exists (by email)
    const existingTeacher = await database.get(
      'SELECT id, teacher_code FROM teachers WHERE email = ?',
      [teacherEmail]
    );

    let finalTeacherAccessCode;

    if (existingTeacher) {
      // Update existing teacher record
      console.log(`Updating existing teacher: ${existingTeacher.id} for new school: ${schoolId}`);
      finalTeacherAccessCode = existingTeacher.teacher_code; // Keep existing teacher code

      await database.run(`
        UPDATE teachers
        SET school_id = ?, name = ?, class_code = ?, department = 'CTE'
        WHERE email = ?
      `, [schoolId, teacherName, classCode, teacherEmail]);
    } else {
      // Create new teacher record
      console.log(`Creating teacher: ${teacherId} for school: ${schoolId}`);
      finalTeacherAccessCode = teacherAccessCode;

      await database.run(`
        INSERT INTO teachers (id, school_id, name, email, teacher_code, class_code, department, created_at)
        VALUES (?, ?, ?, ?, ?, ?, 'CTE', datetime('now'))
      `, [teacherId, schoolId, teacherName, teacherEmail, teacherAccessCode, classCode]);
    }

    res.json({
      success: true,
      message: 'School onboarded successfully',
      data: {
        schoolId,
        schoolName,
        programName,
        teacherName,
        teacherEmail,
        classCode,
        teacherAccessCode: finalTeacherAccessCode, // This is what the teacher uses to access dashboard
        createdAt: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error('School onboarding error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to onboard school',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Helper function to generate cryptographically secure teacher access codes
async function generateUniqueTeacherCode() {
  const crypto = require('crypto');
  let code;
  let isUnique = false;
  let attempts = 0;

  while (!isUnique && attempts < 50) {
    attempts++;

    // Generate secure random code: T- prefix + 8 random alphanumeric characters
    // Format: T-ABC12XY9 (easy to type, hard to guess)
    const randomBytes = crypto.randomBytes(6);
    const randomString = randomBytes.toString('base64')
      .replace(/[+/=]/g, '') // Remove special chars
      .toUpperCase()
      .substring(0, 8); // Take first 8 chars

    code = `T-${randomString}`;

    // Check if code already exists in database
    const existing = await database.get(
      'SELECT id FROM teachers WHERE teacher_code = ?',
      [code]
    );

    if (!existing) {
      isUnique = true;
    }
  }

  if (!isUnique) {
    throw new Error('Unable to generate unique teacher code after 50 attempts');
  }

  return code;
}

module.exports = router;