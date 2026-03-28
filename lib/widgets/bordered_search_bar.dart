import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class BorderedSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  
  const BorderedSearchBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(isDark ? 0.3 : 0.1),
            width: 1.5,
          ),
          color: Theme.of(context).cardColor.withOpacity(0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.search_normal,
              size: 18,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(width: 10),
            Text(
              'Search',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
