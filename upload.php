<?php
/**
 * File Upload Handler for DateDash Chat
 * Upload endpoint for chat images and media files
 * Usage: POST multipart/form-data with 'file' parameter
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Check if request is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

// Configuration
$upload_dir = 'uploads/chats/';
$max_file_size = 50 * 1024 * 1024; // 50MB
$allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'audio/mpeg', 'audio/m4a'];

// Create upload directory if it doesn't exist
if (!is_dir($upload_dir)) {
    @mkdir($upload_dir, 0755, true);
}

// Validate request
if (!isset($_FILES['file'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'No file provided']);
    exit;
}

$file = $_FILES['file'];

// Validate file
if ($file['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'File upload error: ' . $file['error']]);
    exit;
}

if ($file['size'] > $max_file_size) {
    http_response_code(413);
    echo json_encode(['success' => false, 'error' => 'File too large. Maximum size: 50MB']);
    exit;
}

if (!in_array($file['type'], $allowed_types)) {
    http_response_code(415);
    echo json_encode(['success' => false, 'error' => 'File type not allowed']);
    exit;
}

// Get optional parameters
$chat_id = isset($_POST['chatId']) ? sanitize_filename($_POST['chatId']) : 'general';
$user_id = isset($_POST['userId']) ? sanitize_filename($_POST['userId']) : 'unknown';
$file_type = isset($_POST['fileType']) ? sanitize_filename($_POST['fileType']) : 'images';

// Create subdirectory for this file type and chat
$type_dir = $upload_dir . $file_type . '/';
if (!is_dir($type_dir)) {
    @mkdir($type_dir, 0755, true);
}

// Generate unique filename
$timestamp = time();
$random = bin2hex(random_bytes(4));
$original_name = pathinfo($file['name'], PATHINFO_FILENAME);
$file_ext = pathinfo($file['name'], PATHINFO_EXTENSION);
$new_filename = $timestamp . '_' . $user_id . '_' . $random . '.' . $file_ext;
$upload_path = $type_dir . $new_filename;

// Move uploaded file
if (!move_uploaded_file($file['tmp_name'], $upload_path)) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Failed to save file']);
    exit;
}

// Set proper permissions
@chmod($upload_path, 0644);

// Return success response with file URL
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];
$base_url = $protocol . '://' . $host;
$file_url = $base_url . '/' . $upload_path;

http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'File uploaded successfully',
    'file_url' => $file_url,
    'file_path' => $upload_path,
    'file_name' => $new_filename,
    'timestamp' => $timestamp
]);
exit;

/**
 * Sanitize filename to prevent directory traversal
 */
function sanitize_filename($filename) {
    $filename = str_replace(['/', '\\', '..'], '', $filename);
    $filename = preg_replace('/[^a-zA-Z0-9_-]/', '', $filename);
    return strlen($filename) > 0 ? $filename : 'unknown';
}
?>
