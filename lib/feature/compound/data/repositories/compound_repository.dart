import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/compound/data/models/compound_response.dart';
import 'package:real/feature/compound/data/models/compound_model.dart';

class CompoundRepository {
  final CompoundWebServices _compoundWebServices;

  CompoundRepository({CompoundWebServices? compoundWebServices})
      : _compoundWebServices = compoundWebServices ?? CompoundWebServices();

  Future<CompoundResponse> getCompounds({int page = 1, int limit = 20, bool forceRefresh = false}) async {
    try {
      final response = await _compoundWebServices.getCompounds(page: page, limit: limit, forceRefresh: forceRefresh);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get compounds with full details (fetches list first, then enriches with details)
  Future<CompoundResponse> getCompoundsWithDetails({int page = 1, int limit = 20, bool forceRefresh = false}) async {
    try {
      // First get the basic compound list - force refresh to bypass cache
      final response = await _compoundWebServices.getCompounds(page: page, limit: limit, forceRefresh: true);

      // Get compound IDs
      final compoundIds = response.data.map((c) => c.id).toList();

      if (compoundIds.isEmpty) {
        return response;
      }

      // Fetch detailed data for all compounds
      final detailsMap = await _compoundWebServices.getCompoundDetailsForIds(compoundIds);

      // Enrich compounds with detailed data
      final enrichedCompounds = response.data.map((compound) {
        final details = detailsMap[compound.id];
        if (details != null && details['data'] != null) {
          // Parse the detailed compound data
          final detailData = details['data'] as Map<String, dynamic>;
          final mergedJson = {
            ...compound.toJson(),
            ...detailData,
          };
          return Compound.fromJson(mergedJson);
        }
        return compound;
      }).toList();

      return response.copyWith(data: enrichedCompounds);
    } catch (e) {
      rethrow;
    }
  }

  Future<CompoundResponse> getCompoundsByCompany({
    required String companyId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _compoundWebServices.getCompoundsByCompany(
        companyId: companyId,
        page: page,
        limit: limit,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get compounds by company with full details (fetches list first, then enriches with details)
  Future<CompoundResponse> getCompoundsByCompanyWithDetails({
    required String companyId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      // First get the basic compound list by company
      final response = await _compoundWebServices.getCompoundsByCompany(
        companyId: companyId,
        page: page,
        limit: limit,
      );

      // Get compound IDs
      final compoundIds = response.data.map((c) => c.id).toList();

      if (compoundIds.isEmpty) {
        return response;
      }

      // Fetch detailed data for all compounds
      final detailsMap = await _compoundWebServices.getCompoundDetailsForIds(compoundIds);

      // Enrich compounds with detailed data
      final enrichedCompounds = response.data.map((compound) {
        final details = detailsMap[compound.id];
        if (details != null && details['data'] != null) {
          // Parse the detailed compound data
          final detailData = details['data'] as Map<String, dynamic>;
          final mergedJson = {
            ...compound.toJson(),
            ...detailData,
          };
          return Compound.fromJson(mergedJson);
        }
        return compound;
      }).toList();

      return response.copyWith(data: enrichedCompounds);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCompoundById(String compoundId) async {
    try {
      final response = await _compoundWebServices.getCompoundById(compoundId);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSalespeopleByCompound(String compoundName) async {
    try {
      final response = await _compoundWebServices.getSalespeopleByCompound(compoundName);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
