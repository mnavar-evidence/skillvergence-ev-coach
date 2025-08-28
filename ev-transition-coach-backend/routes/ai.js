const express = require('express');
const { OpenAI } = require('openai');
const router = express.Router();


const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// POST /api/ai/ask - Ask Coach Nova a question

router.post('/ask', async (req, res) => {
  try {
    const { question, context, deviceId } = req.body;
    
    console.log('Received AI request:');
    console.log('Question:', question);
    console.log('Context:', context);
    console.log('Device ID:', deviceId);
    
    if (!question) {
      return res.status(400).json({ error: 'Question is required' });
    }

    // System prompt for Coach Nova - EV training specialist
    const systemPrompt = `You are Coach Nova, an expert EV technician trainer helping automotive techs transition to EVs.

Response style:
- CONCISE: 2-3 sentences maximum unless complex topic requires more
- DIRECT: Get straight to the point, no fluff
- PRACTICAL: Focus on what techs need to know to do the job
- ANALOGIES: Use familiar automotive comparisons (alternator = DC-DC converter)
- SHOP TALK: Use mechanic-friendly language, avoid academic terms

Keep it short and actionable. Safety first with high voltage.`;

    // Build the conversation context
    const messages = [
      {
        role: "system",
        content: systemPrompt
      },
      {
        role: "user",
        content: context ? 
          `Question about ${context}: ${question}` : 
          question
      }
    ];

    // Call OpenAI API using GPT-4o-mini (fastest, cheapest model)
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: messages,
      max_tokens: 300, // Reduced for concise responses
      temperature: 0.6, // Slightly lower for more focused responses
      presence_penalty: 0.2, // Higher to avoid repetition
      frequency_penalty: 0.2
    });

    const aiResponse = completion.choices[0].message.content;

    // Log the interaction for analytics (if deviceId provided)
    if (deviceId) {
      console.log(`AI interaction logged for device: ${deviceId}`);
      // TODO: Store in database for analytics
    }

    res.json({ 
      response: aiResponse,
      context,
      timestamp: new Date(),
      model: "gpt-4o-mini"
    });
    
  } catch (error) {
    console.error('OpenAI API Error:', error);
    
    // Fallback to mock responses if OpenAI fails
    const { question, context } = req.body;
    const fallbackResponses = {
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

      "default": (question, context) => `I understand you're asking about "${question}" in the context of "${context}".

As your EV coach, let me break this down using familiar automotive concepts. This relates to systems you already know from ICE vehicles, but with key differences in the EV world.

*Note: This is a fallback response. Please check your OpenAI API configuration.*`
    };
    
    const fallbackResponse = fallbackResponses[question] || fallbackResponses["default"](question, context);
    
    res.json({ 
      response: fallbackResponse,
      context,
      timestamp: new Date(),
      model: "fallback",
      error: process.env.NODE_ENV === 'development' ? error.message : 'AI service temporarily unavailable'
    });
  }
});

module.exports = router;
