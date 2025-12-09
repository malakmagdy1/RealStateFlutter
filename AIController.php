<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AIService;
use App\Models\Unit;
use App\Models\Compound;
use App\Models\AIConversation;
use App\Models\AIMessage;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class AIController extends Controller
{
    protected AIService $aiService;

    public function __construct(AIService $aiService)
    {
        $this->aiService = $aiService;
    }

    /**
     * Chat with AI
     * POST /api/ai/chat
     */
    public function chat(Request $request): JsonResponse
    {
        $request->validate([
            'message' => 'required|string|max:2000',
            'conversation_id' => 'nullable|string',
            'language' => 'nullable|string|in:ar,en',
        ]);

        $user = $request->user();
        $message = $request->input('message');
        $conversationId = $request->input('conversation_id');
        $language = $request->input('language', 'ar');

        try {
            // Get or create conversation
            $conversation = null;
            $history = [];

            if ($conversationId) {
                $conversation = AIConversation::where('id', $conversationId)
                    ->where('user_id', $user->id)
                    ->first();

                if ($conversation) {
                    // Load conversation history
                    $messages = AIMessage::where('conversation_id', $conversation->id)
                        ->orderBy('created_at', 'asc')
                        ->get();

                    foreach ($messages as $msg) {
                        $history[] = [
                            'role' => $msg->role,
                            'content' => $msg->content,
                        ];
                    }
                }
            }

            if (!$conversation) {
                // Create new conversation
                $conversation = AIConversation::create([
                    'id' => Str::uuid()->toString(),
                    'user_id' => $user->id,
                    'title' => Str::limit($message, 50),
                    'language' => $language,
                ]);
            }

            // Save user message
            AIMessage::create([
                'conversation_id' => $conversation->id,
                'role' => 'user',
                'content' => $message,
            ]);

            // Get AI response
            $response = $this->aiService->chat($message, [
                'history' => $history,
                'language' => $language,
            ]);

            if (!$response) {
                throw new \Exception('AI service returned empty response');
            }

            // Save AI response
            AIMessage::create([
                'conversation_id' => $conversation->id,
                'role' => 'assistant',
                'content' => $response,
            ]);

            // Update conversation
            $messagesCount = AIMessage::where('conversation_id', $conversation->id)->count();
            $conversation->update(['messages_count' => $messagesCount]);

            return response()->json([
                'success' => true,
                'data' => [
                    'conversation_id' => $conversation->id,
                    'message' => $response,
                    'messages_count' => $messagesCount,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('AI Chat Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'An error occurred while processing your request. Please try again.',
                'message_ar' => 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.',
            ], 500);
        }
    }

    /**
     * Get all conversations
     * GET /api/ai/conversations
     */
    public function getConversations(Request $request): JsonResponse
    {
        $user = $request->user();

        $conversations = AIConversation::where('user_id', $user->id)
            ->orderBy('updated_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $conversations,
        ]);
    }

    /**
     * Get single conversation
     * GET /api/ai/conversations/{id}
     */
    public function getConversation(Request $request, string $id): JsonResponse
    {
        $user = $request->user();

        $conversation = AIConversation::where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (!$conversation) {
            return response()->json([
                'success' => false,
                'message' => 'Conversation not found',
            ], 404);
        }

        $messages = AIMessage::where('conversation_id', $conversation->id)
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $conversation->id,
                'title' => $conversation->title,
                'language' => $conversation->language,
                'messages' => $messages->map(function ($msg) {
                    return [
                        'id' => $msg->id,
                        'role' => $msg->role,
                        'content' => $msg->content,
                        'is_user' => $msg->role === 'user',
                        'created_at' => $msg->created_at->toISOString(),
                    ];
                }),
                'created_at' => $conversation->created_at->toISOString(),
                'updated_at' => $conversation->updated_at->toISOString(),
            ],
        ]);
    }

    /**
     * Delete conversation
     * DELETE /api/ai/conversations/{id}
     */
    public function deleteConversation(Request $request, string $id): JsonResponse
    {
        $user = $request->user();

        $conversation = AIConversation::where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (!$conversation) {
            return response()->json([
                'success' => false,
                'message' => 'Conversation not found',
            ], 404);
        }

        // Delete messages first
        AIMessage::where('conversation_id', $conversation->id)->delete();

        // Delete conversation
        $conversation->delete();

        return response()->json([
            'success' => true,
            'message' => 'Conversation deleted successfully',
        ]);
    }

    /**
     * Get property recommendations
     * POST /api/ai/recommendations
     */
    public function getRecommendations(Request $request): JsonResponse
    {
        $request->validate([
            'preferences' => 'nullable|array',
            'preferences.min_price' => 'nullable|numeric',
            'preferences.max_price' => 'nullable|numeric',
            'preferences.min_area' => 'nullable|numeric',
            'preferences.max_area' => 'nullable|numeric',
            'preferences.bedrooms' => 'nullable|integer',
            'preferences.unit_type' => 'nullable|string',
            'preferences.location' => 'nullable|string',
            'preferences.compound_id' => 'nullable|integer',
            'limit' => 'nullable|integer|max:20',
            'language' => 'nullable|string|in:ar,en',
        ]);

        $preferences = $request->input('preferences', []);
        $limit = $request->input('limit', 10);
        $language = $request->input('language', 'ar');

        try {
            // Build query based on preferences
            $query = Unit::query()->with(['compound', 'compound.company']);

            if (!empty($preferences['max_price'])) {
                $query->where('price', '<=', $preferences['max_price']);
            }
            if (!empty($preferences['min_price'])) {
                $query->where('price', '>=', $preferences['min_price']);
            }
            if (!empty($preferences['max_area'])) {
                $query->where('area', '<=', $preferences['max_area']);
            }
            if (!empty($preferences['min_area'])) {
                $query->where('area', '>=', $preferences['min_area']);
            }
            if (!empty($preferences['bedrooms'])) {
                $query->where('bedrooms', '>=', $preferences['bedrooms']);
            }
            if (!empty($preferences['unit_type'])) {
                $query->where('unit_type', 'like', '%' . $preferences['unit_type'] . '%');
            }
            if (!empty($preferences['compound_id'])) {
                $query->where('compound_id', $preferences['compound_id']);
            }

            $properties = $query->limit($limit)->get()->toArray();

            $response = $this->aiService->getRecommendations($preferences, $properties, $language);

            return response()->json([
                'success' => true,
                'data' => [
                    'recommendations' => $properties,
                    'ai_analysis' => $response,
                ],
            ]);

        } catch (\Exception $e) {
            \Log::error('AI Recommendations Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Unable to generate recommendations',
            ], 500);
        }
    }

    /**
     * Generate property description
     * POST /api/ai/generate-description
     */
    public function generateDescription(Request $request): JsonResponse
    {
        $request->validate([
            'unit_id' => 'nullable|integer|exists:units,id',
            'property_data' => 'nullable|array',
            'language' => 'nullable|string|in:ar,en',
            'style' => 'nullable|string|in:formal,casual,luxury,investment',
        ]);

        $language = $request->input('language', 'ar');
        $style = $request->input('style', 'formal');

        try {
            $propertyData = [];

            if ($request->has('unit_id')) {
                $unit = Unit::with(['compound', 'compound.company'])->find($request->input('unit_id'));
                if ($unit) {
                    $propertyData = $unit->toArray();
                }
            } elseif ($request->has('property_data')) {
                $propertyData = $request->input('property_data');
            }

            if (empty($propertyData)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Property data is required',
                ], 400);
            }

            $description = $this->aiService->generateDescription($propertyData, $language, $style);

            return response()->json([
                'success' => true,
                'data' => [
                    'description' => $description,
                ],
            ]);

        } catch (\Exception $e) {
            \Log::error('AI Generate Description Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Unable to generate description',
            ], 500);
        }
    }

    /**
     * Ask question about property
     * POST /api/ai/ask
     */
    public function askQuestion(Request $request): JsonResponse
    {
        $request->validate([
            'question' => 'required|string|max:1000',
            'unit_id' => 'nullable|integer|exists:units,id',
            'compound_id' => 'nullable|integer|exists:compounds,id',
            'language' => 'nullable|string|in:ar,en',
        ]);

        $question = $request->input('question');
        $language = $request->input('language', 'ar');

        try {
            $context = [];

            if ($request->has('unit_id')) {
                $unit = Unit::with(['compound', 'compound.company'])->find($request->input('unit_id'));
                if ($unit) {
                    $context['unit'] = $unit->toArray();
                }
            }

            if ($request->has('compound_id')) {
                $compound = Compound::with(['company', 'units'])->find($request->input('compound_id'));
                if ($compound) {
                    $context['compound'] = $compound->toArray();
                }
            }

            $answer = $this->aiService->answerQuestion($question, $context, $language);

            return response()->json([
                'success' => true,
                'data' => [
                    'answer' => $answer,
                ],
            ]);

        } catch (\Exception $e) {
            \Log::error('AI Ask Question Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Unable to answer question',
            ], 500);
        }
    }

    /**
     * Compare properties
     * POST /api/ai/compare
     */
    public function compareProperties(Request $request): JsonResponse
    {
        $request->validate([
            'unit_ids' => 'required|array|min:2|max:5',
            'unit_ids.*' => 'integer|exists:units,id',
            'language' => 'nullable|string|in:ar,en',
        ]);

        $unitIds = $request->input('unit_ids');
        $language = $request->input('language', 'ar');

        try {
            $units = Unit::with(['compound', 'compound.company'])
                ->whereIn('id', $unitIds)
                ->get()
                ->toArray();

            if (count($units) < 2) {
                return response()->json([
                    'success' => false,
                    'message' => 'At least 2 valid units are required for comparison',
                ], 400);
            }

            $comparison = $this->aiService->compareProperties($units, $language);

            return response()->json([
                'success' => true,
                'data' => [
                    'comparison' => $comparison,
                    'units' => $units,
                ],
            ]);

        } catch (\Exception $e) {
            \Log::error('AI Compare Properties Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Unable to compare properties',
            ], 500);
        }
    }

    /**
     * Get market insights
     * POST /api/ai/market-insights
     */
    public function getMarketInsights(Request $request): JsonResponse
    {
        $request->validate([
            'compound_id' => 'nullable|integer|exists:compounds,id',
            'location' => 'nullable|string',
            'language' => 'nullable|string|in:ar,en',
        ]);

        $language = $request->input('language', 'ar');

        try {
            $marketData = [];

            if ($request->has('compound_id')) {
                $compound = Compound::with(['company', 'units'])->find($request->input('compound_id'));
                if ($compound) {
                    $marketData['compound'] = $compound->toArray();
                    $marketData['units_count'] = $compound->units->count();
                    $marketData['avg_price'] = $compound->units->avg('price');
                    $marketData['min_price'] = $compound->units->min('price');
                    $marketData['max_price'] = $compound->units->max('price');
                }
            }

            if ($request->has('location')) {
                $location = $request->input('location');
                $marketData['location'] = $location;

                // Get stats for location
                $units = Unit::whereHas('compound', function ($q) use ($location) {
                    $q->where('location', 'like', '%' . $location . '%');
                })->get();

                $marketData['units_in_area'] = $units->count();
                $marketData['avg_price_in_area'] = $units->avg('price');
            }

            if (empty($marketData)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Please provide compound_id or location',
                ], 400);
            }

            $insights = $this->aiService->getMarketInsights($marketData, $language);

            return response()->json([
                'success' => true,
                'data' => [
                    'insights' => $insights,
                    'market_data' => $marketData,
                ],
            ]);

        } catch (\Exception $e) {
            \Log::error('AI Market Insights Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Unable to get market insights',
            ], 500);
        }
    }
}
