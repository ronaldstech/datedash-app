# DateDash File Upload Configuration

## PHP Backend Setup Instructions

### 1. Update the PHP Endpoint URL

In `lib/services/chat_service.dart`, update the `_uploadEndpoint` constant with your actual Hostinger domain:

```dart
static const String _uploadEndpoint = 'https://yourdomain.com/upload.php';
```

Replace `yourdomain.com` with your actual Hostinger domain.

### 2. Deploy upload.php to Your Server

1. Upload the `upload.php` file from the project root to your Hostinger server
2. Place it in the public root directory (usually `public_html/`)
3. The PHP script will automatically create the `uploads/chats/` directory structure

### 3. File Structure on Server

After uploads, your server will have this structure:
```
public_html/
├── upload.php
└── uploads/
    └── chats/
        ├── images/
        │   ├── 1234567890_userId_abc123.jpg
        │   └── ...
        └── voice/
            ├── 1234567890_userId_def456.m4a
            └── ...
```

### 4. PHP Configuration Requirements

**Minimum PHP Requirements:**
- PHP 7.4+
- Upload max file size: 50MB (configured in upload.php)
- Allowed file types: images, audio

**php.ini settings (if needed):**
```ini
upload_max_filesize = 50M
post_max_size = 50M
```

### 5. Permissions

Ensure the following directory permissions on your server:
```bash
chmod 755 public_html/
chmod 755 public_html/uploads/
chmod 755 public_html/uploads/chats/
```

The PHP script automatically creates subdirectories with proper permissions.

### 6. File Access URLs

Uploaded files will be accessible at:
- Images: `https://yourdomain.com/uploads/chats/images/filename.jpg`
- Voice: `https://yourdomain.com/uploads/chats/voice/filename.m4a`

### 7. Security Notes

- Only allowed file types: JPEG, PNG, GIF, WEBP, MP3, M4A
- Maximum file size: 50MB per file
- Filenames are automatically sanitized
- Directory traversal attempts are blocked
- CORS headers enabled for mobile/web apps

### 8. Testing the Endpoint

Test your endpoint with curl:
```bash
curl -X POST \
  -F "file=@/path/to/image.jpg" \
  -F "chatId=user1_user2" \
  -F "userId=user1" \
  -F "fileType=images" \
  https://yourdomain.com/upload.php
```

Expected response:
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "file_url": "https://yourdomain.com/uploads/chats/images/1234567890_user1_abc123.jpg",
  "file_path": "uploads/chats/images/1234567890_user1_abc123.jpg",
  "file_name": "1234567890_user1_abc123.jpg",
  "timestamp": 1234567890
}
```

### 9. Error Handling

Common error responses:
- `400`: No file provided or upload error
- `413`: File too large (max 50MB)
- `415`: File type not allowed
- `500`: Server-side error during save

## Troubleshooting

### Issue: "Upload failed with status 404"
- Solution: Check that `upload.php` is in the correct directory
- Make sure your domain URL is correct

### Issue: "Connection timeout"
- Solution: Check your PHP upload size limits
- Verify your server's file upload handler is working

### Issue: "Permission denied"
- Solution: Check server directory permissions
- Ensure `uploads/` directory is writable

## Support

For Hostinger support, visit: https://www.hostinger.com/support
