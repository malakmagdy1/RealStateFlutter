import 'package:flutter/material.dart';

class UpdateItem {
  final String type; // 'unit', 'compound', 'company'
  final int id;
  final String action; // 'created', 'updated', 'deleted'
  final String itemName;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  UpdateItem({
    required this.type,
    required this.id,
    required this.action,
    required this.itemName,
    this.description,
    required this.timestamp,
    this.details,
  });

  factory UpdateItem.fromJson(Map<String, dynamic> json) {
    return UpdateItem(
      type: json['type'] as String? ?? 'unknown',
      id: json['id'] as int? ?? 0,
      action: json['action'] as String? ?? 'updated',
      itemName: json['item_name'] as String? ?? 'Item',
      description: json['description'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  IconData get icon {
    switch (type) {
      case 'unit':
        return Icons.home;
      case 'compound':
        return Icons.apartment;
      case 'company':
        return Icons.business;
      default:
        return Icons.update;
    }
  }

  Color get color {
    switch (action) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get actionText {
    switch (action) {
      case 'created':
        return 'New';
      case 'updated':
        return 'Updated';
      case 'deleted':
        return 'Removed';
      default:
        return 'Changed';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'action': action,
      'item_name': itemName,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}
