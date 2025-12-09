# Backend AI Files - Installation Guide

## Quick Setup

### 1. Copy Files to Laravel Project

```bash
# Models
cp AIConversation.php /path/to/laravel/app/Models/
cp AIMessage.php /path/to/laravel/app/Models/

# Controller
cp AIController.php /path/to/laravel/app/Http/Controllers/Api/

# Migration
cp 2024_12_08_create_ai_tables.php /path/to/laravel/database/migrations/
```

### 2. Add Routes

Add the contents of `api_routes.php` to your `routes/api.php`:

```php
// Add at the end of routes/api.php
use App\Http\Controllers\Api\AIController;

Route::middleware('auth:sanctum')->prefix('ai')->group(function () {
    Route::post('/chat', [AIController::class, 'chat']);
    Route::post('/sales-assistant', [AIController::class, 'salesAssistant']);
    Route::post('/compare', [AIController::class, 'compareProperties']);
    Route::post('/recommendations', [AIController::class, 'getRecommendations']);
    Route::post('/ask', [AIController::class, 'askQuestion']);
    Route::post('/generate-description', [AIController::class, 'generateDescription']);
    Route::post('/market-insights', [AIController::class, 'getMarketInsights']);
    Route::get('/conversations/{id}', [AIController::class, 'getConversation']);
    Route::delete('/conversations/{id}', [AIController::class, 'deleteConversation']);
});
```

### 3. Add Gemini API Key to .env

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

### 4. Run Migration

```bash
php artisan migrate
```

### 5. Test the API

```bash
# Test chat endpoint
curl -X POST https://aqarapp.co/api/ai/chat \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "مرحبا", "language": "ar"}'
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/ai/chat` | Main chat |
| POST | `/api/ai/sales-assistant` | Quick sales advice |
| POST | `/api/ai/compare` | Compare properties |
| POST | `/api/ai/recommendations` | Get recommendations |
| POST | `/api/ai/ask` | Ask about property |
| POST | `/api/ai/generate-description` | Generate description |
| POST | `/api/ai/market-insights` | Get market insights |
| GET | `/api/ai/conversations/{id}` | Get conversation |
| DELETE | `/api/ai/conversations/{id}` | Delete conversation |

## Request/Response Examples

### Chat Request
```json
{
  "message": "إزاي أتعامل مع عميل متردد؟",
  "language": "ar",
  "conversation_id": null
}
```

### Chat Response
```json
{
  "success": true,
  "data": {
    "message": "يا باشا، العميل المتردد ده نوع مهم جداً...",
    "conversation_id": "123",
    "properties": []
  }
}
```

### Compare Request
```json
{
  "unit_ids": [1, 2, 3],
  "language": "ar"
}
```

## Notes

- All endpoints require authentication (Sanctum token)
- The Gemini API key is stored securely in `.env`
- Prompts are on the server - Flutter app doesn't have access to them
- Conversation history is stored in database for context
