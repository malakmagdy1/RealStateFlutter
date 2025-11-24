import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real/feature/ai_chat/data/services/comparison_list_service.dart';
import 'package:real/feature/ai_chat/data/models/comparison_item.dart';

class WebNavbar extends StatelessWidget {
  WebNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE6E6E6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Logo
                Text(
                  '🏘️',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(width: 6),
                Text(
                  'Real Estate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E4164),
                  ),
                ),
                SizedBox(width: 20),

                // Search Bar
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 600),
                    height: 34,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for companies, compounds, or units...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E8E),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: Color(0xFF1E4164),
                            width: 1,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        suffixIcon: Container(
                          margin: EdgeInsets.all(3),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF5E00),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              'Search',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),

                // Navigation Links
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Browse',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // AI Assistant Button with Badge
                StreamBuilder<List<ComparisonItem>>(
                  stream: ComparisonListService().comparisonStream,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    final count = items.length;

                    return Badge(
                      label: Text('$count'),
                      isLabelVisible: count > 0,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/sales-assistant');
                        },
                        icon: Icon(Icons.smart_toy, size: 16),
                        label: Text(
                          'AI Assistant',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF5E00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
