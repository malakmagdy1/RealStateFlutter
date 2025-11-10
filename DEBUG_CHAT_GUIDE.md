# How to Debug AI Chat - Console Output Guide

## ✅ Debug Logging Added!

I've added detailed logging to track every step of the chat process. The console will show:

1. **When you send a message** - What you typed
2. **API initialization** - Model setup and API key verification
3. **API call** - Request sent to Gemini
4. **Raw AI response** - Exactly what Gemini returns
5. **JSON parsing** - Whether the response is valid JSON
6. **Property creation** - If property card is created
7. **Errors** - Detailed error messages if something fails

---

## 🚀 How to Run and Capture Logs

### Step 1: Run the App with Console Visible

**Option A: Using Command Line (Recommended)**
```bash
flutter run
```
This will show all console output in the terminal.

**Option B: Using Android Studio/VS Code**
- Run the app normally
- Open the "Debug Console" or "Terminal" panel at the bottom
- All logs will appear there

### Step 2: Open AI Chat
1. App launches to home screen
2. Click the "AI Assistant" floating button (bottom-right)
3. Chat screen opens

### Step 3: Send a Test Message

Try this simple message first:
```
Show me a villa
```

### Step 4: Watch the Console

You should see output like this:

```
════════════════════════════════════════════════════════════════
[CHAT BLOC] User sent message: "Show me a villa"
════════════════════════════════════════════════════════════════
[CHAT BLOC] User message added to list. Total messages: 1
[CHAT BLOC] State changed to ChatLoading
[CHAT BLOC] Calling AI data source...

╔════════════════════════════════════════════════════════════════
║ [AI CHAT] Starting AI request
║ User Message: Show me a villa
╚════════════════════════════════════════════════════════════════

[AI CHAT] Initializing GenerativeModel...
[AI CHAT] Model: gemini-1.5-flash
[AI CHAT] API Key: AIzaSyCfNYlgDP_V9qZO...
[AI CHAT] Temperature: 0.7
[AI CHAT] Max Tokens: 1000
[AI CHAT] Model created successfully
[AI CHAT] Chat session started successfully
[AI CHAT] Sending message to Gemini API...

╔════════════════════════════════════════════════════════════════
║ [AI CHAT] RAW RESPONSE FROM GEMINI:
║ {
║   "type": "unit",
║   "name": "Luxury Villa in New Cairo",
║   "location": "New Cairo, Egypt",
║   ...
║ }
╚════════════════════════════════════════════════════════════════

[AI CHAT] Cleaned JSON: {...}
[AI CHAT] JSON parsed successfully!
[AI CHAT] Property data: {...}
[AI CHAT] Property object created: Luxury Villa in New Cairo
[AI CHAT] Formatted response created successfully

╔════════════════════════════════════════════════════════════════
║ [AI CHAT] SUCCESS! Returning response to user
╚════════════════════════════════════════════════════════════════

[CHAT BLOC] AI response received!
[CHAT BLOC] AI response content: I found a great property for you!...
[CHAT BLOC] Has property card: true
[CHAT BLOC] AI message added to list. Total messages: 2
[CHAT BLOC] State changed to ChatSuccess
[CHAT BLOC] Saving chat history...
[CHAT BLOC] Chat history saved successfully
```

---

## 🔍 What to Look For

### ✅ Success Case:
If everything works, you'll see:
1. "Model created successfully"
2. "RAW RESPONSE FROM GEMINI:" with JSON
3. "JSON parsed successfully!"
4. "Property object created: [Property Name]"
5. "SUCCESS! Returning response to user"

### ❌ Error Case 1: API Key Invalid
If you see:
```
[AI CHAT] ERROR: API Call Failed!
Error: Invalid API key
```
**Solution**: Check your API key in `config.dart`

### ❌ Error Case 2: JSON Parsing Failed
If you see:
```
[AI CHAT] ERROR: JSON Parsing Failed!
Error: FormatException: Unexpected character...
Raw response was: [some text]
```
**Reason**: Gemini didn't return valid JSON
**Solution**: The prompt needs adjustment

### ❌ Error Case 3: Network Error
If you see:
```
[AI CHAT] ERROR: API Call Failed!
Error: SocketException: Failed to connect...
```
**Solution**: Check internet connection

---

## 📋 How to Share Logs with Me

### Method 1: Copy from Console

1. Run the app with `flutter run`
2. Send a message in AI chat
3. Select all console output (Ctrl+A)
4. Copy (Ctrl+C)
5. Paste here in our chat

### Method 2: Save to File (Windows)

```bash
flutter run > debug_output.txt 2>&1
```
Then send a message, and the file `debug_output.txt` will have all logs.

### Method 3: Screenshot

If the text is too long:
1. Take screenshots of the console output
2. Share the screenshots

---

## 🧪 Test Cases to Try

### Test 1: Simple Query
**Message**: `Show me a villa`
**Expected**: Property card should appear

### Test 2: Specific Query
**Message**: `3-bedroom apartment in New Cairo`
**Expected**: Property card with 3 bedrooms

### Test 3: Budget Query
**Message**: `Property under 2 million EGP`
**Expected**: Property card with price under 2M

### Test 4: Off-Topic Query
**Message**: `What's the weather?`
**Expected**: AI says it only helps with real estate

---

## 🐛 Common Issues and Solutions

### Issue: "Sorry, I encountered an error"

**Appears in chat but check console for:**

1. **API Key Error**
   ```
   Error: API key not valid
   ```
   Fix: Check `lib/feature/ai_chat/domain/config.dart` has correct key

2. **Network Error**
   ```
   Error: Failed to connect
   ```
   Fix: Check internet connection

3. **JSON Parse Error**
   ```
   ERROR: JSON Parsing Failed!
   ```
   Fix: AI didn't return proper JSON (prompt issue)

4. **Model Error**
   ```
   Error: Model 'gemini-1.5-flash' not found
   ```
   Fix: Check model name in config

---

## 📊 Understanding the Log Flow

```
User Action: Type message and press send
     ↓
[CHAT BLOC] Receives SendMessageEvent
     ↓
[CHAT BLOC] Adds user message to list
     ↓
[CHAT BLOC] Calls AI data source
     ↓
[AI CHAT] Initializes model (if needed)
     ↓
[AI CHAT] Sends message to Gemini API
     ↓
[AI CHAT] Receives raw response
     ↓
[AI CHAT] Cleans and parses JSON
     ↓
[AI CHAT] Creates property object
     ↓
[AI CHAT] Formats response text
     ↓
[AI CHAT] Returns ChatMessage
     ↓
[CHAT BLOC] Receives AI response
     ↓
[CHAT BLOC] Adds AI message to list
     ↓
[CHAT BLOC] Emits ChatSuccess state
     ↓
[CHAT BLOC] Saves to history
     ↓
User sees: Property card in chat!
```

---

## 🎯 What I Need from You

To help debug, please:

1. **Run the app** with `flutter run`
2. **Open AI chat** (floating button)
3. **Send this message**: "Show me a villa"
4. **Copy ALL console output** from start to finish
5. **Paste it here** so I can see what happened

Or if you see an error in the chat itself, tell me:
- What message you sent
- What error you saw
- Copy any console output

---

## ⚡ Quick Debug Command

Run this single command and send me the output:

```bash
flutter run 2>&1 | tee debug_output.txt
```

Then:
1. Open AI chat
2. Send message "Show me a villa"
3. Close app
4. Open `debug_output.txt` file
5. Copy relevant parts (search for "[AI CHAT]" or "[CHAT BLOC]")
6. Share with me

---

**The debug logs will show us EXACTLY where the problem is!** 🔍
