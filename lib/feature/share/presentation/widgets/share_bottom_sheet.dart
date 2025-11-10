import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/share_model.dart';
import '../../data/services/share_service.dart';

class ShareBottomSheet extends StatefulWidget {
  final String type; // 'unit' or 'compound'
  final String id;

  ShareBottomSheet({
    Key? key,
    required this.type,
    required this.id,
  }) : super(key: key);

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final ShareService _shareService = ShareService();
  bool _isLoading = true;
  String? _error;
  ShareData? _shareData;

  @override
  void initState() {
    super.initState();
    _loadShareLink();
  }

  Future<void> _loadShareLink() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _shareService.getShareLink(
        type: widget.type,
        id: widget.id,
      );

      setState(() {
        _shareData = response.share;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          MessageHelper.showError(context, 'Could not open link');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      MessageHelper.showSuccess(context, 'Link copied to clipboard!');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),

          // Title
          CustomText20(
            'Share ${widget.type == 'unit' ? 'Unit' : widget.type == 'compound' ? 'Compound' : 'Company'}',
            bold: true,
            color: AppColors.black,
          ),
          SizedBox(height: 20),

          // Content
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 12),
                  CustomText16(_error!, color: Colors.red, align: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadShareLink,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_shareData != null)
            Column(
              children: [
                // Share options
                _ShareOption(
                  icon: Icons.link,
                  label: 'Copy Link',
                  color: AppColors.mainColor,
                  onTap: () => _copyToClipboard(_shareData!.url),
                ),
                SizedBox(height: 12),
                _ShareOption(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: Color(0xFF25D366),
                  onTap: () => _launchUrl(_shareData!.whatsappUrl),
                ),
              ],
            ),

          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            CustomText16(label, bold: true, color: color),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
