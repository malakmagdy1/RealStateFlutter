import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../compound/data/models/compound_model.dart';

class Location extends StatelessWidget {
  final Compound compound; // ✅ receive the compound object

  const Location({Key? key, required this.compound}) : super(key: key);

  Future<void> _openLocation() async {
    // If there's a location URL, use it directly
    if (compound.locationUrl != null && compound.locationUrl!.isNotEmpty) {
      final Uri uri = Uri.parse(compound.locationUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Otherwise use the location string
    final Uri googleMapsUri = Uri.parse('geo:0,0?q=${compound.location}');
    final Uri browserUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${compound.location}',
    );

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(browserUri)) {
      await launchUrl(browserUri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch ${compound.location}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openLocation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.mainColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.mainColor),
            const SizedBox(width: 8),
            Expanded(
              child: CustomText16(
                compound.location,
                color: AppColors.mainColor,
                bold: true,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mainColor),
          ],
        ),
      ),
    );
  }
}
