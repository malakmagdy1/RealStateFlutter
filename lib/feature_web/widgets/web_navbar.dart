import 'package:flutter/material.dart';

class WebNavbar extends StatelessWidget {
  WebNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
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
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                // Logo
                Text(
                  '🏘️',
                  style: TextStyle(fontSize: 28),
                ),
                SizedBox(width: 8),
                Text(
                  'Real Estate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E4164),
                  ),
                ),
                SizedBox(width: 32),

                // Search Bar
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 600),
                    height: 42,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for companies, compounds, or units...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E8E),
                        ),
                        filled: true,
                        fillColor: Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFFE6E6E6),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFF1E4164),
                            width: 1,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        suffixIcon: Container(
                          margin: EdgeInsets.all(4),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF5E00),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: Text(
                              'Search',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 32),

                // Navigation Links
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                SizedBox(width: 32),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Browse',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
