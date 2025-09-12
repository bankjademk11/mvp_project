import 'package:flutter/material.dart';

class CompanyLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final String companyName;
  final double size;
  final double borderRadius;

  const CompanyLogoWidget({
    super.key,
    this.logoUrl,
    required this.companyName,
    this.size = 48,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: size * 0.4, // Adjust font size based on widget size
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (logoUrl == null || logoUrl?.isEmpty == true) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return placeholder;
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }
}
