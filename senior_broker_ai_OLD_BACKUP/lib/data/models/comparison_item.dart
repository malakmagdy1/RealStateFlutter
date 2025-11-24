/// Model for items to be compared
class ComparisonItem {
  final String id;
  final String name;
  final String type; // 'unit', 'compound', 'company'
  final Map<String, dynamic> data;
  
  const ComparisonItem({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
  });
  
  /// Create from unit data
  factory ComparisonItem.fromUnit(Map<String, dynamic> unit) {
    return ComparisonItem(
      id: unit['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: unit['name'] ?? unit['unit_name'] ?? 'Unknown Unit',
      type: 'unit',
      data: {
        'price': unit['price'],
        'area': unit['area'],
        'bedrooms': unit['bedrooms'],
        'bathrooms': unit['bathrooms'],
        'compound_name': unit['compound_name'],
        'company_name': unit['company_name'] ?? unit['developer'],
        'location': unit['location'],
        'finishing': unit['finishing'],
        'status': unit['status'],
        'floor': unit['floor'],
        'view': unit['view'],
        'garden_area': unit['garden_area'],
        'roof_area': unit['roof_area'],
        'down_payment': unit['down_payment'],
        'installment_years': unit['installment_years'],
        'delivery_date': unit['delivery_date'],
      },
    );
  }
  
  /// Create from compound data
  factory ComparisonItem.fromCompound(Map<String, dynamic> compound) {
    return ComparisonItem(
      id: compound['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: compound['name'] ?? compound['compound_name'] ?? 'Unknown Compound',
      type: 'compound',
      data: {
        'location': compound['location'],
        'company_name': compound['company_name'] ?? compound['developer'],
        'units_count': compound['units_count'] ?? compound['total_units'],
        'available_units': compound['available_units'],
        'status': compound['status'],
        'min_price': compound['min_price'],
        'max_price': compound['max_price'],
        'amenities': compound['amenities'],
        'description': compound['description'],
      },
    );
  }
  
  /// Create from company data
  factory ComparisonItem.fromCompany(Map<String, dynamic> company) {
    return ComparisonItem(
      id: company['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: company['name'] ?? company['company_name'] ?? 'Unknown Company',
      type: 'company',
      data: {
        'number_of_compounds': company['number_of_compounds'] ?? company['compounds_count'],
        'number_of_units': company['number_of_units'] ?? company['total_units'],
        'founded_year': company['founded_year'],
        'headquarters': company['headquarters'],
        'reputation': company['reputation'],
        'description': company['description'],
      },
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'data': data,
    };
  }
  
  /// Create from JSON
  factory ComparisonItem.fromJson(Map<String, dynamic> json) {
    return ComparisonItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComparisonItem && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  /// Get formatted price
  String get formattedPrice {
    final price = data['price'];
    if (price == null) return 'N/A';
    try {
      final numPrice = double.parse(price.toString());
      if (numPrice >= 1000000) {
        return '${(numPrice / 1000000).toStringAsFixed(2)}M EGP';
      } else if (numPrice >= 1000) {
        return '${(numPrice / 1000).toStringAsFixed(0)}K EGP';
      }
      return '${numPrice.toStringAsFixed(0)} EGP';
    } catch (e) {
      return price.toString();
    }
  }
  
  /// Get formatted area
  String get formattedArea {
    final area = data['area'];
    if (area == null) return 'N/A';
    return '$area m²';
  }
  
  /// Get price per sqm
  String get pricePerSqm {
    final price = data['price'];
    final area = data['area'];
    if (price == null || area == null) return 'N/A';
    try {
      final numPrice = double.parse(price.toString());
      final numArea = double.parse(area.toString());
      if (numArea == 0) return 'N/A';
      return '${(numPrice / numArea).toStringAsFixed(0)} EGP/m²';
    } catch (e) {
      return 'N/A';
    }
  }
  
  /// Get localized type name
  String getLocalizedType(String lang) {
    if (lang == 'ar') {
      switch (type) {
        case 'unit': return 'وحدة عقارية';
        case 'compound': return 'كمباوند';
        case 'company': return 'شركة تطوير';
        default: return type;
      }
    } else {
      switch (type) {
        case 'unit': return 'Property Unit';
        case 'compound': return 'Compound';
        case 'company': return 'Developer';
        default: return type;
      }
    }
  }
}
