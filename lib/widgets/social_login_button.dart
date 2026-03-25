import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String? assetPath;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.text,
    this.assetPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          assetPath != null
              ? Image.asset(
                  assetPath!,
                  height: 24,
                  width: 24,
                )
              : const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 24,
                  color: Colors.blueAccent,
                ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
