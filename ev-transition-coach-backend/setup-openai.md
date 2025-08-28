# OpenAI Integration Setup

## Quick Setup

To enable real OpenAI responses instead of fallback mode:

1. Get your OpenAI API key from https://platform.openai.com/account/api-keys

2. Update your `.env.local` file:
   ```bash
   # Replace the placeholder with your actual API key
   OPENAI_API_KEY=sk-your-actual-openai-api-key-here
   ```

3. Restart the development server:
   ```bash
   npm run dev
   ```

## Testing

Test the AI integration:
```bash
curl -X POST http://localhost:3000/api/ai/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What is the difference between AC and DC charging?",
    "context": "EV Charging Systems",
    "deviceId": "test-device-123"
  }'
```

## Model & Pricing

Using **GPT-4o-mini** - OpenAI's fastest and cheapest model:
- **Input**: $0.150 / 1M tokens 
- **Output**: $0.600 / 1M tokens
- **Typical cost per Q&A**: ~$0.001-0.005 (much cheaper than GPT-4)
- **Performance**: Excellent for training/educational content

## Coach Nova Features

The AI is configured as "Coach Nova" with expertise in:
- High voltage safety procedures
- Battery systems and thermal management
- Electric motors and power electronics
- Charging systems (AC/DC, infrastructure)
- EV diagnostics and troubleshooting
- Electrical theory applied to EVs
- Hybrid systems and regenerative braking

Coach Nova uses familiar automotive analogies and shop-friendly language to help technicians transition from ICE to EV systems.

## Fallback Mode

If the OpenAI API key is not configured or fails, the system automatically falls back to predefined responses for common questions while clearly indicating the fallback status.