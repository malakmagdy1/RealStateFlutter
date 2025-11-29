import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/share_model.dart';

class ShareService {
  // API Base URL
  static const String apiBaseUrl = 'https://aqar.bdcbiz.com/api/share-link';

  // Base URL for share pages (fallback)
  static const String shareBaseUrl = 'https://aqar.bdcbiz.com/share';

  /// Get share link from API with full parameter support
  ///
  /// Parameters:
  /// - type: 'unit', 'compound', 'company', or 'sale'
  /// - id: ID of the entity
  /// - compoundIds: List of compound IDs (for company type)
  /// - unitIds: List of unit IDs (for compound/company type)
  /// - hiddenFields: Fields to hide from ALL levels
  /// - hiddenCompanyFields: Fields to hide from company level only
  /// - hiddenCompoundFields: Fields to hide from compound level only
  /// - hiddenUnitFields: Fields to hide from unit level only
  Future<ShareResponse> getShareLink({
    required String type,
    required String id,
    List<String>? compoundIds,
    List<String>? unitIds,
    List<String>? hiddenFields,
    List<String>? hiddenCompanyFields,
    List<String>? hiddenCompoundFields,
    List<String>? hiddenUnitFields,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {
        'type': type,
        'id': id,
      };

      // Add compound IDs if provided
      if (compoundIds != null && compoundIds.isNotEmpty) {
        queryParams['compounds'] = compoundIds.join(',');
      }

      // Add unit IDs if provided
      if (unitIds != null && unitIds.isNotEmpty) {
        queryParams['units'] = unitIds.join(',');
      }

      // Add global hidden fields (applies to all levels)
      if (hiddenFields != null && hiddenFields.isNotEmpty) {
        queryParams['hide'] = hiddenFields.join(',');
      }

      // Add level-specific hidden fields
      if (hiddenCompanyFields != null && hiddenCompanyFields.isNotEmpty) {
        queryParams['hide_company'] = hiddenCompanyFields.join(',');
      }

      if (hiddenCompoundFields != null && hiddenCompoundFields.isNotEmpty) {
        queryParams['hide_compound'] = hiddenCompoundFields.join(',');
      }

      if (hiddenUnitFields != null && hiddenUnitFields.isNotEmpty) {
        queryParams['hide_unit'] = hiddenUnitFields.join(',');
      }

      // Build URI with query parameters
      final uri = Uri.parse(apiBaseUrl).replace(queryParameters: queryParams);

      print('[ShareService] Calling API: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('[ShareService] Response status: ${response.statusCode}');
      print('[ShareService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ShareResponse.fromJson(jsonData);
      } else {
        // Fallback to local URL generation
        print('[ShareService] API failed, using fallback URL generation');
        return _generateLocalShareLink(
          type: type,
          id: id,
          compoundIds: compoundIds,
          unitIds: unitIds,
          hiddenFields: hiddenFields,
          hiddenCompanyFields: hiddenCompanyFields,
          hiddenCompoundFields: hiddenCompoundFields,
          hiddenUnitFields: hiddenUnitFields,
        );
      }
    } catch (e) {
      print('[ShareService] Error calling API: $e');
      // Fallback to local URL generation
      return _generateLocalShareLink(
        type: type,
        id: id,
        compoundIds: compoundIds,
        unitIds: unitIds,
        hiddenFields: hiddenFields,
        hiddenCompanyFields: hiddenCompanyFields,
        hiddenCompoundFields: hiddenCompoundFields,
        hiddenUnitFields: hiddenUnitFields,
      );
    }
  }

  /// Fallback method to generate share link locally
  ShareResponse _generateLocalShareLink({
    required String type,
    required String id,
    List<String>? compoundIds,
    List<String>? unitIds,
    List<String>? hiddenFields,
    List<String>? hiddenCompanyFields,
    List<String>? hiddenCompoundFields,
    List<String>? hiddenUnitFields,
  }) {
    // Build the base URL
    String url = '$shareBaseUrl/$type/$id';
    List<String> queryParts = [];

    // Add compound IDs
    if (compoundIds != null && compoundIds.isNotEmpty) {
      queryParts.add('compounds=${compoundIds.join(',')}');
    }

    // Add unit IDs
    if (unitIds != null && unitIds.isNotEmpty) {
      queryParts.add('units=${unitIds.join(',')}');
    }

    // Add global filter
    if (hiddenFields != null && hiddenFields.isNotEmpty) {
      queryParts.add('filter=${hiddenFields.join(',')}');
    }

    // Add level-specific filters (web view uses filter_company, filter_compound, filter_unit)
    if (hiddenCompanyFields != null && hiddenCompanyFields.isNotEmpty) {
      queryParts.add('filter_company=${hiddenCompanyFields.join(',')}');
    }

    if (hiddenCompoundFields != null && hiddenCompoundFields.isNotEmpty) {
      queryParts.add('filter_compound=${hiddenCompoundFields.join(',')}');
    }

    if (hiddenUnitFields != null && hiddenUnitFields.isNotEmpty) {
      queryParts.add('filter_unit=${hiddenUnitFields.join(',')}');
    }

    // Append query string
    if (queryParts.isNotEmpty) {
      url += '?${queryParts.join('&')}';
    }

    // Generate share URLs for different platforms
    final encodedUrl = Uri.encodeComponent(url);
    final shareTitle = '${_capitalizeType(type)} Details';
    final shareDescription = 'Check out this $type on Aqar App';
    final encodedTitle = Uri.encodeComponent(shareTitle);
    final encodedDescription = Uri.encodeComponent(shareDescription);

    final shareData = ShareData(
      url: url,
      title: shareTitle,
      description: shareDescription,
      image: null,
      whatsappUrl: 'https://wa.me/?text=$encodedTitle%0A$encodedUrl',
      facebookUrl: 'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl',
      twitterUrl: 'https://twitter.com/intent/tweet?text=$encodedTitle&url=$encodedUrl',
      emailUrl: 'mailto:?subject=$encodedTitle&body=$encodedDescription%0A%0A$encodedUrl',
    );

    return ShareResponse(
      success: true,
      type: type,
      data: {'id': id},
      share: shareData,
    );
  }

  String _capitalizeType(String type) {
    if (type.isEmpty) return type;
    return type[0].toUpperCase() + type.substring(1);
  }

  /// Available filter categories for hiding fields
  /// Based on API documentation
  static const Map<String, List<String>> filterCategories = {
    'price': ['normal_price', 'base_price', 'total_price', 'cash_price', 'price_per_meter', 'min_price', 'max_price', 'finishing_price', 'sale_price'],
    'payment': ['down_payment', 'monthly_installment', 'over_years'],
    'area': ['built_up_area', 'land_area', 'garden_area', 'roof_area', 'terrace_area', 'basement_area', 'garage_area', 'total_area', 'pergola_area', 'storage_area', 'penthouse', 'semi_covered_roof_area', 'uncovered_basement', 'extra_built_up_area'],
    'finishing': ['finishing_type', 'finishing_specs', 'finishing_price', 'total_finish_pricing', 'unit_total_with_finish_price'],
    'delivery': ['delivery_date', 'planned_delivery_date', 'actual_delivery_date', 'delivered_at', 'completion_progress'],
    'contact': ['email', 'phone', 'address'],
    'images': ['images', 'floor_plan_image'],
    'location': ['location', 'location_url', 'address', 'headquarters'],
    'building': ['building_name', 'building_number', 'phase', 'stage_number', 'unit_number', 'floor_number'],
    'specs': ['number_of_beds', 'bathrooms', 'living_rooms', 'floor_number', 'view'],
    'type': ['unit_type', 'usage_type', 'category', 'model'],
    'status': ['status', 'is_sold', 'available'],
    'description': ['description'],
    'code': ['unit_code', 'unit_name'],
  };

  /// Company-level specific fields
  static const List<String> companyFields = [
    'name', 'email', 'phone', 'address', 'logo', 'website',
    'headquarters', 'total_compounds'
  ];

  /// Compound-level specific fields
  static const List<String> compoundFields = [
    'name', 'location', 'location_url', 'images', 'total_units',
    'available_units', 'min_price', 'max_price', 'built_up_area',
    'land_area', 'how_many_floors', 'planned_delivery_date',
    'actual_delivery_date', 'completion_progress', 'status', 'club'
  ];

  /// Unit-level specific fields
  static const List<String> unitFields = [
    'unit_code', 'unit_name', 'unit_type', 'usage_type', 'category',
    'model', 'status', 'is_sold', 'available', 'description',
    'building_name', 'building_number', 'unit_number', 'phase',
    'floor_number', 'stage_number', 'number_of_beds', 'bathrooms',
    'living_rooms', 'view', 'built_up_area', 'land_area', 'garden_area',
    'roof_area', 'basement_area', 'terrace_area', 'garage_area',
    'pergola_area', 'storage_area', 'penthouse', 'semi_covered_roof_area',
    'uncovered_basement', 'extra_built_up_area', 'total_area',
    'normal_price', 'base_price', 'total_price', 'cash_price',
    'price_per_meter', 'sale_price', 'down_payment', 'monthly_installment',
    'over_years', 'finishing_type', 'finishing_specs', 'finishing_price',
    'total_finish_pricing', 'unit_total_with_finish_price', 'delivery_date',
    'planned_delivery_date', 'actual_delivery_date', 'delivered_at',
    'completion_progress', 'images', 'floor_plan_image'
  ];

  /// Get category label for display
  static const Map<String, String> categoryLabels = {
    'price': 'Price Information',
    'payment': 'Payment Details',
    'area': 'Area Details',
    'finishing': 'Finishing Info',
    'delivery': 'Delivery Date',
    'contact': 'Contact Info',
    'images': 'Images',
    'location': 'Location',
    'building': 'Building Info',
    'specs': 'Specifications',
    'type': 'Unit Type',
    'status': 'Status',
    'description': 'Description',
    'code': 'Unit Code',
  };

  /// Get Arabic category labels
  static const Map<String, String> categoryLabelsAr = {
    'price': 'معلومات السعر',
    'payment': 'تفاصيل الدفع',
    'area': 'تفاصيل المساحة',
    'finishing': 'معلومات التشطيب',
    'delivery': 'تاريخ التسليم',
    'contact': 'معلومات الاتصال',
    'images': 'الصور',
    'location': 'الموقع',
    'building': 'معلومات المبنى',
    'specs': 'المواصفات',
    'type': 'نوع الوحدة',
    'status': 'الحالة',
    'description': 'الوصف',
    'code': 'كود الوحدة',
  };

  /// Categories available for each level
  static const Map<String, List<String>> levelCategories = {
    'company': ['contact', 'location', 'images'],
    'compound': ['price', 'area', 'delivery', 'location', 'images', 'status'],
    'unit': ['price', 'payment', 'area', 'finishing', 'delivery', 'images', 'building', 'specs', 'type', 'status', 'description', 'code'],
  };
}
