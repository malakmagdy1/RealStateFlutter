# AI Chat Feature - Setup Guide

## Overview
This AI Chat feature integrates Google's Gemini AI into your real estate app. Users can ask about properties, and the AI will respond with property recommendations displayed as beautiful cards.

## Features
- 🤖 AI-powered property search and recommendations
- 💬 Natural language conversations
- 🏠 Property cards displayed in chat (Unit/Compound cards)
- 📱 Floating action button on home screen for easy access
- 🎨 Beautiful UI matching your app's design

## Setup Instructions

### 1. Get Your Gemini API Key

1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the API key

### 2. Configure the API Key

Open the file: `lib/feature/ai_chat/domain/config.dart`

Replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key:

```dart
class AppConfig {
  static const String geminiApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
  // ... rest of the file
}
```

### 3. Install Dependencies

Run the following command in your terminal:

```bash
flutter pub get
```

This will install the `google_generative_ai` package.

### 4. Test the Feature

1. Run your app
2. Go to the Home Screen
3. Click the "AI Assistant" floating action button (bottom right)
4. Start chatting!

## Example Queries

Try asking the AI:
- "Show me a 3-bedroom villa in New Cairo"
- "I'm looking for an apartment under 3 million EGP"
- "Find me a compound with swimming pool"
- "What properties do you have in Sheikh Zayed?"
- "I need a duplex with 4 bedrooms"

## How It Works

1. **User Input**: User types a query about properties
2. **AI Processing**: Gemini AI processes the natural language query
3. **JSON Response**: AI returns property data in JSON format
4. **Card Display**: The app displays the property as a beautiful card
5. **Chat History**: All messages are saved in the session

## File Structure

```
lib/feature/ai_chat/
├── data/
│   └── chat_remote_data_source.dart    # Gemini API integration
├── domain/
│   ├── chat_message.dart                # Chat message model
│   ├── config.dart                      # API configuration
│   └── real_estate_product.dart         # Property model
└── presentation/
    ├── bloc/
    │   ├── chat_bloc.dart               # Chat business logic
    │   ├── chat_event.dart              # Chat events
    │   └── chat_state.dart              # Chat states
    ├── screen/
    │   └── ai_chat_screen.dart          # Main chat UI
    └── widget/
        └── property_card_widget.dart    # Property card display
```

## Customization

### Change AI Behavior

Edit the system prompt in `chat_remote_data_source.dart`:

```dart
static const String _realEstateSystemPrompt = '''
You are an AI assistant specialized ONLY in real estate properties.
// Customize this prompt to change AI behavior
''';
```

### Modify Property Card Design

Edit `property_card_widget.dart` to customize how properties are displayed.

### Adjust AI Model Settings

In `config.dart`, you can modify:
- `temperature`: 0.0-1.0 (higher = more creative responses)
- `maxOutputTokens`: Maximum response length
- `geminiModel`: Model version

## Troubleshooting

### "API key not valid"
- Make sure you replaced `YOUR_GEMINI_API_KEY_HERE` with your actual key
- Check that the key is copied correctly (no extra spaces)

### "Package not found"
- Run `flutter clean`
- Run `flutter pub get`
- Restart your IDE

### "Chat not responding"
- Check your internet connection
- Verify your API key is valid
- Check the console for error messages

## API Usage & Limits

- Free tier: 60 requests per minute
- Monitor usage at: https://makersuite.google.com/app/apikeys
- Consider implementing rate limiting for production

## Security Best Practices

⚠️ **Important**: Never commit your API key to Git!

1. Add to `.gitignore`:
```
lib/feature/ai_chat/domain/config.dart
```

2. Use environment variables in production:
```dart
static String get geminiApiKey =>
  const String.fromEnvironment('GEMINI_API_KEY',
    defaultValue: 'fallback_key');
```

## Future Enhancements

Ideas for extending the feature:
- [ ] Save chat history to local storage
- [ ] Add image support for properties
- [ ] Implement voice input
- [ ] Add favorite properties from chat
- [ ] Multi-language support
- [ ] Property comparison feature
- [ ] Price predictions
- [ ] Market insights

## Support

For issues or questions:
1. Check Gemini AI docs: https://ai.google.dev/docs
2. Flutter bloc docs: https://bloclibrary.dev/
3. File an issue in your project repository

---

**Happy Chatting! 🎉**
