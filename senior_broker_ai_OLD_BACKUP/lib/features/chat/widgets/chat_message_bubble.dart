import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bloc/unified_chat_state.dart';

/// 💬 Chat Message Bubble Widget
/// Beautiful, RTL-aware message bubbles
class ChatMessageBubble extends StatelessWidget {
  final UnifiedChatMessage message;
  
  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context, isArabic),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getBubbleColor(),
                  borderRadius: _getBorderRadius(),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    SelectableText(
                      message.content,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      textDirection: _detectTextDirection(message.content),
                    ),
                    const SizedBox(height: 6),
                    // Timestamp
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: message.isUser 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[500],
                      ),
                    ),
                    // Property cards if available
                    if (message.hasProperties) ...[
                      const SizedBox(height: 12),
                      _buildPropertyCards(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isError 
            ? Colors.red.withOpacity(0.2)
            : const Color(0xFF1E3A5F).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        message.isError 
            ? Icons.error_outline_rounded
            : Icons.support_agent_rounded,
        size: 18,
        color: message.isError ? Colors.red : const Color(0xFF1E3A5F),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 18,
        color: Colors.grey,
      ),
    );
  }

  Color _getBubbleColor() {
    if (message.isError) return Colors.red.shade50;
    if (message.isUser) return const Color(0xFF1E3A5F);
    return Colors.white;
  }

  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(16);
    const smallRadius = Radius.circular(4);
    
    if (message.isUser) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: smallRadius,
      );
    } else {
      return const BorderRadius.only(
        topLeft: smallRadius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      );
    }
  }

  TextDirection _detectTextDirection(String text) {
    // Check if text starts with Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    if (text.isNotEmpty && arabicRegex.hasMatch(text.substring(0, 1))) {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildPropertyCards(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: message.units!.length,
        itemBuilder: (context, index) {
          final unit = message.units![index];
          return _buildPropertyCard(context, unit);
        },
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, Map<String, dynamic> unit) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unit['name'] ?? 'Unit',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (unit['price'] != null)
            _buildPropertyDetail(Icons.attach_money, '${unit['price']} EGP'),
          if (unit['area'] != null)
            _buildPropertyDetail(Icons.square_foot, '${unit['area']} m²'),
          if (unit['bedrooms'] != null)
            _buildPropertyDetail(Icons.bed, '${unit['bedrooms']} beds'),
          const Spacer(),
          // View details button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // Navigate to unit details
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(isArabic ? 'نسخ' : 'Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isArabic ? 'تم النسخ' : 'Copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            if (!message.isUser)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(isArabic ? 'إعادة المحاولة' : 'Regenerate'),
                onTap: () {
                  Navigator.pop(context);
                  // Trigger regeneration
                },
              ),
          ],
        ),
      ),
    );
  }
}
