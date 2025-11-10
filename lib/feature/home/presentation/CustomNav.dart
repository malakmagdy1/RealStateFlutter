import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/login_event.dart';
import 'package:real/feature/auth/presentation/bloc/login_state.dart';
import 'package:real/feature/auth/presentation/bloc/user_bloc.dart';
import 'package:real/feature/auth/presentation/bloc/user_state.dart';
import 'package:real/feature/auth/presentation/screen/loginScreen.dart';
import 'package:real/feature/auth/presentation/screen/blocked_user_screen.dart';
import 'package:real/feature/home/presentation/profileScreen.dart';

import '../../../core/utils/text_style.dart';
import 'FavoriteScreen.dart';
import 'HistoryScreen.dart';
import 'homeScreen.dart';
import '../../notifications/presentation/screens/notifications_screen.dart';
import '../../compound/presentation/screen/compounds_screen.dart';
import '../../subscription/presentation/screens/subscription_plans_screen.dart';

class CustomNav extends StatefulWidget {
  static String routeName = '/nav';

  @override
  State<CustomNav> createState() => _CustomNavState();
}

class _CustomNavState extends State<CustomNav> {
  int _selectedIndex = 0;

  final List<Widget> widgetOptions = [
    HomeScreen(),
    CompoundsScreen(),
    FavoriteScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer

    // Capture the LoginBloc before showing the dialog
    final loginBloc = context.read<LoginBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                loginBloc.add(LogoutEvent());
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 👇 get screen width & height
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return MultiBlocListener(
      listeners: [
        // Listen to logout events
        BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
              MessageHelper.showSuccess(context, state.message);
            } else if (state is LogoutError) {
              MessageHelper.showError(context, state.message);
            }
          },
        ),
        // Listen to user status changes to check if banned or not verified
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserSuccess) {
              // Check if user is banned
              if (state.user.isBanned) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => BlockedUserScreen(
                      reason: 'Account Banned',
                      message: 'Your account has been banned. Please contact support for more information.',
                      icon: Icons.block,
                      iconColor: Colors.red,
                    ),
                  ),
                  (route) => false,
                );
              }
              // Check if user is not verified
              else if (!state.user.isVerified) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => BlockedUserScreen(
                      reason: 'Account Not Verified',
                      message: 'Your account is not verified yet. Please check your email or contact support to verify your account.',
                      icon: Icons.email_outlined,
                      iconColor: Colors.orange,
                    ),
                  ),
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, NotificationsScreen.routeName);
              },
              icon: Icon(
                Icons.notifications,
                color: AppColors.mainColor,
                size: screenWidth * 0.05,
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppColors.mainColor),
                child: BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state is UserSuccess) {
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: screenWidth * 0.08,
                            child: Text(
                              state.user.name.isNotEmpty
                                  ? state.user.name[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText20(
                                  state.user.name,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  state.user.email,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: screenWidth * 0.08,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        CustomText20("user name", color: Colors.white),
                      ],
                    );
                  },
                ),
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.home_outlined,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16("home", color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.person_3_outlined,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16("profile", color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16("Compounds", color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.favorite_border_outlined,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16("favorite", color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              ListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: AppColors.mainColor,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    CustomText16("Subscription", color: AppColors.mainColor),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Close drawer
                  Navigator.pushNamed(
                    context,
                    SubscriptionPlansScreen.routeName,
                  );
                },
              ),
              Divider(),
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  if (state is LogoutLoading) {
                    return ListTile(
                      title: Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      ),
                    );
                  }
                  return ListTile(
                    title: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: screenWidth * 0.06,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        CustomText16("Logout", color: Colors.red),
                      ],
                    ),
                    onTap: () => _handleLogout(context),
                  );
                },
              ),
            ],
          ),
        ),
        body: widgetOptions[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenHeight * 0.01,
              ),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: screenWidth * 0.01,
                color: AppColors.mainColor,
                // inactive icon color
                activeColor: Colors.white,
                // active icon color
                iconSize: screenWidth * 0.06,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.012,
                ),
                duration: Duration(milliseconds: 400),
                tabBackgroundColor: AppColors.mainColor.withOpacity(0.9),
                // highlight color (main color)
                tabBorderRadius: 12,
                // decrease radius of background bubble
                tabs: [
                  GButton(icon: Icons.home_outlined,),
                  GButton(icon: Icons.business, ),
                  GButton(
                    icon: Icons.favorite_border_outlined,
                  ),
                  GButton(icon: Icons.history, ),
                  GButton(icon: Icons.person_2_outlined),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
