# 🧪 AI Comparison Feature - Quick Test Checklist

## ⚡ 5-Minute Test

### 1. Basic Comparison Test (2 minutes)
```
□ Open app
□ Find any unit card
□ Tap Compare button (🔄 icon)
□ Sheet opens with unit selected ✓
□ Tap Compare on another unit
□ Counter shows "2/4" ✓
□ Tap "Start AI Comparison Chat"
□ AI Chat opens ✓
□ User message appears ✓
□ AI responds with comparison ✓
```

### 2. UI Validation (1 minute)
```
□ Selected items show as chips
□ Can remove items with X button
□ Button disabled with < 2 items
□ Button enabled with 2+ items
□ Instructions visible
```

### 3. Language Test (1 minute)
```
English:
□ Change to English
□ Open comparison sheet
□ All text in English ✓

Arabic:
□ Change to Arabic
□ Open comparison sheet
□ All text in Arabic ✓
□ RTL layout correct ✓
```

### 4. Error Test (1 minute)
```
□ Turn off WiFi
□ Start comparison
□ Error message shows ✓
□ Turn on WiFi
□ Can retry successfully ✓
```

---

## 🎯 Where to Find Compare Buttons

### Mobile:
- **Unit Cards:** Top-left corner, circular button after share
- **Company Cards:** Top-right corner over logo

### Web:
- **Unit Cards:** Top-left action row, after note button
- **Compound Cards:** Top-left action row, after note button
- **Company Cards:** Top-right next to company name

---

## 📋 Expected AI Response Format

Your AI should respond with:

1. **Price Comparison**
   - Actual prices
   - Price per m² (for units)
   - Value analysis

2. **Features Comparison**
   - Key specs side-by-side
   - Unique features highlighted

3. **Location Analysis**
   - Accessibility
   - Nearby amenities
   - Commute times

4. **Pros & Cons**
   - Clear bullet points
   - Balanced view

5. **Recommendation**
   - Clear suggestion
   - Reasoning provided
   - Context-aware (family size, budget, etc.)

6. **Bilingual**
   - English section
   - Arabic section (complete translation)

---

## 🐛 Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|----------|
| Button not visible | Rebuild app: `flutter clean && flutter run` |
| Sheet not opening | Check imports in card widgets |
| No AI response | Check API key in `config.dart` |
| Localization missing | Run `flutter gen-l10n` |
| Navigation fails | Verify `/ai-chat` route in `app_router.dart` |

---

## 📊 Test Data Suggestions

### Good Test Cases:
1. **Budget Comparison:** Cheap unit vs expensive unit
2. **Size Comparison:** Studio vs 3BR apartment
3. **Location Comparison:** Downtown vs suburb
4. **Status Comparison:** Ready vs under construction
5. **Company Comparison:** Established vs new developer

### Edge Cases:
1. **Missing Data:** Units with incomplete information
2. **Identical Units:** Same specs, different location
3. **Mixed Types:** Unit + Compound (should still work)
4. **Max Selection:** Try adding 5th item (should prevent)

---

## ✅ Success Criteria

Feature is working correctly if:

- ✅ Compare button visible on all cards (mobile & web)
- ✅ Selection sheet opens smoothly
- ✅ Items display correctly with proper names
- ✅ Min 2, max 4 items enforced
- ✅ Navigation to AI chat works
- ✅ AI receives structured prompt
- ✅ AI responds with detailed comparison
- ✅ Works in both English and Arabic
- ✅ Error handling graceful
- ✅ No crashes or freezes

---

## 📸 Screenshot Checklist

Capture for documentation:

1. [ ] Compare button on unit card
2. [ ] Comparison selection sheet (empty)
3. [ ] Selection sheet with 2 items
4. [ ] Selection sheet with 4 items (max)
5. [ ] AI chat with comparison request
6. [ ] AI response showing comparison
7. [ ] Arabic version of selection sheet
8. [ ] Error state

---

## 🎬 Demo Script

For presenting to stakeholders:

```
"I'll demonstrate our new AI Comparison feature."

1. "First, I browse available properties..."
   [Show unit cards]

2. "I find an interesting unit and tap Compare."
   [Tap compare button]

3. "The comparison sheet opens. I can see my selection."
   [Show selected item chip]

4. "Let me add another property to compare."
   [Tap compare on another unit]

5. "Now I have 2 items. I can add up to 4 total."
   [Show counter: 2/4]

6. "I'm ready to compare. I tap 'Start AI Comparison Chat'."
   [Tap button]

7. "The AI receives all property details..."
   [Show user message in chat]

8. "And provides a comprehensive comparison..."
   [Show AI response with formatted comparison]

9. "The comparison includes price analysis, features,
    location insights, pros/cons, and a recommendation."
   [Scroll through response]

10. "It works in Arabic too!"
    [Switch language and show Arabic version]

"This helps users make informed decisions quickly!"
```

---

## 💡 Tips for Testing

1. **Test on Real Devices:** Emulators may not show all issues
2. **Test Both Platforms:** Web and mobile behave slightly differently
3. **Test Network Issues:** Users will experience poor connections
4. **Test with Real Data:** Use actual property listings
5. **Test User Scenarios:** Think like a property buyer

---

## 📞 Need Help?

1. Check full guide: `AI_COMPARISON_FEATURE_GUIDE.md`
2. Review logs for error messages
3. Verify `config.dart` has valid API key
4. Ensure latest code: `git pull && flutter pub get`

---

**Happy Testing! 🚀**
