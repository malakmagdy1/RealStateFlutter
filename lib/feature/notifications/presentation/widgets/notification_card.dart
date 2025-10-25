import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  NotificationCard({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  IconData _getIconByType(String type) {
    switch (type) {
      case 'sale':
        return Icons.local_offer;
      case 'unit':
        return Icons.apartment;
      case 'compound':
        return Icons.location_city;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorByType(String type) {
    switch (type) {
      case 'sale':
        return Colors.orange;
      case 'unit':
        return Colors.blue;
      case 'compound':
        return Colors.green;
      default:
        return AppColors.mainColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (onDelete != null) {
          onDelete!();
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.mainColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : AppColors.mainColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getColorByType(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconByType(notification.type),
                      color: _getColorByType(notification.type),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.greyText,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.greyText,
                            ),
                            SizedBox(width: 4),
                            Text(
                              timeago.format(notification.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.greyText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: () {
                      _showOptionsDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(
                notification.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                color: AppColors.mainColor,
              ),
              title: Text(
                notification.isRead ? l10n.markAsUnread : l10n.markAsRead,
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                // Handle mark as read/unread
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: Text(
                l10n.delete,
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onDelete != null) {
                  onDelete!();
                }
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
