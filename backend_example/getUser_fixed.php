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
    // Get token from query parameter or Authorization header
    $token = $_GET['token'] ?? '';

    if (empty($token)) {
        // Try to get from Authorization header
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            $token = trim($matches[1]);
        }
    }

    // Validate token exists
    if (empty($token)) {
        http_response_code(400);
        echo json_encode(['error' => 'Email or token is required']);
        exit();
    }

    // Decode token (format: base64(userId:timestamp))
    $decoded = base64_decode($token);
    if ($decoded === false) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token format']);
        exit();
    }

    $parts = explode(':', $decoded);
    if (count($parts) < 2 || !is_numeric($parts[0])) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token structure']);
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
            created_at
        FROM users
        WHERE id = :id
        LIMIT 1
    ");
    $stmt->execute(['id' => $userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid token or user not found']);
        exit();
    }

    // Get user stats (optional)
    $savedSearchesCount = 0;
    $favoritesCount = 0;

    // Return user data
    http_response_code(200);
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
        'error' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Server error: ' . $e->getMessage()
    ]);
}
