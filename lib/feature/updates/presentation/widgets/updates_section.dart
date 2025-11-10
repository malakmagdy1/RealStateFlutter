import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:real/feature/updates/data/models/update_model.dart';
import 'package:real/feature/updates/data/web_services/updates_web_services.dart';

class UpdatesSection extends StatefulWidget {
  const UpdatesSection({Key? key}) : super(key: key);

  @override
  State<UpdatesSection> createState() => _UpdatesSectionState();
}

class _UpdatesSectionState extends State<UpdatesSection> {
  List<UpdateItem> _updates = [];
  bool _isLoading = true;
  final UpdatesWebServices _webServices = UpdatesWebServices();

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    try {
      final updatesData = await _webServices.getRecentUpdates(
        hours: 24,
        type: 'all',
        limit: 10,
      );

      setState(() {
        _updates = updatesData
            .map((data) => UpdateItem.fromJson(data))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('[UPDATES WIDGET] Error loading updates: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
          ),
        ),
      );
    }

    if (_updates.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.update, color: AppColors.mainColor, size: 24),
                  SizedBox(width: 8),
                  CustomText20('Recent Updates', bold: true),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_updates.length} new',
                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _updates.length,
            itemBuilder: (context, index) {
              final update = _updates[index];
              return _buildUpdateCard(update);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCard(UpdateItem update) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shadowColor: update.color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: update.color.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to item details
            MessageHelper.showMessage(
              context: context,
              message: 'Opening ${update.itemName}...',
              isSuccess: true,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and badge
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: update.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        update.icon,
                        color: update.color,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: update.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        update.actionText.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                  ],
                ),
                SizedBox(height: 12),
                // Title
                Text(
                  update.itemName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                // Description
                if (update.description != null && update.description!.isNotEmpty)
                  Text(
                    update.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Spacer(),
                // Time ago
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      timeago.format(update.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
