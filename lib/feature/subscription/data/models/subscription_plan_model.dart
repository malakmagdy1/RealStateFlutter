class PlanFeature {
  final int id;
  final String feature;
  final String featureEn;
  final String? value;
  final String? valueEn;
  final int isIncluded;

  PlanFeature({
    required this.id,
    required this.feature,
    required this.featureEn,
    this.value,
    this.valueEn,
    required this.isIncluded,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      id: json['id'] as int,
      feature: json['feature'] as String? ?? '',
      featureEn: json['feature_en'] as String? ?? '',
      value: json['value'] as String?,
      valueEn: json['value_en'] as String?,
      isIncluded: json['is_included'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feature': feature,
      'feature_en': featureEn,
      'value': value,
      'value_en': valueEn,
      'is_included': isIncluded,
    };
  }
}

class SubscriptionPlanModel {
  final int id;
  final String name;
  final String nameEn;
  final String slug;
  final String? description;
  final String? descriptionEn;
  final double monthlyPrice;
  final double annualPrice;
  final int maxUsers;
  final int searchesAllowed; // -1 for unlimited
  final int validityDays; // -1 for unlimited
  final String? icon;
  final String? color;
  final String? badge;
  final String? badgeEn;
  final bool isFeatured;
  final bool isFreeModel;
  final List<PlanFeature> features;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.slug,
    this.description,
    this.descriptionEn,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.maxUsers,
    required this.searchesAllowed,
    required this.validityDays,
    this.icon,
    this.color,
    this.badge,
    this.badgeEn,
    required this.isFeatured,
    required this.isFreeModel,
    required this.features,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    // Helper function to parse price (handles both String and num)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Parse features array
    List<PlanFeature> parseFeatures(dynamic featuresData) {
      if (featuresData == null) return [];
      if (featuresData is List) {
        return featuresData
            .map((item) => PlanFeature.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return SubscriptionPlanModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      descriptionEn: json['description_en'] as String?,
      monthlyPrice: parsePrice(json['monthly_price']),
      annualPrice: parsePrice(json['yearly_price'] ?? json['annual_price']),
      maxUsers: json['max_users'] as int? ?? 1,
      searchesAllowed: json['search_limit'] ?? json['searches_allowed'] as int? ?? 0,
      validityDays: json['validity_days'] as int? ?? -1,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      badge: json['badge'] as String?,
      badgeEn: json['badge_en'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      isFreeModel: json['is_free'] as bool? ?? false,
      features: parseFeatures(json['features']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'slug': slug,
      'description': description,
      'description_en': descriptionEn,
      'monthly_price': monthlyPrice,
      'yearly_price': annualPrice,
      'max_users': maxUsers,
      'search_limit': searchesAllowed,
      'validity_days': validityDays,
      'icon': icon,
      'color': color,
      'badge': badge,
      'badge_en': badgeEn,
      'is_featured': isFeatured,
      'is_free': isFreeModel,
      'features': features.map((f) => f.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isUnlimited => searchesAllowed == -1;
  bool get isFree => monthlyPrice == 0;

  String getDisplayName(String locale) {
    return locale == 'ar' ? name : nameEn;
  }

  String? getDisplayDescription(String locale) {
    return locale == 'ar' ? description : descriptionEn;
  }

  String? getDisplayBadge(String locale) {
    return locale == 'ar' ? badge : badgeEn;
  }
}
