<?php
/**
 * Datedash Image Upload Proxy
 * Handles multipart/form-data image uploads and returns JSON response with URLs.
 */

// Allow CORS for Flutter Web if needed
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$target_dir = "uploads/";
if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
}

// Check if image file was uploaded
if (!isset($_FILES["image"])) {
    echo json_encode(["status" => "error", "message" => "No image file provided."]);
    exit;
}

$file = $_FILES["image"];
$imageFileType = strtolower(pathinfo($file["name"], PATHINFO_EXTENSION));

// Generate a unique filename to prevent overwriting
$unique_name = uniqid("profile_") . "." . $imageFileType;
$target_file = $target_dir . $unique_name;

// Check if image file is an actual image
$check = getimagesize($file["tmp_name"]);
if ($check === false) {
    echo json_encode(["status" => "error", "message" => "File is not an image."]);
    exit;
}

// Check file size (limit to 5MB)
if ($file["size"] > 5000000) {
    echo json_encode(["status" => "error", "message" => "File is too large (Max 5MB)."]);
    exit;
}

// Allow certain file formats
$allowed_types = ["jpg", "jpeg", "png", "webp"];
if (!in_array($imageFileType, $allowed_types)) {
    echo json_encode(["status" => "error", "message" => "Only JPG, JPEG, PNG & WEBP files are allowed."]);
    exit;
}

// Try to upload file
if (move_uploaded_file($file["tmp_name"], $target_file)) {
    // Construct the full URL
    // NOTE: You should replace 'yourdomain.com' with your actual server URL
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
    $host = $_SERVER['HTTP_HOST'];
    $dir = dirname($_SERVER['PHP_SELF']);
    $base_url = "$protocol://$host" . ($dir === "/" ? "" : $dir) . "/";
    $actual_link = $base_url . $target_file;

    echo json_encode([
        "status" => "success",
        "message" => "File uploaded successfully.",
        "url" => $actual_link
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Sorry, there was an error uploading your file."]);
}
?>
