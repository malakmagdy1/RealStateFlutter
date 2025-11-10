import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_state.dart';

class WebProfileSettingsScreen extends StatefulWidget {
  static String routeName = '/web-profile-settings';

  @override
  State<WebProfileSettingsScreen> createState() => _WebProfileSettingsScreenState();
}

class _WebProfileSettingsScreenState extends State<WebProfileSettingsScreen> {
  String _selectedSection = 'Profile';

  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Notification preferences
  bool _propertyAlerts = true;
  bool _newsletter = false;
  bool _accountActivity = true;

  // Theme preference
  bool _isDarkMode = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            color: Colors.white,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Icon(Icons.location_city, color: AppColors.mainColor, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'RealtyFind',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                SizedBox(height: 16),

                // Navigation Items
                _buildNavItem(Icons.person_outline, 'Profile'),
                _buildNavItem(Icons.security_outlined, 'Security'),
                _buildNavItem(Icons.notifications_outlined, 'Notifications'),
                _buildNavItem(Icons.palette_outlined, 'Appearance'),
                _buildNavItem(Icons.history, 'Activity History'),

                Spacer(),

                // User Profile Section at bottom
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    String userName = 'John Doe';
                    String userEmail = 'john.doe@example.com';

                    if (state is UserSuccess) {
                      userName = state.user.name;
                      userEmail = state.user.email;
                    }

                    return Container(
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.mainColor.withOpacity(0.1),
                            child: Icon(Icons.person, color: AppColors.mainColor),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Title
                    Text(
                      'Profile Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage your profile, password, and notification preferences.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Content based on selected section
                    if (_selectedSection == 'Profile') _buildProfileSection(),
                    if (_selectedSection == 'Security') _buildSecuritySection(),
                    if (_selectedSection == 'Notifications') _buildNotificationsSection(),
                    if (_selectedSection == 'Appearance') _buildAppearanceSection(),
                    if (_selectedSection == 'Activity History') _buildActivityHistorySection(),

                    SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Save changes
                            MessageHelper.showSuccess(context, 'Changes saved successfully');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            // Cancel changes
                            context.pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title) {
    final isSelected = _selectedSection == title;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSection = title;
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mainColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.mainColor : Colors.grey[700],
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.mainColor : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Section
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.mainColor.withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: AppColors.mainColor),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'john.doe@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.upload, size: 16),
                        label: Text('Upload Picture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                      ),
                      SizedBox(width: 12),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Remove',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 32),
          Divider(),
          SizedBox(height: 32),

          // Form Fields
          Text(
            'Full Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: fullNameController,
            decoration: InputDecoration(
              hintText: 'John Doe',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.mainColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          SizedBox(height: 20),

          Text(
            'Email Address',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'john.doe@example.com',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.mainColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Choose a new password for your account.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          // Current Password
          Text(
            'Current Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: currentPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.mainColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm New Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Control how you receive notifications from us.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          _buildNotificationToggle(
            'Property Alerts',
            'Get notified about new properties matching your criteria.',
            _propertyAlerts,
            (value) {
              setState(() {
                _propertyAlerts = value;
              });
            },
          ),
          SizedBox(height: 20),
          _buildNotificationToggle(
            'Newsletter',
            'Receive our monthly real estate insights.',
            _newsletter,
            (value) {
              setState(() {
                _newsletter = value;
              });
            },
          ),
          SizedBox(height: 20),
          _buildNotificationToggle(
            'Account Activity',
            'Get notified about important account events.',
            _accountActivity,
            (value) {
              setState(() {
                _accountActivity = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.mainColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Customize the look and feel of the application.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          Text(
            'Theme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),

          // Theme Toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDarkMode = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: !_isDarkMode ? AppColors.mainColor.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_isDarkMode ? AppColors.mainColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: !_isDarkMode ? AppColors.mainColor : Colors.grey[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.light_mode,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Light',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: !_isDarkMode ? AppColors.mainColor : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDarkMode = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? AppColors.mainColor.withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDarkMode ? AppColors.mainColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? AppColors.mainColor : Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.dark_mode,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Dark',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isDarkMode ? AppColors.mainColor : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHistorySection() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View your recent account activity.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          Text(
            'Recent activities will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
