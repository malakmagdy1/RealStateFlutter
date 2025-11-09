import 'package:equatable/equatable.dart';

/// Represents a real estate property returned by the AI
class RealEstateProduct extends Equatable {
  final String type; // "unit" or "compound"
  final int? id;
  final String name;
  final String location;
  final String propertyType;
  final String price;
  final String? area;
  final String? bedrooms;
  final String? bathrooms;
  final List<String> features;
  final String? imagePath;
  final String? description;

  const RealEstateProduct({
    required this.type,
    this.id,
    required this.name,
    required this.location,
    required this.propertyType,
    required this.price,
    this.area,
    this.bedrooms,
    this.bathrooms,
    required this.features,
    this.imagePath,
    this.description,
  });

  @override
  List<Object?> get props => [
        type,
        id,
        name,
        location,
        propertyType,
        price,
        area,
        bedrooms,
        bathrooms,
        features,
        imagePath,
        description,
      ];

  factory RealEstateProduct.fromJson(Map<String, dynamic> json) {
    return RealEstateProduct(
      type: json['type']?.toString() ?? 'unit',
      id: json['id'] is int ? json['id'] as int : null,
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      propertyType: json['propertyType']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      area: json['area']?.toString(),
      bedrooms: json['bedrooms']?.toString(),
      bathrooms: json['bathrooms']?.toString(),
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imagePath: json['imagePath']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (id != null) 'id': id,
      'name': name,
      'location': location,
      'propertyType': propertyType,
      'price': price,
      if (area != null) 'area': area,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      'features': features,
      if (imagePath != null) 'imagePath': imagePath,
      if (description != null) 'description': description,
    };
  }
}
