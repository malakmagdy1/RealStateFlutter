<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CompanyController;
use App\Http\Controllers\CompoundController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\FinishSpecController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\UnitController;
use App\Http\Controllers\UnitSearchController;
use App\Http\Controllers\SalesController;
use App\Http\Controllers\StageController;
use App\Http\Controllers\ShareLinkController;
use App\Http\Controllers\StatisticsController;
use App\Http\Controllers\SavedSearchController;
use App\Http\Controllers\UnitTypeController;
use App\Http\Controllers\UnitAreaController;
use App\Http\Controllers\API\FCMTokenController;
use App\Http\Controllers\API\NotificationController;
use App\Http\Controllers\API\DeviceController;
use App\Http\Controllers\Admin\UnitAdminController;
use App\Http\Controllers\Admin\SaleAdminController;
use App\Http\Controllers\ActivityController;
use App\Http\Controllers\HistoryController;
use App\Http\Controllers\SubscriptionController;
use App\Http\Controllers\UpdatesController;
use App\Http\Controllers\UnitUpdatesController;
use App\Http\Controllers\NoteController;
use App\Http\Controllers\Api\AIController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Laravel Real Estate API - All API routes with Token Authentication
| Base URL: http://127.0.0.1:8001/api
|
| Public Routes: /register, /login
| Protected Routes: All other endpoints require Bearer token
|
*/

// ============================================================
// PUBLIC ROUTES (No Authentication Required)
// ============================================================
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// EMAIL VERIFICATION
Route::post('/verify-email', [AuthController::class, 'verifyEmail']);
Route::post('/resend-verification-code', [AuthController::class, 'resendVerificationCode']);

// PASSWORD RESET
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/verify-reset-code', [AuthController::class, 'verifyResetCode']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);

// Public access to companies and compounds for website
Route::get('/companies', [CompanyController::class, 'index']);
Route::get('/companies/{id}', [CompanyController::class, 'show']);
Route::get('/compounds', [CompoundController::class, 'index']);
Route::get('/compounds/{id}', [CompoundController::class, 'show']);
Route::get('/sales', [SalesController::class, 'index']);
Route::get('/sales/{id}', [SalesController::class, 'show']);

// ACTIVITIES - Recent updates for the app
Route::get('/activities', [ActivityController::class, 'index']);
Route::get('/activities/recent', [ActivityController::class, 'recent']);
Route::get('/activities/stats', [ActivityController::class, 'stats']);

// SHARE LINKS - Public access for sharing
Route::get('/share-link', [ShareLinkController::class, 'getShareData']);

// UPDATES - Recent updates for units, compounds, companies
Route::get('/updates/recent', [UpdatesController::class, 'getRecentUpdates']);
Route::get('/updates/summary', [UpdatesController::class, 'getUpdatesSummary']);
Route::get('/updates/item', [UpdatesController::class, 'getItemDetails']);

// UNIT UPDATES - New and updated units (PUBLIC)
Route::get('/units/new', [UnitUpdatesController::class, 'getNewUnits']);
Route::get('/units/updated', [UnitUpdatesController::class, 'getUpdatedUnits']);
Route::get('/units/changes', [UnitUpdatesController::class, 'getAllChanges']);
Route::get('/units/changes/summary', [UnitUpdatesController::class, 'getChangesSummary']);
Route::get('/units/marked-updated', [UnitUpdatesController::class, 'getUnitsMarkedAsUpdated']);
Route::post('/units/{id}/mark-seen', [UnitUpdatesController::class, 'markUnitAsSeen']);
Route::post('/units/mark-seen/multiple', [UnitUpdatesController::class, 'markMultipleUnitsAsSeen']);
Route::post('/units/mark-seen/all', [UnitUpdatesController::class, 'markAllAsSeen']);

// UNIFIED SEARCH & FILTER (PUBLIC)
Route::get('/search-and-filter', [SearchController::class, 'searchAndFilter']);

// UNIT SEARCH IN COMPOUND (PUBLIC)
Route::get('/units/search-in-compound', [UnitSearchController::class, 'searchInCompound']);

// DEVICE MANAGEMENT (PUBLIC - No token required, uses email/password)
Route::post('/devices/by-email', [DeviceController::class, 'getDevicesByEmail']);
Route::post('/devices/remove-by-email', [DeviceController::class, 'removeDeviceByEmail']);

// ACCOUNT DELETION REQUEST (PUBLIC - for web form)
Route::post('/delete-account-request', [AuthController::class, 'deleteAccountRequest']);


// ============================================================
// PROTECTED ROUTES (Require Bearer Token)
// ============================================================
Route::middleware('auth:sanctum')->group(function () {

    // AUTH - Logout & Delete Account
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::delete('/delete-account', [AuthController::class, 'deleteAccount']);
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // TUTORIAL - Mark tutorial as seen
    Route::post('/tutorial/mark-seen', [AuthController::class, 'markTutorialSeen']);

    // DEVICE MANAGEMENT
    Route::get('/devices', [DeviceController::class, 'index']);
    Route::get('/devices/active-sessions', [DeviceController::class, 'getActiveSessions']);
    Route::delete('/devices/{deviceId}', [DeviceController::class, 'destroy']);
    Route::post('/devices/check', [DeviceController::class, 'checkDevice']);
    Route::post('/devices/update-activity', [DeviceController::class, 'updateActivity']);
    Route::post('/devices/remote-logout', [DeviceController::class, 'remoteLogout']);

    // SEARCH & FILTER (no subscription required - free for all users)
    Route::get('/search', [SearchController::class, 'search']);
    Route::post('/filter-units', [UnitController::class, 'filter']);
    Route::get('/filter-units', [UnitController::class, 'filter']);

    // COMPANIES (authenticated)
    Route::get('/companies-with-sales', [SalesController::class, 'getCompaniesWithSales']);

    // UNITS
    Route::get('/units', [UnitController::class, 'index']);
    Route::get('/units/{id}', [UnitController::class, 'show']);

    // STAGES
    Route::get('/stages', [StageController::class, 'index']);
    Route::get('/stages/{id}', [StageController::class, 'show']);
    Route::post('/stages', [StageController::class, 'store']);
    Route::put('/stages/{id}', [StageController::class, 'update']);
    Route::delete('/stages/{id}', [StageController::class, 'destroy']);

    // STATISTICS
    Route::get('/statistics', [StatisticsController::class, 'index']);

    // SAVED SEARCHES
    Route::get('/saved-searches', [SavedSearchController::class, 'index']);
    Route::get('/saved-searches/{id}', [SavedSearchController::class, 'show']);
    Route::post('/saved-searches', [SavedSearchController::class, 'store']);
    Route::put('/saved-searches/{id}', [SavedSearchController::class, 'update']);
    Route::delete('/saved-searches/{id}', [SavedSearchController::class, 'destroy']);

    // UNIT TYPES
    Route::get('/unit-types', [UnitTypeController::class, 'index']);
    Route::get('/unit-types/{id}', [UnitTypeController::class, 'show']);
    Route::post('/unit-types', [UnitTypeController::class, 'store']);
    Route::put('/unit-types/{id}', [UnitTypeController::class, 'update']);
    Route::delete('/unit-types/{id}', [UnitTypeController::class, 'destroy']);

    // UNIT AREAS
    Route::get('/unit-areas', [UnitAreaController::class, 'show']);
    Route::post('/unit-areas', [UnitAreaController::class, 'store']);
    Route::put('/unit-areas', [UnitAreaController::class, 'update']);
    Route::delete('/unit-areas', [UnitAreaController::class, 'destroy']);

    // FINISH SPECIFICATIONS
    Route::get('/finish-specs', [FinishSpecController::class, 'index']);
    Route::get('/finish-specs/{id}', [FinishSpecController::class, 'show']);
    Route::post('/finish-specs', [FinishSpecController::class, 'store']);
    Route::put('/finish-specs/{id}', [FinishSpecController::class, 'update']);
    Route::delete('/finish-specs/{id}', [FinishSpecController::class, 'destroy']);

    // USER PROFILE
    Route::get('/user-by-email', [UserController::class, 'getUserByEmail']);
    Route::get('/profile', [UserController::class, 'getProfile']);
    Route::put('/profile', [UserController::class, 'updateProfile']);
    Route::put('/profile/name', [UserController::class, 'updateName']);
    Route::put('/profile/phone', [UserController::class, 'updatePhone']);
    Route::post('/change-password', [UserController::class, 'changePassword']);
    Route::post('/upload-image', [UserController::class, 'uploadImage']);

    // SALESPEOPLE
    Route::get('/salespeople-by-compound', [UserController::class, 'getSalespeopleByCompound']);

    // FAVORITES
    // NOTES (Favorites with notes) - Must be before /favorites to avoid route collision
    Route::get('/favorites/notes', [FavoriteController::class, 'getNotes']);

    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites', [FavoriteController::class, 'store']);
    Route::put('/favorites', [FavoriteController::class, 'update']);
    Route::delete('/favorites', [FavoriteController::class, 'destroy']);

    // USER HISTORY
    Route::get('/history', [HistoryController::class, 'index']);
    Route::post('/history', [HistoryController::class, 'store']);
    Route::delete('/history/{id}', [HistoryController::class, 'destroy']);
    Route::delete('/history-clear', [HistoryController::class, 'clear']);
    Route::get('/history/recently-viewed', [HistoryController::class, 'recentlyViewed']);
    Route::get('/history/searches', [HistoryController::class, 'searches']);

    // NOTES
    Route::get('/notes', [NoteController::class, 'index']);
    Route::post('/notes', [NoteController::class, 'store']);
    Route::get('/notes/{id}', [NoteController::class, 'show']);
    Route::put('/notes/{id}', [NoteController::class, 'update']);
    Route::delete('/notes/{id}', [NoteController::class, 'destroy']);

    // SUBSCRIPTIONS
    Route::get('/subscription-plans', [SubscriptionController::class, 'getPlans']);
    Route::get('/subscription-plans/{id}', [SubscriptionController::class, 'getPlan']);
    Route::get('/subscription/current', [SubscriptionController::class, 'getCurrentSubscription']);
    Route::get('/subscription/status', [SubscriptionController::class, 'checkStatus']);
    Route::get('/subscription/history', [SubscriptionController::class, 'getSubscriptionHistory']);
    Route::post('/subscription/subscribe', [SubscriptionController::class, 'subscribe']);
    Route::post('/subscription/cancel', [SubscriptionController::class, 'cancelSubscription']);
    Route::post('/subscription/free-plan', [SubscriptionController::class, 'assignFreePlan']);

    // ACTIVITIES - Detailed activity logs (protected)
    Route::get('/activities/{id}', [ActivityController::class, 'show']);
    Route::get('/activities/action/{action}', [ActivityController::class, 'byAction']);
    Route::get('/activities/subject/{subjectType}/{subjectId}', [ActivityController::class, 'bySubject']);

    // FCM TOKEN (Push Notifications)
    Route::post('/fcm-token', [FCMTokenController::class, 'store']);
    Route::delete('/fcm-token', [FCMTokenController::class, 'destroy']);
    Route::post('/update-locale', [FCMTokenController::class, 'updateLocale']);

    // MANUAL NOTIFICATIONS (Optional - for admin/testing)
    Route::post('/notifications/send-all', [NotificationController::class, 'sendToAll']);
    Route::post('/notifications/send-role', [NotificationController::class, 'sendToRole']);
    Route::post('/notifications/send-topic', [NotificationController::class, 'sendToTopic']);

    // UPDATE NOTIFICATIONS - Send notifications when items are updated
    Route::post('/updates/notify', [UpdatesController::class, 'sendUpdateNotification']);

    // ============================================================
    // AI ROUTES - AI Assistant & Property Intelligence
    // ============================================================
    Route::prefix('ai')->group(function () {
        // Chat - Multi-turn conversations
        Route::post('/chat', [AIController::class, 'chat']);

        // Conversations management
        Route::get('/conversations', [AIController::class, 'getConversations']);
        Route::get('/conversations/{id}', [AIController::class, 'getConversation']);
        Route::delete('/conversations/{id}', [AIController::class, 'deleteConversation']);

        // Property Recommendations
        Route::post('/recommendations', [AIController::class, 'getRecommendations']);

        // Property Description Generator
        Route::post('/generate-description', [AIController::class, 'generateDescription']);

        // Question Answering
        Route::post('/ask', [AIController::class, 'askQuestion']);

        // Property Comparison
        Route::post('/compare', [AIController::class, 'compareProperties']);

        // Market Insights
        Route::post('/market-insights', [AIController::class, 'getMarketInsights']);
    });

    // ============================================================
    // ADMIN ROUTES - Units & Sales Management (Auto-send FCM notifications)
    // ============================================================
    Route::prefix('admin')->group(function () {
        // UNITS - Create/Update/Delete (Auto-sends notifications to buyers)
        Route::post('/units', [UnitAdminController::class, 'store']);
        Route::put('/units/{id}', [UnitAdminController::class, 'update']);
        Route::delete('/units/{id}', [UnitAdminController::class, 'destroy']);

        // SALES - Create/Update/Delete (Auto-sends notifications to buyers)
        Route::post('/sales', [SaleAdminController::class, 'store']);
        Route::put('/sales/{id}', [SaleAdminController::class, 'update']);
        Route::delete('/sales/{id}', [SaleAdminController::class, 'destroy']);
    });
});
