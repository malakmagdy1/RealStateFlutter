<?php

/**
 * AI Routes - Add these to your routes/api.php file
 */

use App\Http\Controllers\Api\AIController;

// AI Chat Routes (requires authentication)
Route::middleware('auth:sanctum')->prefix('ai')->group(function () {
    // Main chat
    Route::post('/chat', [AIController::class, 'chat']);

    // Sales assistant (quick responses)
    Route::post('/sales-assistant', [AIController::class, 'salesAssistant']);

    // Property comparison
    Route::post('/compare', [AIController::class, 'compareProperties']);

    // Get recommendations
    Route::post('/recommendations', [AIController::class, 'getRecommendations']);

    // Ask question about property
    Route::post('/ask', [AIController::class, 'askQuestion']);

    // Generate description
    Route::post('/generate-description', [AIController::class, 'generateDescription']);

    // Market insights
    Route::post('/market-insights', [AIController::class, 'getMarketInsights']);

    // Conversation management
    Route::get('/conversations/{id}', [AIController::class, 'getConversation']);
    Route::delete('/conversations/{id}', [AIController::class, 'deleteConversation']);
});
