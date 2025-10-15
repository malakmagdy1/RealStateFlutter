<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'db_connection.php'; // Your database connection

try {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);

    $googleId = $input['google_id'] ?? null;
    $email = $input['email'] ?? null;
    $name = $input['name'] ?? null;
    $photoUrl = $input['photo_url'] ?? null;
    $loginMethod = $input['login_method'] ?? 'google';

    // Validate input
    if (empty($googleId) || empty($email)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'Google ID and email are required'
        ]);
        exit();
    }

    // Check if user exists by Google ID or email
    $stmt = $pdo->prepare("
        SELECT * FROM users
        WHERE google_id = :google_id OR email = :email
        LIMIT 1
    ");
    $stmt->execute([
        'google_id' => $googleId,
        'email' => $email
    ]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        // User exists - update Google ID if not set
        if (empty($user['google_id'])) {
            $updateStmt = $pdo->prepare("
                UPDATE users
                SET google_id = :google_id,
                    photo_url = :photo_url,
                    is_verified = 1
                WHERE id = :id
            ");
            $updateStmt->execute([
                'google_id' => $googleId,
                'photo_url' => $photoUrl,
                'id' => $user['id']
            ]);
        }

        $userId = $user['id'];
    } else {
        // Create new user
        $insertStmt = $pdo->prepare("
            INSERT INTO users (
                name,
                email,
                google_id,
                photo_url,
                role,
                is_verified,
                password,
                phone
            ) VALUES (
                :name,
                :email,
                :google_id,
                :photo_url,
                'buyer',
                1,
                '',
                ''
            )
        ");
        $insertStmt->execute([
            'name' => $name,
            'email' => $email,
            'google_id' => $googleId,
            'photo_url' => $photoUrl
        ]);

        $userId = $pdo->lastInsertId();
    }

    // Generate authentication token
    $token = base64_encode($userId . ':' . time());

    // Store token in database (optional - for token validation)
    $tokenStmt = $pdo->prepare("
        UPDATE users
        SET last_login = NOW(),
            login_method = :login_method
        WHERE id = :id
    ");
    $tokenStmt->execute([
        'login_method' => $loginMethod,
        'id' => $userId
    ]);

    // Fetch updated user data
    $userStmt = $pdo->prepare("SELECT * FROM users WHERE id = :id");
    $userStmt->execute(['id' => $userId]);
    $userData = $userStmt->fetch(PDO::FETCH_ASSOC);

    // Return success response (matching LoginResponse format)
    echo json_encode([
        'success' => true,
        'message' => 'Google login successful',
        'token' => $token,
        'user' => [
            'id' => $userData['id'],
            'name' => $userData['name'],
            'email' => $userData['email'],
            'phone' => $userData['phone'] ?? '',
            'role' => $userData['role'],
            'is_verified' => $userData['is_verified'],
            'google_id' => $userData['google_id'],
            'photo_url' => $userData['photo_url']
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Google login failed: ' . $e->getMessage()
    ]);
}
