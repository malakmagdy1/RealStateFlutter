# AI-Powered Weekly Recommendations Implementation

## Overview
The recommended compounds feature has been upgraded from random selection to **AI-powered intelligent selection** using Google's Gemini AI.

## What Changed

### Before (Random Selection)
- Used `dart:math Random()` to randomly shuffle compounds
- No intelligence or criteria for selection
- Simple random.shuffle() approach

### After (AI-Powered Selection)
- Uses **Gemini AI (gemini-2.0-flash)** to intelligently select compounds
- AI analyzes compound data and selects based on multiple criteria
- Falls back to random selection if AI fails

## How It Works

### 1. AI Selection Criteria
The AI is instructed to select 10 compounds based on:
- **Diverse locations** - Provides geographical variety
- **Different companies** - Avoids bias toward one developer
- **Quality indicators** - Prefers compounds with descriptions and multiple images
- **Property variety** - Mix of different types and price ranges
- **Buyer personas** - Appeals to different customer segments

### 2. Weekly Refresh Cycle
- Recommendations refresh **once per week** (every 7 days)
- Same 10 compounds shown for the entire week
- Cached locally for performance
- Automatic refresh when week expires

### 3. Implementation Flow

```
User opens home screen
    ↓
Check if cached recommendations exist & are < 7 days old
    ↓
    Yes → Use cached IDs     No → Generate new recommendations
    ↓                              ↓
Load from DB              Fetch all compounds from DB (limit 100)
    ↓                              ↓
Display to user           Send to Gemini AI for analysis
                                  ↓
                          AI selects 10 best compounds
                                  ↓
                          Save IDs + timestamp to cache
                                  ↓
                          Display to user
```

## Files Modified/Created

### Created:
1. **`lib/feature/compound/data/services/ai_weekly_recommendations_service.dart`**
   - New AI-powered recommendation service
   - Handles Gemini AI integration
   - Manages caching and weekly refresh logic
   - Includes fallback to random selection

### Modified:
2. **`lib/feature/compound/presentation/bloc/compound_bloc.dart`**
   - Updated to use `AIWeeklyRecommendationsService` instead of `WeeklyRecommendationsService`
   - Enhanced logging with AI-specific messages
   - Same API interface for backwards compatibility

## Key Features

### Intelligent Selection
The AI receives compound data including:
- ID
- Project name
- Location
- Company name
- Description
- Image count

And uses this to make informed decisions.

### Error Handling
- If AI fails → Automatic fallback to random selection
- If AI returns invalid IDs → Validates and fills with random
- Network errors → Falls back to random selection
- Ensures recommendations always work

### Performance
- Uses `gemini-2.0-flash` model (fast & free)
- Temperature set to 0.8 for variety
- Results cached for 7 days
- No repeated API calls during cache period

## Configuration

AI settings in `lib/feature/ai_chat/domain/config.dart`:
- Model: `gemini-2.0-flash`
- Temperature: `0.8` (for recommendations)
- Max tokens: `1000`
- API Key: Already configured

## Benefits

### For Users:
✅ More relevant compound recommendations
✅ Better variety in selections
✅ Discover quality properties they might miss
✅ Weekly fresh recommendations

### For Business:
✅ Showcases diverse inventory
✅ Promotes different developers equally
✅ Highlights quality listings
✅ Improved user engagement

## Testing

### To test AI recommendations:
1. Clear cache: Call `AIWeeklyRecommendationsService.clearRecommendations()`
2. Navigate to home screen
3. Check console logs for `[AI WEEKLY RECOMMENDATIONS]`
4. Verify 10 compounds are displayed
5. Check for variety in locations and companies

### To force refresh:
```dart
context.read<CompoundBloc>().add(
  FetchWeeklyRecommendedCompoundsEvent(forceRefresh: true)
);
```

## Technical Details

### Cache Keys:
- Last update: `ai_weekly_recommendations_last_update`
- Recommended IDs: `ai_weekly_recommended_compound_ids`

### Refresh Logic:
```dart
shouldRefresh = (currentDate - lastUpdate) >= 7 days
```

### AI Prompt Strategy:
The AI receives a structured JSON array of compounds and clear selection criteria. It responds with a JSON array of 10 IDs, which are then validated and used to filter the compound list.

## Backwards Compatibility

✅ Same event: `FetchWeeklyRecommendedCompoundsEvent`
✅ Same state: `CompoundSuccess`
✅ No UI changes required
✅ Works on both web and mobile
✅ Falls back gracefully if AI unavailable

## Monitoring

Watch console logs for:
- `[AI WEEKLY RECOMMENDATIONS] Starting fetch...`
- `[AI WEEKLY RECOMMENDATIONS] Using cached recommendations`
- `[AI WEEKLY RECOMMENDATIONS] Generating new AI-powered recommendations`
- `[AI WEEKLY RECOMMENDATIONS] AI selected X compounds`
- `[AI WEEKLY RECOMMENDATIONS] Falling back to random selection` (if AI fails)

## Future Enhancements

Possible improvements:
- User preference-based recommendations
- Learning from user interactions
- A/B testing AI vs random
- Personalized recommendations per user
- Analytics on recommendation performance
