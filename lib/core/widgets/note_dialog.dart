import 'package:flutter/material.dart';
import 'package:real/core/utils/colors.dart';

class NoteDialog extends StatefulWidget {
  final String? initialNote;
  final String title;

  const NoteDialog({
    Key? key,
    this.initialNote,
    this.title = 'Add Note',
  }) : super(key: key);

  @override
  State<NoteDialog> createState() => _NoteDialogState();

  static Future<String?> show(
    BuildContext context, {
    String? initialNote,
    String title = 'Add Note',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => NoteDialog(
        initialNote: initialNote,
        title: title,
      ),
    );
  }
}

class _NoteDialogState extends State<NoteDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.note_add, color: AppColors.mainColor),
          SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Enter your notes here...\n\ne.g., "Great location, near schools"\n"Check payment plan"\n"Schedule viewing for weekend"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        if (widget.initialNote != null && widget.initialNote!.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear'),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _controller.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mainColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Save'),
        ),
      ],
    );
  }
}
