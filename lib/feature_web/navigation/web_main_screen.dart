import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';
import '../home/presentation/web_home_screen.dart';
import '../compounds/presentation/web_compounds_screen.dart';
import '../favorites/presentation/web_favorites_screen.dart';
import '../history/presentation/web_history_screen.dart';
import '../profile/presentation/web_profile_screen.dart';

class WebMainScreen extends StatefulWidget {
  static String routeName = '/web-main';

  const WebMainScreen({Key? key}) : super(key: key);

  @override
  State<WebMainScreen> createState() => _WebMainScreenState();
}

class _WebMainScreenState extends State<WebMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    WebHomeScreen(),
    const WebCompoundsScreen(),
    const WebFavoritesScreen(),
    WebHistoryScreen(),
    const WebProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildNavBar(),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFE6E6E6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                // Logo
                const Text(
                  '🏘️',
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 8),
                Text(
                  'Real Estate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainColor,
                  ),
                ),
                const Spacer(),

                // Navigation Links
                _buildNavItem('Home', 0, Icons.home_outlined, Icons.home),
                const SizedBox(width: 24),
                _buildNavItem('Compounds', 1, Icons.apartment_outlined, Icons.apartment),
                const SizedBox(width: 24),
                _buildNavItem('Favorites', 2, Icons.favorite_border, Icons.favorite),
                const SizedBox(width: 24),
                _buildNavItem('History', 3, Icons.history_outlined, Icons.history),
                const SizedBox(width: 24),
                _buildNavItem('Profile', 4, Icons.person_outline, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, int index, IconData outlinedIcon, IconData filledIcon) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              size: 20,
              color: isSelected ? AppColors.mainColor : const Color(0xFF666666),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.mainColor : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
