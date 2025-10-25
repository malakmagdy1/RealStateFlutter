import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/l10n/app_localizations.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_cache_service.dart';
import '../widgets/notification_card.dart';
import 'package:real/feature/compound/data/models/unit_model.dart';
import 'package:real/feature/compound/presentation/screen/unit_detail_screen.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';
import 'package:real/feature/home/presentation/CompoundScreen.dart';

class NotificationsScreen extends StatefulWidget {
  static String routeName = '/notifications';

  NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  final NotificationCacheService _cacheService = NotificationCacheService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load notifications from cache
  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final cachedNotifications = await _cacheService.getAllNotifications();
      setState(() {
        notifications = cachedNotifications;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<NotificationModel> _getFilteredNotifications(String filter) {
    if (filter == 'all') {
      return notifications;
    } else if (filter == 'unread') {
      return notifications.where((n) => !n.isRead).toList();
    } else {
      return notifications.where((n) => n.type == filter).toList();
    }
  }

  int _getUnreadCount() {
    return notifications.where((n) => !n.isRead).toList().length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        title: Text(
          l10n.notifications,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            onPressed: () async {
              await _cacheService.markAllAsRead();
              await _loadNotifications();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.markedAllAsRead),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            tooltip: l10n.markAllAsRead,
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () {
              _showClearAllDialog();
            },
            tooltip: l10n.clearAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.all),
                  if (_getUnreadCount() > 0) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_getUnreadCount()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: l10n.sales),
            Tab(text: l10n.units),
            Tab(text: l10n.updates),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList('all'),
          _buildNotificationsList('sale'),
          _buildNotificationsList('unit'),
          _buildNotificationsList('compound'),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(String filter) {
    final l10n = AppLocalizations.of(context)!;
    final filteredNotifications = _getFilteredNotifications(filter);

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              l10n.noNotifications,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.greyText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              l10n.allCaughtUp,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyText,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.mainColor,
      onRefresh: () async {
        await _loadNotifications();
      },
      child: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.mainColor,
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                return NotificationCard(
                  notification: notification,
                  onTap: () async {
                    // Mark as read in cache
                    await _cacheService.markAsRead(notification.id);
                    await _loadNotifications();
                    if (mounted) {
                      _showNotificationDetails(notification);
                    }
                  },
                  onDelete: () async {
                    // Delete from cache
                    await _cacheService.deleteNotification(notification.id);
                    await _loadNotifications();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.notificationDeleted),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.greyText,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  if (notification.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        notification.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(Icons.image, size: 50),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToDetails(notification);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.viewDetails,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to appropriate screen based on notification type
  void _navigateToDetails(NotificationModel notification) {
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case 'sale':
      case 'unit':
        // Navigate to unit details
        final unitId = data['unit_id'] ?? data['id'];
        if (unitId != null) {
          _navigateToUnitDetails(unitId.toString());
        }
        break;

      case 'compound':
        // Navigate to compound details
        final compoundId = data['compound_id'] ?? data['id'];
        if (compoundId != null) {
          _navigateToCompoundDetails(compoundId.toString());
        }
        break;

      case 'general':
      default:
        // For general notifications, just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noDetailsAvailable),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  /// Navigate to UnitDetailScreen with minimal data
  /// The detail screen will load full data when opened
  void _navigateToUnitDetails(String unitId) {
    // Try to find the notification with this unit ID
    NotificationModel? foundNotification;
    try {
      foundNotification = notifications.firstWhere(
        (n) => n.data?['unit_id']?.toString() == unitId || n.data?['id']?.toString() == unitId,
      );
    } catch (e) {
      // Notification not found, use null
      foundNotification = null;
    }

    final data = foundNotification?.data;

    // Create a minimal Unit object from notification data
    final unit = Unit(
      id: unitId,
      compoundId: data?['compound_id']?.toString() ?? '',
      unitType: data?['unit_type']?.toString() ?? 'Unit',
      area: data?['area']?.toString() ?? '0',
      price: data?['price']?.toString() ?? '0',
      bedrooms: data?['bedrooms']?.toString() ?? '0',
      bathrooms: data?['bathrooms']?.toString() ?? '0',
      floor: data?['floor']?.toString() ?? '0',
      status: data?['status']?.toString() ?? 'available',
      unitNumber: data?['unit_number']?.toString() ?? '',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      images: data?['images'] != null ? List<String>.from(data!['images']) : [],
      usageType: data?['usage_type']?.toString(),
      companyName: data?['company_name']?.toString(),
      companyLogo: data?['company_logo']?.toString(),
    );

    // Navigate to unit detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnitDetailScreen(unit: unit),
      ),
    );
  }

  /// Navigate to CompoundScreen with minimal data
  void _navigateToCompoundDetails(String compoundId) {
    // Try to find the notification with this compound ID
    NotificationModel? foundNotification;
    try {
      foundNotification = notifications.firstWhere(
        (n) => n.data?['compound_id']?.toString() == compoundId || n.data?['id']?.toString() == compoundId,
      );
    } catch (e) {
      // Notification not found, use null
      foundNotification = null;
    }

    final data = foundNotification?.data;

    // Create a minimal Compound object from notification data
    final compound = Compound(
      id: data?['id']?.toString() ?? compoundId,
      companyId: data?['company_id']?.toString() ?? '',
      project: data?['compound_name']?.toString() ?? data?['name']?.toString() ?? data?['project']?.toString() ?? 'Compound',
      location: data?['location']?.toString() ?? '',
      images: data?['images'] != null ? List<String>.from(data!['images']) : [],
      builtUpArea: data?['built_up_area']?.toString() ?? '0',
      howManyFloors: data?['how_many_floors']?.toString() ?? '0',
      plannedDeliveryDate: data?['delivery_date']?.toString() ?? data?['planned_delivery_date']?.toString(),
      club: data?['club']?.toString() ?? '0',
      isSold: data?['is_sold']?.toString() ?? '0',
      status: data?['status']?.toString() ?? 'in_progress',
      totalUnits: data?['total_units']?.toString() ?? '0',
      createdAt: data?['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: data?['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      companyName: data?['company_name']?.toString() ?? data?['developer']?.toString() ?? '',
      companyLogo: data?['company_logo']?.toString(),
      soldUnits: data?['sold_units']?.toString() ?? '0',
      availableUnits: data?['available_units']?.toString() ?? '0',
      sales: [],
    );

    // Navigate to compound screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompoundScreen(compound: compound),
      ),
    );
  }

  void _showClearAllDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllNotifications),
        content: Text(l10n.clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              // Clear all notifications from cache
              await _cacheService.clearAllNotifications();
              await _loadNotifications();

              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.allNotificationsCleared),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(
              l10n.clearAll,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
