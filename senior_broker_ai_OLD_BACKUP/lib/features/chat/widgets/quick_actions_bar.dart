import 'package:flutter/material.dart';
import '../bloc/unified_chat_bloc.dart';

/// 🚀 Quick Actions Bar
/// Horizontal scrollable bar with common broker scenarios
class QuickActionsBar extends StatelessWidget {
  final Function(AdviceType) onActionTap;
  
  const QuickActionsBar({
    super.key,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    final actions = [
      _QuickAction(
        icon: Icons.person_add_rounded,
        label: isArabic ? 'عميل جديد' : 'New Client',
        type: AdviceType.newClient,
        color: const Color(0xFF4CAF50),
      ),
      _QuickAction(
        icon: Icons.gavel_rounded,
        label: isArabic ? 'تفاوض السعر' : 'Price Negotiation',
        type: AdviceType.negotiation,
        color: const Color(0xFFFF9800),
      ),
      _QuickAction(
        icon: Icons.block_rounded,
        label: isArabic ? 'اعتراضات' : 'Objections',
        type: AdviceType.handleObjection,
        color: const Color(0xFFF44336),
      ),
      _QuickAction(
        icon: Icons.handshake_rounded,
        label: isArabic ? 'إقفال صفقة' : 'Close Deal',
        type: AdviceType.closeDeal,
        color: const Color(0xFF2196F3),
      ),
      _QuickAction(
        icon: Icons.trending_up_rounded,
        label: isArabic ? 'استثمار' : 'Investment',
        type: AdviceType.investment,
        color: const Color(0xFF9C27B0),
      ),
      _QuickAction(
        icon: Icons.phone_callback_rounded,
        label: isArabic ? 'متابعة' : 'Follow Up',
        type: AdviceType.followUp,
        color: const Color(0xFF00BCD4),
      ),
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isArabic ? '💡 اسألني عن:' : '💡 Ask me about:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionChip(context, action);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, _QuickAction action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => onActionTap(action.type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: action.color.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                color: action.color,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: action.color.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final AdviceType type;
  final Color color;
  
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.type,
    required this.color,
  });
}
