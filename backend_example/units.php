<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'db_connection.php';

try {
    // Get compound_id from query parameter
    $compoundId = $_GET['compound_id'] ?? null;

    if (empty($compoundId)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'compound_id parameter is required'
        ]);
        exit();
    }

    // Pagination parameters
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $offset = ($page - 1) * $limit;

    // Count total units for this compound
    $countStmt = $pdo->prepare("SELECT COUNT(*) as total FROM units WHERE compound_id = :compound_id");
    $countStmt->execute(['compound_id' => $compoundId]);
    $totalCount = (int)$countStmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Fetch units for the compound
    $stmt = $pdo->prepare("
        SELECT
            id,
            compound_id,
            unit_type,
            area,
            price,
            bedrooms,
            bathrooms,
            floor,
            status,
            unit_number,
            delivery_date,
            view,
            finishing,
            created_at,
            updated_at
        FROM units
        WHERE compound_id = :compound_id
        ORDER BY unit_number ASC, id ASC
        LIMIT :limit OFFSET :offset
    ");

    $stmt->bindValue(':compound_id', $compoundId, PDO::PARAM_STR);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();

    $units = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Calculate pagination info
    $totalPages = ceil($totalCount / $limit);

    // Return success response
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'count' => count($units),
        'total' => $totalCount,
        'page' => $page,
        'limit' => $limit,
        'total_pages' => $totalPages,
        'data' => $units
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
