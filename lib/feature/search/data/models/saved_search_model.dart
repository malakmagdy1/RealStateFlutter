import 'package:equatable/equatable.dart';
import 'search_filter_model.dart';

class SavedSearch extends Equatable {
  final String id;
  final String userId;
  final String name;
  final SearchFilter searchParameters;
  final String? createdAt;
  final String? updatedAt;

  const SavedSearch({
    required this.id,
    required this.userId,
    required this.name,
    required this.searchParameters,
    this.createdAt,
    this.updatedAt,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      searchParameters: json['search_parameters'] != null
          ? SearchFilter.fromJson(json['search_parameters'] as Map<String, dynamic>)
          : SearchFilter.empty(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'search_parameters': searchParameters.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [id, userId, name, searchParameters, createdAt, updatedAt];

  @override
  String toString() {
    return 'SavedSearch{id: $id, userId: $userId, name: $name, searchParameters: $searchParameters}';
  }
}

class SavedSearchResponse extends Equatable {
  final bool success;
  final String? message;
  final SavedSearch? savedSearch;
  final List<SavedSearch>? savedSearches;

  const SavedSearchResponse({
    required this.success,
    this.message,
    this.savedSearch,
    this.savedSearches,
  });

  factory SavedSearchResponse.fromJson(Map<String, dynamic> json) {
    // For single saved search response
    if (json['data'] != null && json['data'] is Map) {
      return SavedSearchResponse(
        success: json['success'] == true || json['success'] == 1,
        message: json['message']?.toString(),
        savedSearch: SavedSearch.fromJson(json['data'] as Map<String, dynamic>),
      );
    }

    // For list of saved searches response
    if (json['data'] != null && json['data'] is List) {
      return SavedSearchResponse(
        success: json['success'] == true || json['success'] == 1,
        message: json['message']?.toString(),
        savedSearches: (json['data'] as List<dynamic>)
            .map((item) => SavedSearch.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    // For delete/success response without data
    return SavedSearchResponse(
      success: json['success'] == true || json['success'] == 1,
      message: json['message']?.toString(),
    );
  }

  @override
  List<Object?> get props => [success, message, savedSearch, savedSearches];

  @override
  String toString() {
    return 'SavedSearchResponse{success: $success, message: $message, '
        'savedSearch: $savedSearch, savedSearches: ${savedSearches?.length}}';
  }
}

class CreateSavedSearchRequest {
  final String userId;
  final String name;
  final Map<String, dynamic> searchParameters;

  const CreateSavedSearchRequest({
    required this.userId,
    required this.name,
    required this.searchParameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'search_parameters': searchParameters,
    };
  }
}

class UpdateSavedSearchRequest {
  final String? name;
  final Map<String, dynamic>? searchParameters;

  const UpdateSavedSearchRequest({
    this.name,
    this.searchParameters,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) {
      data['name'] = name;
    }
    if (searchParameters != null) {
      data['search_parameters'] = searchParameters;
    }
    return data;
  }
}
