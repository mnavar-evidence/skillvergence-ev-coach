#!/usr/bin/env node

/**
 * Setup script to activate Fallbrook High School
 * Usage: node scripts/setup-fallbrook.js
 */

const fs = require('fs');
const path = require('path');

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3000';

async function setupFallbrookHigh() {
  try {
    console.log('🏫 Setting up Fallbrook High School...');

    // Load the activation data
    const activationDataPath = path.join(__dirname, '../examples/fallbrook-activation.json');
    const activationData = JSON.parse(fs.readFileSync(activationDataPath, 'utf8'));

    console.log('📋 Activation data loaded');
    console.log(`   School: ${activationData.schoolInfo.name}`);
    console.log(`   Instructor: ${activationData.instructor.name}`);
    console.log(`   Teacher Code: ${activationData.instructor.teacherCode}`);
    console.log(`   Bulk Licenses: ${activationData.licensing.bulkLicenses}`);

    // Make API call to activate school
    const response = await fetch(`${BACKEND_URL}/api/school/activate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(activationData)
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`Activation failed: ${error.error}`);
    }

    const result = await response.json();

    console.log('✅ School activated successfully!');
    console.log(`   School ID: ${result.schoolId}`);
    console.log(`   Teacher Code: ${result.teacherCode}`);
    console.log(`   Basic Codes Generated: ${result.generatedCodes.basicCodesCount}`);
    console.log(`   Premium Codes Generated: ${result.generatedCodes.premiumCodesCount}`);
    console.log(`   Activation Date: ${result.activationDate}`);

    console.log('\n📝 Next Steps:');
    result.nextSteps.forEach((step, index) => {
      console.log(`   ${index + 1}. ${step}`);
    });

    console.log('\n🔑 Sample Access Codes:');
    console.log('   Basic Codes (share with students):');
    result.generatedCodes.sampleBasicCodes.forEach(code => {
      console.log(`     ${code}`);
    });

    console.log('   Premium Codes (for advanced students):');
    result.generatedCodes.samplePremiumCodes.forEach(code => {
      console.log(`     ${code}`);
    });

    console.log('\n🎯 Ready to use!');
    console.log(`   Teacher can access dashboard with code: ${result.teacherCode}`);
    console.log(`   Students will hit paywall at: ${activationData.curriculum.xpThreshold} XP`);

  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    process.exit(1);
  }
}

// Check if we have fetch available (Node.js 18+)
if (typeof fetch === 'undefined') {
  console.log('⚠️  This script requires Node.js 18+ or install node-fetch');
  console.log('   Alternative: Use curl or Postman to POST the JSON data to /api/school/activate');

  const activationDataPath = path.join(__dirname, '../examples/fallbrook-activation.json');
  console.log(`\n📋 Activation data file: ${activationDataPath}`);
  console.log(`\n🌐 POST to: ${BACKEND_URL}/api/school/activate`);
  process.exit(1);
}

setupFallbrookHigh();