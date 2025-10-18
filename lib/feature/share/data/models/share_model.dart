class ShareData {
  final String url;
  final String title;
  final String description;
  final String? image;
  final String whatsappUrl;
  final String facebookUrl;
  final String twitterUrl;
  final String emailUrl;

  ShareData({
    required this.url,
    required this.title,
    required this.description,
    this.image,
    required this.whatsappUrl,
    required this.facebookUrl,
    required this.twitterUrl,
    required this.emailUrl,
  });

  factory ShareData.fromJson(Map<String, dynamic> json) {
    return ShareData(
      url: json['url']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString(),
      whatsappUrl: json['whatsapp_url']?.toString() ?? '',
      facebookUrl: json['facebook_url']?.toString() ?? '',
      twitterUrl: json['twitter_url']?.toString() ?? '',
      emailUrl: json['email_url']?.toString() ?? '',
    );
  }
}

class ShareResponse {
  final bool success;
  final String type;
  final Map<String, dynamic> data;
  final ShareData share;

  ShareResponse({
    required this.success,
    required this.type,
    required this.data,
    required this.share,
  });

  factory ShareResponse.fromJson(Map<String, dynamic> json) {
    return ShareResponse(
      success: json['success'] == true,
      type: json['type']?.toString() ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      share: ShareData.fromJson(json['share'] as Map<String, dynamic>),
    );
  }
}
