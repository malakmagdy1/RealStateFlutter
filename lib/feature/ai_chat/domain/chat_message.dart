import 'package:equatable/equatable.dart';
import 'real_estate_product.dart';

/// Represents a single message in the chat
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final RealEstateProduct? product;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.product,
    this.isError = false,
  });

  @override
  List<Object?> get props => [id, content, isUser, timestamp, product, isError];

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    RealEstateProduct? product,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      product: product ?? this.product,
      isError: isError ?? this.isError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'product': product?.toJson(),
      'isError': isError,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      product: json['product'] != null
          ? RealEstateProduct.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      isError: json['isError'] as bool? ?? false,
    );
  }
}
