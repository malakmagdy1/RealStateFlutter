import 'package:equatable/equatable.dart';
import '../../compound/data/models/unit_model.dart';
import '../../compound/data/models/compound_model.dart';

/// Represents a single message in the chat
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Unit? unit; // Database unit model
  final Compound? compound; // Database compound model
  final bool isError;
  final String debugInfo;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.unit,
    this.compound,
    this.isError = false,
    this.debugInfo = '',
  });

  @override
  List<Object?> get props => [id, content, isUser, timestamp, unit, compound, isError, debugInfo];

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    Unit? unit,
    Compound? compound,
    bool? isError,
    String? debugInfo,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      unit: unit ?? this.unit,
      compound: compound ?? this.compound,
      isError: isError ?? this.isError,
      debugInfo: debugInfo ?? this.debugInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'unit': unit?.toJson(),
      'compound': compound?.toJson(),
      'isError': isError,
      'debugInfo': debugInfo,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      unit: json['unit'] != null
          ? Unit.fromJson(json['unit'] as Map<String, dynamic>)
          : null,
      compound: json['compound'] != null
          ? Compound.fromJson(json['compound'] as Map<String, dynamic>)
          : null,
      isError: json['isError'] as bool? ?? false,
      debugInfo: json['debugInfo'] as String? ?? '',
    );
  }
}
