# How to Test and Write Prompts in Google AI Studio

## Quick Start: Test Before Code

**Always test your prompts in Google AI Studio BEFORE adding them to your app!**

## Step-by-Step Guide

### Step 1: Open Google AI Studio
1. Go to: https://aistudio.google.com
2. Sign in with your Google account
3. You'll see the main dashboard

### Step 2: Create a New Prompt
1. Click "Create new prompt" button (or "Text prompt")
2. You'll see a text editor

### Step 3: Write Your System Prompt

In the prompt editor, write your system instructions:

```
You are a real estate assistant for Egypt.

When users ask about properties, respond with JSON:
{
  "type": "unit",
  "name": "Luxury Villa",
  "location": "New Cairo, Egypt",
  "propertyType": "Villa",
  "price": "5,000,000",
  "area": "350",
  "bedrooms": "4",
  "bathrooms": "3",
  "features": ["Swimming Pool", "Garden", "Modern Kitchen"],
  "imagePath": ""
}
```

### Step 4: Test Your Prompt

In the "Test your prompt" section, try these queries:
- "Show me a villa in New Cairo"
- "I need a 3-bedroom apartment"
- "Find me a property with a pool"

**Check that AI responds with proper JSON format!**

### Step 5: Adjust Settings

On the right sidebar, adjust:
- **Model**: Select "Gemini 1.5 Flash" (recommended)
- **Temperature**: 0.7 (balanced creativity)
- **Max output tokens**: 1000
- **Safety settings**: As needed

### Step 6: Refine Your Prompt

If the AI doesn't respond correctly:
- Add more specific instructions
- Provide examples in the prompt
- Adjust temperature (lower = more focused)
- Test again

### Step 7: Copy to Your App

Once your prompt works well:
1. Copy the entire system prompt
2. Open `lib/feature/ai_chat/data/chat_remote_data_source.dart`
3. Find line 36: `static const String _realEstateSystemPrompt`
4. Paste your prompt between the triple quotes `'''`
5. Save the file

## Example Prompts You Can Try

### Example 1: Simple Real Estate Assistant
```
You are a helpful real estate assistant.

When users ask about properties in Egypt, respond with JSON:
{
  "type": "unit",
  "name": "Property name here",
  "location": "City, Area",
  "propertyType": "Villa/Apartment/Duplex",
  "price": "Price in EGP",
  "area": "Area in sqm",
  "bedrooms": "Number",
  "bathrooms": "Number",
  "features": ["feature1", "feature2"],
  "imagePath": ""
}
```

### Example 2: Conversational Assistant
```
You are a friendly Egyptian real estate expert named Ahmed.

Greet users warmly and help them find properties.
Ask questions to understand their needs (budget, location, size).

When showing a property, respond with JSON:
{
  "type": "unit",
  "name": "Elegant Villa in Maadi",
  "location": "Maadi, Cairo",
  "propertyType": "Villa",
  "price": "8,500,000",
  "area": "400",
  "bedrooms": "5",
  "bathrooms": "4",
  "features": ["Private Garden", "Parking", "Security"],
  "imagePath": ""
}
```

### Example 3: Detailed Assistant with Validation
```
You are a real estate AI for Egypt. Follow these rules:

1. ONLY answer questions about Egyptian real estate
2. If asked about other topics, politely redirect to properties
3. Always ask for user preferences if not specified
4. Provide property recommendations in JSON format

JSON Response Format:
{
  "type": "unit or compound",
  "name": "Full property name",
  "location": "District, City",
  "propertyType": "Villa/Apartment/Duplex/Penthouse/Townhouse",
  "price": "Price in Egyptian Pounds",
  "area": "Size in square meters",
  "bedrooms": "Number of bedrooms",
  "bathrooms": "Number of bathrooms",
  "features": ["List all features"],
  "imagePath": ""
}

Property Types:
- Villa: Standalone house
- Apartment: Unit in building
- Duplex: Two-level unit
- Penthouse: Top floor luxury
- Townhouse: Row house

Valid Locations:
New Cairo, 6th October, Sheikh Zayed, Maadi, Heliopolis,
New Capital, Zamalek, Nasr City, Rehab, Katameya, etc.
```

## Testing Different Scenarios

### Test Case 1: General Query
**User**: "Show me a property"
**Expected**: AI asks for preferences (budget, location, type)

### Test Case 2: Specific Query
**User**: "3-bedroom villa in New Cairo under 5 million"
**Expected**: JSON with villa matching criteria

### Test Case 3: Off-Topic Query
**User**: "What's the weather today?"
**Expected**: Polite redirect to real estate questions

### Test Case 4: Complex Query
**User**: "I need a modern apartment with gym and pool in a gated compound"
**Expected**: JSON with compound/unit matching features

## Advanced Prompt Techniques

### Technique 1: Few-Shot Learning
Add examples to your prompt:

```
Example 1:
User: "Show me a villa"
Assistant: {
  "type": "unit",
  "name": "Modern Villa",
  ...
}

Example 2:
User: "What about apartments?"
Assistant: {
  "type": "unit",
  "name": "Luxury Apartment",
  ...
}
```

### Technique 2: Structured Instructions
```
ROLE: You are a real estate expert

TASK: Help users find properties in Egypt

OUTPUT FORMAT: JSON only

CONSTRAINTS:
- Only Egyptian properties
- Prices in EGP
- Areas in square meters
- Valid property types only

TONE: Professional and helpful
```

### Technique 3: Chain of Thought
```
Before responding:
1. Understand user's requirements
2. Check if all details are provided
3. If missing details, ask clarifying questions
4. Generate property recommendation
5. Format as JSON
6. Verify JSON is valid
```

## Common Prompt Issues and Fixes

### Issue 1: AI Doesn't Return JSON
**Problem**: Response is text, not JSON
**Fix**: Add to prompt:
```
IMPORTANT: You MUST respond ONLY with valid JSON.
Do NOT add any text before or after the JSON.
```

### Issue 2: Invalid JSON Format
**Problem**: Missing quotes, commas, or brackets
**Fix**: Add to prompt:
```
JSON must be valid and follow this EXACT format:
{
  "type": "value",
  "name": "value"
}
Use double quotes for all strings.
```

### Issue 3: AI Talks Too Much
**Problem**: Long explanations instead of concise answers
**Fix**: Add to prompt:
```
Be concise. Respond with JSON only.
No additional explanations.
```

### Issue 4: Inconsistent Property Data
**Problem**: Some fields empty or random
**Fix**: Add to prompt:
```
All fields are required. If you don't know a value:
- For numbers: Use "0"
- For strings: Use "Contact for details"
- For arrays: Use empty array []
```

## Settings Explained

### Model Selection
- **Gemini 1.5 Flash**: Fast, good for chat (Recommended)
- **Gemini 1.5 Pro**: More capable, slower
- **Gemini 1.0 Pro**: Legacy model

### Temperature (0.0 - 2.0)
- **0.0 - 0.3**: Focused, predictable, factual
- **0.4 - 0.7**: Balanced (Recommended)
- **0.8 - 1.0**: Creative, varied
- **1.1 - 2.0**: Very creative, unpredictable

### Max Output Tokens
- **100-500**: Short responses
- **500-1000**: Medium (Recommended)
- **1000+**: Long, detailed responses

### Top P (0.0 - 1.0)
- Controls diversity
- 0.9 - 0.95 recommended
- Lower = more focused

### Top K
- Number of top tokens to consider
- 40 is default
- Higher = more diverse

## Copying Settings to Your App

After testing in Google AI Studio, update your app config:

**File**: `lib/feature/ai_chat/domain/config.dart`

```dart
class AppConfig {
  static const String geminiApiKey = 'YOUR_API_KEY';

  // Model from Google AI Studio
  static const String geminiModel = 'gemini-1.5-flash';

  // Temperature from Google AI Studio
  static const double temperature = 0.7;

  // Max tokens from Google AI Studio
  static const int maxOutputTokens = 1000;
}
```

## Best Practices

### ✅ DO:
- Test prompts thoroughly before deploying
- Start simple, add complexity gradually
- Use specific, clear instructions
- Provide examples in prompt
- Validate JSON responses
- Test edge cases

### ❌ DON'T:
- Deploy untested prompts
- Make prompts too complex
- Use vague instructions
- Forget to handle errors
- Assume AI knows your data
- Skip testing edge cases

## Iterative Improvement Process

1. **Write initial prompt** → Test in Google AI Studio
2. **Find issues** → Note what doesn't work
3. **Refine prompt** → Add instructions to fix issues
4. **Test again** → Verify improvements
5. **Repeat** → Until satisfied
6. **Deploy** → Copy to your app
7. **Monitor** → Check real user interactions
8. **Update** → Refine based on usage

## Quick Reference

| Action | Location |
|--------|----------|
| Test prompts | https://aistudio.google.com |
| Get API key | https://aistudio.google.com/app/apikey |
| Edit prompt in app | `lib/feature/ai_chat/data/chat_remote_data_source.dart` line 36 |
| Edit settings in app | `lib/feature/ai_chat/domain/config.dart` |
| View API usage | https://aistudio.google.com/app/apikeys |

---

**Pro Tip**: Save your working prompts as different versions in Google AI Studio so you can compare and revert if needed!
