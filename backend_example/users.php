<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'db_connection.php'; // Your database connection

try {
    // Get Authorization header
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    // Extract token from "Bearer TOKEN"
    $token = '';
    if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        $token = trim($matches[1]);
    }

    // Also check query parameter for backward compatibility
    if (empty($token) && isset($_GET['token'])) {
        $token = $_GET['token'];
    }

    // Validate token
    if (empty($token)) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'error' => 'No authentication token provided'
        ]);
        exit();
    }

    // Decode token to get user ID
    // Token format: base64(userId:timestamp)
    $decoded = base64_decode($token);
    $parts = explode(':', $decoded);

    if (count($parts) < 1 || !is_numeric($parts[0])) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'error' => 'Invalid token format'
        ]);
        exit();
    }

    $userId = (int)$parts[0];

    // Fetch user from database
    $stmt = $pdo->prepare("
        SELECT
            id,
            name,
            email,
            phone,
            role,
            is_verified,
            company_id,
            google_id,
            photo_url,
            created_at
        FROM users
        WHERE id = :id
        LIMIT 1
    ");
    $stmt->execute(['id' => $userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'error' => 'User not found'
        ]);
        exit();
    }

    // Get user stats (optional - if you have these tables)
    $savedSearchesCount = 0;
    $favoritesCount = 0;

    try {
        // Count saved searches (if table exists)
        $searchStmt = $pdo->prepare("SELECT COUNT(*) as count FROM saved_searches WHERE user_id = :user_id");
        $searchStmt->execute(['user_id' => $userId]);
        $savedSearchesCount = (int)$searchStmt->fetch(PDO::FETCH_ASSOC)['count'];
    } catch (Exception $e) {
        // Table doesn't exist, skip
    }

    try {
        // Count favorites (if table exists)
        $favStmt = $pdo->prepare("SELECT COUNT(*) as count FROM favorites WHERE user_id = :user_id");
        $favStmt->execute(['user_id' => $userId]);
        $favoritesCount = (int)$favStmt->fetch(PDO::FETCH_ASSOC)['count'];
    } catch (Exception $e) {
        // Table doesn't exist, skip
    }

    // Return authenticated user data
    echo json_encode([
        'id' => $user['id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'phone' => $user['phone'] ?? '',
        'role' => $user['role'],
        'is_verified' => $user['is_verified'],
        'company_id' => $user['company_id'],
        'stats' => [
            'saved_searches_count' => $savedSearchesCount,
            'favorites_count' => $favoritesCount
        ]
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Server error: ' . $e->getMessage()
    ]);
}
