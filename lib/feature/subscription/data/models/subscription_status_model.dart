class SubscriptionStatusModel {
  final bool hasActiveSubscription;
  final bool canSearch;
  final int searchesUsed;
  final int remainingSearches;
  final int searchLimit;
  final String? expiresAt;
  final String planName;
  final String planNameEn;

  SubscriptionStatusModel({
    required this.hasActiveSubscription,
    required this.canSearch,
    required this.searchesUsed,
    required this.remainingSearches,
    required this.searchLimit,
    this.expiresAt,
    required this.planName,
    required this.planNameEn,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      hasActiveSubscription: json['has_active_subscription'] ?? false,
      canSearch: json['can_search'] ?? false,
      searchesUsed: json['searches_used'] ?? 0,
      remainingSearches: json['remaining_searches'] ?? 0,
      searchLimit: json['search_limit'] ?? 0,
      expiresAt: json['expires_at'],
      planName: json['plan_name'] ?? '',
      planNameEn: json['plan_name_en'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_active_subscription': hasActiveSubscription,
      'can_search': canSearch,
      'searches_used': searchesUsed,
      'remaining_searches': remainingSearches,
      'search_limit': searchLimit,
      'expires_at': expiresAt,
      'plan_name': planName,
      'plan_name_en': planNameEn,
    };
  }

  bool get hasUnlimitedSearches => searchLimit == -1;
  bool get isUnlimited => searchLimit == -1;
  int get searchesAllowed => searchLimit;

  int get searchesRemaining {
    if (hasUnlimitedSearches) return -1;
    return remainingSearches;
  }

  bool get hasSearchesLeft {
    if (hasUnlimitedSearches) return true;
    return remainingSearches > 0;
  }

  /// Check if subscription is expired
  bool get isExpired {
    if (expiresAt == null || expiresAt!.isEmpty) return false;
    try {
      final expirationDate = DateTime.parse(expiresAt!);
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      return false;
    }
  }
}
