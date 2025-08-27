const express = require('express');
const router = express.Router();

// POST /api/ai/ask - Ask Coach Nova a question

router.post('/ask', async (req, res) => {
  try {
    const { question, context } = req.body;
    
    // Add these debug lines
    console.log('Received AI request:');
    console.log('Question:', question);
    console.log('Context:', context);
    
    if (!question) {
      return res.status(400).json({ error: 'Question is required' });
    }
    
    // ... rest of your code


    
    // Mock AI responses for your EV training content
    const mockResponses = {
      "Compare alternator vs DC-DC": `Think of it like this:

**Alternator (ICE vehicles):**
- Like a generator in your shop - converts mechanical energy to electrical
- Produces AC power, then converts to DC for the 12V system
- Belt-driven by the engine

**DC-DC Converter (EVs):**
- Like a voltage transformer in your welding equipment
- Steps down high voltage (400V) to low voltage (12V)
- No moving parts - solid state electronics
- Powers all your familiar 12V accessories (lights, radio, etc.)

Both do the same job - keep the 12V system charged - but the DC-DC converter is way more efficient and reliable since there's no mechanical wear.`,

      "Explain DC fast charging": `Think of DC fast charging like the difference between filling a gas tank with a garden hose vs. a fire hose!

**How it works:**
- Bypasses the car's onboard charger (like going straight to the tank)
- Delivers DC power directly to the battery pack
- Can deliver 50-350 kW vs. 7-11 kW for AC charging

**Shop analogy:** 
It's like having 240V vs 120V in your shop - higher voltage = faster work.`,

      "default": `I understand you're asking about "${question}" in the context of "${context}".

As your EV coach, let me break this down using familiar automotive concepts. This relates to systems you already know from ICE vehicles, but with key differences in the EV world.`
    };
    
    const response = mockResponses[question] || mockResponses["default"];
    
    res.json({ 
      response,
      context,
      timestamp: new Date()
    });
    
  } catch (error) {
    res.status(500).json({ error: 'Failed to process AI request' });
  }
});

module.exports = router;
