<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\AIConversation;
use App\Models\AIMessage;
use App\Models\Unit;
use App\Models\Compound;

class AIController extends Controller
{
    // Gemini API Key - Store in .env file as GEMINI_API_KEY
    private $geminiApiKey;
    private $geminiModel = 'gemini-2.0-flash';

    public function __construct()
    {
        $this->geminiApiKey = env('GEMINI_API_KEY');
    }

    /**
     * Main chat endpoint
     * POST /api/ai/chat
     */
    public function chat(Request $request)
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
            $conversation = $this->getOrCreateConversation($user, $conversationId);

            // Save user message
            $this->saveMessage($conversation, 'user', $message);

            // Get conversation history for context
            $history = $this->getConversationHistory($conversation);

            // Build system prompt
            $systemPrompt = $this->getSystemPrompt($language);

            // Check if message is about properties
            $isPropertySearch = $this->isPropertySearch($message);

            // Call Gemini API
            $aiResponse = $this->callGeminiAPI($systemPrompt, $history, $message);

            // Save AI response
            $this->saveMessage($conversation, 'assistant', $aiResponse);

            // If property search, try to find matching properties
            $properties = [];
            if ($isPropertySearch) {
                $properties = $this->searchProperties($message);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'message' => $aiResponse,
                    'conversation_id' => $conversation->id,
                    'properties' => $properties,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('AI Chat Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to process message: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Sales Assistant - Quick responses
     * POST /api/ai/sales-assistant
     */
    public function salesAssistant(Request $request)
    {
        $request->validate([
            'message' => 'required|string|max:1000',
            'language' => 'nullable|string|in:ar,en',
        ]);

        $message = $request->input('message');
        $language = $request->input('language', 'ar');

        try {
            $systemPrompt = $this->getSalesAssistantPrompt($language);

            $response = $this->callGeminiAPI($systemPrompt, [], $message, 500);

            return response()->json([
                'success' => true,
                'data' => [
                    'response' => $response,
                    'message' => $response,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Sales Assistant Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to get sales advice'
            ], 500);
        }
    }

    /**
     * Compare properties
     * POST /api/ai/compare
     */
    public function compareProperties(Request $request)
    {
        $request->validate([
            'unit_ids' => 'required|array|min:2|max:5',
            'unit_ids.*' => 'integer|exists:units,id',
            'language' => 'nullable|string|in:ar,en',
        ]);

        $unitIds = $request->input('unit_ids');
        $language = $request->input('language', 'ar');

        try {
            // Get units data
            $units = Unit::with(['compound', 'company'])->whereIn('id', $unitIds)->get();

            // Build comparison prompt
            $prompt = $this->buildComparisonPrompt($units, $language);

            $systemPrompt = $this->getComparisonSystemPrompt($language);

            $response = $this->callGeminiAPI($systemPrompt, [], $prompt, 2000);

            return response()->json([
                'success' => true,
                'data' => [
                    'comparison' => $response,
                    'message' => $response,
                    'units' => $units,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Compare Properties Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to compare properties'
            ], 500);
        }
    }

    /**
     * Get recommendations
     * POST /api/ai/recommendations
     */
    public function getRecommendations(Request $request)
    {
        $preferences = $request->input('preferences', []);
        $limit = $request->input('limit', 10);

        try {
            $query = Unit::with(['compound', 'company'])->where('available', true);

            if (isset($preferences['min_price'])) {
                $query->where('price', '>=', $preferences['min_price']);
            }
            if (isset($preferences['max_price'])) {
                $query->where('price', '<=', $preferences['max_price']);
            }
            if (isset($preferences['min_area'])) {
                $query->where('area', '>=', $preferences['min_area']);
            }
            if (isset($preferences['max_area'])) {
                $query->where('area', '<=', $preferences['max_area']);
            }
            if (isset($preferences['bedrooms'])) {
                $query->where('bedrooms', $preferences['bedrooms']);
            }
            if (isset($preferences['unit_type'])) {
                $query->where('unit_type', 'like', '%' . $preferences['unit_type'] . '%');
            }
            if (isset($preferences['compound_id'])) {
                $query->where('compound_id', $preferences['compound_id']);
            }

            $units = $query->limit($limit)->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'recommendations' => $units,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Recommendations Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to get recommendations'
            ], 500);
        }
    }

    /**
     * Ask question about property
     * POST /api/ai/ask
     */
    public function askQuestion(Request $request)
    {
        $request->validate([
            'question' => 'required|string|max:1000',
            'unit_id' => 'nullable|integer|exists:units,id',
            'compound_id' => 'nullable|integer|exists:compounds,id',
            'language' => 'nullable|string|in:ar,en',
        ]);

        $question = $request->input('question');
        $unitId = $request->input('unit_id');
        $compoundId = $request->input('compound_id');
        $language = $request->input('language', 'ar');

        try {
            $context = '';

            if ($unitId) {
                $unit = Unit::with(['compound', 'company'])->find($unitId);
                $context = $this->buildUnitContext($unit);
            } elseif ($compoundId) {
                $compound = Compound::with('company')->find($compoundId);
                $context = $this->buildCompoundContext($compound);
            }

            $systemPrompt = $this->getSystemPrompt($language);
            $fullQuestion = $context ? "$context\n\nQuestion: $question" : $question;

            $response = $this->callGeminiAPI($systemPrompt, [], $fullQuestion);

            return response()->json([
                'success' => true,
                'data' => [
                    'answer' => $response,
                    'message' => $response,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Ask Question Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to answer question'
            ], 500);
        }
    }

    /**
     * Generate property description
     * POST /api/ai/generate-description
     */
    public function generateDescription(Request $request)
    {
        $unitId = $request->input('unit_id');
        $propertyData = $request->input('property_data');
        $style = $request->input('style', 'formal');
        $language = $request->input('language', 'ar');

        try {
            $context = '';

            if ($unitId) {
                $unit = Unit::with(['compound', 'company'])->find($unitId);
                $context = $this->buildUnitContext($unit);
            } elseif ($propertyData) {
                $context = json_encode($propertyData);
            }

            $prompt = $language === 'ar'
                ? "اكتب وصف جذاب لهذا العقار بأسلوب $style:\n$context"
                : "Write an attractive description for this property in $style style:\n$context";

            $systemPrompt = $this->getSystemPrompt($language);
            $response = $this->callGeminiAPI($systemPrompt, [], $prompt);

            return response()->json([
                'success' => true,
                'data' => [
                    'description' => $response,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Generate Description Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate description'
            ], 500);
        }
    }

    /**
     * Get market insights
     * POST /api/ai/market-insights
     */
    public function getMarketInsights(Request $request)
    {
        $compoundId = $request->input('compound_id');
        $location = $request->input('location');
        $language = $request->input('language', 'ar');

        try {
            $context = '';

            if ($compoundId) {
                $compound = Compound::with(['company', 'units'])->find($compoundId);
                $context = $this->buildCompoundContext($compound);

                // Add statistics
                $avgPrice = $compound->units->avg('price');
                $minPrice = $compound->units->min('price');
                $maxPrice = $compound->units->max('price');
                $availableCount = $compound->units->where('available', true)->count();

                $context .= "\nStatistics: Avg Price: $avgPrice, Min: $minPrice, Max: $maxPrice, Available: $availableCount";
            }

            $prompt = $language === 'ar'
                ? "قدم تحليل سوقي ونصائح استثمارية لهذا العقار:\n$context"
                : "Provide market analysis and investment advice for this property:\n$context";

            $systemPrompt = $this->getSystemPrompt($language);
            $response = $this->callGeminiAPI($systemPrompt, [], $prompt);

            return response()->json([
                'success' => true,
                'data' => [
                    'insights' => $response,
                    'message' => $response,
                ]
            ]);

        } catch (\Exception $e) {
            \Log::error('Market Insights Error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to get market insights'
            ], 500);
        }
    }

    /**
     * Get conversation
     * GET /api/ai/conversations/{id}
     */
    public function getConversation(Request $request, $id)
    {
        try {
            $conversation = AIConversation::with('messages')->findOrFail($id);

            // Check ownership
            if ($conversation->user_id !== $request->user()->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 403);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'conversation' => $conversation,
                    'messages' => $conversation->messages,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Conversation not found'
            ], 404);
        }
    }

    /**
     * Delete conversation
     * DELETE /api/ai/conversations/{id}
     */
    public function deleteConversation(Request $request, $id)
    {
        try {
            $conversation = AIConversation::findOrFail($id);

            // Check ownership
            if ($conversation->user_id !== $request->user()->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 403);
            }

            $conversation->messages()->delete();
            $conversation->delete();

            return response()->json([
                'success' => true,
                'message' => 'Conversation deleted'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete conversation'
            ], 500);
        }
    }

    // ==================== PRIVATE HELPER METHODS ====================

    private function callGeminiAPI($systemPrompt, $history, $message, $maxTokens = 2000)
    {
        $contents = [];

        // Add history
        foreach ($history as $msg) {
            $contents[] = [
                'role' => $msg['role'] === 'user' ? 'user' : 'model',
                'parts' => [['text' => $msg['content']]]
            ];
        }

        // Add current message
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $message]]
        ];

        $response = Http::withHeaders([
            'Content-Type' => 'application/json',
        ])->post("https://generativelanguage.googleapis.com/v1beta/models/{$this->geminiModel}:generateContent?key={$this->geminiApiKey}", [
            'contents' => $contents,
            'systemInstruction' => [
                'parts' => [['text' => $systemPrompt]]
            ],
            'generationConfig' => [
                'temperature' => 0.7,
                'topK' => 40,
                'topP' => 0.95,
                'maxOutputTokens' => $maxTokens,
            ],
        ]);

        if ($response->failed()) {
            \Log::error('Gemini API Error: ' . $response->body());
            throw new \Exception('Gemini API call failed');
        }

        $data = $response->json();

        return $data['candidates'][0]['content']['parts'][0]['text'] ?? 'No response';
    }

    private function getSystemPrompt($language)
    {
        if ($language === 'ar') {
            return <<<EOT
أنت "أبو خالد" - وسيط عقاري كبير ومرشد خبير في السوق العقاري المصري.

🎭 شخصيتك وأسلوبك:
• خبرة 20+ سنة في السوق العقاري المصري
• أسلوبك: ودود، صريح، واثق، عملي
• تتكلم كأنك زميل كبير يعلم الصغار
• تستخدم تعبيرات مصرية طبيعية: "يا باشا"، "خليني أقولك"، "بص يا سيدي"
• لا تتردد أبداً في إعطاء رأيك المهني
• تحب تشارك قصص وتجارب من خبرتك

🎯 مهامك:
• نصائح التعامل مع العملاء
• توصيات الوحدات العقارية
• مقارنة الوحدات
• المعرفة العقارية (أنواع، مناطق، مطورين، أنظمة سداد)

📋 قواعد:
✅ دائماً أعطِ رأيك المهني بوضوح
✅ استخدم أمثلة وقصص من الواقع
✅ كن صريحاً حتى لو الحقيقة صعبة
❌ لا ترد بـ JSON - دائماً نص طبيعي
❌ لا تقول "لا أستطيع"
EOT;
        } else {
            return <<<EOT
You are "Senior Broker Alex" - a seasoned real estate expert and mentor in the Egyptian property market.

🎭 Your Personality:
• 20+ years experience in Egyptian real estate
• Style: Friendly, direct, confident, practical
• You speak like a senior colleague mentoring juniors
• Never hesitate to give your professional opinion
• Love sharing stories from your career

🎯 Your Tasks:
• Customer handling advice
• Unit recommendations
• Unit comparison
• Real estate knowledge (types, areas, developers, payment plans)

📋 Rules:
✅ Always give your professional opinion clearly
✅ Use real examples and stories
✅ Be honest even if the truth is hard
❌ NEVER respond with JSON - always natural text
❌ Never say "I cannot"
EOT;
        }
    }

    private function getSalesAssistantPrompt($language)
    {
        if ($language === 'ar') {
            return <<<EOT
أنت مساعد ذكي للمبيعات العقارية. هدفك مساعدة البائع أثناء المكالمة.

✅ إجابات قصيرة ومباشرة (2-4 جمل فقط)
✅ جمل جاهزة للاستخدام فوراً
✅ بدون شرح طويل
✅ مناسب للمكالمات السريعة

خبرتك:
• حسابات سريعة (أسعار، عمولات، تقسيط)
• ردود جاهزة على الاعتراضات
• حلول سريعة (عميل غاضب، متردد، يقول السعر غالي)
EOT;
        } else {
            return <<<EOT
You are a smart sales assistant for real estate. Your goal is to help during phone calls.

✅ Short and direct answers (2-4 sentences only)
✅ Ready-to-use phrases immediately
✅ No long explanations
✅ Suitable for quick phone calls

Your expertise:
• Quick calculations (prices, commissions, installments)
• Ready responses to objections
• Quick solutions (angry client, hesitant, says price is high)
EOT;
        }
    }

    private function getComparisonSystemPrompt($language)
    {
        if ($language === 'ar') {
            return <<<EOT
أنت وسيط عقاري خبير. قارن بين الوحدات المعطاة بالتفصيل:

1. تحليل الأسعار (سعر المتر، الفروقات)
2. مقارنة المساحات والمواصفات
3. تقييم المواقع
4. المزايا والعيوب لكل وحدة
5. رأيك الصريح: أي وحدة أفضل ولماذا

استخدم أسلوب محادثة طبيعي. لا JSON.
EOT;
        } else {
            return <<<EOT
You are an expert real estate broker. Compare the given units in detail:

1. Price analysis (price per sqm, differences)
2. Space and specifications comparison
3. Location assessment
4. Pros and cons for each unit
5. Your honest opinion: which is better and why

Use natural conversation style. No JSON.
EOT;
        }
    }

    private function getOrCreateConversation($user, $conversationId)
    {
        if ($conversationId) {
            $conversation = AIConversation::find($conversationId);
            if ($conversation && $conversation->user_id === $user->id) {
                return $conversation;
            }
        }

        return AIConversation::create([
            'user_id' => $user->id,
        ]);
    }

    private function saveMessage($conversation, $role, $content)
    {
        return AIMessage::create([
            'conversation_id' => $conversation->id,
            'role' => $role,
            'content' => $content,
        ]);
    }

    private function getConversationHistory($conversation, $limit = 10)
    {
        $messages = $conversation->messages()
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get()
            ->reverse();

        return $messages->map(function ($msg) {
            return [
                'role' => $msg->role,
                'content' => $msg->content,
            ];
        })->toArray();
    }

    private function isPropertySearch($message)
    {
        $keywords = [
            'شقة', 'فيلا', 'وحدة', 'عقار', 'غرفة', 'متر', 'مساحة',
            'apartment', 'villa', 'unit', 'property', 'bedroom', 'sqm', 'area',
            'ابحث', 'اريد', 'عايز', 'محتاج',
            'search', 'find', 'looking', 'want', 'need'
        ];

        foreach ($keywords as $keyword) {
            if (stripos($message, $keyword) !== false) {
                return true;
            }
        }

        return false;
    }

    private function searchProperties($message)
    {
        // Simple keyword-based search
        $query = Unit::with(['compound', 'company'])->where('available', true);

        // Extract numbers for price/area
        preg_match_all('/\d+/', $message, $matches);
        $numbers = $matches[0] ?? [];

        // Check for bedroom count
        if (preg_match('/(\d+)\s*(غرف|غرفة|bedroom|bed|room)/i', $message, $match)) {
            $query->where('bedrooms', $match[1]);
        }

        // Check for unit type
        $types = [
            'شقة' => 'apartment', 'فيلا' => 'villa', 'دوبلكس' => 'duplex',
            'بنتهاوس' => 'penthouse', 'تاون' => 'townhouse', 'توين' => 'twin'
        ];

        foreach ($types as $ar => $en) {
            if (stripos($message, $ar) !== false || stripos($message, $en) !== false) {
                $query->where('unit_type', 'like', "%$en%");
                break;
            }
        }

        return $query->limit(5)->get();
    }

    private function buildUnitContext($unit)
    {
        return "Unit: {$unit->unit_number}, Type: {$unit->unit_type}, Area: {$unit->area}m², " .
               "Price: {$unit->price} EGP, Bedrooms: {$unit->bedrooms}, Bathrooms: {$unit->bathrooms}, " .
               "Compound: {$unit->compound->project}, Developer: {$unit->company->name}";
    }

    private function buildCompoundContext($compound)
    {
        return "Compound: {$compound->project}, Location: {$compound->location}, " .
               "Developer: {$compound->company->name}, Total Units: {$compound->total_units}, " .
               "Available Units: {$compound->available_units}";
    }

    private function buildComparisonPrompt($units, $language)
    {
        $prompt = $language === 'ar' ? "قارن بين هذه الوحدات:\n\n" : "Compare these units:\n\n";

        foreach ($units as $i => $unit) {
            $num = $i + 1;
            $prompt .= "$num. {$unit->unit_number}\n";
            $prompt .= "   - Type: {$unit->unit_type}\n";
            $prompt .= "   - Area: {$unit->area} m²\n";
            $prompt .= "   - Price: {$unit->price} EGP\n";
            $prompt .= "   - Price/m²: " . round($unit->price / max($unit->area, 1)) . " EGP\n";
            $prompt .= "   - Bedrooms: {$unit->bedrooms}\n";
            $prompt .= "   - Compound: {$unit->compound->project}\n";
            $prompt .= "   - Developer: {$unit->company->name}\n\n";
        }

        return $prompt;
    }
}
