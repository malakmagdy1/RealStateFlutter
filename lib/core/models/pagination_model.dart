/// Pagination info model for API responses
class PaginationInfo {
  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginationInfo({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
      hasMore: json['has_more'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'per_page': perPage,
      'total': total,
      'total_pages': totalPages,
      'has_more': hasMore,
    };
  }

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage >= totalPages;

  /// Get the next page number (returns null if no more pages)
  int? get nextPage => hasMore ? currentPage + 1 : null;

  /// Get the previous page number (returns null if on first page)
  int? get previousPage => currentPage > 1 ? currentPage - 1 : null;

  @override
  String toString() {
    return 'PaginationInfo(currentPage: $currentPage, perPage: $perPage, total: $total, totalPages: $totalPages, hasMore: $hasMore)';
  }
}

/// Paginated response wrapper for any data type
class PaginatedResponse<T> {
  final bool success;
  final String? message;
  final List<T> data;
  final int total;
  final int count;
  final PaginationInfo pagination;

  PaginatedResponse({
    required this.success,
    this.message,
    required this.data,
    required this.total,
    required this.count,
    required this.pagination,
  });

  /// Check if there are more items to load
  bool get hasMore => pagination.hasMore;

  /// Get the current page
  int get currentPage => pagination.currentPage;

  /// Get total number of items
  int get totalItems => total;

  /// Get number of items in current response
  int get itemCount => count;

  @override
  String toString() {
    return 'PaginatedResponse(success: $success, total: $total, count: $count, pagination: $pagination)';
  }
}

/// Helper class for building pagination query parameters
class PaginationParams {
  final int page;
  final int limit;

  PaginationParams({
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      'page': page,
      'limit': limit,
    };
  }

  /// Create next page params
  PaginationParams nextPage() {
    return PaginationParams(page: page + 1, limit: limit);
  }

  /// Create first page params
  PaginationParams firstPage() {
    return PaginationParams(page: 1, limit: limit);
  }
}
